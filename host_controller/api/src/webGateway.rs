

use std::collections::HashMap;
use std::error::Error;
use std::process::exit;
use std::sync::Arc;

use axum::extract::State;
use axum::routing::{get, post};
use base64ct::Encoding;
use serde::{Deserialize, Serialize};
use serde_json; 
use tokio; 
use axum::{Server, Router, body, Json}; 
use axum::debug_handler; 
use axum::http::{self, Request, Response};
use sha2::{Sha256, Digest};
use tower_http::cors::{Any, CorsLayer};
use std::sync::Mutex;
use cookie::Cookie;



const DB_FIELDS: &[&str; 5] = &["user","passhash","is_superuser","valid_token","token_expire_time"];
const CSV_DB_PATH: &str = "/var/data/users.csv";

#[derive(Debug)]
struct UserAccessRecord {
    passhash: String,
    is_superuser: bool, 
    valid_token: String,
    token_expire_time: String
}

struct AppState{
    access_db: Mutex<HashMap<String, UserAccessRecord>>
    
}

fn main() {

    // build shared app state 
    let mut database_records = csv::Reader::from_path(CSV_DB_PATH).unwrap();
    let mut database: HashMap<String, UserAccessRecord> = HashMap::new(); 
    // database fields: user,passhash,is_superuser,valid_token,token_expire_time
    for record in database_records.deserialize() {
        let rec_deserialized: HashMap<String, String> = record.unwrap();
        let mut access_record = UserAccessRecord {
            passhash: rec_deserialized.get("passhash").unwrap().into(), 
            is_superuser: if rec_deserialized.get("is_superuser").unwrap().to_ascii_lowercase() == "yes" {true} else {false},
            valid_token: rec_deserialized.get("valid_token").unwrap_or(&String::new()).into(), 
            token_expire_time: rec_deserialized.get("token_expire_time").unwrap_or(&String::new()).into()
        }; 
        database.insert(rec_deserialized.get("user").unwrap().into(), access_record);
    }

    let shared_state = Arc::new(AppState {
        access_db: Mutex::new(database)
    });

    let ss_ctrlc = shared_state.clone(); 
    ctrlc::set_handler(move || {
        write_csv(&ss_ctrlc.access_db);
        exit(0); 
    }).expect("ERROR: failed to set program exit handler"); 

    if let Err(err) = tokio::runtime::Builder::new_multi_thread()
    .enable_all()
    .build()
    .unwrap()
    .block_on(server_loop(shared_state)) 
    {
        panic!("ERROR: failed to start \n {:?}", err);    
    }; 
    
}

async fn server_loop(shared_state: Arc<AppState>) -> Result<(), Box<dyn std::error::Error + Send + Sync>>{
    let addr =  "127.0.0.1:8080";

    let server_routing = Router::new()
        .route("/v1/auth", get(auth))
        .route("/v1/deauthorize", get(deauthorize))
        .route("/v1/authorize", post(authorize))
        .route("/v1/add_user", post(add_user))
        .with_state(shared_state)
        .layer(
            tower::ServiceBuilder::new()
            .layer(CorsLayer::permissive())
        );
        
    return Server::bind(&addr.parse().unwrap()).serve(server_routing.into_make_service())
    .await
    .map_err(|e| panic!("{:?}", e)); 

}
#[debug_handler]
async fn deauthorize(state: State<Arc<AppState>> , req: Request<axum::body::Body>) -> Response<body::Body> {
    let user_cookie = delete_cookie("X-RCAP-Access-User");
    let token_cookie = delete_cookie("X-RCAP-Access-Token");
    let app_cookie = delete_cookie("X-Target-App");

    let res = Response::builder()
        .header("Set-Cookie", user_cookie)
        .header("Set-Cookie", token_cookie)
        .header("Set-Cookie", app_cookie)
        .header("Location", "/frc4669")
        .status(302).body(empty()).unwrap();
    return res;
}

#[debug_handler]
async fn auth(state: State<Arc<AppState>> , req: Request<axum::body::Body>) -> Response<body::Body> {
    let cookie_header = match req.headers().get("Cookie") {
        Some(d) => d,
        None => return Response::builder().status(401).body(empty()).unwrap(),
    };
    let mut user = String::new() ; 
    let mut token = String::new();
    let mut count = 0; 
    for c in Cookie::split_parse_encoded(cookie_header.to_str().unwrap_or(&String::new())) {
        if c.is_err() {return Response::builder().status(401).body(empty()).unwrap(); };
        let cookie = c.unwrap();
        if cookie.name() == "X-RCAP-Access-User" { user = String::from(cookie.value()); count+=1; }
        else if cookie.name() == "X-RCAP-Access-Token" { token = String::from(cookie.value()); count +=1;};
        if count >= 2{ break; };
    };
    if count < 2 { return Response::builder().status(401).body(empty()).unwrap(); }
    // let user = match req.headers().get("X-Access-User") {
    //     Some(d) => d,
    //     None => return Response::builder().status(401).body(empty()).unwrap(),
    // };
    // let token = match req.headers().get("X-Access-Token") {
    //     Some(d) => d,
    //     None => return Response::builder().status(401).body(empty()).unwrap(),
    // };

    let access_db = state.access_db.lock().unwrap();
    let user_record = match access_db.get(&user.to_string()) {
        Some(rec) => rec, 
        None => return Response::builder().status(401).body(empty()).unwrap()
    };

    //TODO: Add timeout
    if user_record.valid_token == token.to_string() {
        return Response::builder().status(200).body(empty()).unwrap();
    }
    return Response::builder().status(401).body(empty()).unwrap();
}

#[derive(Deserialize, Debug)]
struct JsonAuthorizeStruct {
    user: String,
    passhash: String
}
#[derive(Serialize,Debug)]
struct JsonAuthReturn {
    token: String
}
#[debug_handler]
async fn authorize(state: State<Arc<AppState>>, req: Json<JsonAuthorizeStruct>) -> Response<body::Body> {
    println!("{:?}", req); 
    let mut access_db = state.access_db.lock().unwrap(); 
    let mut user_record = if let Some(r) = access_db.get_mut(&req.user) { 
        r
    } else { return Response::builder().status(401).body(empty()).unwrap(); };
    
    if user_record.passhash != req.passhash { return Response::builder().status(401).body(empty()).unwrap() };

    let new_token = base64ct::Base64ShaCrypt::encode_string(&(Sha256::new().chain_update(rand::random::<i128>().to_string()).finalize())); 
    user_record.valid_token = new_token.clone(); 
    
    // let res_json = serde_json::to_string(&(JsonAuthReturn { token: new_token})).unwrap(); 
    // println!("{}, {}", res_json, user_record.valid_token); 
    let user_cookie = config_access_cookie("X-RCAP-Access-User", &req.user);
    let token_cookie = config_access_cookie("X-RCAP-Access-Token", &new_token);
    let app_cookie = config_access_cookie("X-Target-App", "RCAP");
    let res = Response::builder()
        .header("Set-Cookie", user_cookie)
        .header("Set-Cookie", token_cookie)
        .header("Set-Cookie", app_cookie)
        .status(200).body(empty()).unwrap();
    return res;
}


#[debug_handler]
async fn add_user(state: State<Arc<AppState>>, req: Json<JsonAuthorizeStruct>) -> Response<body::Body> {
    let mut access_db = match state.access_db.lock() {
        Ok(v) => v,
        Err(_) => return Response::builder().status(400).body(empty()).unwrap()
    }; 
    let new_user_record = UserAccessRecord {
        passhash: req.passhash.clone(),
        is_superuser: false,
        valid_token: String::new(), 
        token_expire_time: String::new()
    }; 
    access_db.insert(req.user.clone(), new_user_record); 
    return Response::builder().status(200).body(empty()).unwrap()
}
// utility functions
fn empty() -> body::Body {
    body::Body::empty()
}
fn write_csv(mut_db: &Mutex<HashMap<String, UserAccessRecord>>) {
    if let Err(err) = (|| -> Result<(), Box<dyn Error>> {
        let database = mut_db.lock().unwrap();
        let mut builder = csv::Writer::from_path(CSV_DB_PATH)?;
        builder.write_record(DB_FIELDS)?;
        for (user, record) in database.iter() {
            builder.write_record([user, &record.passhash, &String::from(if record.is_superuser {"yes"} else {"no"}), &record.valid_token, &record.token_expire_time])?;
        };
        builder.flush()?;
        println!("Config written to db file"); 
        return Ok(());
    })() {
        let db = match mut_db.lock() {
            Ok(v) => v,
            Err(v) => v.into_inner()
        }; 
        println!("{:?}", db); 
        println!("Failed to open database file, changes written to STD OUT");
        exit(1); // bascially panicing here, but we need the entire program to exit, not the thread
    }
    
}

fn config_access_cookie(name: &str, value: &str) -> String {
    let mut c = Cookie::new(name, value); 
    c.set_path("/");
    c.set_max_age(cookie::time::Duration::days(1));
    c.set_secure(true);
    c.set_http_only(true);
    c.set_same_site(cookie::SameSite::Strict);
    
    return c.to_string();
}

fn delete_cookie(name: &str) -> String {
    // copied from config_access_cookie
    let mut c = Cookie::new(name, ""); 
    c.set_path("/");
    c.set_max_age(cookie::time::Duration::days(1));
    c.set_secure(true);
    c.set_http_only(true);
    c.set_same_site(cookie::SameSite::Strict);

    c.make_removal(); 
    
    return c.to_string();
}

// fn full<T: Into<Bytes>>(chunk: T) -> BoxBody<Bytes, hyper::Error> {
//     Full::new(chunk.into())
//         .map_err(|never| match never {})
//         .boxed()
// }
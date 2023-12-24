

let e_username = document.getElementById("name");
let e_password = document.getElementById("password");
let e_submit = document.getElementById("submit");

e_submit.onclick = async function(e) {
    let usernameSanitaized = e_username.value.replace(/\s+/g, '');
    let passwordSanitaized = e_password.value.replace(/\s+/g, '');
    if (usernameSanitaized.length == 0 || passwordSanitaized.length == 0) {
        return showNotification(NOTIFICATIONS.notEnoughRequiredFields); 
    }
    let reqStruct = {
        "user": usernameSanitaized, 
        "passhash": await computePasshash(passwordSanitaized)
    }
    
    let res = await fetch("./authorize", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(reqStruct),
    });

    if (!res.ok) {
        switch (res.status) {
            case 401: return showNotification(NOTIFICATIONS.incorrectPasswordOrUsername);
            case 404: return showNotification(NOTIFICATIONS.fourOhFour(res.statusText));
            default: return showNotification(NOTIFICATIONS.serverError(res.statusText));
        }
    }
    alert(`Logout's not implenmented yet, so just clear cookies for ${location.origin} to logout.\n-\n Alvin He :)`)
    window.location = "/"
    console.log("Auth suscess")

}
e_submit.addEventListener("keydown", (e) => {
    if (e.key == "Enter") e_submit.onclick(e); 
});
async function computePasshash(password) {
    let hash = await crypto.subtle.digest("SHA-256", (new TextEncoder()).encode(password));
    let hashStringBuf = "";
    for (let i of new Uint8Array(hash)) { // don't questions it
        hashStringBuf += i.toString()
    }
    let hashEncoded = btoa(hashStringBuf)
    return hashEncoded;
}

const NOTIFICATIONS = {
    notEnoughRequiredFields: "Please make sure all fields are filled out.\nSpaces are not letters.",
    incorrectPasswordOrUsername: "Incorrect Username or Password. \nPlease try again.",
    serverError: (errorText) => `The server had encountered an ERROR.\n${errorText}`,
    fourOhFour: (errorText) => `You have been rejected by the server.\n${errorText}`
}

let e_noti = document.getElementById("noti");
let e_notiText = document.getElementById("noti-text"); 
async function showNotification(text) {
    e_noti.removeAttribute("hidden"); 
    e_notiText.innerText = text
    setTimeout(() => {
        e_noti.setAttribute("hidden", "true");
    }, 5000); 
}
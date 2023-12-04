

use std::{process::Command, os::unix::process::CommandExt}; 

fn main() {
    println!("Host Controller Boot"); 

    Command::new("bash")
    .args(["-c", "echo \"vscode local server start command args\""])
    .exec();
}

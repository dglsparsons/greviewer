use anyhow::Result;

use crate::github::auth::check_auth;

pub async fn run() -> Result<()> {
    let status = check_auth().await?;
    println!("{}", status);
    Ok(())
}

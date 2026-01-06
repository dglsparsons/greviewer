use anyhow::Result;

use crate::github::client::GitHubClient;
use crate::github::types::CommentsResponse;

pub async fn run(url: &str) -> Result<()> {
    let client = GitHubClient::new()?;
    let pr_ref = GitHubClient::parse_pr_url(url)?;

    let comments = client.get_review_comments(&pr_ref).await?;

    let response = CommentsResponse { comments };

    println!("{}", serde_json::to_string(&response)?);

    Ok(())
}

use anyhow::Result;

use crate::github::client::GitHubClient;
use crate::github::types::FetchResponse;

pub async fn run(url: &str) -> Result<()> {
    let client = GitHubClient::new()?;
    let pr_ref = GitHubClient::parse_pr_url(url)?;

    // Fetch PR metadata
    let pr = client.get_pr(&pr_ref).await?;

    // Fetch files with hunks
    let files = client.get_pr_files(&pr_ref, &pr.head_sha).await?;

    // Fetch existing comments
    let comments = client.get_review_comments(&pr_ref).await?;

    let response = FetchResponse {
        pr,
        files,
        comments,
    };

    // Output as JSON for Neovim consumption
    println!("{}", serde_json::to_string(&response)?);

    Ok(())
}

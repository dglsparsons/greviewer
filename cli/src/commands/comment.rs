use anyhow::Result;

use crate::github::client::GitHubClient;
use crate::github::types::CommentResponse;

pub async fn run(url: &str, path: &str, line: u32, side: &str, body: &str) -> Result<()> {
    let client = GitHubClient::new()?;
    let pr_ref = GitHubClient::parse_pr_url(url)?;

    // Get PR to get the head SHA
    let pr = client.get_pr(&pr_ref).await?;

    // Add the comment
    match client
        .add_review_comment(&pr_ref, &pr.head_sha, path, line, side, body)
        .await
    {
        Ok(comment) => {
            let response = CommentResponse {
                success: true,
                comment_id: Some(comment.id),
                html_url: Some(comment.html_url),
                error: None,
            };
            println!("{}", serde_json::to_string(&response)?);
        }
        Err(e) => {
            let response = CommentResponse {
                success: false,
                comment_id: None,
                html_url: None,
                error: Some(e.to_string()),
            };
            println!("{}", serde_json::to_string(&response)?);
        }
    }

    Ok(())
}

use serde::{Deserialize, Serialize};

/// A hunk represents a contiguous block of changes in a diff
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Hunk {
    /// Line number in the new file where this hunk starts (1-indexed)
    pub start: u32,
    /// Number of lines in the new version
    pub count: u32,
    /// Line number in the old file where this hunk starts
    pub old_start: u32,
    /// Number of lines in the old version
    pub old_count: u32,
    /// The actual old content lines (for inline preview)
    pub old_lines: Vec<String>,
    /// Type of change
    pub hunk_type: HunkType,
}

/// Type of change in a hunk
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum HunkType {
    /// Lines only in new version (additions)
    Add,
    /// Lines only in old version (deletions)
    Delete,
    /// Lines modified (both additions and deletions)
    Change,
}

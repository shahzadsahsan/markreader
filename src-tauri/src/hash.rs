// MarkScout — Content Hash for Move Tracking (Rust port of src/lib/hash.ts)
// Hash = SHA-256(first 1KB of content + file size)

use sha2::{Digest, Sha256};
use std::fs;
use std::io::Read;
use std::path::Path;

const HASH_BYTES: usize = 1024;

/// Compute a content hash for move tracking.
/// Uses first 1KB of file content + file size as input.
/// Returns SHA-256 hex string.
pub fn compute_content_hash(path: &Path) -> Result<String, std::io::Error> {
    let metadata = fs::metadata(path)?;
    let file_size = metadata.len();

    let mut file = fs::File::open(path)?;
    let mut buffer = vec![0u8; HASH_BYTES];
    let bytes_read = file.read(&mut buffer)?;
    buffer.truncate(bytes_read);

    let mut hasher = Sha256::new();
    hasher.update(&buffer);
    hasher.update(file_size.to_string().as_bytes());

    Ok(format!("{:x}", hasher.finalize()))
}

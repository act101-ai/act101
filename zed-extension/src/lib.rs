//! Zed MCP server extension for act101.
//!
//! Downloads the `act` binary from the act101-ai/act101 GitHub Releases for the
//! current platform, caches it, and launches `act mcp serve` as a Zed context
//! server. This mirrors `plugin/bin/act.js` (the Node launcher) in Rust/WASM:
//! the asset-naming and target mapping MUST stay in sync with that file and
//! `scripts/install.sh`.

use std::fs;
use zed_extension_api::{self as zed, Command, ContextServerId, Project, Result};

/// Public mirror that carries act's release assets.
const REPO: &str = "act101-ai/act101";

struct Act101Extension {
    /// Path to the downloaded `act` binary, cached across calls within a session.
    cached_binary_path: Option<String>,
}

impl Act101Extension {
    /// Resolve the `act` binary, downloading the latest release for this
    /// platform if it is not already cached on disk.
    fn binary_path(&mut self) -> Result<String> {
        if let Some(path) = &self.cached_binary_path {
            if fs::metadata(path).map_or(false, |stat| stat.is_file()) {
                return Ok(path.clone());
            }
        }

        let release = zed::latest_github_release(
            REPO,
            zed::GithubReleaseOptions {
                require_assets: true,
                pre_release: false,
            },
        )?;

        let (os, arch) = zed::current_platform();
        let target = act_target(os, arch)?;
        let ext = match os {
            zed::Os::Windows => "zip",
            _ => "tar.gz",
        };
        let asset_name = format!("act-{target}.{ext}");

        let asset = release
            .assets
            .iter()
            .find(|asset| asset.name == asset_name)
            .ok_or_else(|| {
                format!(
                    "act release {} has no asset named {asset_name}",
                    release.version
                )
            })?;

        let version_dir = format!("act-{}", release.version);
        let binary_name = match os {
            zed::Os::Windows => "act.exe",
            _ => "act",
        };
        let binary_path = format!("{version_dir}/{binary_name}");

        if !fs::metadata(&binary_path).map_or(false, |stat| stat.is_file()) {
            fs::create_dir_all(&version_dir)
                .map_err(|err| format!("failed to create directory '{version_dir}': {err}"))?;

            let file_kind = match os {
                zed::Os::Windows => zed::DownloadedFileType::Zip,
                _ => zed::DownloadedFileType::GzipTar,
            };
            zed::download_file(&asset.download_url, &version_dir, file_kind)
                .map_err(|err| format!("failed to download {}: {err}", asset.download_url))?;
            zed::make_file_executable(&binary_path)?;

            // Prune older cached versions.
            if let Ok(entries) = fs::read_dir(".") {
                for entry in entries.flatten() {
                    if entry.file_name().to_str() != Some(&version_dir) {
                        fs::remove_dir_all(entry.path()).ok();
                    }
                }
            }
        }

        self.cached_binary_path = Some(binary_path.clone());
        Ok(binary_path)
    }
}

/// Map Zed's platform tuple to act's release target triple. MUST match
/// `plugin/bin/act.js` `detectTarget()` and `scripts/install.sh`.
fn act_target(os: zed::Os, arch: zed::Architecture) -> Result<&'static str> {
    Ok(match (os, arch) {
        (zed::Os::Linux, zed::Architecture::X8664) => "x86_64-unknown-linux-musl",
        (zed::Os::Linux, zed::Architecture::Aarch64) => "aarch64-unknown-linux-gnu",
        (zed::Os::Mac, zed::Architecture::X8664) => "x86_64-apple-darwin",
        (zed::Os::Mac, zed::Architecture::Aarch64) => "aarch64-apple-darwin",
        (zed::Os::Windows, zed::Architecture::X8664) => "x86_64-pc-windows-msvc",
        (zed::Os::Windows, zed::Architecture::Aarch64) => "aarch64-pc-windows-msvc",
        _ => return Err("act has no prebuilt release for this platform/architecture".into()),
    })
}

impl zed::Extension for Act101Extension {
    fn new() -> Self {
        Self {
            cached_binary_path: None,
        }
    }

    fn context_server_command(
        &mut self,
        _context_server_id: &ContextServerId,
        _project: &Project,
    ) -> Result<Command> {
        Ok(Command {
            command: self.binary_path()?,
            args: vec!["mcp".to_string(), "serve".to_string()],
            env: vec![("ACT_LOG_LEVEL".to_string(), "warn".to_string())],
        })
    }
}

zed::register_extension!(Act101Extension);

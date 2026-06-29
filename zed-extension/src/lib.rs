//! Zed MCP server extension for act101.
//!
//! Launches the installed `act` binary as a Zed context server. The binary
//! owns installation, licensing, and auto-update behavior; the extension must
//! not download or cache its own copy.

use zed_extension_api::{self as zed, Command, ContextServerId, Project, Result};

struct Act101Extension;

impl zed::Extension for Act101Extension {
    fn new() -> Self {
        Self
    }

    fn context_server_command(
        &mut self,
        _context_server_id: &ContextServerId,
        _project: &Project,
    ) -> Result<Command> {
        Ok(Command {
            command: "act".to_string(),
            args: vec!["mcp".to_string(), "serve".to_string()],
            env: vec![("ACT_LOG_LEVEL".to_string(), "warn".to_string())],
        })
    }
}

zed::register_extension!(Act101Extension);

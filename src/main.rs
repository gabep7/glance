use clap::Parser;
use std::path::PathBuf;

mod tui;

/// markdown preview for neovim
#[derive(clap::Parser)]
#[command(name = "glance", version, about = "")]
struct Cli {
    /// markdown file to preview
    file: String,

    /// render to terminal (ANSI)
    #[arg(short, long)]
    tui: bool,

    /// watch file for changes and re-render
    #[arg(short, long)]
    watch: bool,

    /// file to read cursor line from for scroll sync
    #[arg(long)]
    cursor_file: Option<String>,
}

fn main() {
    let cli = Cli::parse();

    let path = PathBuf::from(&cli.file);
    if !path.exists() {
        eprintln!("glance: file not found: {}", path.display());
        std::process::exit(1);
    }

    if cli.watch {
        let cursor_file = cli.cursor_file.map(PathBuf::from);
        tui::poll_watch(&path, cursor_file);
    } else {
        tui::render_once(&path);
    }
}
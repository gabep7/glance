use clap::Parser;

mod daemon;
mod ipc;
mod render;
mod watch;

/// A markdown preview daemon with editor integration.
#[derive(Parser)]
#[command(name = "glance", version, about)]
struct Cli {
    /// Markdown file to preview
    file: Option<String>,

    /// Send command to running daemon instead of starting a new one
    #[arg(short, long)]
    daemon: bool,
}

fn main() {
    let cli = Cli::parse();

    match cli.file {
        Some(path) => {
            let path = std::path::PathBuf::from(&path);
            if !path.exists() {
                eprintln!("glance: file not found: {}", path.display());
                std::process::exit(1);
            }
            daemon::run(&path);
        }
        None => {
            eprintln!("glance: no file specified. Usage: glance <file.md>");
            std::process::exit(1);
        }
    }
}

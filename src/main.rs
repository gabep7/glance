use clap::Parser;

mod daemon;
mod ipc;
mod render;
mod tui;
mod watch;

/// markdown preview daemon with editor integration
#[derive(Parser)]
#[command(name = "glance", version, about)]
struct Cli {
    /// markdown file to preview
    file: Option<String>,

    /// render to terminal (ANSI) instead of opening a window
    #[arg(short, long)]
    tui: bool,

    /// read markdown from stdin (implies --tui)
    #[arg(long)]
    stdin: bool,

    /// read length-prefixed markdown from stdin and re-render continuously
    #[arg(long)]
    pipe: bool,

    /// watch file for changes and re-render (only with --tui)
    #[arg(short, long)]
    watch: bool,

    /// send command to running daemon instead of starting a new one
    #[arg(short, long)]
    daemon: bool,
}

fn main() {
    let cli = Cli::parse();

    // stdin mode
    if cli.stdin {
        tui::render_stdin();
        return;
    }

    // pipe mode (nvim split)
    if cli.pipe {
        tui::pipe_mode();
        return;
    }

    // TUI mode
    if cli.tui {
        match &cli.file {
            Some(path) => {
                let path = std::path::PathBuf::from(path);
                if !path.exists() {
                    eprintln!("glance: file not found: {}", path.display());
                    std::process::exit(1);
                }
                if cli.watch {
                    tui::watch_loop(&path);
                } else {
                    tui::render_once(&path);
                }
            }
            None => {
                eprintln!("glance: --tui requires a file argument (or use --stdin)");
                std::process::exit(1);
            }
        }
        return;
    }

    // window mode (default)
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

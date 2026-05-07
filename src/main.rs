use clap::Parser;

mod daemon;
mod render;
mod tui;
mod watch;

/// markdown preview daemon with editor integration
#[derive(Parser)]
#[command(name = "glance", version, about = "", after_long_help = "Examples:
  glance file.md              Open a webview window
  glance --tui file.md        Render to terminal
  glance --stdin --tui        Read markdown from stdin
  glance --pipe --tui         Continuous mode from stdin
  glance --tui --watch f.md   Watch file and re-render")]
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

    /// file to read cursor line from for scroll sync (only with --tui --watch)
    #[arg(long)]
    cursor_file: Option<String>,
}

fn validate_args(cli: &Cli) {
    // cursor_file only valid with watch mode
    if cli.cursor_file.is_some() && !(cli.tui && cli.watch) {
        eprintln!("glance: --cursor_file requires --tui and --watch");
        std::process::exit(1);
    }

    // stdin and pipe are mutually exclusive with other modes
    if cli.stdin && (cli.pipe || cli.watch || cli.file.is_some()) {
        eprintln!("glance: --stdin cannot be used with other file modes");
        std::process::exit(1);
    }

    if cli.pipe && (cli.stdin || cli.watch || cli.file.is_some()) {
        eprintln!("glance: --pipe cannot be used with other file modes");
        std::process::exit(1);
    }
}

fn main() {
    let cli = Cli::parse();
    validate_args(&cli);

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
                    let cursor_file = cli.cursor_file.map(std::path::PathBuf::from);
                    tui::poll_watch(&path, cursor_file);
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

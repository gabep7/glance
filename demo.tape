Output demo.gif

Set FontSize 14
Set Width 1200
Set Height 800
Set Shell "zsh"
Set Theme "Builtin Dark"

Hide

Type "cat > /tmp/demo.md <<'EOF'"
Enter
Type "# glance"
Enter
Type ""
Enter
Type "> live markdown previewer"
Enter
Type ""
Enter
Type "## features"
Enter
Type ""
Enter
Type "- **live preview** -- renders as you type"
Enter
Type "- **scroll sync** -- keeps the preview aligned"
Enter
Type "- *terminal-first*, with an optional webview window"
Enter
Type ""
Enter
Type "## install"
Enter
Type ""
Enter
Type "```bash"
Enter
Type "cargo install glance-md"
Enter
Type "```"
Enter
Type ""
Enter
Type "## usage"
Enter
Type ""
Enter
Type "| command | does |"
Enter
Type "| --- | --- |"
Enter
Type "| `glance file.md` | open webview |"
Enter
Type "| `glance --tui file.md` | terminal preview |"
Enter
Type "| `glance --tui --watch file.md` | watch for changes |"
Enter
Type "| `:Glance` | neovim split preview |"
Enter
Type ""
Enter
Type "## quickstart"
Enter
Type ""
Enter
Type "Open any markdown file and run `:Glance`. A split opens on the right with the rendered preview and keeps pace while you edit."
Enter
Type ""
Enter
Type "No save required. No browser. No node."
Enter
Type ""
Enter
Type "## why another previewer"
Enter
Type ""
Enter
Type "Most markdown previewers fall into one of two camps:"
Enter
Type ""
Enter
Type "1. **Browser-based** -- spawns a headless server, opens a tab, and leaves you context-switching."
Enter
Type "2. **Static TUI** -- renders in the terminal but is a one-shot command. Edit, save, re-run."
Enter
Type ""
Enter
Type "glance is different. It renders inside your editor split and updates on every keystroke."
Enter
Type ""
Enter
Type "## how scroll sync works"
Enter
Type ""
Enter
Type "neovim writes cursor position to a temp file. a 30ms rust poll loop picks it up and re-renders."
Enter
Type ""
Enter
Type "```rust"
Enter
Type "let ratio = cursor_line as f32 / total_lines as f32;"
Enter
Type "let preview_offset = ratio * rendered_height;"
Enter
Type "```"
Enter
Type ""
Enter
Type "## roadmap"
Enter
Type ""
Enter
Type "- [x] neovim integration"
Enter
Type "- [x] scroll sync"
Enter
Type "- [x] live reload"
Enter
Type "- [ ] helix support"
Enter
Type "- [ ] zed support"
Enter
Type ""
Enter
Type "## license"
Enter
Type ""
Enter
Type "MIT"
Enter
Type "EOF"
Enter
Sleep 500ms

Type "clear"
Enter
Sleep 100ms

Show
Type "nvim -n /tmp/demo.md"
Enter
Sleep 1s

Type ":Glance"
Enter
Sleep 2s

# scroll down through sections
Ctrl+D
Sleep 1s
Ctrl+D
Sleep 1s
Ctrl+D
Sleep 1s
Ctrl+D
Sleep 2s

# edit lower down
Type "o- ~~bugs~~ none"
Sleep 500ms
Escape
Sleep 1s

# scroll back up
Ctrl+U
Sleep 1s
Ctrl+U
Sleep 1s
Ctrl+U
Sleep 2s

Type ":GlanceStop"
Enter
Sleep 1s

Type ":q!"
Enter
Sleep 500ms

Hide

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
Type "> markdown preview in your nvim split"
Enter
Type ""
Enter
Type "## features"
Enter
Type ""
Enter
Type "- live preview on every keystroke"
Enter
Type "- scroll sync with cursor position"
Enter
Type "- terminal rendering, no browser"
Enter
Type "- no runtime dependencies"
Enter
Type ""
Enter
Type "## code"
Enter
Type ""
Enter
Type "```rust"
Enter
Type "fn main() {"
Enter
Type "    let nums = (1..100)"
Enter
Type "        .filter(|n| n % 2 == 0)"
Enter
Type "        .collect::<Vec<_>>();"
Enter
Type "    println!(nums.len());"
Enter
Type "}"
Enter
Type "```"
Enter
Type ""
Enter
Type "## usage"
Enter
Type ""
Enter
Type "| key | action |"
Enter
Type "| --- | --- |"
Enter
Type "| `<leader>gp` | toggle |"
Enter
Type "| `<leader>gf` | focus |"
Enter
Type "| `<leader>gs` | freeze sync |"
Enter
Type "| `:Glance` | open |"
Enter
Type "| `:GlanceStop` | close |"
Enter
Type ""
Enter
Type "## install"
Enter
Type ""
Enter
Type "```lua"
Enter
Type '{ "gabep7/glance", build = "cargo build --release" }'
Enter
Type "```"
Enter
Type ""
Enter
Type "## how it works"
Enter
Type ""
Enter
Type "opens a terminal split running a rust binary that renders markdown to ANSI. the binary watches a temp file; nvim writes buffer content on every change. cursor position is written to a second temp file for scroll sync."
Enter
Type ""
Enter
Type "no daemon, no socket, no browser."
Enter
Type ""
Enter
Type "## scroll sync"
Enter
Type ""
Enter
Type "the preview viewport is proportional to your cursor position. move your cursor down through the source and the preview follows. the preview stays aligned to what you are editing."
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
Type "## why"
Enter
Type ""
Enter
Type "most markdown previewers bring a browser tab, a node runtime, or a headless server. glance is one binary with no runtime dependencies, and a preview that keeps its place while you write."
Enter
Type ""
Enter
Type "## license"
Enter
Type ""
Enter
Type "MIT"
Enter
Type ""
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

# scroll down through the document
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms
Type "j"
Sleep 400ms

# scroll back up
Type "k"
Sleep 300ms
Type "k"
Sleep 300ms
Type "k"
Sleep 300ms
Type "k"
Sleep 300ms
Type "k"
Sleep 300ms

# type a new line to show live preview
Type "o"
Sleep 300ms
Type "## live update works"
Sleep 1s
Enter
Sleep 500ms

Type ":GlanceStop"
Enter
Sleep 500ms

Type ":q!"
Enter
Sleep 500ms

Hide
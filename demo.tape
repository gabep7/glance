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
Type "    println!(42);"
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
Type "## why"
Enter
Type ""
Enter
Type "one binary, no runtime deps, keeps its place while you write."
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

Type "j"
Sleep 600ms
Type "j"
Sleep 600ms
Type "j"
Sleep 600ms
Type "j"
Sleep 600ms
Type "k"
Sleep 400ms
Type "k"
Sleep 400ms

Type ":GlanceStop"
Enter
Sleep 500ms

Type ":q!"
Enter
Sleep 500ms

Hide
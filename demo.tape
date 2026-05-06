# demo tape for vhs (charmbracelet/vhs)
# install: brew install vhs
# run:     vhs demo.tape

Output demo.gif

Set FontSize 14
Set Width 1200
Set Height 800
Set Shell "zsh"

Hide

Type `cat > /tmp/demo.md <<'GLANCEDEMO'`
Enter
Type `# glance`
Enter
Type ``
Enter
Type `> live markdown previewer`
Enter
Type ``
Enter
Type `## features`
Enter
Type ``
Enter
Type `- **live preview** — renders as you type`
Enter
Type `- **scroll sync** — preview follows your cursor`
Enter
Type `- *terminal-first*, with an optional webview window`
Enter
Type ``
Enter
Type `## install`
Enter
Type ``
Enter
Type "```bash"
Enter
Type `cargo install glance-md`
Enter
Type "```"
Enter
Type ``
Enter
Type `## usage`
Enter
Type ``
Enter
Type `| command | does |`
Enter
Type `| --- | --- |`
Enter
Type "| `glance file.md` | open webview |"
Enter
Type "| `glance --tui file.md` | terminal preview |"
Enter
Type "| `glance --tui --watch file.md` | watch for changes |"
Enter
Type "| `:Glance` | neovim split preview |"
Enter
Type ``
Enter
Type `GLANCEDEMO`
Enter
Sleep 500ms

Type `clear`
Enter
Sleep 100ms

Show
Type `nvim -n /tmp/demo.md`
Enter
Sleep 1s

# open glance
Type `:Glance`
Enter
Sleep 2s

# scroll down a bit
Type `jjjjj`
Sleep 500ms

# go back up to features section and edit
Type `kkkkk`
Sleep 300ms
Type `o- ~~bugs~~ none`
Escape
Sleep 500ms

# close preview
Type `:GlanceStop`
Enter
Sleep 1s

Type `:q!`
Enter
Sleep 500ms

Hide

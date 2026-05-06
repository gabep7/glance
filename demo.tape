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
Type `> markdown preview that scrolls with your cursor`
Enter
Type ``
Enter
Type `## features`
Enter
Type ``
Enter
Type `- live preview`
Enter
Type `- scroll sync`
Enter
Type `- real-time editing`
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
Type `o- terminal first`
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

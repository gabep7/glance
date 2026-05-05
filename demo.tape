# demo tape for vhs (charmbracelet/vhs)
# install: brew install vhs
# run:     vhs demo.tape
# note:    keybinds (<leader>*) don't work in vhs since it types literal chars.
#          :Glance and :GlanceStop work fine.

Output demo.gif

Set FontSize 14
Set Width 1200
Set Height 800
Set Shell "zsh"

Hide

# create demo markdown file
Type `echo "# glance demo" > /tmp/demo.md`
Enter
Type `echo "" >> /tmp/demo.md`
Enter
Type `echo "## features" >> /tmp/demo.md`
Enter
Type `echo "" >> /tmp/demo.md`
Enter
Type `echo "- live preview" >> /tmp/demo.md`
Enter
Type `echo "- scroll sync" >> /tmp/demo.md`
Enter
Type `echo "- keyboard driven" >> /tmp/demo.md`
Enter
Type `echo "" >> /tmp/demo.md`
Enter
Type "echo '```rust' >> /tmp/demo.md"
Enter
Type `echo 'fn main() {' >> /tmp/demo.md`
Enter
Type `echo '    println!("hello");' >> /tmp/demo.md`
Enter
Type `echo '}' >> /tmp/demo.md`
Enter
Type "echo '```' >> /tmp/demo.md"
Enter
Sleep 500ms
Ctrl+L

Show
Type `nvim /tmp/demo.md`
Enter
Sleep 1s

# open glance preview
Type `:Glance`
Enter
Sleep 2s

# scroll down, preview follows
Type `jjjjjjjjjj`
Sleep 1s

# edit some text live
Type `o## edited live`
Escape
Sleep 1s

# jump to preview window
Type `<C-w>l`
Sleep 1s

# back to source
Type `<C-w>h`
Sleep 1s

# close preview with command
Type `:GlanceStop`
Enter
Sleep 1s

Type `:q!`
Enter
Sleep 500ms

Hide

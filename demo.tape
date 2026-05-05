# demo tape for vhs (charmbracelet/vhs)
# install: brew install vhs
# run:     vhs demo.tape
# note:    nested nvim :terminal might not work in vhs.
#          if it fails, use the manual QuickTime + ffmpeg approach (gif.sh).

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

Show
Type `nvim /tmp/demo.md`
Enter
Sleep 1s

# open glance
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

# freeze scroll sync
Type `<leader>gs`
Sleep 1s

# jump to preview
Type `<leader>gf`
Sleep 1s

# back to source
Type `<leader>gf`
Sleep 1s

# close preview
Type `<leader>gp`
Sleep 1s

Type `:q!`
Enter
Sleep 500ms

Hide

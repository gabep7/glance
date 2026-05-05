# demo tape for vhs (charmbracelet/vhs)
# install: brew install vhs
# run:     vhs demo.tape

Output demo.gif

Set FontSize 14
Set Width 1200
Set Height 800
Set Shell "zsh"

Hide

Type `rm -f /tmp/demo.md /tmp/demo.md.swp /tmp/demo.md.swo`
Enter
Sleep 200ms

Type `cd /tmp && echo '# glance demo' > demo.md`
Enter
Type `echo '' >> demo.md`
Enter
Type `echo '## features' >> demo.md`
Enter
Type `echo '' >> demo.md`
Enter
Type `echo '- live preview' >> demo.md`
Enter
Type `echo '- scroll sync' >> demo.md`
Enter
Type `echo '- keyboard driven' >> demo.md`
Enter
Type `echo '' >> demo.md`
Enter
Type "echo '```rust' >> demo.md"
Enter
Type `echo 'fn main() {' >> demo.md`
Enter
Type `echo '    println!("hello");' >> demo.md`
Enter
Type `echo '}' >> demo.md`
Enter
Type "echo '```' >> demo.md"
Enter
Sleep 500ms

Show
Type `nvim -n demo.md`
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

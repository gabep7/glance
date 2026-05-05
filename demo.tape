# demo tape for vhs (charmbracelet/vhs)
# install: brew install vhs
# run:     vhs demo.tape
# note:    nested nvim :terminal might not work in vhs.
#          if it fails, use the manual QuickTime + ffmpeg approach below.

Output demo.gif

Set FontSize 14
Set Width 1200
Set Height 800
Set Shell "zsh"

Hide

Type "cd /tmp && echo '# glance demo' > demo.md && printf '\n## features\n\n- live preview\n- scroll sync\n- keyboard driven\n\n```rust\nfn main() {\n    println!(\"hello\");\n}\n```\n' >> demo.md"
Enter
Sleep 500ms

Show
Type "nvim demo.md"
Enter
Sleep 1s

# open glance
Type ":Glance"
Enter
Sleep 2s

# scroll down, preview follows
Type "jjjjjjjjjj"
Sleep 1s

# edit some text live
Type "o## edited live"
Escape
Sleep 1s

# freeze scroll sync
Type "<leader>gs"
Sleep 1s

# jump to preview
Type "<leader>gf"
Sleep 1s

# back to source
Type "<leader>gf"
Sleep 1s

# close preview
Type "<leader>gp"
Sleep 1s

Type ":q!"
Enter
Sleep 500ms

Hide

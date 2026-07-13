Output demo.gif

Set FontSize 13
Set Width 1000
Set Height 640
Set Shell "zsh"
Set Theme "Builtin Dark"
Set Padding 0

Hide

Type "cp ~/Projects/Personal/glance/demo.md /tmp/demo.md"
Enter
Sleep 200ms

Type "clear"
Enter
Sleep 100ms

Show
Sleep 300ms

Type "nvim -n /tmp/demo.md"
Enter
Sleep 800ms

# open the preview
Type ":Glance"
Enter
Sleep 1000ms

# scroll down smoothly
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms
Type "j"
Sleep 200ms

# scroll back up
Type "k"
Sleep 150ms
Type "k"
Sleep 150ms
Type "k"
Sleep 150ms
Type "k"
Sleep 150ms
Type "k"
Sleep 150ms
Type "k"
Sleep 150ms

# type a new heading to show live preview
Type "o"
Sleep 200ms
Type "## live update"
Sleep 600ms
Escape
Sleep 400ms

# close and quit
Type ":GlanceStop"
Enter
Sleep 300ms
Type ":q!"
Enter
Sleep 300ms

Hide
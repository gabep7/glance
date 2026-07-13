Output demo.gif

Set FontSize 14
Set Width 1200
Set Height 800
Set Shell "zsh"
Set Theme "Builtin Dark"
Set Padding 0

Hide

Type "cp ~/Projects/Personal/glance/demo.md /tmp/demo.md"
Enter
Sleep 300ms

Type "clear"
Enter
Sleep 200ms

Show
Sleep 500ms

Type "nvim -n /tmp/demo.md"
Enter
Sleep 1500ms

# open the preview
Type ":Glance"
Enter
Sleep 2000ms

# scroll down page by page so the RHS visibly changes
Ctrl+d
Sleep 1000ms
Ctrl+d
Sleep 1000ms
Ctrl+d
Sleep 1000ms
Ctrl+d
Sleep 1000ms

# scroll back up
Ctrl+u
Sleep 1000ms
Ctrl+u
Sleep 1000ms
Ctrl+u
Sleep 1000ms

# type a new heading to show live preview
Type "o"
Sleep 300ms
Type "## this line just appeared"
Sleep 1500ms
Enter
Sleep 1000ms

# close and quit
Type ":GlanceStop"
Enter
Sleep 500ms
Type ":q!"
Enter
Sleep 500ms

Hide
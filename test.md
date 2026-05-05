# glance

> a markdown preview daemon with editor integration

## features

- [x] render gfm markdown
- [x] native webview window
- [x] dark mode (follows system)
- [ ] live reload on file change
- [ ] nvim integration (scroll sync)

## table

| platform | webview | status |
|----------|---------|--------|
| macos | wkwebview | tested |
| linux | webkitgtk | planned |

## code

```rust
fn main() {
    println!("hello from glance");
}
```

## footnotes

built with rust[^1] and pulldown-cmark[^2].

[^1]: zero-cost abstractions, no gc
[^2]: the fastest commonmark parser

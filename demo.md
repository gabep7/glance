# glance

> markdown preview in your nvim split

## features

- live preview on every keystroke
- scroll sync with cursor position
- terminal rendering, no browser

## code

```rust
fn main() {
    println!(42);
}
```

## usage

| key | action |
| --- | --- |
| `<leader>gp` | toggle |
| `<leader>gf` | focus |
| `<leader>gs` | freeze sync |

## install

```lua
{ "gabep7/glance", build = "cargo build --release" }
```

## why

one binary, no runtime deps, keeps its place while you write.
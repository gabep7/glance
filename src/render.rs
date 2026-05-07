use std::fs;
use std::path::Path;

use pulldown_cmark::{html, Options, Parser};

const CSS: &str = include_str!("../css/github.css");

const HTML_TEMPLATE: &str = r#"<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>{css}</style>
</head>
<body>
<article class="markdown-body">
{content}
</article>
</body>
</html>"#;

pub fn render_file(path: &Path) -> String {
    let md = fs::read_to_string(path).unwrap_or_else(|e| {
        format!("Failed to read file: {e}")
    });

    render(&md)
}

pub fn render(markdown: &str) -> String {
    let mut options = Options::empty();
    options.insert(Options::ENABLE_TABLES);
    options.insert(Options::ENABLE_FOOTNOTES);
    options.insert(Options::ENABLE_STRIKETHROUGH);
    options.insert(Options::ENABLE_TASKLISTS);
    options.insert(Options::ENABLE_HEADING_ATTRIBUTES);

    let parser = Parser::new_ext(markdown, options);

    let mut content = String::new();
    html::push_html(&mut content, parser);

    HTML_TEMPLATE
        .replacen("{css}", CSS, 1)
        .replacen("{content}", &content, 1)
}

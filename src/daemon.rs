use std::path::Path;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use tao::event_loop::{ControlFlow, EventLoop};
use tao::window::WindowBuilder;
use wry::WebViewBuilder;

use crate::render;

pub fn run(path: &Path) {
    let html = render::render_file(path);
    let title = path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("glance");

    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .with_title(&format!("{} — glance", title))
        .with_inner_size(tao::dpi::LogicalSize::new(900.0, 700.0))
        .build(&event_loop)
        .expect("failed to create window");

    // Allow cmd+w to close
    let opened = Arc::new(AtomicBool::new(true));

    #[cfg(target_os = "linux")]
    let _webview = {
        use tao::platform::unix::WindowExtUnix;
        WebViewBuilder::new()
            .with_html(&html)
            .build_gtk(window.gtk_window())
            .expect("failed to create webview")
    };

    #[cfg(not(target_os = "linux"))]
    let _webview = WebViewBuilder::new()
        .with_html(&html)
        .build(&window)
        .expect("failed to create webview");

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            tao::event::Event::WindowEvent {
                event: tao::event::WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,

            tao::event::Event::WindowEvent {
                event: tao::event::WindowEvent::Destroyed,
                ..
            } => {
                opened.store(false, Ordering::SeqCst);
                *control_flow = ControlFlow::Exit;
            }

            _ => {}
        }
    });
}

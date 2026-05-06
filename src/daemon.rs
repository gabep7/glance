use std::path::{Path, PathBuf};
use std::sync::mpsc;

use tao::event_loop::{ControlFlow, EventLoopBuilder};
use tao::window::WindowBuilder;
use wry::WebViewBuilder;

use crate::render;
use crate::watch;

#[derive(Debug)]
enum UserEvent {
    Reload(PathBuf),
}

pub fn run(path: &Path) {
    let path = path.to_path_buf();
    let html = render::render_file(&path);
    let title = path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("glance");

    let event_loop = EventLoopBuilder::<UserEvent>::with_user_event().build();
    let proxy = event_loop.create_proxy();

    // file watcher on a background thread
    let watch_path = path.clone();
    let watch_proxy = proxy.clone();
    let (watcher_tx, watcher_rx) = mpsc::channel::<PathBuf>();
    let _watcher = watch::watch_file(&watch_path, watcher_tx)
        .expect("failed to start file watcher");
    std::thread::spawn(move || {
        for changed in watcher_rx {
            let _ = watch_proxy.send_event(UserEvent::Reload(changed));
        }
    });

    let window = WindowBuilder::new()
        .with_title(format!("{} — glance", title))
        .with_inner_size(tao::dpi::LogicalSize::new(900.0, 700.0))
        .build(&event_loop)
        .expect("failed to create window");

    #[cfg(target_os = "linux")]
    let webview = {
        use tao::platform::unix::WindowExtUnix;
        use wry::WebViewBuilderExtUnix;
        WebViewBuilder::new()
            .with_html(&html)
            .build_gtk(window.gtk_window())
            .expect("failed to create webview")
    };

    #[cfg(not(target_os = "linux"))]
    let webview = WebViewBuilder::new()
        .with_html(&html)
        .build(&window)
        .expect("failed to create webview");

    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            tao::event::Event::UserEvent(UserEvent::Reload(changed)) => {
                let new_html = render::render_file(&changed);
                let _ = webview.load_html(&new_html);
            }

            tao::event::Event::WindowEvent {
                event: tao::event::WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,

            tao::event::Event::WindowEvent {
                event: tao::event::WindowEvent::Destroyed,
                ..
            } => *control_flow = ControlFlow::Exit,

            _ => {}
        }
    });
}

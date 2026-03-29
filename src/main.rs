use axum::{Router, routing::get};
use tokio::net::TcpListener;

mod config;
mod db;
mod error;
mod state;

#[tokio::main]
async fn main() {
    //*import env variables from .env file
    dotenvy::dotenv().ok();

    //*load config from env variables into a typed struct
    let config = config::Config::from_env().expect("Failed to load config files");
    let pool = db::create_pool(&config.database_url).await;

    let port = config.port;

    let state = state::AppState {
        config,
        db_pool: pool,
    };

    //*build the app with routes and shared state (config, db pool, etc.)
    let app = Router::new()
        .route("/health", get(handler))
        .with_state(state);

    //*bind to the port and serve the app
    let listener = TcpListener::bind(format!("0.0.0.0:{port}")).await.unwrap();

    println!("Listening on port {}", listener.local_addr().unwrap());

    //*serve the app with hyper (via axum)
    axum::serve(listener, app).await.unwrap();
}

//route handler for health check endpoint
async fn handler() -> &'static str {
    "Hello, world!"
}

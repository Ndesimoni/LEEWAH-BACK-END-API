use crate::config::Config;
use sqlx::postgres::PgPool;

#[derive(Debug, Clone)]
pub struct AppState {
    pub config: Config,
    pub db_pool: PgPool,
}

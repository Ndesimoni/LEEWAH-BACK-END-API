// Axum and serde imports needed to convert errors into HTTP JSON responses

use axum::{Json, http::StatusCode, response::IntoResponse, response::Response};

use serde_json::json;

// All possible errors in the Leewah API — every handler returns this type

pub enum AppError {
    Unauthorized,
    Forbidden,
    NotFound(String),
    ValidationError(String),
    InsufficientBalance,
    RateLimitExceeded,
    Internal(anyhow::Error),
}

// Maps each error variant to the correct HTTP status code and JSON body

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, "Unauthorized".to_string()),
            AppError::Forbidden => (StatusCode::FORBIDDEN, "Forbidden".to_string()),
            AppError::NotFound(message) => (StatusCode::NOT_FOUND, message.to_string()),
            AppError::ValidationError(message) => {
                (StatusCode::UNPROCESSABLE_ENTITY, message.to_string())
            }
            AppError::InsufficientBalance => (
                StatusCode::UNPROCESSABLE_ENTITY,
                "Insufficient balance".to_string(),
            ),
            AppError::RateLimitExceeded => (
                StatusCode::TOO_MANY_REQUESTS,
                "Rate limit exceeded".to_string(),
            ),
            AppError::Internal(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "Internal server error".to_string(),
            ),
        };

        (status, Json(json!({ "error": message }))).into_response()
    }
}

// Helper to wrap any external error (sqlx, redis, etc.) into AppError::Internal
impl AppError {
    pub fn internal(e: impl std::error::Error) -> Self {
        AppError::Internal(anyhow::anyhow!(e.to_string()))
    }
}

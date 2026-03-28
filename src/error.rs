pub enum AppError {
    Unauthorized,
    Forbidden,
    NotFound(String),
    ValidationError(String),
    InsufficientBalance,
    RateLimitExceeded,
    Internal(anyhow::Error),
}

use axum::{Json, http::StatusCode, response::IntoResponse, response::Response};

use serde_json::json;

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

impl AppError {
    pub fn internal(e: impl std::error::Error) -> Self {
        AppError::Internal(anyhow::anyhow!(e.to_string()))
    }
}

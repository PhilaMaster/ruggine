use actix_web::{web, HttpResponse, Responder};

use crate::models::AppState;


pub async fn index() -> impl Responder {
    HttpResponse::Ok().body("<h1>Welcome!</h1><p>Go to <a href=\"/users\">/users</a> to see the list of users.</p>")
}
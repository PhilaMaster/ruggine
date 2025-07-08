mod schema;
mod models;

mod middleware{
    pub mod authentication_middleware;
}

// utilities
mod utility {
    pub mod authorization;
    pub mod connection;
    pub mod user;
}

// handlers
mod handler {
    pub mod authorization;
    pub mod user;
}


// imports
use diesel::prelude::*;
use actix_web::{web, App, HttpServer, Result, HttpResponse, middleware::Logger, HttpRequest};
use serde::{Deserialize, Serialize};
use crate::handler::authorization::authorization::{login_handler, test_handler};
use crate::handler::user::user::{create_user_handler, get_users_handler};
use crate::middleware::authentication_middleware::AuthMiddleware;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();


    println!("Server running on http://localhost:8080");

    HttpServer::new(|| {
        App::new()
            .wrap(Logger::default())
            .service(
                web::scope("")
                    .route("/auth/register", web::post().to(create_user_handler))
                    .route("/auth/login", web::post().to(login_handler))
                    .service(
                        web::scope("")
                            .wrap(AuthMiddleware)
                            .route("/users", web::get().to(get_users_handler))
                            .route("/testToken", web::get().to(test_handler))
                    )
            )
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}

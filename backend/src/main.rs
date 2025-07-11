pub(crate) mod schema;
pub(crate) mod models;

mod middleware{
    pub mod authentication_middleware;
}

// utilities
mod utility {
    pub mod authorization;
    pub mod connection;
    pub mod user;
    pub mod private_messages;
    pub mod group_message;
    pub mod group;
    pub mod group_invitation;
}

// handlers
mod handler {
    pub mod authorization;
    pub mod user;
    pub mod private_messages;
    pub mod group_message;
    pub mod group;
    pub mod group_invitation;
}


// imports
use diesel::prelude::*;
use actix_web::{web, App, HttpServer, Result, HttpResponse, middleware::Logger, HttpRequest};
use serde::{Deserialize, Serialize};
use crate::handler::authorization::authorization::{login_handler, test_handler};
use crate::handler::user::user::{create_user_handler, get_users_handler};
use crate::middleware::authentication_middleware::AuthMiddleware;
use crate::handler::private_messages::private_messages::{get_private_messages_handler, send_private_message_handler};
use crate::handler::group::group::{get_all_groups_of_a_user_handler, create_group_handler};
use crate::handler::group_invitation::group_invitation::{create_group_invitation_handler, delete_group_invitation_handler, get_user_group_invitations_handler};
use crate::handler::group_message::group_message::{get_all_group_messages_handler, send_group_message_handler};

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
                            .route("/privateMessages", web::get().to(get_private_messages_handler))
                            .route("/privateMessages", web::post().to(send_private_message_handler))
                            .route("/groupMessages", web::get().to(get_all_group_messages_handler))
                            .route("/groupMessages", web::post().to(send_group_message_handler))
                            .route("/groups", web::get().to(get_all_groups_of_a_user_handler))
                            .route("/groups", web::post().to(create_group_handler))
                            .route("/groupInvites", web::get().to(get_user_group_invitations_handler))
                            .route("/groupInvites", web::post().to(create_group_invitation_handler))
                            .route("/groupInvites", web::delete().to(delete_group_invitation_handler))
                    )
            )
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}

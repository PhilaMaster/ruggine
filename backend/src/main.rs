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
    pub mod messages;
    pub mod group_invitation;
    pub mod chats;
    pub mod log_manager;
}

// handlers
mod handler {
    pub mod authorization;
    pub mod user;
    // pub mod private_messages;
    pub mod messages;
    // pub mod group_message;
    pub mod group_invitation;
    pub mod chats;
    pub mod websocket;
}

use std::collections::HashMap;
use std::sync::{Arc, Mutex};
// imports
use actix::prelude::*;
use actix_web::{web, App, HttpServer, Result, HttpResponse, middleware::Logger, HttpRequest};
use actix_web::web::Data;
use dotenvy::dotenv;
use serde::{Deserialize, Serialize};
use crate::handler::authorization::authorization::{login_handler, test_handler};
use crate::handler::chats::chats::{create_group_handler, create_private_chat_handler, get_chat_info_handler};
use crate::handler::user::user::{create_user_handler, get_users_handler};
use crate::middleware::authentication_middleware::AuthMiddleware;
// use crate::handler::private_messages::private_messages::{get_private_messages_handler, send_private_message_handler};
use crate::handler::group_invitation::group_invitation::{accept_group_invitation_handler, create_group_invitation_handler, delete_group_invitation_handler, get_user_group_invitations_handler};
// use crate::handler::group_message::group_message::{get_all_group_messages_handler, send_group_message_handler};
use crate::handler::websocket;
use crate::handler::websocket::{ws_index, WebSocketHandler};
use crate::handler::messages::messages::{get_new_messages_since_handler, send_message_handler};
use crate::utility::log_manager::log_manager::log_cpu_usage;

type ClientSockets = Arc<Mutex<HashMap<String, Addr<WebSocketHandler>>>>;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv().ok();
    env_logger::init();
    tokio::spawn(log_cpu_usage());

    let client_sockets: ClientSockets = Arc::new(Mutex::new(HashMap::new()));


    println!("Server running on http://localhost:8080");

    HttpServer::new(move || {
        App::new()
            .app_data(Data::new(client_sockets.clone()))
            .wrap(Logger::default())
            .service(
                web::scope("")
                    .route("/auth/register", web::post().to(create_user_handler))
                    .route("/auth/login", web::post().to(login_handler))
                    .service(
                        web::scope("")
                            .wrap(AuthMiddleware)
                            .route("/ws", web::get().to(ws_index))
                            .route("/users", web::get().to(get_users_handler))
                            .route("/testToken", web::get().to(test_handler))
                            .route("/chat", web::post().to(create_private_chat_handler))
                            .route("/groups", web::post().to(create_group_handler))
                            .route("/groupInvites", web::get().to(get_user_group_invitations_handler))
                            .route("/groupInvites", web::post().to(create_group_invitation_handler))
                            .route("/groupInvites", web::delete().to(delete_group_invitation_handler))
                            .route("/groupInvites/accept", web::post().to(accept_group_invitation_handler))
                            .route("/chatMessages", web::get().to(get_new_messages_since_handler))
                            .route("/chatInfo", web::get().to(get_chat_info_handler))
                            .route("/sendMessage", web::post().to(send_message_handler))
                    )
            )
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}

pub mod messages {
use crate::handler::websocket::SocketMessage;
    use crate::utility::authorization::authorization::Claims;
    use crate::utility::chats::chats::{get_id_members_of_chat, is_user_in_chat};
    use crate::utility::connection::establish_connection;
    use crate::utility::messages::messages::{get_new_messages_since, send_message, GetNewMessagesQuery, SendMessageRequest};
    use crate::ClientSockets;
    use actix_web::{web, HttpMessage, HttpRequest};
    use diesel::QueryResult;

    // ottiene i nuovi messaggi da una chat o gruppo
    pub async fn get_new_messages_since_handler(req: HttpRequest, query: web::Query<GetNewMessagesQuery>) -> actix_web::Result<actix_web::HttpResponse> {
        let mut conn = establish_connection();

        if let Some(claims) = req.extensions().get::<Claims>() {
            //recupera la data dal query param (esempio: ?since=2025-07-01T00:00:00)
            let since = query.since
                .clone()
                .unwrap_or_else(|| "1970-01-01T00:00:00".to_string());//prende tutti i messaggi se non viene specificato un valore


            match get_new_messages_since(&mut conn, claims.user_id, since) {
                Ok(messages) => Ok(actix_web::HttpResponse::Ok().json(messages)),
                Err(_) => Ok(actix_web::HttpResponse::InternalServerError().json(serde_json::json!({
                    "status": 500,
                    "error": "Errore nel recupero dei messaggi"
                }))),
            }
        } else {
            Ok(actix_web::HttpResponse::Unauthorized().json(serde_json::json!({
                "status": 401,
                "error": "Unauthorized access"
            })))
        }
    }

    pub async fn send_message_handler(req: HttpRequest,
                                      message_data: web::Json<SendMessageRequest>,
                                      client_sockets: web::Data<ClientSockets>,
    ) -> actix_web::Result<actix_web::HttpResponse> {
        let mut conn = establish_connection();

        if let Some(claims) = req.extensions().get::<Claims>() {
            //controllo che l'utente faccia parte della chat
            println!("User ID: {}, Chat ID: {}, Content: {}", claims.user_id, message_data.chat_id, message_data.content);
            if !is_user_in_chat(&mut conn, claims.user_id, message_data.chat_id){
                return Ok(actix_web::HttpResponse::Forbidden().json(serde_json::json!({
                    "status": 403,
                    "error": "User is not part of the chat"
                })));
            }

            match send_message(&mut conn, message_data.chat_id, claims.user_id, message_data.content.clone()) {
                Ok(messages) => {
                    match get_id_members_of_chat(&mut conn, message_data.chat_id){
                        Ok(members) => {
                            // Notifica tutti gli utenti nella chat
                            let user_sockets = client_sockets.get_ref().lock().unwrap();
                            for member in members {
                                if let Some(socket) = user_sockets.get(&member) {
                                    socket.do_send(SocketMessage{
                                        json_message: serde_json::to_string(&messages)?,
                                    });
                                }
                                println!("Notifying user {} about new message in chat {}", member, message_data.chat_id);
                            }
                        }
                        Err(_) => return Ok(actix_web::HttpResponse::InternalServerError().json(serde_json::json!({
                            "status": 500,
                            "error": "Errore nel recupero dei membri della chat"
                        }))),
                    }
                    // Notifica tutti gli utenti nella chat

                    Ok(actix_web::HttpResponse::Ok().json(messages))
                },
                Err(_) => Ok(actix_web::HttpResponse::InternalServerError().json(serde_json::json!({
                    "status": 500,
                    "error": "Errore nel recupero dei messaggi"
                }))),
            }
        } else {
            Ok(actix_web::HttpResponse::Unauthorized().json(serde_json::json!({
                "status": 401,
                "error": "Unauthorized access"
            })))
        }
    }
}
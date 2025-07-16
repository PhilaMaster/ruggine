pub mod messages {
    use actix_web::{web, HttpMessage, HttpRequest};
    use crate::utility::authorization::authorization::Claims;
    use crate::utility::chats::chats::is_user_in_chat;
    use crate::utility::connection::establish_connection;
    use crate::utility::group::group::{is_user_part_of_group, CreateGroupRequest};
    use crate::utility::messages::messages::{get_new_messages_since, send_message, SendMessageRequest};

    pub async fn get_new_messages_since_handler(req: HttpRequest) -> actix_web::Result<actix_web::HttpResponse> {
        let mut conn = establish_connection();

        if let Some(claims) = req.extensions().get::<Claims>() {
            //recupera la data dal query param (esempio: ?since=2025-07-01T00:00:00)
            let since = req.query_string()
                .split('&')
                .find_map(|kv| {
                    let mut parts = kv.split('=');
                    if parts.next()? == "since" {
                        parts.next().map(|v| v.to_string())
                    } else {
                        None
                    }
                })
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
    
    pub async fn send_message_handler(req: HttpRequest, message_data: web::Json<SendMessageRequest>) -> actix_web::Result<actix_web::HttpResponse> {
        let mut conn = establish_connection();

        if let Some(claims) = req.extensions().get::<Claims>() {
            //controllo che l'utente faccia parte della chat 
            if !is_user_in_chat(&mut conn, claims.user_id, message_data.chat_id){
                return Ok(actix_web::HttpResponse::Forbidden().json(serde_json::json!({
                    "status": 403,
                    "error": "User is not part of the chat"
                })));
            }

            match send_message(&mut conn, message_data.chat_id, claims.user_id, message_data.content.clone()) {
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
}
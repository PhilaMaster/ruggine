pub mod chats{
    use actix_web::{web, HttpMessage, HttpRequest, HttpResponse, Result};
    use crate::utility::connection::establish_connection;
    use serde::Deserialize;
    use crate::utility::chats::chats::{get_chat_by_id, get_chat_members_by_chat_id, is_user_in_chat, ChatMemberInfo};
    use crate::models::{Chat, User};
    use crate::utility::authorization::authorization::Claims;

    #[derive(Deserialize)]
    pub struct ChatInfoQuery {
        pub chat_id: i32,
    }

    #[derive(serde::Serialize)]
    pub struct ChatInfoWithMembers {
        pub chat: Chat,
        pub members: Vec<ChatMemberInfo>,
    }

    pub async fn get_chat_info_handler(req: HttpRequest, query: web::Query<ChatInfoQuery>) -> Result<HttpResponse> {
        let mut conn = establish_connection();

        if let Some(claims) = req.extensions().get::<Claims>() {
            if !is_user_in_chat(&mut conn, claims.user_id, query.chat_id) {
                return Ok(HttpResponse::Forbidden().json(serde_json::json!({
                        "status": 403,
                        "error": "User is not part of the chat"
                    })))
            };
            let chat = get_chat_by_id(&mut conn, query.chat_id).ok().flatten();//sarebbe possibile effettuare un check per vedere se la chat è sua, tramite il token
            if let Some(chat) = chat {
                let members = get_chat_members_by_chat_id(&mut conn, query.chat_id).unwrap();
                Ok(HttpResponse::Ok().json(ChatInfoWithMembers {
                    chat,
                    members,
                }))
            } else {
                Ok(HttpResponse::NotFound().json(serde_json::json!({
                "error": "Chat non trovata"
            })))
            }
        }else {
            Ok(actix_web::HttpResponse::Unauthorized().json(serde_json::json!({
                "status": 401,
                "error": "Unauthorized access"
            })))
        }
    }

}
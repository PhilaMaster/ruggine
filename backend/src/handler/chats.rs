pub mod chats{
    use actix_web::{web, HttpRequest, HttpResponse, Result};
    use crate::utility::connection::establish_connection;
    use serde::Deserialize;
    use crate::utility::chats::chats::{get_chat_by_id, get_chat_members_by_chat_id, ChatMemberInfo};
    use crate::models::{Chat, User};

    #[derive(Deserialize)]
    pub struct ChatInfoQuery {
        pub chat_id: i32,
    }

    #[derive(serde::Serialize)]
    pub struct ChatInfoWithMembers {
        pub chat: Chat,
        pub members: Vec<ChatMemberInfo>,
    }

    pub async fn get_chat_info_handler(query: web::Query<ChatInfoQuery>) -> Result<HttpResponse> {
        let mut conn = establish_connection();
        let chat = get_chat_by_id(&mut conn, query.chat_id).ok().flatten();
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
    }

}
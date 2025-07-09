
pub mod private_messages {
    use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};
    use diesel::QueryResult;
    use crate::utility::authorization::authorization::Claims;
    use crate::utility::connection::establish_connection;
    use crate::utility::private_messages::private_messages::{get_all_private_messages, send_private_message};
    use crate::utility::private_messages::private_messages::SendPrivateMessageRequest;

    pub(crate) async fn get_private_messages_handler(req: HttpRequest) -> actix_web::Result<actix_web::HttpResponse> {
        let mut conn = establish_connection();

        if let Some(claims) = req.extensions().get::<Claims>(){
            match get_all_private_messages(&mut conn, claims.user_id) {
                Ok(messages) => {
                    Ok(HttpResponse::Ok().json(messages))
                }
                Err(_) => {
                    Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                        "error": "Failed to create user"
                    })))
                }  
            }
        }else {
            return Ok(actix_web::HttpResponse::Unauthorized().json(serde_json::json!({
                "status": 403,
                "error": "Unauthorized access"
            })));
        }
    }
    
    pub async fn send_private_message_handler(req: HttpRequest, user_data: web::Json<SendPrivateMessageRequest>) -> actix_web::Result<actix_web::HttpResponse> {
        let mut conn = establish_connection();
        if let Some(claims) = req.extensions().get::<Claims>(){
            match send_private_message(&mut conn, claims.user_id, user_data.receiver_id, user_data.text.clone()) {
                Ok(sent) => {
                    Ok(HttpResponse::Created().json(sent))
                }
                Err(_) => {
                    Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                        "error": "Failed to send private message"
                    })))
                } 
            }
        }else {
            return Ok(actix_web::HttpResponse::Unauthorized().json(serde_json::json!({
                "status": 403,
                "error": "Unauthorized access"
            })));
        }
    }
}
pub mod group_message{
    // create handlers for group messages
    use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};
    use crate::utility::authorization::authorization::Claims;
    use crate::utility::connection::establish_connection;
    use crate::utility::group_message::group_message::{get_all_group_messages, send_group_message, GroupMessageRequest};
    use crate::utility::group::group::{get_group_by_name};

    pub async fn get_all_group_messages_handler(req: HttpRequest) -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();
        if let Some(claims) = req.extensions().get::<Claims>() {
            match get_all_group_messages(&mut conn, claims.user_id) {
                Ok(messages) => {
                    Ok(HttpResponse::Ok().json(messages))
                },
                Err(e) => {
                    Err(actix_web::error::ErrorInternalServerError(format!("Database error: {}", e)))
                }
            }
        } else {
            Ok(HttpResponse::Unauthorized().body("Claims not found"))
        }
    }

    pub async fn send_group_message_handler(req: HttpRequest, message_data: web::Json<GroupMessageRequest>) -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();

        let group_name = message_data.group_name.clone();
        let group_id = match get_group_by_name(&mut conn, group_name.clone()) {
            Ok(group) => match group.id {
                Some(id) => id,
                None => {
                    return Ok(HttpResponse::BadRequest().json(format!("Group {} has no valid ID", &group_name)));
                }
            },
            Err(_) => {
                return Ok(HttpResponse::NotFound().json(format!("Group {} not found", &group_name)));
            }
        };

        if let Some(claims) = req.extensions().get::<Claims>() {
            match send_group_message(&mut conn, claims, group_id, message_data.text.clone()) {
                Ok(sent) => {
                    Ok(HttpResponse::Created().json(sent))
                },
                Err(e) => {
                    Err(actix_web::error::ErrorInternalServerError(format!("Database error: {}", e)))
                }
            }
        } else {
            Ok(HttpResponse::Unauthorized().body("Claims not found"))
        }
    }
}
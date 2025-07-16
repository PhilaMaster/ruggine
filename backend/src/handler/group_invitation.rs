pub mod group_invitation {
    use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};
    use crate::utility::authorization::authorization::Claims;
    use crate::utility::chats::chats::is_user_in_chat;
    use crate::utility::connection::establish_connection;
    use crate::utility::group_chat::group_chat::{get_group_by_name};
    use crate::utility::group_invitation::group_invitation::{get_user_group_invitations, create_group_invitation, GroupInvitationRequest};
    use crate::utility::user::user::get_user_by_username;

    pub async fn get_user_group_invitations_handler(req: HttpRequest) -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();
        // richiede login, quindi serve ottenere i claims
        if let Some(claims) = req.extensions().get::<Claims>() {
            match get_user_group_invitations(&mut conn, claims.user_id) {
                Ok(invitations) => {
                    Ok(HttpResponse::Ok().json(invitations))
                },
                Err(e) => {
                    Err(actix_web::error::ErrorInternalServerError(format!("Database error: {}", e)))
                }
            }
        } else {
            Ok(HttpResponse::Unauthorized().body("Claims not found"))
        }
    }

    pub async fn create_group_invitation_handler(req: HttpRequest, invitation_data: web::Json<GroupInvitationRequest>) -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();
        
        // richiede login, quindi serve ottenere i claims
        if let Some(claims) = req.extensions().get::<Claims>() {
            if !is_user_in_chat(&mut conn, claims.user_id, invitation_data.chat_id) {
                return Ok(HttpResponse::Forbidden().body("User is not part of the chat"));
            }
            if is_user_in_chat(&mut conn, invitation_data.receiver_id, invitation_data.chat_id) {
                return Ok(HttpResponse::BadRequest().body("Receiver is already part of the chat"));
            }
            match create_group_invitation(&mut conn, invitation_data.chat_id, claims.user_id, invitation_data.receiver_id) {
                Ok(_) => {
                    Ok(HttpResponse::Created().finish())
                },
                Err(e) => {
                    Err(actix_web::error::ErrorInternalServerError(format!("Database error: {}", e)))
                }
            }
        } else {
            Ok(HttpResponse::Unauthorized().body("Claims not found"))
        }
    }

    pub(crate) async fn delete_group_invitation_handler(req: HttpRequest) -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();
        // richiede login, quindi serve ottenere i claims
        if let Some(claims) = req.extensions().get::<Claims>() {
            let group_id: i32 = req.match_info().get("group_id").unwrap_or("0").parse().unwrap_or(0);
            let sender_id: i32 = claims.user_id;
            let receiver_id: i32 = req.match_info().get("receiver_id").unwrap_or("0").parse().unwrap_or(0);

            match crate::utility::group_invitation::group_invitation::delete_group_invitation(&mut conn, group_id, sender_id) {
                Ok(_) => {
                    Ok(HttpResponse::NoContent().finish())
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
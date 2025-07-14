pub mod group_invitation {
    use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};
    use crate::utility::authorization::authorization::Claims;
    use crate::utility::connection::establish_connection;
    use crate::utility::group::group::{get_group_by_name};
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

        let rec_username = invitation_data.receiver_username.clone();

        let rec_user_id = match get_user_by_username(&mut conn, &rec_username) {
            Ok(user) => user.id,
            Err(_) => {
                return Ok(HttpResponse::NotFound().json(format!("Username {} not found", &rec_username)));
            }
        };

        let group_name = invitation_data.group_name.clone();
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
        // richiede login, quindi serve ottenere i claims
        if let Some(claims) = req.extensions().get::<Claims>() {
            match create_group_invitation(&mut conn, group_id, claims.user_id, rec_user_id) {
                Ok(invitation) => {
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

            match crate::utility::group_invitation::group_invitation::delete_group_invitation(&mut conn, group_id, sender_id, receiver_id) {
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
pub mod group_invitation {
    use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};
    use crate::utility::authorization::authorization::Claims;
    use crate::utility::chats::chats::{add_member_to_chat, is_user_in_chat};
    use crate::utility::connection::establish_connection;
    use crate::utility::group_chat::group_chat::get_group_chat_info_new_member;
    use crate::utility::group_invitation::group_invitation::{get_user_group_invitations, create_group_invitation, GroupInvitationRequest, GroupInvitationQuery, delete_group_invitation};

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
                return Ok(HttpResponse::Forbidden().body("L'utente non è parte del gruppo"));
            }
            if is_user_in_chat(&mut conn, invitation_data.receiver_id, invitation_data.chat_id) {
                return Ok(HttpResponse::BadRequest().body("Il destinatario è già membro del gruppo"));
            }
            match create_group_invitation(&mut conn, invitation_data.chat_id, claims.user_id, invitation_data.receiver_id) {
                Ok(_) => {
                    Ok(HttpResponse::Created().finish())
                },
                // se esiste già un invito per questo gruppo, restituisce un errore 400
                Err(diesel::result::Error::DatabaseError(diesel::result::DatabaseErrorKind::UniqueViolation, _)) => {
                    Ok(HttpResponse::BadRequest().body("L'invito per questo gruppo esiste già"))
                },
                Err(e) => {
                    Err(actix_web::error::ErrorInternalServerError(format!("Database error: {}", e)))
                }
            }
        } else {
            Ok(HttpResponse::Unauthorized().body("Claims not found"))
        }
    }


    pub(crate) async fn delete_group_invitation_handler(req: HttpRequest, query: web::Query<GroupInvitationQuery>) -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();
        // richiede login, quindi serve ottenere i claims
        if let Some(claims) = req.extensions().get::<Claims>() {
            if(query.group_id.is_none()) {
                return Ok(HttpResponse::BadRequest().body("L'ID del gruppo è richiesto"));
            }

            let group_id: i32 = query.group_id.unwrap();
            let user_id: i32 = claims.user_id;


            match delete_group_invitation(&mut conn, group_id, user_id) {
                Ok(0) => {
                    Ok(HttpResponse::NotFound().body(format!("Nessun invito per il gruppo {}", group_id)))
                },
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

    pub(crate) async fn accept_group_invitation_handler(req: HttpRequest, query: web::Query<GroupInvitationQuery>) -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();
        // richiede login, quindi serve ottenere i claims
        if let Some(claims) = req.extensions().get::<Claims>() {
            if(query.group_id.is_none()) {
                return Ok(HttpResponse::BadRequest().body("L'ID del gruppo è richiesto"));
            }

            let group_id: i32 = query.group_id.unwrap();
            let user_id: i32 = claims.user_id;

            match add_member_to_chat(&mut conn, group_id, user_id) {
                Ok(_) => {
                    delete_group_invitation(&mut conn, group_id, user_id).expect(" Errore durante l'eliminazione dell'invito");
                    Ok(HttpResponse::Accepted().json(serde_json::json!(
                        get_group_chat_info_new_member(& mut conn, group_id).unwrap()
                    )))
                },
                Err(diesel::NotFound) => {
                    Ok(HttpResponse::NotFound().body("Nessun invito per il gruppo richiesto"))
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
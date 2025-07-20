pub mod group_invitation {
    use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};
    use crate::handler::websocket::SocketMessage;
    use crate::utility::authorization::authorization::Claims;
    use crate::utility::chats::chats::{accept_group_invitation, is_user_in_chat,get_group_by_name, get_group_chat_info_new_member};
    use crate::utility::connection::establish_connection;
    use crate::utility::group_invitation::group_invitation::{get_user_group_invitations, create_group_invitation, GroupInvitationRequest, GroupInvitationQuery, delete_group_invitation};
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

    pub async fn create_group_invitation_handler(
        req: HttpRequest,
        invitation_data: web::Json<GroupInvitationRequest>,
        client_sockets: web::Data<crate::ClientSockets>,
    ) -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();

        // richiede login, quindi serve ottenere i claims
        if let Some(claims) = req.extensions().get::<Claims>() {
            let chat_id_result = get_group_by_name(&mut conn, invitation_data.group_name.clone());
            let receiver_id_result = get_user_by_username(&mut conn, &invitation_data.receiver_name.clone());

            if chat_id_result.is_err() {
                return Ok(HttpResponse::NotFound().body("Gruppo non trovato"));
            }
            if receiver_id_result.is_err() {
                return Ok(HttpResponse::NotFound().body("Utente non trovato"));
            }

            let chat_id = chat_id_result.unwrap().id;
            let receiver_id = receiver_id_result.unwrap().id;

            if !is_user_in_chat(&mut conn, claims.user_id, chat_id) {
                return Ok(HttpResponse::Forbidden().body("L'utente non è parte del gruppo"));
            }
            if is_user_in_chat(&mut conn, receiver_id, chat_id) {
                return Ok(HttpResponse::BadRequest().body("Il destinatario è già membro del gruppo"));
            }
            match create_group_invitation(&mut conn, chat_id, claims.user_id, receiver_id) {
                Ok(invitation) => {
                    let user_sockets = client_sockets.get_ref().lock().unwrap();
                    // Invia un messaggio al WebSocket del destinatario dell'invito
                    if let Some(socket) = user_sockets.get(&receiver_id) {
                        socket.do_send(SocketMessage{
                            tipe: "group_invite".to_string(),
                            json_message: serde_json::to_string(&invitation)?,
                        });
                    }
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
            if query.group_id.is_none() {
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
            if query.group_id.is_none() {
                return Ok(HttpResponse::BadRequest().body("L'ID del gruppo è richiesto"));
            }

            let group_id: i32 = query.group_id.unwrap();
            let user_id: i32 = claims.user_id;

            match accept_group_invitation(&mut conn, group_id, user_id) {
                Ok(_) => {
                    delete_group_invitation(&mut conn, group_id, user_id).expect(" Errore durante l'eliminazione dell'invito");
                    Ok(HttpResponse::Accepted().json(serde_json::json!(
                        get_group_chat_info_new_member(& mut conn, group_id).unwrap()
                        //{"id": group_id,}
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
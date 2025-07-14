pub mod group_message{
    // create handlers for group messages
    use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};
    use serde::Deserialize;
    use crate::utility::authorization::authorization::Claims;
    use crate::utility::connection::establish_connection;
    use crate::utility::group_message::group_message::{get_all_group_messages, send_group_message, GroupMessageRequest};
    use crate::utility::group::group::{get_group_by_name};

    #[derive(Deserialize)]
    pub struct QueryParams {
        group_name: Option<String>,
    }
    pub async fn get_all_group_messages_handler(query: web::Query<QueryParams>, req: HttpRequest) -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();
        if let Some(claims) = req.extensions().get::<Claims>() {

            // controlla che il nome del gruppo sia stato passato
            let group_name = match query.group_name.clone() {
                None => return Ok(HttpResponse::BadRequest().body("Group name is required")),
                Some(params) => params,
            };

            // controlla che il gruppo esista e prendi il suo id
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

            // effettivo get dei messaggi
            match get_all_group_messages(&mut conn, claims.user_id, group_id) {
                Ok(messages) => {
                    Ok(HttpResponse::Ok().json(messages))
                },
                Err(e) => {
                    match e {
                        diesel::result::Error::NotFound => {
                            Ok(HttpResponse::Forbidden().body("L'utente non fa parte del gruppo"))
                        },
                        _ => {
                            Err(actix_web::error::ErrorInternalServerError(format!("Database error: {}", e)))
                        }
                    }
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
                Ok(()) => {
                    Ok(HttpResponse::Created().finish())
                },
                Err(e) => {
                    match e {
                        diesel::result::Error::NotFound => {
                            Ok(HttpResponse::Forbidden().body("L'utente non fa parte del gruppo"))
                        },
                        _ => {
                            Err(actix_web::error::ErrorInternalServerError(format!("Database error: {}", e)))
                        }
                    }
                }
            }
        } else {
            Ok(HttpResponse::Unauthorized().body("Claims not found"))
        }
    }
}
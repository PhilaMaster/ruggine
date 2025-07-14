pub mod group {
    use actix_web::{web, HttpMessage, HttpRequest, HttpResponse};
    use crate::utility::authorization::authorization::Claims;
    use crate::utility::connection::establish_connection;
    use crate::utility::group::group::{get_all_groups_of_a_user, create_group, CreateGroupRequest};

    pub async fn get_all_groups_of_a_user_handler(req: HttpRequest) ->  actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();
        if let Some(claims) = req.extensions().get::<Claims>() {
            match get_all_groups_of_a_user(&mut conn, claims.user_id) {
                Ok(groups) => {
                    Ok(HttpResponse::Ok().json(groups))
                },
                Err(e) => {
                    Err(actix_web::error::ErrorInternalServerError(format!("Database error: {}", e)))
                }
            }
        } else {
            Ok(HttpResponse::Unauthorized().body("Claims non trovati"))
        }
    }
    
    pub async fn create_group_handler(req: HttpRequest, group_data: web::Json<CreateGroupRequest>) -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();
        if let Some(claims) = req.extensions().get::<Claims>() {
            match create_group(&mut conn, claims.user_id, group_data.name.clone()) {
                Ok(group) => {
                    Ok(HttpResponse::Created().json(group))
                },
                Err(e) => {
                    Err(actix_web::error::ErrorInternalServerError(format!("Database error: {}", e)))
                }
            }
        } else {
            Ok(HttpResponse::Unauthorized().body("Claims non trovati"))
        }
    }
}
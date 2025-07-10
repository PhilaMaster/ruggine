pub mod authorization{
    use actix_web::{web, HttpMessage, HttpRequest, HttpResponse, Result};
    use crate::utility::user::user::UserRequest;
    use std::env;
    use std::time::{SystemTime, UNIX_EPOCH};
    use jsonwebtoken::{encode, Header, EncodingKey};
    use crate::utility::authorization::authorization::{authenticate_user, Claims};
    use crate::utility::connection::establish_connection;

    pub(crate) async fn login_handler(user_data: web::Json<UserRequest>) -> Result<HttpResponse> {
        let mut conn = establish_connection();

        match authenticate_user(&mut conn, user_data.username.as_str(), user_data.password.as_str()) {
            Ok(user) => {
                let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as usize;
                let expiration = now + 604800; // 604800 secondi = 1 settimana
                let my_claims = Claims::new(
                    user.id,
                    user.username,
                    expiration, 
                );
                let jwt_secret = env::var("JWT_SECRET").expect("JWT_SECRET must be set");
                let token = encode(&Header::default(), &my_claims, &EncodingKey::from_secret(jwt_secret.as_ref()))
                    .expect("Failed to encode JWT");
                Ok(HttpResponse::Ok().json(serde_json::json!({
                "token": token,
            })))
            }
            Err(_) => {
                Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to authenticate user"
            })))
            }
        }
    }

    pub(crate) async fn test_handler(req: HttpRequest) -> Result<HttpResponse> {
        if let Some(claims) = req.extensions().get::<Claims>() {
            // Usa i dati dei claims come preferisci
            Ok(HttpResponse::Ok().body(format!("L'utente che ha fatto la richiesta è {}, il suo id è: {}", claims.username, claims.user_id)))
        } else {
            Ok(HttpResponse::Unauthorized().body("Claims non trovati"))
        }
    }
}
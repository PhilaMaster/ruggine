pub mod authorization{

    use actix_web::{web, HttpRequest, HttpResponse, Result};
    use crate::utility::user::user::CreateUserRequest;
    use std::env;
    use jsonwebtoken::{encode, decode, Header, Validation, EncodingKey, DecodingKey};
    use crate::utility::authorization::authorization::{authenticate_user, Claims};
    use crate::utility::connection::establish_connection;

    pub(crate) async fn login_handler(user_data: web::Json<CreateUserRequest>) -> Result<HttpResponse> {
        let mut conn = establish_connection();

        match authenticate_user(&mut conn, user_data.0){
            Ok(user) => {
                let my_claims = Claims::new(
                    user.id.to_string(),
                    user.username,
                    10000000000, // Example expiration time
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
        if let Some(auth_header) = req.headers().get("Authorization") {
            if let Ok(token) = auth_header.to_str() {
                // `token` is a struct with 2 fields: `header` and `claims` where `claims` is your own struct.
                let jwt_secret = env::var("JWT_SECRET").expect("JWT_SECRET must be set");
                let token = decode::<Claims>(&token, &DecodingKey::from_secret(jwt_secret.as_ref()), &Validation::default());
                match token {
                    Ok(token) => {
                        return Ok(token.claims.return_valid_response("Token valido".to_string()));
                    }
                    Err(_) => {
                        return Ok(HttpResponse::Unauthorized().body("Token non valido"));
                    }
                }
            }
        }
        Ok(HttpResponse::Unauthorized().body("Token mancante o non valido"))
    }
}
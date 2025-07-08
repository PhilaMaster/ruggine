pub mod user{
    use actix_web::{web, HttpResponse};
    use crate::utility::connection::establish_connection;
    use crate::utility::user::user::{create_user, get_all_users, hash_password, CreateUserRequest, UserResponse};
    
    // API Endpoints
    pub(crate) async fn create_user_handler(user_data: web::Json<CreateUserRequest>) -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();

        let password_hash = hash_password(user_data.password.as_str()).expect("Failed to hash password");

        match create_user(&mut conn, &user_data.username, &password_hash) {
            Ok(user) => {
                let response: UserResponse = user.into();
                Ok(HttpResponse::Created().json(response))
            }
            Err(diesel::result::Error::DatabaseError(diesel::result::DatabaseErrorKind::UniqueViolation, _)) => {
                Ok(HttpResponse::BadRequest().json(serde_json::json!({
                "error": "Username already exists"
            })))
            }
            Err(_) => {
                Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to create user"
            })))
            }
        }
    }

    pub(crate) async fn get_users_handler() -> actix_web::Result<HttpResponse> {
        let mut conn = establish_connection();

        match get_all_users(&mut conn) {
            Ok(users) => {
                let response: Vec<UserResponse> = users.into_iter().map(|u| u.into()).collect();
                Ok(HttpResponse::Ok().json(response))
            }
            Err(_) => {
                Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to fetch users"
            })))
            }
        }
    }
}
pub mod authorization{
    use diesel::prelude::*;
    use crate::models::{User};
    use crate::schema::users;
    use actix_web::{HttpResponse};
    use serde::{Deserialize, Serialize};
    use crate::utility::user::user::{hash_password, CreateUserRequest};

    /// Our claims struct, it needs to derive `Serialize` and/or `Deserialize`
    #[derive(Debug, Serialize, Deserialize)]
    pub(crate) struct Claims {
        user_id: String,
        username: String,
        exp: usize,
    }

    impl Claims {
        pub fn new(user_id: String, username: String, exp: usize) -> Self {
            Claims { user_id, username, exp }
        }

        pub fn return_valid_response(&self, message: String) ->  HttpResponse {
            HttpResponse::Ok().json(serde_json::json!({
                        "message": message,
                        "user_id": self.user_id,
                        "username": self.username,
                    }))
        }
    }

    pub fn authenticate_user(conn: &mut SqliteConnection, user: CreateUserRequest) -> QueryResult<User> {
        //let password_hash = format!("hashed_{}", user.password);
        // la funzione per hashare la password magari la mettiamo in utility.user???
        let password_hash = hash_password(user.clone());
        users::table
            .filter(users::username.eq(user.username))
            .filter(users::password_hash.eq(password_hash))
            .first(conn)
    }
}
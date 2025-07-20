pub mod authorization{
    use diesel::prelude::*;
    use crate::models::{User};
    use crate::schema::users;
    use serde::{Deserialize, Serialize};
    use crate::utility::user::user::{verify_password };

    /// Our claims struct, it needs to derive `Serialize` and/or `Deserialize`
    #[derive(Debug, Serialize, Deserialize)]
    pub(crate) struct Claims {
        pub user_id: i32,
        pub username: String,
        pub exp: usize,
    }

    impl Claims {
        pub fn new(user_id: i32, username: String, exp: usize) -> Self {
            Claims { user_id, username, exp }
        }

    }

    pub fn authenticate_user(conn: &mut SqliteConnection, username: &str, password: &str) -> QueryResult<User> {
        let user = users::table
            .filter(users::username.eq(username))
            .first::<User>(conn);
        if let Ok(user) = user {
            if verify_password(&user.password_hash, password).expect("Failed to verify password") {
                return Ok(user);
            }else {
                return Err(diesel::result::Error::NotFound);
            }
        }else {
            return Err(diesel::result::Error::NotFound);
        }
    }
}
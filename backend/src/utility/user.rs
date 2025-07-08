pub mod user{
    use diesel::prelude::*;
    use crate::models::{User};
    use crate::schema::users;
    use serde::{Deserialize, Serialize};

    pub fn hash_password(user: CreateUserRequest) -> String {
        // Here you would implement your password hashing logic
        // For simplicity, we are just returning a placeholder string
        format!("hashed_{}", user.password)
    }

    // user utility
    #[derive(Deserialize, Clone, Debug)]
    pub(crate) struct CreateUserRequest {
        pub(crate) username: String,
        password: String,
    }

    impl CreateUserRequest {
        pub fn new(username: String, password: String) -> Self {
            CreateUserRequest { username, password }
        }

    }

    #[derive(Serialize)]
    pub(crate) struct UserResponse {
        id: i32,
        username: String,
    }

    #[derive(Insertable)]
    #[diesel(table_name = users)]
    pub struct NewUser<'a> {
        pub username: &'a str,
        pub password_hash: &'a str,
    }



    impl From<User> for UserResponse {
        fn from(user: User) -> Self {
            UserResponse {
                id: user.id,
                username: user.username,
            }
        }
    }


    pub fn create_user(conn: &mut SqliteConnection, username: &str, password_hash: &str) -> QueryResult<User> {
        use diesel::insert_into;
        let new_user = NewUser { username, password_hash };
        insert_into(users::table)
            .values(&new_user)
            .execute(conn)?;
        users::table.order(users::id.desc()).first(conn)
    }

    pub fn get_all_users(conn: &mut SqliteConnection) -> QueryResult<Vec<User>> {
        users::table.load::<User>(conn)
    }

}
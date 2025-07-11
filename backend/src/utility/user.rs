pub mod user{
    use diesel::prelude::*;
    use crate::models::{User};
    use crate::schema::users;
    use serde::{Deserialize, Serialize};

    use argon2::{Argon2, PasswordHasher};
    use argon2::password_hash::{SaltString, PasswordHash, PasswordVerifier};
    use rand_core::OsRng;

    pub fn hash_password(password: &str) -> Result<String, Box<dyn std::error::Error>> {
        let salt = SaltString::generate(&mut OsRng); // OsRng è generatore crittografico di numeri casuali fornito dal sistema operativo
        let argon2 = Argon2::default();

        let password_hash = argon2.hash_password(password.as_bytes(), &salt).expect("Failed to hash password")
            .to_string();
        // password_hash è una stringa che contiene: il tipo di algoritmo (argon2id) e i suoi parametri (memoria, tempo, thread)
        // il salt generato e hash finale
        Ok(password_hash)
    }
    pub fn verify_password(hash: &str, password: &str) -> Result<bool, Box<dyn std::error::Error>> {
        let parsed_hash = PasswordHash::new(hash).expect("Failed to parse password hash"); //Converte la stringa hash in un oggetto PasswordHash, che contiene: il salt, i parametri e l’hash
        Ok(Argon2::default().verify_password(password.as_bytes(), &parsed_hash).is_ok()) //ritorna Ok(true) se la password è corretta, altrimenti ritorna Ok(false)
    }

    // user utility
    #[derive(Deserialize, Clone, Debug)]
    pub(crate) struct UserRequest {
        pub(crate) username: String,
        pub(crate) password: String,
    }

    impl UserRequest {
        pub fn new(username: String, password: String) -> Self {
            UserRequest { username, password }
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

    pub(crate) fn get_user_by_username(conn: &mut SqliteConnection, user: &str) -> QueryResult<User> {
        use crate::schema::users::dsl::*;
        users.filter(username.eq(user)).first::<User>(conn)
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
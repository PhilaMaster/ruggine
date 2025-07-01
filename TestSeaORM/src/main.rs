mod schema;
mod models;

use diesel::prelude::*;
use dotenvy::dotenv;
use std::env;
use crate::models::{User};
use crate::schema::users;
use actix_web::{web, App, HttpServer, Result, HttpResponse, middleware::Logger};
use serde::{Deserialize, Serialize};

// user utility
#[derive(Deserialize)]
pub(crate) struct CreateUserRequest {
    username: String,
    password: String,
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


pub fn establish_connection() -> SqliteConnection {
    dotenv().ok();

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    SqliteConnection::establish(&database_url)
        .unwrap_or_else(|_| panic!("Error connecting to {}", database_url))
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

// API Endpoints
async fn create_user_handler(user_data: web::Json<CreateUserRequest>) -> Result<HttpResponse> {
    let mut conn = establish_connection();

    // In un'app reale dovresti hashare la password con bcrypt
    let password_hash = format!("hashed_{}", user_data.password);

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

async fn get_users_handler() -> Result<HttpResponse> {
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

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();

    println!("🚀 Server starting on http://localhost:8080");
    println!("📖 API endpoints:");
    println!("  POST /api/users - Create user");
    println!("  GET  /api/users - Get all users");

    HttpServer::new(|| {
        App::new()
            .wrap(Logger::default())
            .route("/api/users", web::post().to(create_user_handler))
            .route("/api/users", web::get().to(get_users_handler))
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}

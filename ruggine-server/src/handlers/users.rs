use actix_web::{web, HttpResponse, Responder};
use rusqlite::Result;
use crate::models::{AppState, CreateUserRequest, User};

pub async fn get_users(data: web::Data<AppState>) -> impl Responder {
    let conn = data.db.lock().unwrap();
    let mut stmt = match conn.prepare("SELECT * FROM users") {
        Ok(stmt) => stmt,
        Err(_) => return HttpResponse::InternalServerError().body("Failed to prepare statement"),
    };

    let user_iter = match stmt.query_map([], |row| {
        Ok(User {
            id: row.get(0)?,
            username: row.get(1)?,
            password_hash: row.get(2)?,
        })
    }) {
        Ok(iter) => iter,
        Err(_) => return HttpResponse::InternalServerError().body("Failed to query users"),
    };

    let users: Vec<User> = user_iter.filter_map(Result::ok).collect();

    HttpResponse::Ok().json(users)
}

pub async fn create_user(user: web::Json<CreateUserRequest>, data: web::Data<AppState>) -> impl Responder {
    let conn = data.db.lock().unwrap();
    match conn.execute(
        "INSERT INTO users (username, password_hash) VALUES (?1, ?2)",
        &[&user.username, &user.password_hash],
    ) {
        Ok(_) => HttpResponse::Created().body("User created"),
        Err(_) => HttpResponse::InternalServerError().body("Error creating user"),
    }
}

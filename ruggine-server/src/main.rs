use actix_web::{web, App, HttpServer};
use rusqlite::Connection;
use std::sync::Mutex;

mod handlers;
mod models;
mod db;
use db::db::create_tables; //il primo db è il modulo, il secondo db è il file db.rs
use handlers::home::*;
use handlers::users::*;
use models::*;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    unsafe { std::env::set_var("RUST_LOG", "actix_web=info"); } //serve per stampare su console i messaggi di debug di actix-web
    env_logger::init();

    let conn = Connection::open("ruggine.db").unwrap();
    create_tables(&conn).unwrap();

    let data = web::Data::new(AppState { //web::Data serve per condividere variabili  in modo thread-safe tra tutti gli handler
        db: Mutex::new(conn), 
    });
    
    println!("server is running on http://localhost:8080");
    HttpServer::new(move || {
        App::new()
            .app_data(data.clone()) //mette a disposizione data(cioè il database) a tutti gli handler (accessibile come parametro di tipo web::Data<AppState>)
            .route("/", web::get().to(index)) 
            .route("/users", web::get().to(get_users))
            .route("/users", web::post().to(create_user))
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}

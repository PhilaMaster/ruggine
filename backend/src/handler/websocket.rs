use actix::prelude::*;
use actix_web_actors::ws;
use actix_web::{web, HttpRequest, HttpResponse, Error, HttpMessage};
use serde::{Deserialize, Serialize};
use crate::ClientSockets;
use crate::utility::connection::establish_connection;
use crate::utility::authorization::authorization::Claims;
use crate::utility::messages::messages::get_new_messages_since;

pub struct WebSocketHandler {
    user_id: Option<String>,
    client_sockets: ClientSockets,
}

impl WebSocketHandler {
    pub fn new(user_id: Option<String>, client_sockets: ClientSockets) -> Self {
        Self { user_id, client_sockets }
    }
}

impl Actor for WebSocketHandler{
    type Context = ws::WebsocketContext<Self>;

    fn started(&mut self, ctx: &mut Self::Context) {
        println!("WebSocket connection established");
        if let Some(user_id) = &self.user_id {
            add_socket(user_id.clone(), ctx.address(), &self.client_sockets);
        }
    }

    fn stopped(&mut self, ctx: &mut Self::Context) {
        println!("WebSocket connection closed");
        if let Some(user_id) = &self.user_id {
            let mut map = self.client_sockets.lock().unwrap();
            map.remove(&user_id.clone());
            println!("Removed socket for user: {}, now have: {}", user_id, &map.len());
        }
    }
}

fn add_socket(user_id: String, addr: Addr<WebSocketHandler>, user_sockets: &ClientSockets) {
    let mut map = user_sockets.lock().unwrap();
    map.entry(user_id)
        .or_insert_with(|| addr);
}

impl StreamHandler<Result<ws::Message, ws::ProtocolError>> for WebSocketHandler {
    fn handle(&mut self, msg: Result<ws::Message, ws::ProtocolError>, ctx: &mut Self::Context) {
        match msg {
            Ok(ws::Message::Text(text)) => {
                println!("Received text message: {}", text);
                ctx.text(format!("{}", text));
            }
            Ok(ws::Message::Binary(bin)) => {
                println!("Received binary message of length: {}", bin.len());
                ctx.binary(bin);
            }
            Ok(ws::Message::Close(reason)) => {
                println!("WebSocket connection closed: {:?}", reason);
                ctx.close(reason);
            }
            Err(e) => {
                println!("WebSocket error: {:?}", e);
                ctx.stop();
            }
            _ => {}
        }
    }
}

pub async fn ws_index(
    req: HttpRequest,
    stream: web::Payload,
    client_sockets: web::Data<ClientSockets>,
) -> Result<HttpResponse, Error> {
    // Recupera i claims dall'extension (inseriti dal middleware di autenticazione)
    if let Some(claims) = req.extensions().get::<Claims>() {
        let user_id = claims.user_id;
        // Crea l'attore WebSocket passando la mappa condivisa
        let ws_handler = WebSocketHandler::new(Some(user_id.to_string()), client_sockets.get_ref().clone());
        let resp = ws::start(ws_handler, &req, stream)?;
        println!("WebSocket connection started for user: {}", user_id);
        Ok(resp)
    } else {
        println!("No claims found in request");
        Ok(HttpResponse::Unauthorized().json(
            serde_json::json!({
                "status": 401,
                "error": "Unauthorized access"
            })
        ))
    }
}
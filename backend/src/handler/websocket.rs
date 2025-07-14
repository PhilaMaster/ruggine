use actix::prelude::*;
use actix_web_actors::ws;
use actix_web::{web, HttpRequest, HttpResponse, Error};
use serde::{Deserialize, Serialize};
use crate::ClientSockets;
use crate::utility::connection::establish_connection;
use crate::utility::authorization::authorization::Claims;

pub struct WebSocketHandler;

impl Actor for WebSocketHandler{
    type Context = ws::WebsocketContext<Self>;

    fn started(&mut self, ctx: &mut Self::Context) {
        println!("WebSocket connection established");
    }

    fn stopped(&mut self, ctx: &mut Self::Context) {
        println!("WebSocket connection closed");
    }
}

fn add_socket(user_id: String, addr: Addr<WebSocketHandler>, user_sockets: &ClientSockets) {
    let mut map = user_sockets.lock().unwrap();
    map.entry(user_id)
        .or_insert_with(Vec::new)
        .push(addr);
}

impl StreamHandler<Result<ws::Message, ws::ProtocolError>> for WebSocketHandler {
    fn handle(&mut self, msg: Result<ws::Message, ws::ProtocolError>, ctx: &mut Self::Context) {
        match msg {
            Ok(ws::Message::Text(text)) => {
                println!("Received text message: {}", text);
                ctx.text(format!("Echo: {}", text));
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

pub async fn ws_index(req: HttpRequest, stream: web::Payload) -> Result<HttpResponse, Error> {
    let resp = ws::start(WebSocketHandler {}, &req, stream)?;
    println!("WebSocket connection started, responding with: {:?}", resp);
    Ok(resp)
}
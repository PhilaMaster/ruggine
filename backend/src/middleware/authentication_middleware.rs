use std::env;
use actix_web::{
    dev::{Service, ServiceRequest, ServiceResponse, Transform},
    error::ErrorUnauthorized,
    Error, HttpMessage,
};
use futures::future::{ok, Ready, LocalBoxFuture};
use std::task::{Context, Poll};
use std::rc::Rc;
use jsonwebtoken::{decode, DecodingKey, Validation};
use crate::utility::authorization::authorization::Claims;

pub struct AuthMiddleware;

/// Transform trait: serve per creare l'istanza del middleware
impl<S, B> Transform<S, ServiceRequest> for AuthMiddleware
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = AuthMiddlewareService<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ok(AuthMiddlewareService {
            service: Rc::new(service),
        })
    }
}

//Service trait: serve per implementare la logica del middleware e viene chiamato per ogni richiesta
pub struct AuthMiddlewareService<S> {
    service: Rc<S>,
}

impl<S, B> Service<ServiceRequest> for AuthMiddlewareService<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;

    fn poll_ready(&self, ctx: &mut Context<'_>) -> Poll<Result<(), Self::Error>> {
        self.service.poll_ready(ctx)
    }

    fn call(&self, req: ServiceRequest) -> Self::Future {
        // Verifica la presenza dell'header Authorization
        let auth_header_opt = req.headers().get("Authorization").and_then(|hv| hv.to_str().ok());

        let authorized = match auth_header_opt {
            Some(header_value) if header_value.starts_with("Bearer ") => {
                let token = header_value.trim_start_matches("Bearer ").trim();
                let jwt_secret = match env::var("JWT_SECRET") {
                    Ok(val) => val,
                    Err(_) => return Box::pin(async { Err(ErrorUnauthorized("Server config error")) }),
                };                    let token = decode::<Claims>(&token, &DecodingKey::from_secret(jwt_secret.as_ref()), &Validation::default());
                match token {
                    Ok(data) => {
                        req.extensions_mut().insert(data.claims); // salva i dati dell'utente nella richiesta per il prossimo handler
                        //per accedere ai dati usare: let claims = req.extensions().get::<Claims>().unwrap();
                        true
                    }
                    Err(_) => false,
                }
            }
            _ => false,
        };

        if authorized {
            let fut = self.service.call(req);
            Box::pin(async move {
                let res = fut.await?;
                Ok(res)
            })
        } else {
            Box::pin(async {
                Err(ErrorUnauthorized("Token non valido o mancante"))
            })
        }

    }
}
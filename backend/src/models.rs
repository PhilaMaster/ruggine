use diesel::prelude::*;
use serde::{Deserialize, Serialize};
use crate::schema::*;

#[derive(Queryable, Debug, Identifiable, Serialize)]
#[diesel(table_name = users)]
pub struct User {
    pub id: i32,
    pub username: String,
    pub password_hash: String,
}

#[derive(Queryable, Debug, Identifiable)]
#[diesel(table_name = groups)]
pub struct Group {
    pub id: Option<i32>,
    pub name: String,
}

#[derive(Queryable, Debug, Identifiable)]
#[diesel(table_name = group_message)]
pub struct GroupMessage {
    pub id: i32,
    pub text: String,
    pub sender_id: i32,
    pub group_rx_id: i32,
    pub sent_at: String,
}

#[derive(Queryable, Debug, Identifiable, Serialize)]
#[diesel(table_name = private_message)]
pub struct PrivateMessage {
    pub id: i32,
    pub text: String,
    pub sender_id: i32,
    pub receiver_id: i32,
    pub sent_at: String,
}

#[derive(Queryable, Debug)]
#[diesel(primary_key(group_id, user_id))]
pub struct UserInGroup {
    pub group_id: i32,
    pub user_id: i32,
}




pub mod private_messages{
    use diesel::{ExpressionMethods, Insertable, QueryDsl, QueryResult, RunQueryDsl, SqliteConnection};
    use serde::Deserialize;
    use crate::schema::{private_message};
    use crate::models::PrivateMessage;

    pub fn get_all_private_messages(conn: &mut SqliteConnection, user_id: i32) -> QueryResult<Vec<PrivateMessage>> {
        private_message::table
            .filter(private_message::sender_id.eq(user_id))
            .or_filter(private_message::receiver_id.eq(user_id))
            .order_by(private_message::sent_at.desc())
            .load::<PrivateMessage>(conn)
    }
    
    pub fn send_private_message(
        conn: &mut SqliteConnection,
        sender_id: i32,
        receiver_id: i32,
        text: String,
    ) -> QueryResult<PrivateMessage> {
        let new_message = NewPrivateMessage {
            text,
            sender_id,
            receiver_id,
            sent_at: chrono::Utc::now().to_string(), // Use current time as sent_at
        };
        
        diesel::insert_into(private_message::table)
            .values(&new_message)
            .execute(conn)?;
        private_message::table
            .order_by(private_message::id.desc())
            .first::<PrivateMessage>(conn)
    }

    #[derive(Deserialize, Clone, Debug)]
    pub(crate) struct SendPrivateMessageRequest {
        pub(crate) receiver_id: i32,
        pub(crate) text: String,
    }

    #[derive(Insertable)]
    #[diesel(table_name = private_message)]
    pub struct NewPrivateMessage {
        pub receiver_id: i32,
        pub sender_id: i32,
        pub text: String,
        pub sent_at: String,
    }
}
    
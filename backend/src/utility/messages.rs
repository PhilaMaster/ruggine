use serde::Deserialize;

pub mod messages {
    use diesel::{QueryResult, SqliteConnection, ExpressionMethods, QueryDsl, RunQueryDsl, Insertable};
    use serde::Deserialize;
    use crate::models::Message;
    use crate::schema::{messages};
    use crate::utility::chats::chats::get_chat_ids_of_user;
    
    pub fn get_new_messages_since(conn: &mut SqliteConnection, user_id: i32, date: String) -> QueryResult<Vec<Message>> {
        let chat_ids = get_chat_ids_of_user(conn, user_id)?;
        messages::table
            .filter(messages::chat_id.eq_any(chat_ids))
            .filter(messages::sent_at.gt(date))
            .order_by(messages::sent_at.desc())
            .load::<Message>(conn)
    }
    
    pub fn send_message(
        conn: &mut SqliteConnection,
        chat_id: i32,
        sender_id: i32,
        content: String,
    ) -> QueryResult<Message> {
        let new_message = NewMessage {
            chat_id,
            sender_id,
            content,
        };

        diesel::insert_into(messages::table)
            .values(&new_message)
            .returning(messages::all_columns)
            .get_result::<Message>(conn)
    }

    #[derive(Deserialize, Clone, Debug)]
    pub(crate) struct SendMessageRequest {
        pub(crate) chat_id: i32,
        pub(crate) content: String,
    }
    
    #[derive(Insertable)]
    #[diesel(table_name = messages)]
    struct NewMessage {
        chat_id: i32,
        sender_id: i32,
        content: String
    }
}
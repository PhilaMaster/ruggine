pub mod messages {
    use diesel::{QueryResult, SqliteConnection, ExpressionMethods, QueryDsl, RunQueryDsl};
    use crate::models::Message;
    use crate::schema::{messages, chat_members};
    use crate::utility::chats::chats::get_chat_ids_of_user;
    
    pub fn get_new_messages_since(conn: &mut SqliteConnection, user_id: i32, date: String) -> QueryResult<Vec<Message>> {
        let chat_ids = get_chat_ids_of_user(conn, user_id)?;

        messages::table
            .filter(messages::chat_id.eq_any(chat_ids))
            .filter(messages::sent_at.gt(date))
            .order_by(messages::sent_at.desc())
            .load::<Message>(conn)
    }
}
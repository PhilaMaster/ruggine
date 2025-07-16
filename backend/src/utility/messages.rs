use serde::Deserialize;

pub mod messages {
    use diesel::{QueryResult, SqliteConnection, ExpressionMethods, QueryDsl, RunQueryDsl, Insertable, Queryable, JoinOnDsl};
    use serde::{Deserialize, Serialize};
    use crate::utility::chats::chats::get_chat_ids_of_user;
    use crate::schema::{messages, users};
    use crate::models::{Message, User};
    
    #[derive(Queryable, Serialize)]
    pub struct MessageWithSender {
        pub id: i32,
        pub chat_id: i32,
        pub sender_id: i32,
        pub content: String,
        pub sent_at: String,
        pub username: String,
    }
    
    pub fn get_new_messages_since(conn: &mut SqliteConnection, user_id: i32, date: String) -> QueryResult<Vec<MessageWithSender>> {
        use crate::schema::users::dsl::{users, username as user_username, id as user_id_col};
        use crate::schema::messages::dsl::{messages, chat_id, sender_id, content, sent_at, id as message_id};

        let chat_ids = get_chat_ids_of_user(conn, user_id)?;

        messages
            .filter(chat_id.eq_any(chat_ids))
            .filter(sent_at.gt(date))
            .inner_join(users.on(sender_id.eq(user_id_col)))
            .select((message_id, chat_id, sender_id, content, sent_at, user_username))
            .order_by(sent_at.desc())
            .load::<MessageWithSender>(conn)
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

    // struct per i parametri query della richiesta
    #[derive(Deserialize)]
    pub struct GetNewMessagesQuery {
        pub since: Option<String>
    }

}
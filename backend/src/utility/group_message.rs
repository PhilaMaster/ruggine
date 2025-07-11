pub mod group_message{
    use diesel::prelude::*;
    use serde::{Serialize, Deserialize};
    use crate::models::GroupMessage;
    use crate::utility::authorization::authorization::Claims;

    #[derive(Insertable, Debug, Serialize, Deserialize)]
    #[diesel(table_name = crate::schema::group_message)]
    pub struct NewGroupMessage {
        pub text: String,
        pub sender_id: i32,
        pub group_rx_id: i32,
        pub sent_at: String,
    }

    #[derive(Deserialize, Clone, Debug)]
    pub struct GroupMessageRequest {
        pub group_name: String,
        pub text: String,
    }

    pub fn get_all_group_messages(conn: &mut SqliteConnection, group_id: i32) -> QueryResult<Vec<GroupMessage>> {
        use crate::schema::group_message::dsl::*;
        group_message
            .filter(group_rx_id.eq(group_id))
            .select(GroupMessage::as_select())
            .load::<GroupMessage>(conn)
    }

    pub fn send_group_message(conn: &mut SqliteConnection, claims: &Claims, group_id: i32, text: String) -> QueryResult<()> {
        use crate::schema::group_message;

        let new_message = NewGroupMessage {
            text,
            sender_id: claims.user_id,
            group_rx_id: group_id,
            sent_at: chrono::Utc::now().to_string(),
        };

        diesel::insert_into(group_message::table)
            .values(&new_message)
            .execute(conn)?;

        Ok(())
    }
}
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

    // controlla che un utente sia membro di un dato gruppo
    fn is_user_in_group(conn: &mut SqliteConnection, req_user_id: i32, req_group_id: i32) -> QueryResult<bool> {
        use crate::schema::user_in_group::dsl::*;
        let exists = user_in_group
            .filter(user_id.eq(req_user_id).and(group_id.eq(req_group_id)))
            .select(user_id)
            .first::<i32>(conn)
            .optional()?;
        Ok(exists.is_some())
    }

    pub fn get_all_group_messages(conn: &mut SqliteConnection, user_id: i32, group_id: i32) -> QueryResult<Vec<GroupMessage>> {
        use crate::schema::group_message::dsl::*;

        // controlla se l'utente è membro del gruppo
        if !is_user_in_group(conn, user_id, group_id)? {
            return Err(diesel::result::Error::NotFound);
        }

        group_message
            .filter(group_rx_id.eq(group_id))
            .select(GroupMessage::as_select())
            .load::<GroupMessage>(conn)
    }

    pub fn send_group_message(conn: &mut SqliteConnection, claims: &Claims, group_id: i32, text: String) -> QueryResult<()> {
        use crate::schema::group_message;

        // controlla che l'utente sia nel gruppo
        if !is_user_in_group(conn, claims.user_id, group_id)? {
            return Err(diesel::result::Error::NotFound);
        }

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
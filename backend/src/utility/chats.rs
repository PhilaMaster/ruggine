pub mod chats{
    use crate::schema::{chats, chat_members, users};
    use crate::models::{Chat, ChatMember, User};
    use diesel::prelude::*;

    pub fn get_chat_ids_of_user(conn: &mut SqliteConnection, user_id: i32) -> QueryResult<Vec<i32>>{
        let chat_ids: Vec<i32> = chat_members::table
            .filter(chat_members::user_id.eq(user_id))
            .select(chat_members::chat_id)
            .load(conn)?;
        Ok(chat_ids)
    }


    pub fn get_chat_by_id(conn: &mut SqliteConnection, chat_id: i32) -> QueryResult<Option<Chat>> {
        use crate::schema::chats::dsl::*;
        chats.filter(id.eq(chat_id)).first::<Chat>(conn).optional()
    }

    #[derive(serde::Serialize)]
    pub struct ChatMemberInfo {
        pub user_id: i32,
        pub username: String,
    }

    pub fn get_chat_members_by_chat_id(conn: &mut SqliteConnection, chat_id_val: i32) -> QueryResult<Vec<ChatMemberInfo>> {
        use crate::schema::users::dsl::*;
        use crate::schema::chat_members::dsl as cm;

        users
            .inner_join(cm::chat_members.on(cm::user_id.eq(id)))
            .filter(cm::chat_id.eq(chat_id_val))
            .select((id, username))
            .load::<(i32, String)>(conn)
            .map(|results| {
                results
                    .into_iter()
                    .map(|(user_id, u)| ChatMemberInfo { user_id, username:u })
                    .collect()
            })
    }
    
    pub fn is_user_in_chat(conn: &mut SqliteConnection, u_id: i32, c_id: i32) -> bool {
        use crate::schema::chat_members::dsl::*;
        
        let res = chat_members
            .filter(user_id.eq(u_id))
            .filter(chat_id.eq(c_id))
            .first::<ChatMember>(conn);
        res.is_ok()
    }


    #[derive(serde::Deserialize, Clone, Debug, Insertable)]
    #[diesel(table_name = chat_members)]
    pub struct InsertChatMember {
        chat_id: i32,
        user_id: i32,
    }

    // aggiungi un membro a una chat
    pub fn add_member_to_chat(conn: &mut SqliteConnection, chat_id: i32, user_id: i32) -> QueryResult<()> {
        use crate::schema::chat_members::dsl as cm;
        use crate::schema::group_invitation::dsl as gi;

        let new_member = InsertChatMember {
            chat_id,
            user_id,
        };

        // controlla che effettivamente l'utentesia stato invitato a questa chat
        let invitation_exists = gi::group_invitation
            .filter(gi::group_id.eq(chat_id))
            .filter(gi::receiver_id.eq(user_id))
            .first::<crate::models::GroupInvitation>(conn)
            .optional()?
            .is_some();
        if !invitation_exists {
            return Err(diesel::result::Error::NotFound);
        }

        diesel::insert_into(cm::chat_members)
            .values(&new_member)
            .execute(conn)?;

        Ok(())
    }
}

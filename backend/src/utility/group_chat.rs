use crate::utility::chats::chats::ChatInfo;

pub mod group_chat {
    use diesel::{ExpressionMethods, Insertable, QueryDsl, QueryResult, RunQueryDsl, SqliteConnection};
    use serde::Deserialize;
    use crate::schema::{chat_members, chats};
    use diesel::prelude::*;
    use crate::models::{ChatMember, Chat};
    use crate::utility::chats::chats::ChatInfo;

    // restituisce le info di una chat per nuovi utenti che entrano in un gruppo
    pub fn get_group_chat_info_new_member(conn: &mut SqliteConnection, chat_id: i32) -> QueryResult<ChatInfo> {
        use crate::schema::chat_members::dsl as cm;
        use crate::schema::chats::dsl as c;
        use crate::schema::users::dsl as u;

        // Retrieve chat details
        let chat = c::chats
            .filter(c::id.eq(chat_id))
            .first::<Chat>(conn)?;

        // Retrieve members of the chat
        let members: Vec<String> = cm::chat_members
            .inner_join(u::users.on(u::id.eq(cm::user_id)))
            .filter(cm::chat_id.eq(chat_id))
            .select(u::username)
            .load::<String>(conn)?;

        let last_message = "".to_string();
        let last_sender = "".to_string();

        // come su whatsapp, l'utente non vede i messaggi scritti prima che entrasse nel gruppo
        // quindi last time = now
        let last_time = chrono::Utc::now().to_rfc3339();
        let creator_username = u::users
            .filter(u::id.eq(chat.created_by))
            .select(u::username)
            .first::<String>(conn)
            .unwrap_or("".to_string());

        // ChatInfo
        Ok(ChatInfo {
            id: chat.id,
            last_sender,
            last_message,
            last_time,
            new_messages: 0,
            name: chat.name.unwrap_or("".to_string()),
            created_by: creator_username,
            members,
            is_group: chat.is_group,
            created_at: chat.created_at,
        })
    }
    
    pub fn is_user_part_of_group(conn: &mut SqliteConnection, user_id: i32, group_id: i32) -> QueryResult<()>{

        use self::chat_members::dsl as cm;

        cm::chat_members.filter(cm::user_id.eq(user_id))
            .filter(cm::user_id.eq(user_id))
            .filter(cm::chat_id.eq(group_id))
            .first::<ChatMember>(conn)?;
            
        Ok(())
                
    }

    pub fn create_group(conn: &mut SqliteConnection, user_id: i32, name: String) -> QueryResult<Chat> {
        let new_group = NewGroup { name, is_group:true, created_by:user_id };
        
        diesel::insert_into(chats::table)
            .values(&new_group)
            .execute(conn)?;
        
        let group = chats::table
            .order_by(chats::id.desc())
            .first::<Chat>(conn)?;
        
        diesel::insert_into(chat_members::table)
            .values(NewChatMember {
                chat_id: group.id,
                user_id,
                joined_at: chrono::Utc::now().to_rfc3339(),
            })
            .execute(conn)?;
        
        Ok(group)
    }
    pub(crate) fn get_group_by_name(conn: &mut SqliteConnection, group_name: String) -> QueryResult<Chat> {
        use self::chats::dsl as c;
        
        c::chats.filter(c::is_group.eq(true))
            .filter(c::name.eq(group_name))
            .first::<Chat>(conn)

    }

    #[derive(Deserialize, Clone, Debug)]
    pub(crate) struct CreateGroupRequest {
        pub(crate) name: String,
    }

    #[derive(Insertable)]
    #[diesel(table_name = chats)]
    pub struct NewGroup {
        pub name: String,
        pub is_group: bool,
        pub created_by: i32
    }

    #[derive(Insertable)]
    #[diesel(table_name = chat_members)]
    pub struct NewChatMember {
        pub chat_id: i32,
        pub user_id: i32,
        pub joined_at: String,
    }
}
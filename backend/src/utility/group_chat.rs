pub mod group_chat {
    use diesel::{ExpressionMethods, Insertable, QueryDsl, QueryResult, RunQueryDsl, SqliteConnection};
    use serde::Deserialize;
    use crate::schema::{chat_members, chats};
    use diesel::prelude::*;
    use crate::models::{ChatMember, Chat};
    use crate::schema::chats::{created_by, is_group};
    
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
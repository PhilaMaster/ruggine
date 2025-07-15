pub mod group {
    use diesel::{ExpressionMethods, Insertable, QueryDsl, QueryResult, RunQueryDsl, SqliteConnection};
    use serde::Deserialize;
    use crate::schema::{groups, user_in_group, chat_members, chats};
    use diesel::prelude::*;
    use crate::models::{ChatMember, Group, Chat};
    use crate::schema::chats::{created_by, is_group};
    // pub fn get_all_groups_of_a_user(conn: &mut SqliteConnection, user_id: i32) -> QueryResult<Vec<Group>> {
    //     use self::user_in_group::dsl as uig;
    //     use self::groups::dsl as grps;
    //     let group_ids: Vec<i32> = uig::user_in_group
    //         .filter(uig::user_id.eq(user_id))
    //         .select(uig::group_id)
    //         .load(conn)?;
    //     let group_ids_option: Vec<Option<i32>> = group_ids.into_iter().map(Some).collect();
    //     grps::groups
    //         .filter(grps::id.eq_any(group_ids_option))
    //         .load::<Group>(conn)
    // }

    pub fn get_all_groups_of_a_user(conn: &mut SqliteConnection, user_id: i32) -> QueryResult<Vec<Group>> {
        use self::chat_members::dsl as cm;
        
        unimplemented!()//i think that this is not used anymore, but i will leave it here for now
    }
    
    pub fn is_user_part_of_group(conn: &mut SqliteConnection, user_id: i32, group_id: i32) -> QueryResult<()>{

        use self::chat_members::dsl as cm;

        cm::chat_members.filter(cm::user_id.eq(user_id))
            .filter(cm::user_id.eq(user_id))
            .filter(cm::chat_id.eq(group_id))
            .first::<ChatMember>(conn)?;//will launch Err(Not found) if user is not part of group
            
        Ok(())
                
    }
    // pub fn create_group(conn: &mut SqliteConnection, user_id: i32, name: String) -> QueryResult<Group> {
    //     let new_group = NewGroup { name };
    // 
    //     diesel::insert_into(groups::table)
    //         .values(&new_group)
    //         .execute(conn)?;
    // 
    //     let group = groups::table
    //         .order_by(groups::id.desc())
    //         .first::<Group>(conn)?;
    // 
    //     diesel::insert_into(user_in_group::table)
    //         .values((user_in_group::group_id.eq(group.id.unwrap()), user_in_group::user_id.eq(user_id)))
    //         .execute(conn)?;
    // 
    //     Ok(group)
    // }

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
        
        
            // .map_err(|_| diesel::result::Error::NotFound)//restituisce già not found se non lo trova
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
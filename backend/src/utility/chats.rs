pub mod chats{
    use diesel::dsl::now;
    use crate::schema::{chats, chat_members, users};
    use crate::models::{Chat, ChatMember, Message, User};
    use diesel::prelude::*;
    use crate::utility::user::user::get_user_by_username;
    use diesel::{ExpressionMethods, Insertable, QueryDsl, QueryResult, RunQueryDsl, SqliteConnection};
    use serde::Deserialize;
    use diesel::prelude::*;
    use diesel::result::Error;
    use diesel::sql_types::Integer;

    #[derive(serde::Deserialize, serde::Serialize, Clone, Debug)]
    pub struct ChatInfo {
        pub id: i32,                //group id
        pub last_sender: String,
        pub last_message: String,
        pub last_time: String,
        pub new_messages: i32,
        pub name: String,           // group name
        pub created_by: String,
        pub members: Vec<String>,
        pub is_group: bool,
        pub created_at: String,
    }

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

    pub fn get_id_members_of_chat(conn: &mut SqliteConnection, chat_id: i32) -> QueryResult<Vec<(i32,String)>> {
        use crate::schema::chat_members::dsl as cm;
        use crate::schema::users::dsl as u;

        cm::chat_members
            .inner_join(u::users.on(u::id.eq(cm::user_id)))
            .filter(cm::chat_id.eq(chat_id))
            .select((u::id, u::username))
            .load::<(i32, String)>(conn)
    }


    #[derive(serde::Deserialize, Clone, Debug, Insertable)]
    #[diesel(table_name = chat_members)]
    pub struct InsertChatMember {
        chat_id: i32,
        user_id: i32,
    }

    // aggiungi un membro a una chat
    pub fn accept_group_invitation(conn: &mut SqliteConnection, chat_id: i32, user_id: i32) -> QueryResult<()> {
        use crate::schema::group_invitation::dsl as gi;
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

        add_member_to_chat(conn, chat_id, user_id)?;

        Ok(())
    }

    fn add_member_to_chat(conn: &mut SqliteConnection, chat_id: i32, user_id: i32) -> QueryResult<()> {
        use crate::schema::chat_members::dsl as cm;
        let new_member = InsertChatMember {
            chat_id,
            user_id,
        };

        diesel::insert_into(cm::chat_members)
            .values(&new_member)
            .execute(conn)?;
        Ok(())
    }

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
        let last_time = chrono::Utc::now().to_string();
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
        create_chat(conn, user_id, name, true)?
    }

    pub fn create_private_chat(conn: &mut SqliteConnection, user_id1: i32, user_id2: i32) -> QueryResult<Chat> {
        let chat = create_chat(conn, user_id1, "private chat".to_string(), false)??;
        add_member_to_chat(conn, chat.id, user_id2)?;
        Ok(chat)
    }
    fn create_chat(conn: &mut SqliteConnection, user_id: i32, name: String, is_group: bool) -> Result<Result<Chat, Error>, Error> {
        let name = name.trim().to_string();
        let new_chat = NewChat { name: name.clone(), is_group, created_by: user_id };

        diesel::insert_into(chats::table)
            .values(&new_chat)
            .execute(conn)?;

        let chat = chats::table
            .filter(chats::is_group.eq(is_group))
            .filter(chats::name.eq(name))
            .filter(chats::created_by.eq(user_id))
            .order_by(chats::id.desc())
            .first::<Chat>(conn)?;

        diesel::insert_into(chat_members::table)
            .values(NewChatMember {
                chat_id: chat.id,
                user_id,
            })
            .execute(conn)?;

        Ok(Ok(chat))
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

    #[derive(Deserialize, Clone, Debug)]
    pub(crate) struct CreateChatRequest {
        pub(crate) receiver_name: String,
    }

    #[derive(Insertable)]
    #[diesel(table_name = chats)]
    pub struct NewChat {
        pub name: String,
        pub is_group: bool,
        pub created_by: i32
    }

    #[derive(Insertable)]
    #[diesel(table_name = chat_members)]
    pub struct NewChatMember {
        pub chat_id: i32,
        pub user_id: i32,
    }
}

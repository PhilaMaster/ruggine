pub(crate) mod group_invitation {
    use std::sync::mpsc::Receiver;
    use diesel::{ExpressionMethods, Insertable, QueryDsl, QueryResult, RunQueryDsl, SqliteConnection};
    use serde::Deserialize;
    use crate::schema::{group_invitation};
    use crate::models::GroupInvitation;
    use crate::utility::group_chat::group_chat::{is_user_part_of_group};


    #[derive(Deserialize, Clone, Debug)]
    pub(crate) struct GroupInvitationRequest {
        pub(crate) receiver_id: i32,
        pub(crate) chat_id: i32,
    }

    #[derive(Insertable)]
    #[diesel(table_name = group_invitation)]
    pub struct NewGroupInvitation {
        pub group_id: i32,
        pub sender_id: i32,
        pub receiver_id: i32,
    }

    pub fn get_user_group_invitations(conn: &mut SqliteConnection, user_id: i32) -> QueryResult<Vec<GroupInvitation>> {
        group_invitation::table
            .filter(group_invitation::receiver_id.eq(user_id))
            .load::<GroupInvitation>(conn)
    }

    pub fn create_group_invitation(
        conn: &mut SqliteConnection,
        group_id: i32,
        sender_id: i32,
        receiver_id: i32,
    ) -> QueryResult<()> {
        let new_invitation = NewGroupInvitation {
            group_id,
            sender_id,
            receiver_id,
        };
        
        diesel::insert_into(group_invitation::table)
            .values(&new_invitation)
            .execute(conn)?;

        Ok(())
    }

    pub fn delete_group_invitation(
        conn: &mut SqliteConnection,
        group_id: i32,
        receiver_id: i32,
    ) -> QueryResult<usize> {
        diesel::delete(group_invitation::table)
            .filter(group_invitation::group_id.eq(group_id))
            .filter(group_invitation::receiver_id.eq(receiver_id))
            .execute(conn)
    }


}
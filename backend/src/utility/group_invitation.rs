pub(crate) mod group_invitation {
    use diesel::{ExpressionMethods, Insertable, QueryDsl, QueryResult, RunQueryDsl, SqliteConnection};
    use serde::Deserialize;
    use crate::schema::{group_invitation, chats, users};

    #[derive(serde::Deserialize)]
    pub struct GroupInvitationQuery {
        pub group_id: Option<i32>,
    }

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


    #[derive(serde::Serialize)]
    pub struct GroupInvitationResponse {
        pub group_name: String,
        pub sender_name: String
    }

    pub fn get_user_group_invitations(conn: &mut SqliteConnection, user_id: i32) -> QueryResult<Vec<GroupInvitationResponse>> {
        use crate::models::GroupInvitation;

        let invitations = group_invitation::table
            .filter(group_invitation::receiver_id.eq(user_id))
            .load::<GroupInvitation>(conn)?;

        let mut responses = Vec::new();

        for invitation in invitations {
            // Ottieni il nome del gruppo dalla tabella chats usando group_id
            let group_name = chats::table
                .find(invitation.group_id)
                .select(chats::name)
                .first::<Option<String>>(conn)
                .unwrap_or_default()
                .unwrap_or_default();

            // Ottieni il nome del mittente
            let sender_name = users::table
                .find(invitation.sender_id)
                .select(users::username)
                .first::<String>(conn)
                .unwrap_or_default();

            responses.push(GroupInvitationResponse {
                group_name,
                sender_name
            });
        }

        Ok(responses)
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
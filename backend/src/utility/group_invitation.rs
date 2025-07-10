pub(crate) mod group_invitation {
    use diesel::{ExpressionMethods, Insertable, QueryDsl, QueryResult, RunQueryDsl, SqliteConnection};
    use serde::Deserialize;
    use crate::schema::{group_invitation};
    use crate::models::GroupInvitation;
    use crate::utility::group::group::{get_all_groups_of_a_user};

    #[derive(Deserialize, Clone, Debug)]
    pub(crate) struct GroupInvitationRequest {
        pub(crate) group_name: String,
        pub(crate) receiver_username: String,
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
    ) -> QueryResult<GroupInvitation> {
        let new_invitation = NewGroupInvitation {
            group_id,
            sender_id,
            receiver_id,
        };

        // controlla che l'utente che crea l'invito sia effettivamente un membro del gruppo
        let user_groups = get_all_groups_of_a_user(conn, sender_id)?;
        if !user_groups.iter().any(|g| g.id == Some(group_id)) {
            return Err(diesel::result::Error::NotFound);
        }

        diesel::insert_into(group_invitation::table)
            .values(&new_invitation)
            .execute(conn)?;

        group_invitation::table
            .order_by(group_invitation::id.desc())
            .first::<GroupInvitation>(conn)
    }


}
pub mod group {
    use diesel::{ExpressionMethods, Insertable, QueryDsl, QueryResult, RunQueryDsl, SqliteConnection};
    use serde::Deserialize;
    use crate::schema::{groups, user_in_group};
    use diesel::prelude::*;
    use crate::models::{Group};

    pub fn get_all_groups_of_a_user(conn: &mut SqliteConnection, user_id: i32) -> QueryResult<Vec<Group>> {
        use self::user_in_group::dsl as uig;
        use self::groups::dsl as grps;
        let group_ids: Vec<i32> = uig::user_in_group
            .filter(uig::user_id.eq(user_id))
            .select(uig::group_id)
            .load(conn)?;
        let group_ids_option: Vec<Option<i32>> = group_ids.into_iter().map(Some).collect();
        grps::groups
            .filter(grps::id.eq_any(group_ids_option))
            .load::<Group>(conn)
    }

    pub fn create_group(conn: &mut SqliteConnection, user_id: i32, name: String) -> QueryResult<Group> {
        let new_group = NewGroup { name };

        diesel::insert_into(groups::table)
            .values(&new_group)
            .execute(conn)?;

        let group = groups::table
            .order_by(groups::id.desc())
            .first::<Group>(conn).unwrap();

        diesel::insert_into(user_in_group::table)
            .values((user_in_group::group_id.eq(group.id.unwrap()), user_in_group::user_id.eq(user_id)))
            .execute(conn)?;

        groups::table
            .order_by(groups::id.desc())
            .first::<Group>(conn)
    }

    pub(crate) fn get_group_by_name(conn: &mut SqliteConnection, group_name: String) -> QueryResult<Group> {
        use crate::schema::groups::dsl::*;
        groups.filter(name.eq(group_name))
            .first::<Group>(conn)
            .map_err(|_| diesel::result::Error::NotFound)
    }

    #[derive(Deserialize, Clone, Debug)]
    pub(crate) struct CreateGroupRequest {
        pub(crate) name: String,
    }

    #[derive(Insertable)]
    #[diesel(table_name = groups)]
    pub struct NewGroup {
        pub name: String,
    }

}
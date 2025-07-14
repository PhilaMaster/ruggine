// @generated automatically by Diesel CLI.

diesel::table! {
    group_invitation (group_id, sender_id, receiver_id) {
        group_id -> Integer,
        sender_id -> Integer,
        receiver_id -> Integer,
    }
}

diesel::table! {
    group_message (id) {
        id -> Integer,
        text -> Text,
        sender_id -> Integer,
        group_rx_id -> Integer,
        sent_at -> Text,
    }
}

diesel::table! {
    groups (id) {
        id -> Nullable<Integer>,
        name -> Text,
    }
}

diesel::table! {
    private_message (id) {
        id -> Integer,
        text -> Text,
        sender_id -> Integer,
        receiver_id -> Integer,
        sent_at -> Text,
    }
}

diesel::table! {
    user_in_group (group_id, user_id) {
        group_id -> Integer,
        user_id -> Integer,
    }
}

diesel::table! {
    users (id) {
        id -> Integer,
        username -> Text,
        password_hash -> Text,
    }
}

diesel::joinable!(group_invitation -> groups (group_id));
diesel::joinable!(group_message -> groups (group_rx_id));
diesel::joinable!(group_message -> users (sender_id));
diesel::joinable!(user_in_group -> groups (group_id));
diesel::joinable!(user_in_group -> users (user_id));

diesel::allow_tables_to_appear_in_same_query!(
    group_invitation,
    group_message,
    groups,
    private_message,
    user_in_group,
    users,
);

// @generated automatically by Diesel CLI.

diesel::table! {
    chat_members (chat_id, user_id) {
        chat_id -> Integer,
        user_id -> Integer,
        joined_at -> Timestamp,
    }
}

diesel::table! {
    chats (id) {
        id -> Integer,
        is_group -> Bool,
        name -> Nullable<Text>,
        created_by -> Integer,
        created_at -> Timestamp,
    }
}

diesel::table! {
    group_invitation (group_id, sender_id, receiver_id) {
        group_id -> Integer,
        sender_id -> Integer,
        receiver_id -> Integer,
    }
}

diesel::table! {
    groups (id) {
        id -> Nullable<Integer>,
        name -> Text,
    }
}

diesel::table! {
    messages (id) {
        id -> Integer,
        chat_id -> Integer,
        sender_id -> Integer,
        content -> Text,
        sent_at -> Timestamp,
    }
}

diesel::table! {
    users (id) {
        id -> Integer,
        username -> Text,
        password_hash -> Text,
    }
}

diesel::joinable!(chat_members -> chats (chat_id));
diesel::joinable!(chat_members -> users (user_id));
diesel::joinable!(chats -> users (created_by));
diesel::joinable!(group_invitation -> groups (group_id));
diesel::joinable!(messages -> chats (chat_id));
diesel::joinable!(messages -> users (sender_id));

diesel::allow_tables_to_appear_in_same_query!(
    chat_members,
    chats,
    group_invitation,
    groups,
    messages,
    users,
);

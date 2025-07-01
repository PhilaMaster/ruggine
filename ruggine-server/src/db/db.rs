use rusqlite::{Connection, Result};

pub fn create_tables(conn: &Connection) -> Result<()> {
    conn.execute(
        "CREATE TABLE IF NOT EXISTS users (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  username TEXT NOT NULL UNIQUE,
                  password_hash TEXT NOT NULL
                  )",
        [],
    )?;
    conn.execute(
        "CREATE TABLE IF NOT EXISTS groups (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT NOT NULL UNIQUE
                  )",
        [],
    )?;
    conn.execute(
        "CREATE TABLE IF NOT EXISTS user_in_group (
                  group_id INTEGER NOT NULL,
                  user_id INTEGER NOT NULL,
                  PRIMARY KEY (group_id, user_id),
                  FOREIGN KEY (group_id) REFERENCES groups(id),
                  FOREIGN KEY (user_id) REFERENCES users(id)
                  )",
        [],
    )?;
    conn.execute(
        "CREATE TABLE IF NOT EXISTS private_message (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  text TEXT NOT NULL,
                  sender_id INTEGER NOT NULL,
                  receiver_id INTEGER NOT NULL,
                  sent_at TEXT NOT NULL,
                  FOREIGN KEY (sender_id) REFERENCES users(id),
                  FOREIGN KEY (receiver_id) REFERENCES users(id)
                  )",
        [],
    )?;
    conn.execute(
        "CREATE TABLE IF NOT EXISTS group_message (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  text TEXT NOT NULL,
                  sender_id INTEGER NOT NULL,
                  group_rx_id INTEGER NOT NULL,
                  sent_at TEXT NOT NULL,
                  FOREIGN KEY (sender_id) REFERENCES users(id),
                  FOREIGN KEY (group_rx_id) REFERENCES groups(id)
                  )",
        [],
    )?;
    Ok(())
}

-- Your SQL goes here
-- database: ../OneDrive - Politecnico di Torino/Poli/4QuartoAnno/WebApp/labs-capibara/app-capibara/src/components/ruggine.sqlite



CREATE TABLE users (
                       id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                       username TEXT NOT NULL UNIQUE,
                       password_hash TEXT NOT NULL
);

CREATE TABLE groups (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        name TEXT NOT NULL UNIQUE
);

CREATE TABLE user_in_group (
                               group_id INTEGER NOT NULL,
                               user_id INTEGER NOT NULL,
                               PRIMARY KEY (group_id, user_id),
                               FOREIGN KEY (group_id) REFERENCES groups(id)
                                   ON UPDATE CASCADE
                                   ON DELETE CASCADE,
                               FOREIGN KEY (user_id) REFERENCES users(id)
                                   ON UPDATE CASCADE
                                   ON DELETE CASCADE
);

CREATE TABLE private_message (
                                 id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                                 text TEXT NOT NULL,
                                 sender_id INTEGER NOT NULL,
                                 receiver_id INTEGER NOT NULL,
                                 sent_at TEXT NOT NULL,
                                 FOREIGN KEY (sender_id) REFERENCES users(id)
                                     ON UPDATE CASCADE
                                     ON DELETE CASCADE,
                                 FOREIGN KEY (receiver_id) REFERENCES users(id)
                                     ON UPDATE CASCADE
                                     ON DELETE CASCADE
);

CREATE TABLE group_message (
                               id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                               text TEXT NOT NULL,
                               sender_id INTEGER NOT NULL,
                               group_rx_id INTEGER NOT NULL,
                               sent_at TEXT NOT NULL,
                               FOREIGN KEY (sender_id) REFERENCES users(id)
                                   ON UPDATE CASCADE
                                   ON DELETE CASCADE,
                               FOREIGN KEY (group_rx_id) REFERENCES groups(id)
                                   ON UPDATE CASCADE
                                   ON DELETE CASCADE
);

CREATE TABLE group_invitation (
                                 group_id INTEGER NOT NULL,
                                 sender_id INTEGER NOT NULL,
                                 receiver_id INTEGER NOT NULL,
                                 PRIMARY KEY (group_id, sender_id, receiver_id),
                                 FOREIGN KEY (group_id) REFERENCES groups(id)
                                     ON UPDATE CASCADE
                                     ON DELETE CASCADE,
                                 FOREIGN KEY (sender_id) REFERENCES users(id)
                                     ON UPDATE CASCADE
                                     ON DELETE CASCADE,
                                 FOREIGN KEY (receiver_id) REFERENCES users(id)
                                     ON UPDATE CASCADE
                                     ON DELETE CASCADE
);



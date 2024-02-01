-- Add migration script here

CREATE TABLE
    todos
    (
	id varchar(36) PRIMARY KEY,
	created DATETIME NOT NULL,
        body TEXT
    );

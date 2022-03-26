CREATE TABLE IF NOT EXISTS `friends` (
    `identifier_1` VARCHAR(100),
    `identifier_2` VARCHAR(100),
    `name_1` VARCHAR(50),
    `name_2` VARCHAR(50),
    `date` DATE DEFAULT (CURRENT_DATE),

    PRIMARY KEY (`identifier_1`, `identifier_2`)
);

CREATE TABLE IF NOT EXISTS `friend_requests` (
    `sender` VARCHAR(100),
    `sent_to` VARCHAR(100),
    `sender_name` VARCHAR(50),
    `sent_to_name` VARCHAR(50),

    PRIMARY KEY (`sender`, `sent_to`)
);
CREATE TABLE IF NOT EXISTS music_like_list (
  `id` int NOT NULL AUTO_INCREMENT,
  `player_id` INT NOT NULL,
  `like_music_list` JSON,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS music_history (
  `id` int NOT NULL AUTO_INCREMENT,
  `player_id` INT NOT NULL,
  `music_history_list` JSON,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS music_playlist (
  `id` int NOT NULL AUTO_INCREMENT,
  `player_id` INT NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `url_img` VARCHAR(255) DEFAULT NULL,
  `music_playlist` JSON,
  PRIMARY KEY (`id`)
);

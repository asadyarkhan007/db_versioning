DROP TABLE IF EXISTS `db_version_script`;
DROP TABLE IF EXISTS `db_version`;

CREATE TABLE `db_version`(  
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `version` VARCHAR(255) NOT NULL,
  `comment` VARCHAR(255),
  `is_completed` BOOLEAN DEFAULT TRUE,
  `creation_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=INNODB;

CREATE TABLE `db_version_script`(  
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `db_version_id` INT(11),
  `script_name` VARCHAR(255) NOT NULL,
  `is_successful` BOOLEAN,
  `creation_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `FK_DB_VERSION_ID` FOREIGN KEY (`db_version_id`) REFERENCES `db_version`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

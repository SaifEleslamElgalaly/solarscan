-- Settings table required by header.php / settings.php
CREATE TABLE IF NOT EXISTS `settings` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `admin_name` VARCHAR(255) NOT NULL DEFAULT 'System Admin',
  `admin_email` VARCHAR(255) NOT NULL DEFAULT 'admin@solarscan.ai',
  `ml_endpoint` VARCHAR(255) NOT NULL DEFAULT 'http://localhost:8000/predict',
  `api_token` VARCHAR(255) NOT NULL DEFAULT '',
  `auto_audit` TINYINT(1) NOT NULL DEFAULT 1,
  `high_contrast` TINYINT(1) NOT NULL DEFAULT 1,
  `notifications` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ensure the default row with id = 1 exists (the app always reads/updates WHERE id = 1)
INSERT INTO `settings` (`id`, `admin_name`, `admin_email`, `ml_endpoint`, `api_token`, `auto_audit`, `high_contrast`, `notifications`)
SELECT 1, 'System Admin', 'admin@solarscan.ai', 'http://localhost:8000/predict', '', 1, 1, 1
WHERE NOT EXISTS (SELECT 1 FROM `settings` WHERE `id` = 1);

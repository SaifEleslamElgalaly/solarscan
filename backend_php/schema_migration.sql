-- =====================================================================
-- Schema migration: bring solar_defect_db in sync with the updated
-- backend_php code (the code was newer than the original SQL dump).
-- Safe to re-run: every statement is idempotent.
-- Run with: mysql -u root solar_defect_db < schema_migration.sql
-- =====================================================================

-- 1) settings table (used by header.php and settings.php) ------------
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

-- The app always reads/updates the row WHERE id = 1, so make sure it exists.
INSERT INTO `settings` (`id`, `admin_name`, `admin_email`, `ml_endpoint`, `api_token`, `auto_audit`, `high_contrast`, `notifications`)
SELECT 1, 'System Admin', 'admin@solarscan.ai', 'http://localhost:8000/predict', '', 1, 1, 1
WHERE NOT EXISTS (SELECT 1 FROM `settings` WHERE `id` = 1);

-- 2) scans.panel_id column (used by panels.php join + service_api.php) -
-- Links each scan to a panel (panels.panel_id is VARCHAR(50)).
-- Added conditionally so re-running does not error if it already exists.
SET @col_exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'scans'
    AND COLUMN_NAME = 'panel_id'
);
SET @ddl := IF(@col_exists = 0,
  'ALTER TABLE `scans` ADD COLUMN `panel_id` VARCHAR(50) DEFAULT NULL AFTER `user_id`, ADD KEY `scans_panel_id_index` (`panel_id`)',
  'SELECT "scans.panel_id already exists"');
PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3) scans.box column (stores the defect bounding box from the ML model) --
-- Stored as a JSON string: "[x1, y1, x2, y2]" with normalized 0..1 coords,
-- or NULL (e.g. Clean panels / no detection). The client app draws it.
SET @box_exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'scans'
    AND COLUMN_NAME = 'box'
);
SET @ddl_box := IF(@box_exists = 0,
  'ALTER TABLE `scans` ADD COLUMN `box` VARCHAR(255) DEFAULT NULL AFTER `recommendation`',
  'SELECT "scans.box already exists"');
PREPARE stmt_box FROM @ddl_box;
EXECUTE stmt_box;
DEALLOCATE PREPARE stmt_box;

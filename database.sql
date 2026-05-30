CREATE TABLE IF NOT EXISTS `vehicle_tunes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) NOT NULL,
  `vehicle_hash` VARCHAR(20) NOT NULL,
  `tune_name` VARCHAR(100) NOT NULL,
  `tune_data` JSON NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_identifier (`identifier`),
  INDEX idx_vehicle (`vehicle_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

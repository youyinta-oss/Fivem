-- ESX Admin Panel 数据库安装脚本
-- 在 MySQL 中执行此脚本以创建所需的数据表

CREATE DATABASE IF NOT EXISTS `esx` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `esx`;

-- ============================================
-- 封禁记录表
-- ============================================
CREATE TABLE IF NOT EXISTS `admin_bans` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `identifier` VARCHAR(60) NOT NULL COMMENT '玩家标识符 (license:xxx)',
    `player_name` VARCHAR(50) NOT NULL COMMENT '玩家名称',
    `reason` TEXT NOT NULL COMMENT '封禁理由',
    `banned_by` VARCHAR(50) NOT NULL COMMENT '执行封禁的管理员名称',
    `banner_identifier` VARCHAR(60) NOT NULL COMMENT '管理员标识符',
    `ban_duration` INT DEFAULT 0 COMMENT '封禁天数，0=永久',
    `expire_date` DATETIME NULL COMMENT '到期时间，NULL=永久封禁',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '封禁时间',
    `unbanned_by` VARCHAR(50) NULL COMMENT '解封管理员名称',
    `unbanned_at` DATETIME NULL COMMENT '解封时间',
    `unban_reason` TEXT NULL COMMENT '解封理由',
    INDEX `idx_identifier` (`identifier`),
    INDEX `idx_expire` (`expire_date`),
    INDEX `idx_unbanned` (`unbanned_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员封禁记录';

-- ============================================
-- 审计日志表
-- ============================================
CREATE TABLE IF NOT EXISTS `admin_audit_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `admin_name` VARCHAR(50) NOT NULL COMMENT '管理员名称',
    `admin_identifier` VARCHAR(60) NOT NULL COMMENT '管理员标识符',
    `action` VARCHAR(50) NOT NULL COMMENT '操作标识 (如 player.kick, player.ban)',
    `details` TEXT COMMENT '操作详情',
    `target_player` VARCHAR(50) NULL COMMENT '目标玩家名称',
    `target_identifier` VARCHAR(60) NULL COMMENT '目标玩家标识符',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
    INDEX `idx_admin` (`admin_identifier`),
    INDEX `idx_action` (`action`),
    INDEX `idx_date` (`created_at`),
    INDEX `idx_target` (`target_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员操作审计日志';

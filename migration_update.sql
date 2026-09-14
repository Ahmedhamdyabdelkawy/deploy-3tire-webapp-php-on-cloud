-- ============================================
-- SecureVault Database Migration Script
-- Run this script to update your existing database
-- ============================================

USE securevault;

-- 1. Update users table: Add 'pending' status
ALTER TABLE users MODIFY status ENUM('active', 'blocked', 'pending') NOT NULL DEFAULT 'active';

-- 1b. Add security intelligence columns to users (if not exists)
SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'users'
     AND COLUMN_NAME = 'blocked_until') = 0,
    'ALTER TABLE users ADD COLUMN blocked_until DATETIME NULL AFTER status',
    'SELECT "Column blocked_until already exists" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'users'
     AND COLUMN_NAME = 'security_risk_score') = 0,
    'ALTER TABLE users ADD COLUMN security_risk_score INT NOT NULL DEFAULT 0 AFTER blocked_until',
    'SELECT "Column security_risk_score already exists" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'users'
     AND COLUMN_NAME = 'security_risk_level') = 0,
    'ALTER TABLE users ADD COLUMN security_risk_level ENUM(''normal'', ''watch'', ''high'', ''critical'', ''compromised'') NOT NULL DEFAULT ''normal'' AFTER security_risk_score',
    'SELECT "Column security_risk_level already exists" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'users'
     AND COLUMN_NAME = 'is_compromised') = 0,
    'ALTER TABLE users ADD COLUMN is_compromised TINYINT(1) NOT NULL DEFAULT 0 AFTER security_risk_level',
    'SELECT "Column is_compromised already exists" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'users'
     AND COLUMN_NAME = 'security_reason') = 0,
    'ALTER TABLE users ADD COLUMN security_reason TEXT NULL AFTER is_compromised',
    'SELECT "Column security_reason already exists" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'users'
     AND COLUMN_NAME = 'last_security_review_at') = 0,
    'ALTER TABLE users ADD COLUMN last_security_review_at DATETIME NULL AFTER security_reason',
    'SELECT "Column last_security_review_at already exists" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'users'
     AND INDEX_NAME = 'idx_users_blocked_until') = 0,
    'CREATE INDEX idx_users_blocked_until ON users(blocked_until)',
    'SELECT "Index idx_users_blocked_until already exists" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'users'
     AND INDEX_NAME = 'idx_users_security_state') = 0,
    'CREATE INDEX idx_users_security_state ON users(security_risk_level, is_compromised)',
    'SELECT "Index idx_users_security_state already exists" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. Add metadata column to access_requests (if not exists)
-- Using a simple approach: try to add, ignore error if exists
SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_SCHEMA = DATABASE() 
     AND TABLE_NAME = 'access_requests' 
     AND COLUMN_NAME = 'metadata') = 0,
    'ALTER TABLE access_requests ADD COLUMN metadata TEXT NULL AFTER reviewed_by',
    'SELECT "Column metadata already exists" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2b. Add access_scope column to access_requests (if not exists)
SET @sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'access_requests'
     AND COLUMN_NAME = 'access_scope') = 0,
    'ALTER TABLE access_requests ADD COLUMN access_scope ENUM(''department'', ''files'') NOT NULL DEFAULT ''department'' AFTER reviewed_by',
    'SELECT "Column access_scope already exists" AS message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. Create access_request_files table (if not exists)
CREATE TABLE IF NOT EXISTS access_request_files (
    request_id INT NOT NULL,
    file_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (request_id, file_id),
    CONSTRAINT fk_request_files_request
        FOREIGN KEY (request_id) REFERENCES access_requests(id) ON DELETE CASCADE,
    CONSTRAINT fk_request_files_file
        FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
    INDEX idx_request_files_file (file_id),
    INDEX idx_request_files_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Create notifications table (if not exists)
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    department_id INT NULL,
    request_id INT NULL,
    type VARCHAR(40) NOT NULL DEFAULT 'info',
    title VARCHAR(190) NOT NULL,
    message TEXT NOT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_notifications_department 
        FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE SET NULL,
    CONSTRAINT fk_notifications_request 
        FOREIGN KEY (request_id) REFERENCES access_requests(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Add index for faster notification queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_read 
    ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_dept_read 
    ON notifications(department_id, is_read);

-- 6. Verify migration
SELECT 
    'Migration completed successfully!' AS status,
    (SELECT COUNT(*) FROM notifications) AS notification_count,
    (SELECT COUNT(*) FROM users WHERE status = 'pending') AS pending_users;

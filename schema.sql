-- ============================================
-- SecureVault - Complete Database Schema
-- Version: 2.0
-- ============================================

CREATE DATABASE IF NOT EXISTS securevault 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE securevault;

-- ============================================
-- 1. DEPARTMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS departments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL UNIQUE,
    INDEX idx_departments_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 2. USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(80) NOT NULL UNIQUE,
    email VARCHAR(190) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role ENUM('super_admin', 'department_admin', 'user') NOT NULL DEFAULT 'user',
    department_id INT NULL,
    status ENUM('active', 'blocked', 'pending') NOT NULL DEFAULT 'active',
    blocked_until DATETIME NULL,
    security_risk_score INT NOT NULL DEFAULT 0,
    security_risk_level ENUM('normal', 'watch', 'high', 'critical', 'compromised') NOT NULL DEFAULT 'normal',
    is_compromised TINYINT(1) NOT NULL DEFAULT 0,
    security_reason TEXT NULL,
    last_security_review_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_department
        FOREIGN KEY (department_id) REFERENCES departments(id)
        ON DELETE SET NULL,
    INDEX idx_users_email (email),
    INDEX idx_users_role_status (role, status),
    INDEX idx_users_department_status (department_id, status),
    INDEX idx_users_blocked_until (blocked_until),
    INDEX idx_users_security_state (security_risk_level, is_compromised)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 3. FILES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS files (
    id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    stored_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    uploaded_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_files_department
        FOREIGN KEY (department_id) REFERENCES departments(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_files_user
        FOREIGN KEY (uploaded_by) REFERENCES users(id)
        ON DELETE CASCADE,
    INDEX idx_files_department (department_id),
    INDEX idx_files_uploaded_by (uploaded_by),
    INDEX idx_files_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 4. ACCESS REQUESTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS access_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    target_department_id INT NOT NULL,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    reviewed_by INT NULL,
    access_scope ENUM('department', 'files') NOT NULL DEFAULT 'department',
    metadata TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY unique_open_request (user_id, target_department_id),
    CONSTRAINT fk_requests_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_requests_department
        FOREIGN KEY (target_department_id) REFERENCES departments(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_requests_reviewer
        FOREIGN KEY (reviewed_by) REFERENCES users(id)
        ON DELETE SET NULL,
    INDEX idx_requests_status (status),
    INDEX idx_requests_target_dept (target_department_id, status),
    INDEX idx_requests_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 5. ACCESS REQUEST FILES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS access_request_files (
    request_id INT NOT NULL,
    file_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (request_id, file_id),
    CONSTRAINT fk_request_files_request
        FOREIGN KEY (request_id) REFERENCES access_requests(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_request_files_file
        FOREIGN KEY (file_id) REFERENCES files(id)
        ON DELETE CASCADE,
    INDEX idx_request_files_file (file_id),
    INDEX idx_request_files_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 6. AUDIT LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    user_email VARCHAR(190) NULL,
    event_type VARCHAR(80) NOT NULL,
    status VARCHAR(40) NOT NULL,
    department_id INT NULL,
    target_department_id INT NULL,
    file_id INT NULL,
    ip_address VARCHAR(45) NULL,
    details TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_logs_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_audit_logs_department
        FOREIGN KEY (department_id) REFERENCES departments(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_audit_logs_target_department
        FOREIGN KEY (target_department_id) REFERENCES departments(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_audit_logs_file
        FOREIGN KEY (file_id) REFERENCES files(id)
        ON DELETE SET NULL,
    INDEX idx_audit_event_type (event_type, status),
    INDEX idx_audit_created_at (created_at DESC),
    INDEX idx_audit_department (department_id),
    INDEX idx_audit_user (user_id),
    INDEX idx_audit_ip (ip_address)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 7. NOTIFICATIONS TABLE
-- ============================================
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
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_notifications_department
        FOREIGN KEY (department_id) REFERENCES departments(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_notifications_request
        FOREIGN KEY (request_id) REFERENCES access_requests(id)
        ON DELETE SET NULL,
    INDEX idx_notifications_user_read (user_id, is_read),
    INDEX idx_notifications_dept_read (department_id, is_read),
    INDEX idx_notifications_created (created_at DESC),
    INDEX idx_notifications_type (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 8. SEED DATA - Default Departments
-- ============================================
INSERT INTO departments (name)
SELECT 'Cybersecurity'
WHERE NOT EXISTS (SELECT 1 FROM departments WHERE name = 'Cybersecurity');

INSERT INTO departments (name)
SELECT 'IT Support'
WHERE NOT EXISTS (SELECT 1 FROM departments WHERE name = 'IT Support');

INSERT INTO departments (name)
SELECT 'Operations'
WHERE NOT EXISTS (SELECT 1 FROM departments WHERE name = 'Operations');

INSERT INTO departments (name)
SELECT 'Finance'
WHERE NOT EXISTS (SELECT 1 FROM departments WHERE name = 'Finance');

INSERT INTO departments (name)
SELECT 'Human Resources'
WHERE NOT EXISTS (SELECT 1 FROM departments WHERE name = 'Human Resources');

INSERT INTO departments (name)
SELECT 'Legal'
WHERE NOT EXISTS (SELECT 1 FROM departments WHERE name = 'Legal');

-- ============================================
-- 9. SEED DATA - Super Admin Account
-- Default password: Admin@12345
-- ============================================
INSERT INTO users (username, email, password, role, department_id, status)
SELECT
    'superadmin',
    'superadmin@securevault.local',
    '$2y$10$Mp7ecT6iTdy6poOWL4Eib.LVAW1/mMAY6oZ8L2C7rGK4sEj6DT7yK',
    'super_admin',
    (SELECT id FROM departments WHERE name = 'Cybersecurity' LIMIT 1),
    'active'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'superadmin');

-- ============================================
-- 10. VERIFICATION
-- ============================================
SELECT 
    'Database setup completed!' AS status,
    (SELECT COUNT(*) FROM departments) AS total_departments,
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM notifications) AS total_notifications;

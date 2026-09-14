Cloud.png

# **SecureVault - FileFortress Dashboard System**

## 🛡️ Overview
SecureVault is a secure file and user management system built with PHP & MySQL featuring a complete Role-Based Access Control (RBAC) system designed for departmental file isolation and cross-department access requests.

## 🔗 Access URLs (Localhost)

| **Page**                       | **URL**                                   | **Access**                |
|----------------------------|-------------------------------------------|---------------------------|
| **Login**                  | `http://localhost/securevault_/login.php`  | Public                    |
| **Register**               | `http://localhost/securevault_/register.php`    | Public                    |
| **Super Admin Dashboard**  | `http://localhost/securevault_/super_admin_dashboard.php` | Super Admin Only        |
| **Department Admin Dashboard** | `http://localhost/securevault_/admin_dashboard.php` | Department Admin Only     |
| **User Dashboard**     | `http://localhost/securevault_/dashboard.php`       | User Only                 |
| **Logout**               | `http://localhost/securevault_/logout.php`          | Authenticated Users       |

## 📊 Default Credentials

| **#** | **Username** | **Email**                     | **Role**        | **Password**   |
|-------|--------------|-------------------------------|-----------------|----------------|
| 1     | `superadmin` | `superadmin@securevault.local`  | Super Admin     | `Admin@12345`  |
| 1     | `Mohamed`    |   `mohamed@securevault.local`  | Department Admin     | `Mohamed@12345`  |
| 2     | `Yousef`     | `yousef@securevault.local`      | User            | `Admin@12345`  |
| 3     | `Ahmed`      | `ahmed@securevault.local`       | Department Admin| `Admin@12345`  |

> **Unified Security Code:** `SV-ACCESS-2026`

## 📁 Project Structure
```plaintext
secureVault/
├── uploads/                          # File uploads directory
├── auth.php                          # Authentication & Authorization system
├── db.php                            # Database connection configuration
├── layout.php                        # Shared layout templates (Header/Footer)
├── index.php                         # Main entry point / router
├── login.php                         # Login page with slide panels
├── logout.php                        # Session destruction & logout
├── register.php                      # User self-registration page
├── dashboard.php                     # Regular user dashboard
├── admin_dashboard.php               # Department admin dashboard
├── super_admin_dashboard.php         # Super admin dashboard
├── upload.php                        # File upload handler
├── download.php                      # Secure file download handler
├── preview.php                       # In-browser file preview handler
├── request_access.php                # Cross-department access request handler
├── schema.sql                        # Full database schema for fresh installs
└── migration_update.sql              # Database migration for existing installs

# ✨ **Features**

### 1. **Three-Tier Role-Based Access Control (RBAC)**

| **Role**            | **Permissions**                                                                 |
|---------------------|---------------------------------------------------------------------------------|
| `super_admin`       | Full platform control, department & user management, unlimited file access, full audit log visibility |
| `department_admin`  | Manage department, create users, upload files, review registrations & access requests |
| `user`              | Upload files to home department, request cross-department access, track request status |

### 2. **Secure File Management**
- **Secure Upload**: Validates file extensions and type (whitelist).
- **Encrypted Storage**: Files stored with random hexadecimal names.
- **Protected Downloads**: Managed by the `download.php` with permission verification.
- **Inline Preview**: Supports images, PDFs, and various text formats (txt, csv, json, etc.).

### 3. **Cross-Department Access Requests**
- Secure requests to other departments, including a review process by department admins.

### 4. **Real-Time Notification System**
- New registrations, access request notifications, failed login alerts, and other important security/approval updates.

### 5. **Comprehensive Audit Logging**
- Logs user activity: login attempts, file uploads/downloads, access requests, and more.

### 6. **Security Hardening**

| **Enhancement**               | **Description**                                                         |
|-------------------------------|-------------------------------------------------------------------------|
| SQL Injection Prevention       | All queries use PDO Prepared Statements with parameterized binding.     |
| CSRF Protection                | Token generation and verification for form submissions.                 |
| XSS Prevention                 | Ensures output is safely encoded with `htmlspecialchars()`.              |
| Brute Force Detection          | Alerts admin after 4+ failed login attempts.                            |
| Secure File Storage            | Random file names for stored files to prevent direct access.           |
| Password Hashing               | Uses `password_hash()` (bcrypt) for user passwords.                     |
| Session Regeneration           | Ensures new session ID after every successful login.                    |

### 7. **Interactive Dashboards**
- **Super Admin**: Activity tracking, threat analysis, network traffic visualization.
- **Department Admin**: User management, registration & access request reviews.
- **User**: File access, personal request status tracking.

---

## 🗄️ **Database Schema**

| **Table**          | **Description**                        | **Key Columns**               |
|--------------------|----------------------------------------|-------------------------------|
| `departments`      | Organizational departments             | id, name                      |
| `users`            | All user accounts (3 roles)            | id, username, email, password |
| `files`            | Uploaded files with ownership          | id, department_id, file_name   |
| `access_requests`  | Cross-department access requests       | id, user_id, status            |
| `audit_logs`       | Complete audit trail                   | id, user_id, event_type        |
| `notifications`    | User & department notifications        | id, user_id, department_id     |

# 📝 **Change log**

**Version 2.0 (Current)**

✅ **New**:
- Notifications table with role-scoped delivery system
- Metadata column in `access_requests` for detailed request info
- Pending user status for registration approval workflow

✅ **Security**:
- All SQL queries converted from inline to Prepared Statements
- Brute force detection (4+ failures triggers admin alerts)
- File size limit enforcement (10MB max)

✅ **Enhanced**:
- `logNotification()` function with 6 parameters including `$requestId`
- `error_log()` integration for silent error tracking
- Extended file preview support (gif, webp, svg, json, xml, html, css, js, md, log)
- Improved "Preview Unavailable" page with file metadata display
- Download handler with cache-control headers and output buffer cleaning

✅ **Performance**:
- Strategic database indexes for all frequent query patterns

✅ **Data**:
- 6 default departments seeded on install

✅ **UI**:
- Autocomplete attributes on login/register forms

✅ **Robustness**:
- Department existence validation before registration/upload

✅ **Audit**:
- Added `auditLog` entries for preview attempts and download denials

---

🔑 **Important Codes**

| **Code**         | **Purpose**                                                |
|------------------|------------------------------------------------------------|
| `SV-ACCESS-2026` | Security code required for cross-department access requests|
| `Admin@12345`    | Unified default password for all seeded accounts           |

---

🔧 **Troubleshooting**

| **Issue**                          | **Solution**                                                               |
|------------------------------------|---------------------------------------------------------------------------|
| Database connection failed         | Verify MySQL is running and `db.php` credentials match your setup         |
| File upload fails                  | Check `uploads/` folder exists and has write permissions (755/777)         |
| Login redirects to login page      | Clear browser cookies/session and try again                               |
| CSRF token invalid                 | Refresh the page to generate a new token                                  |
| Cannot preview/download file       | Ensure file exists in `uploads/` directory and you have access rights     |
| Notifications not appearing        | Run `migration_update.sql` to create the notifications table              |

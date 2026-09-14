Cloud.png
# SecureVault - Feature-Separated Structure

This version keeps each major feature in its own folder.

## Main feature folders

- `features/login/` — `index.php` controller, `view.html` template, `style.css`, `script.js`
- `features/register/` — registration feature files
- `features/forgot_password/` — forgot-password feature files
- `features/dashboard/` — regular user dashboard files
- `features/admin_dashboard/` — department admin dashboard files
- `features/super_admin_dashboard/` — super admin dashboard files
- `features/preview/` — preview fallback page files

## Backend-only folders

- `core/` — shared PHP backend files: database, authentication, layout helpers
- `actions/` — PHP actions such as upload, download, logout, and request access
- `shared/` — shared CSS/JS used by common layout helpers

## Compatibility files

The root files such as `login.php`, `dashboard.php`, `upload.php`, and `download.php` are kept as small route files so old links and form actions continue to work.

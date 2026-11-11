<?php
// config/constants.php
define('SITE_NAME', 'EduSafe');
define('UPLOAD_PATH', __DIR__ . '/../uploads/');
define('MAX_FILE_SIZE', 50 * 1024 * 1024); // 50MB
define('ENCRYPTION_KEY', 'edusafe-secret-key-2024-256bit-aes');
define('DEFAULT_ROLE', 'mahasiswa');
define('ALLOWED_IMAGE_TYPES', ['jpg', 'jpeg', 'png']);
define('ALLOWED_FILE_TYPES', ['pdf', 'doc', 'docx', 'txt']);

// --- KONFIGURASI BARU UNTUK ANDROID API ---
define('JWT_SECRET', 'edusafe-jwt-secret-key-change-this-in-production');
define('JWT_EXPIRY', 86400); // 24 jam
define('DONGLE_SECRET', 'edusafe-dongle-secret-2024'); // Untuk validasi file dongle

// Pastikan folder uploads ada
if (!is_dir(UPLOAD_PATH)) {
    mkdir(UPLOAD_PATH, 0755, true);
}
?>
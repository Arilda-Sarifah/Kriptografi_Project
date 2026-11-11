<?php
// api/get_files.php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/database_helper.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

$files = DatabaseHelper::getExamFiles($user['user_id']);

// Jangan kirim isi file terenkripsi ke Android (bisa puluhan MB)
// Kirim hanya metadata
$result = array_map(function($f) {
    return [
        'id' => $f['id'],
        'filename' => $f['filename'],
        'original_filename' => $f['original_filename'],
        'uploader_name' => $f['uploader_name'] ?? null,
        'size_kb' => round(strlen($f['encrypted_content']) / 1024, 2),
        'created_at' => $f['created_at']
    ];
}, $files);

ApiResponse::success('Files retrieved', ['files' => $result]);
?>
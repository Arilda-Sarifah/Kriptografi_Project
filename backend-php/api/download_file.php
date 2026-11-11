<?php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/database_helper.php';
require_once __DIR__ . '/../includes/file_processor.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::error('Method not allowed', 405);
}

$file_id = filter_var($_GET['id'] ?? null, FILTER_VALIDATE_INT);
if (!$file_id || $file_id < 1) ApiResponse::error('A valid file id is required');

$file = DatabaseHelper::getExamFileForUser($file_id, $user['user_id']);
if (!$file) ApiResponse::notFound('File not found.');

try {
    $content = FileEncryption::decryptFile($file['encrypted_content']);
    $filename = preg_replace(
        '/[^A-Za-z0-9._-]/',
        '_',
        basename($file['original_filename'])
    );
    header('Content-Type: application/octet-stream');
    header('Content-Length: ' . strlen($content));
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    echo $content;
    exit;
} catch (Exception $e) {
    ApiResponse::error('File decryption failed: ' . $e->getMessage(), 500);
}
?>

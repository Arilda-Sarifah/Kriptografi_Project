<?php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/database_helper.php';
require_once __DIR__ . '/../config/constants.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    ApiResponse::error('Method not allowed', 405);
}

$certificate_id = filter_var($_GET['id'] ?? null, FILTER_VALIDATE_INT);
if (!$certificate_id || $certificate_id < 1) {
    ApiResponse::error('A valid certificate id is required');
}

$certificate = DatabaseHelper::getCertificateForUser(
    $certificate_id,
    $user['user_id']
);
if (!$certificate) ApiResponse::notFound('Certificate not found.');

$filename = basename($certificate['stego_image_path']);
$path = UPLOAD_PATH . 'certificates/' . $filename;
if (!is_file($path)) ApiResponse::notFound('Certificate image not found.');

$mime_type = mime_content_type($path);
if ($mime_type !== 'image/png' && $mime_type !== 'image/jpeg') {
    ApiResponse::error('Unsupported certificate image format', 500);
}
header('Content-Type: ' . $mime_type);
header('Content-Length: ' . filesize($path));
header('Content-Disposition: attachment; filename="' . str_replace('"', '', $filename) . '"');
readfile($path);
exit;
?>

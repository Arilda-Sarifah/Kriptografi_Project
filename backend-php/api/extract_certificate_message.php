<?php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/database_helper.php';
require_once __DIR__ . '/../includes/steganography.php';
require_once __DIR__ . '/../config/constants.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

$input = ApiResponse::getJsonInput();
$certificate_id = filter_var(
    $input['certificate_id'] ?? null,
    FILTER_VALIDATE_INT
);
if (!$certificate_id || $certificate_id < 1) {
    ApiResponse::error('A valid certificate id is required');
}

$certificate = DatabaseHelper::getCertificateForUser(
    $certificate_id,
    $user['user_id']
);
if (!$certificate) ApiResponse::notFound('Certificate not found.');

$path = UPLOAD_PATH . 'certificates/' . basename($certificate['stego_image_path']);
if (!is_file($path)) ApiResponse::notFound('Certificate image not found.');

try {
    $message = Steganography::extractMessageLSB(
        $path,
        EncryptionConfig::KEY
    );
    ApiResponse::success('Hidden message extracted', ['message' => $message]);
} catch (Exception $e) {
    ApiResponse::error('Message extraction failed: ' . $e->getMessage(), 500);
}
?>

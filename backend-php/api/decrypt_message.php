<?php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/database_helper.php';
require_once __DIR__ . '/../includes/encryption_engine.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

$input = ApiResponse::getJsonInput();
$message_id = filter_var($input['message_id'] ?? null, FILTER_VALIDATE_INT);
if (!$message_id || $message_id < 1) {
    ApiResponse::error('A valid message id is required');
}

$message = DatabaseHelper::getMessageForUser($message_id, $user['user_id']);
if (!$message) ApiResponse::notFound('Message not found.');

try {
    $plain_text = SuperEncryption::superDecrypt(
        $message['encrypted_message'],
        EncryptionConfig::KEY
    );
    ApiResponse::success('Message decrypted', ['message' => $plain_text]);
} catch (Exception $e) {
    ApiResponse::error('Message decryption failed: ' . $e->getMessage(), 500);
}
?>

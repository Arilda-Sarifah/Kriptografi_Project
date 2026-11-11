<?php
// api/send_message.php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/database_helper.php';
require_once __DIR__ . '/../includes/encryption_engine.php';
require_once __DIR__ . '/../includes/blockchain.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

$input = ApiResponse::getJsonInput();
$receiver_id = (int)($input['receiver_id'] ?? 0);
$message = trim($input['message'] ?? '');

if ($receiver_id <= 0 || empty($message)) {
    ApiResponse::error('Receiver and message are required');
}

try {
    // Super Encryption (Affine + Vigenere + AES-256-GCM)
    $encrypted = SuperEncryption::superEncrypt($message, EncryptionConfig::KEY);
    
    if (DatabaseHelper::saveMessage($user['user_id'], $receiver_id, $encrypted)) {
        // Catat ke blockchain
        SimpleBlockchain::addBlock([
            'sender_id' => $user['user_id'],
            'receiver_id' => $receiver_id
        ], 'MESSAGE_SEND');
        
        ApiResponse::success('Message sent securely');
    } else {
        ApiResponse::error('Failed to save message', 500);
    }
} catch (Exception $e) {
    ApiResponse::error('Encryption failed: ' . $e->getMessage(), 500);
}
?>
<?php
// api/get_dongle_key.php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';

// Endpoint ini HARUS login (pakai JWT) untuk regenerate dongle
$user = Auth::getAuthenticatedUser();
if (!$user) {
    ApiResponse::unauthorized();
}

$dongle_content = base64_encode(random_bytes(32));
$dongle_hash = hash('sha256', $dongle_content . DONGLE_SECRET);

$pdo = DatabaseConfig::getConnection();
$stmt = $pdo->prepare("UPDATE users SET dongle_key_hash = ? WHERE id = ?");
$stmt->execute([$dongle_hash, $user['user_id']]);

ApiResponse::success('New dongle generated. Save it to your flashdisk!', [
    'dongle_file_name' => 'edusafe_dongle.key',
    'dongle_content' => $dongle_content
]);
?>
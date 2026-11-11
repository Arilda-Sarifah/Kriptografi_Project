<?php
// api/verify_dongle.php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/database_helper.php';

$input = ApiResponse::getJsonInput();
$username = trim($input['username'] ?? '');
$dongle_content = $input['dongle_content'] ?? '';

if (empty($username) || empty($dongle_content)) {
    ApiResponse::error('Username and dongle content are required');
}

$pdo = DatabaseConfig::getConnection();
$stmt = $pdo->prepare("SELECT id FROM users WHERE username = ? AND status = 'active'");
$stmt->execute([$username]);
$user = $stmt->fetch();

if (!$user) {
    ApiResponse::error('User not found', 404);
}

if (!DatabaseHelper::validateDongle($user['id'], $dongle_content)) {
    ApiResponse::error('Invalid dongle. Access denied.', 401);
}

ApiResponse::success('Dongle verified. Proceed with biometric login.');
?>
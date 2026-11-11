<?php
// api/login.php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }

require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/jwt_helper.php';
require_once __DIR__ . '/../includes/database_helper.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

$input = ApiResponse::getJsonInput();
$username = trim($input['username'] ?? '');
$password = $input['password'] ?? '';
$dongle_content = $input['dongle_content'] ?? null; // isi file dongle (base64)

if (empty($username) || empty($password)) {
    ApiResponse::error('Username and password are required');
}

// 1. Verifikasi dongle DULU (sesuai syarat: dongle dulu, baru login)
if (empty($dongle_content)) {
    ApiResponse::error('Dongle is required. Please plug in your USB dongle.', 401);
}

$pdo = DatabaseConfig::getConnection();
$stmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
$stmt->execute([$username]);
$userRow = $stmt->fetch();

if (!$userRow) {
    ApiResponse::error('Invalid credentials', 401);
}

// Validasi dongle terhadap database
if (!DatabaseHelper::validateDongle($userRow['id'], $dongle_content)) {
    ApiResponse::error('Invalid dongle. Access denied.', 401);
}

// 2. Verifikasi password & generate JWT
$token = Auth::loginApi($username, $password);
if (!$token) {
    ApiResponse::error('Invalid username or password', 401);
}

// 3. Ambil data user untuk dikirim ke Android
$user = DatabaseHelper::getUserById($userRow['id']);

ApiResponse::success('Login successful', [
    'token' => $token,
    'user' => $user
]);
?>
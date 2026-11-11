<?php
// api/register.php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }

require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/blockchain.php';
require_once __DIR__ . '/../config/constants.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

$input = ApiResponse::getJsonInput();
$username = trim($input['username'] ?? '');
$password = $input['password'] ?? '';
$role     = $input['role'] ?? 'mahasiswa';

// Validasi
if (empty($username) || empty($password)) {
    ApiResponse::error('Username and password are required');
}
if (strlen($password) < 6) {
    ApiResponse::error('Password must be at least 6 characters');
}
if (!in_array($role, ['mahasiswa', 'dosen'])) {
    ApiResponse::error('Invalid role');
}

try {
    // 1. Generate isi file dongle (random 32 bytes → base64)
    //    Ini akan disimpan ke flashdisk oleh Android sebagai file .key
    $dongle_content = base64_encode(random_bytes(32));
    $dongle_hash = hash('sha256', $dongle_content . DONGLE_SECRET);

    // 2. Daftarkan user dengan dongle_key_hash
    Auth::registerApi($username, $password, $role, $dongle_hash);

    // 3. Catat ke blockchain
    SimpleBlockchain::addBlock([
        'username' => $username,
        'role' => $role
    ], 'USER_REGISTER');

    // 4. Ambil user_id
    $pdo = DatabaseConfig::getConnection();
    $stmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
    $stmt->execute([$username]);
    $user = $stmt->fetch();

    // 5. Kembalikan data dongle ke Android
    //    Android akan tulis file "edusafe_dongle.key" ke flashdisk
    ApiResponse::success('Registration successful. Save the dongle file to your flashdisk!', [
        'user_id' => $user['id'],
        'username' => $username,
        'role' => $role,
        'dongle_file_name' => 'edusafe_dongle.key',
        'dongle_content' => $dongle_content   // base64 string
    ]);
} catch (Exception $e) {
    ApiResponse::error($e->getMessage(), 400);
}
?>
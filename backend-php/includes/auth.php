<?php
// includes/auth.php
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../config/constants.php';
require_once __DIR__ . '/jwt_helper.php';

class Auth {
    // Hash password: Argon2id + SHA3-512
    public static function hashPassword($password) {
        $options = [
            'memory_cost' => 65536,
            'time_cost' => 4,
            'threads' => 2
        ];
        $argon_hash = password_hash($password, PASSWORD_ARGON2ID, $options);
        $final_hash = hash('sha3-512', $argon_hash);
        // Kembalikan array: hash final & hash argon asli untuk verifikasi
        return [
            'stored_hash' => $final_hash,
            'argon_hash'  => $argon_hash
        ];
    }
    
    // Verifikasi password yang SUDAH DIPERBAIKI
    public static function verifyPassword($password, $stored_sha3_hash, $stored_argon_hash) {
        // 1. Cek password cocok dengan hash Argon2 asli
        if (!password_verify($password, $stored_argon_hash)) {
            return false;
        }
        // 2. Cek integritas SHA3-512
        $input_sha3 = hash('sha3-512', $stored_argon_hash);
        return hash_equals($stored_sha3_hash, $input_sha3);
    }
    
    // Login untuk API - return JWT jika sukses
    public static function loginApi($username, $password) {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->prepare("SELECT id, username, password_hash, argon_hash, role FROM users WHERE username = ? AND status = 'active'");
        $stmt->execute([$username]);
        $user = $stmt->fetch();
        
        if ($user && self::verifyPassword($password, $user['password_hash'], $user['argon_hash'])) {
            // Update last login
            $pdo->prepare("UPDATE users SET last_login = NOW() WHERE id = ?")->execute([$user['id']]);
            
            // Generate JWT
            $token = JWT::encode([
                'user_id' => $user['id'],
                'username' => $user['username'],
                'role' => $user['role']
            ]);
            return $token;
        }
        return false;
    }
    
    // Register untuk API
    public static function registerApi($username, $password, $role = 'mahasiswa', $dongle_key = null) {
        $pdo = DatabaseConfig::getConnection();
        
        $check_stmt = $pdo->prepare("SELECT id FROM users WHERE username = ?");
        $check_stmt->execute([$username]);
        if ($check_stmt->fetch()) {
            throw new Exception("Username already exists");
        }
        
        $hashes = self::hashPassword($password);
        
        $stmt = $pdo->prepare("INSERT INTO users (username, password_hash, argon_hash, role, dongle_key_hash, status) VALUES (?, ?, ?, ?, ?, 'active')");
        return $stmt->execute([$username, $hashes['stored_hash'], $hashes['argon_hash'], $role, $dongle_key]);
    }
    
    // Cek user login berdasarkan header Authorization (untuk API)
    public static function getAuthenticatedUser() {
        $token = JWT::getBearerToken();
        if (!$token) return false;
        return JWT::decode($token);
    }
}
?>
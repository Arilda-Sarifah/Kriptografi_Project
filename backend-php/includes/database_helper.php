<?php
// includes/database_helper.php
require_once __DIR__ . '/../config/database.php';

class DatabaseHelper {
    public static function getUserById($id) {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->prepare("SELECT id, username, role, created_at FROM users WHERE id = ?");
        $stmt->execute([$id]);
        return $stmt->fetch();
    }
    
    public static function getAllUsers($exclude_id = null) {
        $pdo = DatabaseConfig::getConnection();
        if ($exclude_id) {
            $stmt = $pdo->prepare("SELECT id, username, role FROM users WHERE id != ? AND status = 'active'");
            $stmt->execute([$exclude_id]);
        } else {
            $stmt = $pdo->prepare("SELECT id, username, role FROM users WHERE status = 'active'");
            $stmt->execute();
        }
        return $stmt->fetchAll();
    }
    
    // Validasi dongle dengan membandingkan hash file dongle
    public static function validateDongle($user_id, $dongle_content) {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->prepare("SELECT dongle_key_hash FROM users WHERE id = ?");
        $stmt->execute([$user_id]);
        $row = $stmt->fetch();
        if (!$row || !$row['dongle_key_hash']) return false;
        $input_hash = hash('sha256', $dongle_content . DONGLE_SECRET);
        return hash_equals($row['dongle_key_hash'], $input_hash);
    }
    
    public static function saveMessage($sender_id, $receiver_id, $encrypted_message) {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->prepare("INSERT INTO messages (sender_id, receiver_id, encrypted_message) VALUES (?, ?, ?)");
        return $stmt->execute([$sender_id, $receiver_id, $encrypted_message]);
    }
    
    public static function getMessages($user_id) {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->prepare("
            SELECT m.*, u1.username as sender_name, u2.username as receiver_name 
            FROM messages m 
            LEFT JOIN users u1 ON m.sender_id = u1.id 
            LEFT JOIN users u2 ON m.receiver_id = u2.id 
            WHERE m.sender_id = ? OR m.receiver_id = ? 
            ORDER BY m.created_at DESC
        ");
        $stmt->execute([$user_id, $user_id]);
        return $stmt->fetchAll();
    }

    public static function getMessageForUser($message_id, $user_id) {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->prepare("
            SELECT encrypted_message FROM messages
            WHERE id = ? AND (sender_id = ? OR receiver_id = ?)
        ");
        $stmt->execute([$message_id, $user_id, $user_id]);
        return $stmt->fetch();
    }
    
    public static function saveExamFile($filename, $original_filename, $encrypted_content, $uploaded_by) {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->prepare("INSERT INTO exam_files (filename, original_filename, encrypted_content, uploaded_by) VALUES (?, ?, ?, ?)");
        return $stmt->execute([$filename, $original_filename, $encrypted_content, $uploaded_by]);
    }
    
    public static function getExamFiles($user_id = null) {
        $pdo = DatabaseConfig::getConnection();
        if ($user_id) {
            $stmt = $pdo->prepare("
                SELECT ef.*, u.username as uploader_name 
                FROM exam_files ef 
                LEFT JOIN users u ON ef.uploaded_by = u.id 
                WHERE ef.uploaded_by = ? 
                ORDER BY ef.created_at DESC
            ");
            $stmt->execute([$user_id]);
        } else {
            $stmt = $pdo->prepare("
                SELECT ef.*, u.username as uploader_name 
                FROM exam_files ef 
                LEFT JOIN users u ON ef.uploaded_by = u.id 
                ORDER BY ef.created_at DESC
            ");
            $stmt->execute();
        }
        return $stmt->fetchAll();
    }

    public static function getExamFileForUser($file_id, $user_id) {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->prepare("
            SELECT id, original_filename, encrypted_content
            FROM exam_files WHERE id = ? AND uploaded_by = ?
        ");
        $stmt->execute([$file_id, $user_id]);
        return $stmt->fetch();
    }

    public static function saveCertificate($student_name, $course_name, $original_image_path, $stego_image_path, $created_by) {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->prepare("INSERT INTO certificates (student_name, course_name, original_image_path, stego_image_path, created_by) VALUES (?, ?, ?, ?, ?)");
        if (!$stmt->execute([$student_name, $course_name, $original_image_path, $stego_image_path, $created_by])) {
            return false;
        }
        return $pdo->lastInsertId();
    }
    
    public static function getCertificates($user_id = null) {
        $pdo = DatabaseConfig::getConnection();
        if ($user_id) {
            $stmt = $pdo->prepare("
                SELECT c.*, u.username as creator_name 
                FROM certificates c 
                LEFT JOIN users u ON c.created_by = u.id 
                WHERE c.created_by = ? 
                ORDER BY c.created_at DESC
            ");
            $stmt->execute([$user_id]);
        } else {
            $stmt = $pdo->prepare("
                SELECT c.*, u.username as creator_name 
                FROM certificates c 
                LEFT JOIN users u ON c.created_by = u.id 
                ORDER BY c.created_at DESC
            ");
            $stmt->execute();
        }
        return $stmt->fetchAll();
    }

    public static function getCertificateForUser($certificate_id, $user_id) {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->prepare("
            SELECT id, student_name, course_name, original_image_path,
                   stego_image_path, created_by, created_at
            FROM certificates WHERE id = ? AND created_by = ?
        ");
        $stmt->execute([$certificate_id, $user_id]);
        return $stmt->fetch();
    }
}
?>
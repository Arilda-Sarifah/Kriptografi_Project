<?php
// api/upload_file.php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/file_processor.php';
require_once __DIR__ . '/../includes/blockchain.php';
require_once __DIR__ . '/../config/constants.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

// Validasi file upload (multipart/form-data)
if (!isset($_FILES['file']) || $_FILES['file']['error'] !== UPLOAD_ERR_OK) {
    ApiResponse::error('No file uploaded or upload error');
}

$file = $_FILES['file'];
$errors = FileEncryption::validateFile($file, ALLOWED_FILE_TYPES);
if (!empty($errors)) {
    ApiResponse::error(implode(', ', $errors));
}

try {
    // Enkripsi file dengan ChaCha20-Poly1305 + HMAC-SHA3-512
    $encrypted_content = FileEncryption::encryptFile($file['tmp_name'], EncryptionConfig::KEY);
    
    $filename = uniqid() . '_' . preg_replace('/[^a-zA-Z0-9._-]/', '_', $file['name']);
    $original_filename = $file['name'];
    
    if (DatabaseHelper::saveExamFile($filename, $original_filename, $encrypted_content, $user['user_id'])) {
        SimpleBlockchain::addBlock([
            'filename' => $original_filename,
            'uploaded_by' => $user['user_id'],
            'size' => $file['size']
        ], 'FILE_UPLOAD');
        
        ApiResponse::success('File uploaded and encrypted successfully', [
            'filename' => $filename,
            'original_filename' => $original_filename
        ]);
    } else {
        ApiResponse::error('Failed to save file to database', 500);
    }
} catch (Exception $e) {
    ApiResponse::error('Encryption failed: ' . $e->getMessage(), 500);
}
?>
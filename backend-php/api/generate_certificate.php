<?php
// api/generate_certificate.php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/steganography.php';
require_once __DIR__ . '/../includes/database_helper.php';
require_once __DIR__ . '/../includes/blockchain.php';
require_once __DIR__ . '/../config/constants.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    ApiResponse::error('Method not allowed', 405);
}

$student_name = trim($_POST['student_name'] ?? '');
$course_name = trim($_POST['course_name'] ?? '');
$hidden_message = trim($_POST['hidden_message'] ?? '');

if (empty($student_name) || empty($course_name) || empty($hidden_message)) {
    ApiResponse::error('All fields are required');
}
if (!isset($_FILES['certificate_image']) || $_FILES['certificate_image']['error'] !== UPLOAD_ERR_OK) {
    ApiResponse::error('Certificate image is required');
}

$image_file = $_FILES['certificate_image'];
$errors = Steganography::validateImage($image_file);
if (!empty($errors)) {
    ApiResponse::error(implode(', ', $errors));
}

try {
    $upload_dir = UPLOAD_PATH . 'certificates/';
    if (!is_dir($upload_dir)) mkdir($upload_dir, 0755, true);
    
    // Simpan gambar asli
    $image_info = getimagesize($image_file['tmp_name']);
    $extension = $image_info[2] === IMAGETYPE_PNG ? 'png' : 'jpg';
    $original_filename = uniqid() . '_original.' . $extension;
    $original_path = $upload_dir . $original_filename;
    if (!move_uploaded_file($image_file['tmp_name'], $original_path)) {
        throw new Exception('Failed to store original image');
    }
    
    // Keep the output lossless so the embedded LSB payload can be extracted.
    $stego_filename = uniqid() . '_stego.png';
    $stego_path = $upload_dir . $stego_filename;
    
    Steganography::hideMessageLSB($original_path, $hidden_message, $stego_path, EncryptionConfig::KEY);
    
    $certificate_id = DatabaseHelper::saveCertificate($student_name, $course_name, $original_filename, $stego_filename, $user['user_id']);
    if ($certificate_id) {
        SimpleBlockchain::addBlock([
            'student_name' => $student_name,
            'course_name' => $course_name,
            'stego_image' => $stego_filename,
            'created_by' => $user['user_id']
        ], 'CERT_CREATE');
        
        ApiResponse::success('Certificate generated with hidden message', [
            'certificate_id' => $certificate_id,
            'stego_image_url' => 'uploads/certificates/' . $stego_filename,
            'original_image_url' => 'uploads/certificates/' . $original_filename
        ]);
    } else {
        ApiResponse::error('Failed to save certificate to database', 500);
    }
} catch (Exception $e) {
    ApiResponse::error('Steganography failed: ' . $e->getMessage(), 500);
}
?>
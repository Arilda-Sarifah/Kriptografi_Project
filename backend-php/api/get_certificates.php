<?php
// api/get_certificates.php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/database_helper.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

$certs = DatabaseHelper::getCertificates($user['user_id']);

$result = array_map(function($c) {
    return [
        'id' => $c['id'],
        'student_name' => $c['student_name'],
        'course_name' => $c['course_name'],
        'stego_image_url' => 'uploads/certificates/' . $c['stego_image_path'],
        'original_image_url' => 'uploads/certificates/' . $c['original_image_path'],
        'creator_name' => $c['creator_name'] ?? null,
        'created_at' => $c['created_at']
    ];
}, $certs);

ApiResponse::success('Certificates retrieved', ['certificates' => $result]);
?>
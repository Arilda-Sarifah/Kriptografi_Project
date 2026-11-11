<?php
// index.php - Halaman pengecekan API
header('Content-Type: application/json');
echo json_encode([
    "status" => "success",
    "message" => "EduSafe API is Running",
    "version" => "2.0.0",
    "timestamp" => date('c')
]);
?>
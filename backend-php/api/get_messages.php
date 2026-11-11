<?php
// api/get_messages.php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/database_helper.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

$messages = DatabaseHelper::getMessages($user['user_id']);
ApiResponse::success('Messages retrieved', ['messages' => $messages]);
?>
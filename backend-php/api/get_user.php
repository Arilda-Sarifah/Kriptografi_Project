<?php
// api/get_users.php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/database_helper.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

$users = DatabaseHelper::getAllUsers($user['user_id']);
ApiResponse::success('Users retrieved', ['users' => $users]);
?>
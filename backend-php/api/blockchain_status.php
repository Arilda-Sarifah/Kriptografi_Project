<?php
// api/blockchain_status.php
require_once __DIR__ . '/response.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/blockchain.php';

$user = Auth::getAuthenticatedUser();
if (!$user) ApiResponse::unauthorized();

$chain = SimpleBlockchain::getChain();
$isValid = SimpleBlockchain::validateChain();

ApiResponse::success('Blockchain status', [
    'total_blocks' => count($chain),
    'is_valid' => $isValid,
    'chain' => $chain
]);
?>
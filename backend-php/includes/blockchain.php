<?php
// includes/blockchain.php
require_once __DIR__ . '/../config/database.php';

class SimpleBlockchain {
    // Menambahkan block baru ke ledger
    public static function addBlock($data, $action_type) {
        $pdo = DatabaseConfig::getConnection();
        
        // Ambil block terakhir
        $stmt = $pdo->query("SELECT * FROM blockchain_ledger ORDER BY id DESC LIMIT 1");
        $lastBlock = $stmt->fetch();
        
        $index = $lastBlock ? $lastBlock['block_index'] + 1 : 0;
        $prevHash = $lastBlock ? $lastBlock['hash'] : '0';
        $timestamp = time();
        
        // Gabungkan data & hash
        $dataString = json_encode($data);
        $blockString = $index . $timestamp . $action_type . $dataString . $prevHash;
        $hash = hash('sha256', $blockString);
        
        // Simpan
        $insertStmt = $pdo->prepare("INSERT INTO blockchain_ledger (block_index, timestamp, action_type, data, previous_hash, hash) VALUES (?, ?, ?, ?, ?, ?)");
        $insertStmt->execute([$index, $timestamp, $action_type, $dataString, $prevHash, $hash]);
        
        return $hash;
    }
    
    // Verifikasi integritas seluruh blockchain
    public static function validateChain() {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->query("SELECT * FROM blockchain_ledger ORDER BY block_index ASC");
        $blocks = $stmt->fetchAll();
        
        $prevHash = '0';
        foreach ($blocks as $block) {
            // Rekalkulasi hash
            $blockString = $block['block_index'] . $block['timestamp'] . $block['action_type'] . $block['data'] . $prevHash;
            $recalcHash = hash('sha256', $blockString);
            
            if ($recalcHash !== $block['hash'] || $block['previous_hash'] !== $prevHash) {
                return false;
            }
            $prevHash = $block['hash'];
        }
        return true;
    }
    
    public static function getChain() {
        $pdo = DatabaseConfig::getConnection();
        $stmt = $pdo->query("SELECT * FROM blockchain_ledger ORDER BY block_index ASC");
        return $stmt->fetchAll();
    }
}
?>
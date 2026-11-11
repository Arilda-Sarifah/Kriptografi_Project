<?php
// config/encryption.php
class EncryptionConfig {
    const METHOD = 'aes-256-gcm';
    const IV_LENGTH = 16;
    const TAG_LENGTH = 16;
    const KEY = 'edusafe-encryption-key-2024';
    
    public static function generateKey() {
        return random_bytes(32);
    }
    
    public static function generateIV() {
        return random_bytes(self::IV_LENGTH);
    }
}
?>
<?php
// includes/file_processor.php
require_once __DIR__ . '/../config/encryption.php';

class FileEncryption {
    private const FORMAT_PREFIX = 'ESF1';
    private const NONCE_LENGTH = 12;
    private const TAG_LENGTH = 16;
    private const HMAC_LENGTH = 64;

    private static function key() {
        return hash('sha256', EncryptionConfig::KEY, true);
    }

    public static function encryptFile($file_path, $key = null) {
        if (!file_exists($file_path)) throw new Exception("File not found: " . $file_path);
        $file_content = file_get_contents($file_path);
        if ($file_content === false) throw new Exception("Cannot read file");

        $encryption_key = self::key();
        $nonce = random_bytes(self::NONCE_LENGTH);
        $tag = '';
        $encrypted = openssl_encrypt(
            $file_content,
            'chacha20-poly1305',
            $encryption_key,
            OPENSSL_RAW_DATA,
            $nonce,
            $tag,
            '',
            self::TAG_LENGTH
        );
        if ($encrypted === false) {
            throw new Exception("ChaCha20-Poly1305 encryption failed");
        }

        $hmac = hash_hmac(
            'sha3-512',
            $nonce . $encrypted . $tag,
            $encryption_key,
            true
        );
        return base64_encode(
            self::FORMAT_PREFIX . $nonce . $tag . $hmac . $encrypted
        );
    }

    public static function decryptFile($encrypted_data, $key = null) {
        $data = base64_decode($encrypted_data, true);
        if ($data === false) throw new Exception("Invalid base64 file data");

        if (substr($data, 0, strlen(self::FORMAT_PREFIX)) === self::FORMAT_PREFIX) {
            $offset = strlen(self::FORMAT_PREFIX);
            $header_length = $offset + self::NONCE_LENGTH + self::TAG_LENGTH + self::HMAC_LENGTH;
            if (strlen($data) < $header_length) {
                throw new Exception("Invalid encrypted data format");
            }

            $nonce = substr($data, $offset, self::NONCE_LENGTH);
            $tag = substr($data, $offset + self::NONCE_LENGTH, self::TAG_LENGTH);
            $hmac = substr($data, $offset + self::NONCE_LENGTH + self::TAG_LENGTH, self::HMAC_LENGTH);
            $ciphertext = substr($data, $header_length);
            $encryption_key = self::key();
            $calculated_hmac = hash_hmac(
                'sha3-512',
                $nonce . $ciphertext . $tag,
                $encryption_key,
                true
            );
            if (!hash_equals($hmac, $calculated_hmac)) {
                throw new Exception("HMAC verification failed");
            }
            $decrypted = openssl_decrypt(
                $ciphertext,
                'chacha20-poly1305',
                $encryption_key,
                OPENSSL_RAW_DATA,
                $nonce,
                $tag
            );
        } else {
            $legacy_header_length = 24 + self::TAG_LENGTH + self::HMAC_LENGTH;
            if (strlen($data) < $legacy_header_length) {
                throw new Exception("Invalid encrypted data format");
            }

            $legacy_nonce = substr($data, 0, 24);
            $tag = substr($data, 24, self::TAG_LENGTH);
            $hmac = substr($data, 24 + self::TAG_LENGTH, self::HMAC_LENGTH);
            $ciphertext = substr($data, $legacy_header_length);
            $calculated_hmac = hash_hmac(
                'sha3-512',
                $legacy_nonce . $ciphertext . $tag,
                EncryptionConfig::KEY,
                true
            );
            if (!hash_equals($hmac, $calculated_hmac)) {
                throw new Exception("HMAC verification failed");
            }
            $decrypted = openssl_decrypt(
                $ciphertext,
                'chacha20-poly1305',
                EncryptionConfig::KEY,
                OPENSSL_RAW_DATA,
                substr($legacy_nonce, 0, 12),
                $tag
            );
        }

        if ($decrypted === false) throw new Exception("Decryption failed");
        return $decrypted;
    }

    public static function validateFile($file, $allowed_types) {
        $errors = [];
        if ($file['size'] > MAX_FILE_SIZE) $errors[] = "File size exceeds 50MB";
        $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
        if (!in_array($ext, $allowed_types)) $errors[] = "File type not allowed";
        if ($file['error'] !== UPLOAD_ERR_OK) $errors[] = "Upload error: " . $file['error'];
        return $errors;
    }
}
?>

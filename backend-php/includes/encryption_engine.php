<?php
// includes/encryption_engine.php
require_once __DIR__ . '/../config/encryption.php';

class SuperEncryption {
    public static function affineEncrypt($text, $a = 5, $b = 8) {
        $result = ""; $m = 26;
        foreach (str_split($text) as $char) {
            if (ctype_alpha($char)) {
                $is_upper = ctype_upper($char);
                $char = strtolower($char);
                $x = ord($char) - ord('a');
                $encrypted = ($a * $x + $b) % $m;
                $encrypted_char = chr($encrypted + ord('a'));
                $result .= $is_upper ? strtoupper($encrypted_char) : $encrypted_char;
            } else { $result .= $char; }
        }
        return $result;
    }
    
    public static function affineDecrypt($text, $a = 5, $b = 8) {
        $result = ""; $m = 26;
        $a_inv = 0;
        for ($i = 0; $i < $m; $i++) {
            if (($a * $i) % $m == 1) { $a_inv = $i; break; }
        }
        foreach (str_split($text) as $char) {
            if (ctype_alpha($char)) {
                $is_upper = ctype_upper($char);
                $char = strtolower($char);
                $y = ord($char) - ord('a');
                $decrypted = ($a_inv * ($y - $b + $m)) % $m;
                $decrypted_char = chr($decrypted + ord('a'));
                $result .= $is_upper ? strtoupper($decrypted_char) : $decrypted_char;
            } else { $result .= $char; }
        }
        return $result;
    }
    
    public static function vigenereEncrypt($text, $key) {
        $result = ""; $key_length = strlen($key); $key_index = 0;
        foreach (str_split($text) as $char) {
            if (ctype_alpha($char)) {
                $is_upper = ctype_upper($char);
                $char = strtolower($char);
                $shift = ord($key[$key_index % $key_length]) - ord('a');
                $encrypted = chr(((ord($char) - ord('a') + $shift) % 26) + ord('a'));
                $result .= $is_upper ? strtoupper($encrypted) : $encrypted;
                $key_index++;
            } else { $result .= $char; }
        }
        return $result;
    }
    
    public static function vigenereDecrypt($text, $key) {
        $result = ""; $key_length = strlen($key); $key_index = 0;
        foreach (str_split($text) as $char) {
            if (ctype_alpha($char)) {
                $is_upper = ctype_upper($char);
                $char = strtolower($char);
                $shift = ord($key[$key_index % $key_length]) - ord('a');
                $decrypted = chr(((ord($char) - ord('a') - $shift + 26) % 26) + ord('a'));
                $result .= $is_upper ? strtoupper($decrypted) : $decrypted;
                $key_index++;
            } else { $result .= $char; }
        }
        return $result;
    }
    
    public static function superEncrypt($text, $key) {
        if (empty($text)) return '';
        $affine_encrypted = self::affineEncrypt($text, 5, 8);
        $vigenere_encrypted = self::vigenereEncrypt($affine_encrypted, $key);
        
        $iv = EncryptionConfig::generateIV();
        $tag = '';
        $encrypted = openssl_encrypt(
            $vigenere_encrypted, EncryptionConfig::METHOD, $key,
            OPENSSL_RAW_DATA, $iv, $tag, '', EncryptionConfig::TAG_LENGTH
        );
        if ($encrypted === false) {
            throw new Exception("AES encryption failed: " . openssl_error_string());
        }
        return base64_encode($iv . $tag . $encrypted);
    }
    
    public static function superDecrypt($encrypted_text, $key) {
        if (empty($encrypted_text)) return '';
        $data = base64_decode($encrypted_text);
        if (strlen($data) < (EncryptionConfig::IV_LENGTH + EncryptionConfig::TAG_LENGTH)) {
            throw new Exception("Invalid encrypted data format");
        }
        $iv = substr($data, 0, EncryptionConfig::IV_LENGTH);
        $tag = substr($data, EncryptionConfig::IV_LENGTH, EncryptionConfig::TAG_LENGTH);
        $ciphertext = substr($data, EncryptionConfig::IV_LENGTH + EncryptionConfig::TAG_LENGTH);
        
        $aes_decrypted = openssl_decrypt(
            $ciphertext, EncryptionConfig::METHOD, $key,
            OPENSSL_RAW_DATA, $iv, $tag
        );
        if ($aes_decrypted === false) {
            throw new Exception("AES decryption failed: " . openssl_error_string());
        }
        $vigenere_decrypted = self::vigenereDecrypt($aes_decrypted, $key);
        return self::affineDecrypt($vigenere_decrypted, 5, 8);
    }
}
?>
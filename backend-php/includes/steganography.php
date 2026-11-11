<?php
// includes/steganography.php
require_once __DIR__ . '/encryption_engine.php';

class Steganography {
    public static function hideMessageLSB($image_path, $message, $output_path, $key) {
        if (!file_exists($image_path)) throw new Exception("Image not found");
        $image_info = getimagesize($image_path);
        if ($image_info === false) throw new Exception("Invalid image");
        
        switch ($image_info[2]) {
            case IMAGETYPE_JPEG: $image = imagecreatefromjpeg($image_path); break;
            case IMAGETYPE_PNG: $image = imagecreatefrompng($image_path); break;
            default: throw new Exception("Unsupported format");
        }
        if (!$image) throw new Exception("Failed to create resource");
        
        $width = imagesx($image); $height = imagesy($image);
        $encrypted_message = SuperEncryption::superEncrypt($message, $key);
        $binary_message = self::stringToBinary($encrypted_message . "###END###");
        
        $message_index = 0; $message_length = strlen($binary_message);
        $max_capacity = $width * $height;
        if ($message_length > $max_capacity) {
            imagedestroy($image);
            throw new Exception("Message too large");
        }
        
        for($y = 0; $y < $height; $y++) {
            for($x = 0; $x < $width; $x++) {
                if($message_index >= $message_length) break 2;
                $rgb = imagecolorat($image, $x, $y);
                $r = ($rgb >> 16) & 0xFF; $g = ($rgb >> 8) & 0xFF; $b = $rgb & 0xFF;
                $new_b = ($b & 0xFE) | intval($binary_message[$message_index]);
                $new_color = imagecolorallocate($image, $r, $g, $new_b);
                if ($new_color === false) continue;
                imagesetpixel($image, $x, $y, $new_color);
                $message_index++;
            }
        }
        
        // PNG preserves the modified least-significant bits; JPEG compression
        // would make the hidden payload unreliable.
        $success = imagepng($image, $output_path);
        imagedestroy($image);
        if (!$success) throw new Exception("Failed to save output");
        return $output_path;
    }
    
    public static function extractMessageLSB($image_path, $key) {
        if (!file_exists($image_path)) throw new Exception("Image not found");
        $image_info = getimagesize($image_path);
        if ($image_info === false) throw new Exception("Invalid image");
        switch ($image_info[2]) {
            case IMAGETYPE_JPEG: $image = imagecreatefromjpeg($image_path); break;
            case IMAGETYPE_PNG: $image = imagecreatefrompng($image_path); break;
            default: throw new Exception("Unsupported format");
        }
        if (!$image) throw new Exception("Failed to open image");
        $width = imagesx($image); $height = imagesy($image);
        
        $binary_message = ""; $end_marker = "###END###";
        $end_marker_binary = self::stringToBinary($end_marker);
        $end_marker_length = strlen($end_marker_binary);
        
        for($y = 0; $y < $height; $y++) {
            for($x = 0; $x < $width; $x++) {
                $rgb = imagecolorat($image, $x, $y);
                $b = $rgb & 0xFF;
                $binary_message .= ($b & 1);
                if (strlen($binary_message) >= $end_marker_length) {
                    if (substr($binary_message, -$end_marker_length) === $end_marker_binary) break 2;
                }
            }
        }
        imagedestroy($image);
        $encrypted_message = self::binaryToString($binary_message);
        $encrypted_message = str_replace($end_marker, "", $encrypted_message);
        return SuperEncryption::superDecrypt($encrypted_message, $key);
    }
    
    private static function stringToBinary($string) {
        $binary = "";
        for($i = 0; $i < strlen($string); $i++) $binary .= str_pad(decbin(ord($string[$i])), 8, '0', STR_PAD_LEFT);
        return $binary;
    }
    
    private static function binaryToString($binary) {
        $string = "";
        for($i = 0; $i < strlen($binary); $i += 8) {
            $byte = substr($binary, $i, 8);
            if (strlen($byte) < 8) break;
            $string .= chr(bindec($byte));
        }
        return $string;
    }
    
    public static function validateImage($file) {
        $errors = [];
        $image_info = getimagesize($file['tmp_name']);
        if ($image_info === false) {
            $errors[] = "Not a valid image";
        } elseif (!in_array($image_info[2], [IMAGETYPE_JPEG, IMAGETYPE_PNG])) {
            $errors[] = "Only JPEG/PNG allowed";
        }
        if ($file['size'] > 10 * 1024 * 1024) $errors[] = "Image exceeds 10MB";
        return $errors;
    }
}
?>
<?php
// config/database.php
require_once 'constants.php';

class DatabaseConfig {
    private static $instance = null;
    
    public static function getConnection() {
        if (self::$instance === null) {
            $host = "localhost";
            $dbname = "edusafe_kripto";      // <-- DIUBAH di sini
            $username = "root";               // <-- Sesuaikan user MySQL Anda
            $password = "";                   // <-- Sesuaikan password MySQL Anda
            
            try {
                self::$instance = new PDO(
                    "mysql:host=$host;dbname=$dbname;charset=utf8mb4", 
                    $username, 
                    $password
                );
                self::$instance->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                self::$instance->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
            } catch(PDOException $e) {
                error_log("Database connection failed: " . $e->getMessage());
                header('Content-Type: application/json');
                die(json_encode(["status" => "error", "message" => "Database connection error"]));
            }
        }
        return self::$instance;
    }
}
?>
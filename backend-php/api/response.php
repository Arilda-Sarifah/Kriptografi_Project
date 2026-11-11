<?php
// api/response.php
class ApiResponse {
    public static function send($status, $message, $data = null, $httpCode = 200) {
        http_response_code($httpCode);
        header('Content-Type: application/json; charset=utf-8');
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization');
        
        $response = [
            'status' => $status,  // 'success' atau 'error'
            'message' => $message
        ];
        if ($data !== null) {
            $response['data'] = $data;
        }
        echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
    
    public static function success($message, $data = null) {
        self::send('success', $message, $data, 200);
    }
    
    public static function error($message, $httpCode = 400, $data = null) {
        self::send('error', $message, $data, $httpCode);
    }
    
    public static function unauthorized($message = 'Unauthorized. Invalid or missing token.') {
        self::send('error', $message, null, 401);
    }
    
    public static function notFound($message = 'Resource not found.') {
        self::send('error', $message, null, 404);
    }
    
    // Ambil body request dalam format JSON (untuk Android yang kirim JSON)
    public static function getJsonInput() {
        $raw = file_get_contents('php://input');
        $data = json_decode($raw, true);
        return is_array($data) ? $data : [];
    }
}
?>
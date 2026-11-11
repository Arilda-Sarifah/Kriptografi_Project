class ApiConfig {
  ApiConfig._();

  // Ganti dengan IPv4 laptop di Wi-Fi yang sama atau set lewat --dart-define.
  static const baseUrl = String.fromEnvironment(
    'EDUSAFE_API_BASE_URL',
    defaultValue: 'http://192.168.100.8:8000/api/',
  );
}

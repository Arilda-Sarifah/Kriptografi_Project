import 'package:local_auth/local_auth.dart';

class BiometricService {
  BiometricService(this._localAuth);

  final LocalAuthentication _localAuth;

  Future<bool> authenticate() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final supported = await _localAuth.isDeviceSupported();
    if (!canCheck || !supported) {
      throw StateError(
        'Perangkat tidak memiliki biometric yang siap digunakan.',
      );
    }

    return _localAuth.authenticate(
      localizedReason: 'Verifikasi biometric untuk membuka EduSafe',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }
}

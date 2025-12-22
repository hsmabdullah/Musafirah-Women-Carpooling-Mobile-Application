import 'dart:math';

class IdUtils {
  static final _random = Random();
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// Generates a realistic transaction ID: TXN-XXXXX-XXXX
  static String generateTransactionId() {
    return 'TXN-${_randomString(5)}-${_randomString(4)}';
  }

  /// Generates a unique ride ID: MUS-XXXX-XXXX
  static String generateRideId() {
    return 'MUS-${_randomString(4)}-${_randomString(4)}';
  }

  static String _randomString(int length) {
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(_random.nextInt(_chars.length)),
      ),
    );
  }
}

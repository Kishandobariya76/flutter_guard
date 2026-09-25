import 'package:flutter_guard/flutter_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package exports FlutterGuard', () {
    expect(FlutterGuard.isInitialized, isFalse);
  });
}

import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package exports FlutterGuard', () {
    expect(FlutterGuard.isInitialized, isFalse);
  });
}

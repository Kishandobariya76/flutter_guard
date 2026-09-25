import 'dart:math';

final Random _random = Random.secure();

/// Builds a unique request identifier such as `fg_18c2_a91f3c`.
String createRequestId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final suffix = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
  return 'fg_$timestamp$suffix';
}

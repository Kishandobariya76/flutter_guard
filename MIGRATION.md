# Migration Guide

## Initial release

FlutterGuard `0.1.0` is the first public version. There is no previous package
API to migrate from.

### Installation

The pub.dev package name is `flutter_guard_sdk`. The Dart API still uses
`FlutterGuard`.

```yaml
dependencies:
  flutter_guard_sdk: ^0.1.0
```

```bash
flutter pub get
```

### Initialization

```dart
await FlutterGuard.initialize(
  FlutterGuardConfig(
    baseUrl: 'https://api.example.com',
  ),
);
```

### Breaking API changes

None. This is the initial release.

When 0.2.0 or 1.0.0 introduces breaking changes, this file will list the old
call, the new call, and the reason for the change.

import 'package:flutter/widgets.dart';

import 'flutter_guard.dart';

/// Optional [InheritedWidget] that exposes a [FlutterGuard] instance.
///
/// FlutterGuard does not require this widget. It exists for apps that prefer
/// `FlutterGuardScope.of(context)` over the process singleton.
class FlutterGuardScope extends InheritedWidget {
  /// Creates a scope.
  const FlutterGuardScope({
    super.key,
    required this.guard,
    required super.child,
  });

  /// Guard made available to descendants.
  final FlutterGuard guard;

  /// The nearest [FlutterGuard], or [FlutterGuard.instance] when no scope
  /// exists.
  static FlutterGuard of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FlutterGuardScope>();
    return scope?.guard ?? FlutterGuard.instance;
  }

  @override
  bool updateShouldNotify(FlutterGuardScope oldWidget) {
    return oldWidget.guard != guard;
  }
}

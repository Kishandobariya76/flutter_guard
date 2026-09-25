import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/demo_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapGuard();
  runApp(const FlutterGuardExampleApp());
}

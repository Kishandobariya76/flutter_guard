import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

import '../features/authentication/auth_page.dart';
import '../features/cache/cache_page.dart';
import '../features/cancellation/cancel_page.dart';
import '../features/connectivity/connectivity_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/deduplication/dedup_page.dart';
import '../features/diagnostics/diagnostics_page.dart';
import '../features/environment/environment_page.dart';
import '../features/feature_flags/flags_page.dart';
import '../features/lifecycle/lifecycle_page.dart';
import '../features/network/network_page.dart';
import '../features/offline/conflict_page.dart';
import '../features/offline/offline_queue_page.dart';
import '../features/offline/sync_page.dart';
import '../features/pagination/pagination_page.dart';
import '../features/playground/playground_page.dart';
import '../features/retry/retry_page.dart';
import '../features/utils/debounce_page.dart';
import '../features/utils/throttle_page.dart';

class FlutterGuardExampleApp extends StatelessWidget {
  const FlutterGuardExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterGuardScope(
      guard: FlutterGuard.instance,
      child: MaterialApp(
        title: 'FlutterGuard Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F4C5C)),
          useMaterial3: true,
        ),
        home: const DashboardPage(),
        routes: <String, WidgetBuilder>{
          '/network': (_) => const NetworkPage(),
          '/auth': (_) => const AuthPage(),
          '/retry': (_) => const RetryPage(),
          '/dedup': (_) => const DedupPage(),
          '/cancel': (_) => const CancelPage(),
          '/cache': (_) => const CachePage(),
          '/offline': (_) => const OfflineQueuePage(),
          '/sync': (_) => const SyncPage(),
          '/conflict': (_) => const ConflictPage(),
          '/pagination': (_) => const PaginationPage(),
          '/connectivity': (_) => const ConnectivityPage(),
          '/diagnostics': (_) => const DiagnosticsPage(),
          '/flags': (_) => const FlagsPage(),
          '/environment': (_) => const EnvironmentPage(),
          '/lifecycle': (_) => const LifecyclePage(),
          '/debounce': (_) => const DebouncePage(),
          '/throttle': (_) => const ThrottlePage(),
          '/playground': (_) => const PlaygroundPage(),
        },
      ),
    );
  }
}

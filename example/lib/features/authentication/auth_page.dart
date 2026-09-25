import 'package:flutter/material.dart';
import 'package:flutter_guard/flutter_guard.dart';

import '../../core/demo_session.dart';
import '../../shared/widgets.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  String _output = 'Sign in, then load /auth/me.';
  final List<String> _flow = <String>[];

  FlutterGuard get guard => FlutterGuardScope.of(context);

  Future<void> _refreshView() async {
    final session = await guard.auth.session();
    setState(() {
      _output = [
        'access ${demoSession.accessToken ?? 'none'}',
        'refresh ${demoSession.refreshToken ?? 'none'}',
        'expired ${demoSession.expired}',
        'authenticated ${session.isAuthenticated}',
        'refreshCount ${guard.auth.refreshCount}',
        ..._flow,
      ].join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Authentication',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBanner(message: _output),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () async {
                  await guard.auth.login(
                    accessToken: 'demo-access-token-1',
                    refreshToken: 'demo-refresh-token',
                  );
                  demoSession.login();
                  _flow
                    ..clear()
                    ..add('Login stored demo tokens');
                  await _refreshView();
                },
                child: const Text('Login'),
              ),
              FilledButton(
                onPressed: () async {
                  demoSession.expired = true;
                  _flow.add('Marked access token expired');
                  await _refreshView();
                },
                child: const Text('Expire token'),
              ),
              FilledButton(
                onPressed: () async {
                  _flow.add('GET /auth/me');
                  try {
                    final response = await guard.network.get<Object>(
                      '/auth/me',
                    );
                    _flow.add('Success ${response.statusCode}');
                  } catch (error) {
                    _flow.add(describeError(error));
                  }
                  await _refreshView();
                },
                child: const Text('Load profile'),
              ),
              FilledButton(
                onPressed: () async {
                  _flow.add('100 parallel /auth/me after expiry');
                  demoSession.expired = true;
                  demoSession.accessToken = 'demo-access-token-1';
                  await Future.wait(
                    List<Future<void>>.generate(8, (_) async {
                      try {
                        await guard.network.get<Object>('/auth/me');
                      } catch (_) {}
                    }),
                  );
                  _flow.add(
                    'Refresh calls: ${demoSession.refreshCount} '
                    '(Guard ${guard.auth.refreshCount})',
                  );
                  await _refreshView();
                },
                child: const Text('Burst after expiry'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await guard.auth.logout();
                  demoSession.logout();
                  _flow.add('Logged out');
                  await _refreshView();
                },
                child: const Text('Logout'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Flow: 401 → one refresh → waiting requests retry with the new '
            'token. Tokens are demo strings only.',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter_guard_sdk/flutter_guard_sdk.dart';
import 'package:flutter_guard_example/app/app.dart';
import 'package:flutter_guard_example/core/demo_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await bootstrapGuard();
  });

  tearDownAll(() async {
    await FlutterGuard.reset();
  });

  testWidgets('dashboard lists features and opens network', (tester) async {
    await tester.pumpWidget(const FlutterGuardExampleApp());
    expect(find.text('FlutterGuard Demo'), findsOneWidget);
    expect(find.text('Production Infrastructure Toolkit'), findsOneWidget);
    await tester.tap(find.text('Network'));
    await tester.pumpAndSettle();
    expect(find.text('GET'), findsOneWidget);
    await tester.tap(find.text('GET'));
    await tester.pumpAndSettle();
    expect(find.textContaining('status 200'), findsOneWidget);
  });

  testWidgets('configuration playground lists options', (tester) async {
    await tester.pumpWidget(const FlutterGuardExampleApp());
    await tester.scrollUntilVisible(find.text('Configuration Playground'), 300);
    await tester.tap(find.text('Configuration Playground'));
    await tester.pumpAndSettle();
    expect(find.text('baseUrl'), findsWidgets);
    await tester.scrollUntilVisible(find.text('maxAttempts'), 400);
    expect(find.text('maxAttempts'), findsWidgets);
  });

  testWidgets('retry screen renders controls', (tester) async {
    await tester.pumpWidget(const FlutterGuardExampleApp());
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Run flaky GET'), findsOneWidget);
    await tester.tap(find.text('Run flaky GET'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Transport calls'), findsOneWidget);
  });

  testWidgets('inspector route can be opened', (tester) async {
    await tester.pumpWidget(const FlutterGuardExampleApp());
    await tester.tap(find.byTooltip('Open inspector'));
    await tester.pumpAndSettle();
    expect(find.text('FlutterGuard Inspector'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);
  });
}

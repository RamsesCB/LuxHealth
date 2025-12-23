import 'package:flutter_test/flutter_test.dart';

import 'package:zenith_health/main.dart';
import 'package:zenith_health/screens/login_screen.dart';

void main() {
  testWidgets('App renders login screen smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    // We pass LoginScreen as the initial screen for testing
    await tester.pumpWidget(const LuxHealthApp(initialScreen: LoginScreen()));

    // Verify that the Login screen is displayed
    expect(find.text('LuxHealth'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}

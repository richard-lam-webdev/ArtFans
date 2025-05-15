import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Basic integration test', (WidgetTester tester) async {
    // Start the app
    app.main();
    await tester.pumpAndSettle();

    // Verify the app loads correctly
    expect(find.text('Welcome'), findsOneWidget);

    // Interact with the app (example: tap a button)
    final Finder button = find.text('Get Started');
    await tester.tap(button);
    await tester.pumpAndSettle();

    // Verify navigation or state change
    expect(find.text('Home'), findsOneWidget);
  });
}

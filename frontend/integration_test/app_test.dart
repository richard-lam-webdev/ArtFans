import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart'
    as app; // <-- remplace "your_app" par le nom de ton package

void main() async {
  // 1️⃣ Initialisation du binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // 2️⃣ Appelle ton application
  app.main();
  await Future<void>.delayed(const Duration(seconds: 1));
  // (optionnel) attendre que runApp() ait bien construit le widget

  // 3️⃣ Écrire tes tests
  testWidgets('Exemple de test d’intégration Web', (WidgetTester tester) async {
    // ATTENTION : si tu appelles app.main() **avant**, tu peux directement faire
    // await tester.pumpAndSettle();
    expect(find.text('Bienvenue'), findsOneWidget);
    // … tes interactions / vérifications
  });
}

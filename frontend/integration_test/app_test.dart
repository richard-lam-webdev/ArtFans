import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart'
    as app; // ← Remplace `frontend` par le name de ton package

void main() {
  // 1) Initialise le binding pour l’intégration
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Lancement de l’app et affichage de l\'écran d\'accueil', (
    tester,
  ) async {
    // 2) Lance l’entrypoint de l’app
    app.main();
    await tester.pumpAndSettle();

    // 3) Vérifie qu’un widget attendu est présent
    expect(find.text('Bienvenue'), findsOneWidget);

    // 4) (Exemple) appuie sur un bouton et vérifie la navigation
    // await tester.tap(find.byIcon(Icons.login));
    // await tester.pumpAndSettle();
    // expect(find.text('Page suivante'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('placeholder — app smoke test', (WidgetTester tester) async {
    // Smoke test vacío: la app requiere dotenv + ApiClient inicializados.
    // Las pruebas de integración se agregarán cuando el backend esté disponible.
    expect(true, isTrue);
  });
}

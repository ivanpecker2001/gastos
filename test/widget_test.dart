import 'package:flutter_test/flutter_test.dart';
import 'package:gastos/main.dart';

void main() {
  testWidgets('Sin configuración muestra el aviso', (tester) async {
    await tester.pumpWidget(const GastosApp());
    expect(find.textContaining('Faltan SUPABASE_URL'), findsOneWidget);
  });
}

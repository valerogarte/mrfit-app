import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/main.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';

// FakeUsuario implementa solo lo necesario para el test.
// El resto de miembros se resuelve con noSuchMethod, útil para mocks en tests.
class FakeUsuario implements Usuario {
  final bool available;
  FakeUsuario(this.available);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Muestra InicioPage cuando HealthConnect está disponible', (WidgetTester tester) async {
    final fakeUsuario = FakeUsuario(true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [usuarioProvider.overrideWithValue(fakeUsuario)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hoy'), findsOneWidget);
  });
}

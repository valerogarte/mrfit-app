import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/main.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/screens/home.dart';
import 'package:mrfit/widgets/home/daily_hc_disable.dart';

// FakeUsuario implementa solo lo necesario para el test.
// El resto de miembros se resuelve con noSuchMethod, útil para mocks en tests.
class FakeUsuario implements Usuario {
  final bool available;
  FakeUsuario(this.available);

  @override
  Future<bool> isHealthConnectAvailable() async => available;

  @override
  Future<void> installHealthConnect() async {}

  // Implementa el resto de miembros usando noSuchMethod para evitar errores de compilación.
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

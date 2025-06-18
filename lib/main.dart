import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/screens/home.dart';
import 'package:mrfit/screens/usuario/usuario_config.dart';
import 'package:mrfit/providers/walking_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Manejo de errores con Firebase Crashlytics
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  final usuario = await Usuario.load();

  runApp(
    ProviderScope(
      overrides: [usuarioProvider.overrideWithValue(usuario)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Siempre muestra InicioPage como pantalla principal.
    return MaterialApp(
      title: 'Mr Fit',
      theme: _buildTheme(),
      home: HomeShell(body: const InicioPage()),
    );
  }

  ThemeData _buildTheme() => ThemeData(
        primaryColor: AppColors.accentColor,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'MadeTommy',
        appBarTheme: AppBarTheme(
          color: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textNormal),
          titleTextStyle: TextStyle(
            color: AppColors.textNormal,
            fontFamily: 'MadeTommy',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.textMedium),
          bodyMedium: TextStyle(color: AppColors.textMedium),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardBackground,
          labelStyle: TextStyle(color: AppColors.textNormal),
          hintStyle: TextStyle(color: AppColors.textMedium),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentColor),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentColor,
            foregroundColor: AppColors.textNormal,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.accentColor,
          selectedItemColor: AppColors.accentColor,
          unselectedItemColor: AppColors.textMedium,
        ),
      );
}

/// Scaffold común con AppBar
class HomeShell extends ConsumerWidget {
  final Widget body;
  const HomeShell({super.key, required this.body});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWalking = ref.watch(walkingProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).appBarTheme.titleTextStyle,
            children: [
              TextSpan(text: 'Mr', style: const TextStyle(color: AppColors.mutedAdvertencia)),
              TextSpan(text: 'Fit', style: const TextStyle(color: AppColors.textNormal)),
            ],
          ),
        ),
        actions: [
          if (isWalking)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.directions_walk, color: AppColors.mutedAdvertencia),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UsuarioConfigPage(),
                  ));
            },
          ),
        ],
      ),
      body: body,
    );
  }
}

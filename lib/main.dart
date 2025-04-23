import 'package:flutter/material.dart';
import 'package:mrfit/screens/home.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/screens/usuario/usuario_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/models/usuario/usuario.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final usuario = await Usuario.load();
  runApp(
    ProviderScope(
      overrides: [
        usuarioProvider.overrideWithValue(usuario),
      ],
      child: const MyApp(),
    ),
  );
}

// Clase principal de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mr Fit',
      theme: ThemeData(
        primaryColor: AppColors.secondaryColor,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'MadeTommy', // Añadido para usar la fuente personalizada
        appBarTheme: AppBarTheme(
          color: AppColors.appBarBackground,
          iconTheme: IconThemeData(color: AppColors.textNormal),
          titleTextStyle: TextStyle(
            color: AppColors.textNormal,
            fontFamily: 'MadeTommy', // Aplica la fuente al título del AppBar
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
            borderSide: BorderSide(color: AppColors.secondaryColor),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentColor),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentColor, // Cambiado de 'primary'
            foregroundColor: AppColors.textNormal, // Cambiado de 'onPrimary'
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.secondaryColor,
          selectedItemColor: AppColors.accentColor,
          unselectedItemColor: AppColors.textMedium,
        ),
      ),
      home: const MyHomePage(), // Cambiado de InicioPage a MyHomePage
    );
  }
}

// Página principal después del inicio de sesión
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsuarioConfigPage()),
              );
            },
          ),
        ],
      ),
      body: const InicioPage(), // Directly load InicioPage
    );
  }
}

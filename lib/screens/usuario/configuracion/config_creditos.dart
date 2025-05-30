import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/utils/constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfiguracionCreditosPage extends StatelessWidget {
  const ConfiguracionCreditosPage({Key? key}) : super(key: key);

  /// Abre el cliente de correo con la dirección predefinida.
  /// Utiliza la API recomendada de url_launcher para mayor compatibilidad.
  Future<void> _enviarCorreo() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'admin@valerogarte.com',
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('No se pudo abrir el cliente de correo.');
    }
  }

  /// Intenta abrir el perfil de LinkedIn en la app nativa.
  /// Si no está disponible, abre el perfil en el navegador.
  Future<void> _abrirLinkedIn() async {
    final Uri linkedInAppUri = Uri.parse('linkedin://in/daniel-valero-gonzalez');
    final Uri linkedInIntentUri = Uri.parse('intent://in/daniel-valero-gonzalez/#Intent;package=com.linkedin.android;scheme=linkedin;end');
    final Uri linkedInWebUri = Uri.parse('https://www.linkedin.com/in/daniel-valero-gonzalez/');

    // Intenta abrir la app de LinkedIn con el esquema nativo
    if (await canLaunchUrl(linkedInAppUri)) {
      if (!await launchUrl(linkedInAppUri, mode: LaunchMode.externalApplication)) {
        debugPrint('No se pudo abrir el perfil en la app de LinkedIn.');
      }
      return;
    }

    // Intenta abrir usando intent:// (especialmente útil en Android)
    if (await canLaunchUrl(linkedInIntentUri)) {
      if (!await launchUrl(linkedInIntentUri, mode: LaunchMode.externalApplication)) {
        debugPrint('No se pudo abrir LinkedIn con intent.');
      }
      return;
    }

    // Si ninguna opción anterior funciona, abre en el navegador
    if (!await launchUrl(linkedInWebUri, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir LinkedIn en el navegador.');
    }
  }

  /// Intenta abrir el perfil de GitHub en la app nativa.
  /// Si no está disponible, abre el perfil en el navegador.
  Future<void> _abrirGitHub() async {
    final Uri githubAppUri = Uri.parse('github://user?username=valerogarte');
    final Uri githubWebUri = Uri.parse('https://github.com/valerogarte');

    // Intenta abrir la app de GitHub primero
    if (await canLaunchUrl(githubAppUri)) {
      if (!await launchUrl(githubAppUri, mode: LaunchMode.externalApplication)) {
        debugPrint('No se pudo abrir el perfil en la app de GitHub.');
      }
    } else {
      // Si la app no está disponible, abre en el navegador
      if (!await launchUrl(githubWebUri, mode: LaunchMode.externalApplication)) {
        debugPrint('No se pudo abrir GitHub en el navegador.');
      }
    }
  }

  /// Abre la página de calificación de la app en Google Play Store.
  Future<void> _calificarApp() async {
    final String url = 'https://play.google.com/store/apps/details?id=${AppConstants.domainNameApp}';
    final Uri playStoreUri = Uri.parse(url);

    // Intenta abrir la URL en el navegador externo
    if (!await launchUrl(playStoreUri, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo abrir la página de calificación en Play Store.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textNormal),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            // Añadido para permitir scroll
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con fondo y avatar
                Stack(
                  clipBehavior: Clip.none, // Ensures the avatar is not clipped
                  children: [
                    Container(
                      height: 100,
                      color: AppColors.cardBackground,
                    ),
                    Positioned(
                      top: 50,
                      left: MediaQuery.of(context).size.width / 2 - 50,
                      child: Material(
                        elevation: 6, // Higher elevation for better z-index
                        shape: CircleBorder(),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/dvg.png'),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 70),
                Center(
                  child: Text(
                    'Daniel Valero González',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mutedAdvertencia,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Center(
                  child: Text(
                    'Desarrollador de MrFit',
                    style: TextStyle(color: AppColors.accentColor),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Soy un apasionado del Open Source, la inteligencia artificial, el arte y por supuesto la vida sana.\n\nPor la tarde riego bonsáis para relajarme y de vez en cuando miro al cielo preguntándome si el universo también tiene bugs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textNormal),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'A LA FELICIDAD DE LA LUZ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedAdvertencia,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón de Email
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.envelope, color: AppColors.accentColor),
                      onPressed: _enviarCorreo, // Llama al método para enviar correo
                    ),
                    // Botón de LinkedIn
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.linkedin, color: AppColors.accentColor),
                      onPressed: _abrirLinkedIn, // Llama al método para abrir LinkedIn
                    ),
                    // Botón de GitHub
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.github, color: AppColors.accentColor),
                      onPressed: _abrirGitHub, // Llama al método para abrir GitHub
                    ),
                  ],
                ),
                Divider(height: 32),
                Container(
                  color: AppColors.background,
                  child: Column(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.cover,
                          height: 65, // Adjust size as needed
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Versión ${AppConstants.version}',
                        style: TextStyle(color: AppColors.textMedium),
                      ),
                    ],
                  ),
                ),
                // SizedBox(height: 10),
                // Padding(
                //   padding: EdgeInsets.symmetric(horizontal: 24),
                //   child: Column(
                //     // Changed from Row to Column
                //     crossAxisAlignment: CrossAxisAlignment.stretch, // Align buttons to stretch
                //     children: [
                //       TextButton.icon(
                //         icon: Icon(Icons.star, color: AppColors.accentColor),
                //         label: Text(
                //           'Calificar 5 estrellas',
                //           style: TextStyle(color: AppColors.accentColor),
                //         ),
                //         onPressed: _calificarApp,
                //       ),
                //       TextButton.icon(
                //         icon: Icon(Icons.lock, color: AppColors.accentColor),
                //         label: Text(
                //           'Política de privacidad',
                //           style: TextStyle(color: AppColors.accentColor),
                //         ),
                //         onPressed: () {},
                //       ),
                //       TextButton.icon(
                //         icon: Icon(Icons.share, color: AppColors.accentColor),
                //         label: Text(
                //           'Compartir',
                //           style: TextStyle(color: AppColors.accentColor),
                //         ),
                //         onPressed: () {},
                //       ),
                //     ],
                //   ),
                // ),
                SizedBox(height: 40),
              ],
            ),
          ),
          // Elimina el Positioned con el IconButton de retroceso, ya que ahora está en el AppBar.
        ],
      ),
    );
  }
}

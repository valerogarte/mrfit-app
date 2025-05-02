import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

class ConfiguracionCreditosPage extends StatelessWidget {
  const ConfiguracionCreditosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      height: 200,
                      color: AppColors.appBarBackground,
                    ),
                    Positioned(
                      top: 130,
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
                    IconButton(
                      icon: Icon(Icons.email, color: AppColors.accentColor),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: AppColors.accentColor), // Instagram
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.business, color: AppColors.accentColor), // LinkedIn
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.code, color: AppColors.accentColor), // GitHub
                      onPressed: () {},
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
                        'Versión 1.0.0',
                        style: TextStyle(color: AppColors.textMedium),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    // Changed from Row to Column
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Align buttons to stretch
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.star, color: AppColors.accentColor),
                        label: Text(
                          'Calificar 5 estrellas',
                          style: TextStyle(color: AppColors.accentColor),
                        ),
                        onPressed: () {},
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.lock, color: AppColors.accentColor),
                        label: Text(
                          'Política de privacidad',
                          style: TextStyle(color: AppColors.accentColor),
                        ),
                        onPressed: () {},
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.share, color: AppColors.accentColor),
                        label: Text(
                          'Compartir',
                          style: TextStyle(color: AppColors.accentColor),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16, // Margen superior
            left: 16, // Margen izquierdo
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textNormal),
              onPressed: () {
                Navigator.of(context).pop(); // Navegar hacia atrás
              },
            ),
          ),
        ],
      ),
    );
  }
}

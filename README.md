# MrFit

MrFit es una aplicación de entrenamiento personalizada que permite gestionar rutinas, seguir el progreso de los ejercicios y utilizar funcionalidades de voz para guiar al usuario. Con Flutter y SQLite como base, ofrece una experiencia multiplataforma sencilla de configurar.

## Tour por la app
![Tour](./img_app/gif/tour.gif)

## Capturas de pantalla

![Collage](./img_app/collage.png)

## Características principales
- Gestión de rutinas diarias de entrenamiento.
- Integración con voz para indicar repeticiones, peso y series a realizar.
- SQLite para guardar y consultar ejercicios.
- Interfaz intuitiva con animaciones y filtros avanzados para encontrar ejercicios.

## Requisitos
- Flutter SDK instalado.
- IDE o editor con soporte para Flutter (VSCode, Android Studio, etc.).

## Instalación
1. Clona este repositorio en tu máquina local.
2. Abre el proyecto en tu IDE.
3. Ejecuta en la terminal:
   ```
   flutter pub get
   ```
4. Ejecuta el siguiente comando para confirmar que tienes todo:
   ```
   flutter doctor
   ```

## Ejecución
1. Conecta un dispositivo o emulador.
2. Compila y ejecuta la app:
   ```
   flutter run
   ```

## Compilación para producción
Para generar un APK release:
```
flutter build apk --release
```

Para más herramientas y configuración avanzada, consulta la documentación oficial de Flutter.

## Arquitectura general
- Carpeta "models" con los modelos de los contenidos.
- Carpeta "utils" con colores y constantes globales.
- Carpeta "screens" para pintar pantallas organizadas por procesos: entrenamiento, ejercicios, etc.
- Componente de text-to-speech con Flutter TTS.
- Patrones de Estado con StatefulWidgets y Singletons simplificados.

## Conectividad Google Fit
- Aún pendiente de ajustar.

## Contribuciones
¡Las contribuciones a MrFit son bienvenidas! Si encuentras algún problema o tienes sugerencias para nuevas funcionalidades, por favor abre un issue o envía un pull request. Asegúrate de seguir el estilo de código y las directrices del proyecto.

## Disclaimer
MrFit no es una aplicación con propósitos médicos. No podemos confirmar que todos los datos hayan sido validados y deberían usarse con precaución.
Por favor, mantén un estilo de vida saludable y consulta a un profesional si tienes algún problema. No se recomienda su uso durante enfermedades, embarazo o lactancia.
La aplicación aún está en construcción. Pueden ocurrir errores, fallos y cierres inesperados.

## Agradecimientos
Se agradece a toda la comunidad de Flutter y a los desarrolladores de paquetes de terceros que hicieron posible crear una experiencia más completa.

## Licencia
Este proyecto está disponible bajo los términos de la licencia que se especifica en el repositorio. Revisa el archivo LICENSE para más detalles.
Imagen modelo basada en: https://www.artstation.com/artwork/rVqBe

## TODO:

Django:
- Altura
- Entrenador activo
- Voz del entrenador
- Aviso 10 segundos
- Aviso cuenta atrás
- Objetivo kcal
- Primer día de la semana
Usuario:
- Montar todo nuevamente
Cache:
- Establecer caché para elementos de la home
Frecuencia cardiaca:
- Funcionalidad
Sueño:
- Debe aparecer después de que el tiempo de inactividad haya sido superior a 2 horas.
Escaleras subidas:
* Funcionalidad
Mejoras:
- Al dejar pulsado el botón de - o + debería subir o bajar mucho
- Revisar entrenamiento "Pierna" el ejercicio de sentadillas
Editar entrenamiento:
- Poder añadir un ejercicio
- Esconder por las esquinas los bloques
Actualización:
- Al hacer scroll down en la home arriba del todo, debe recargar la página al completo
Rings:
- Se deben pintar los datos bien en el calendario
- Pintar bien los números cuando da más de una vuelta
-----
TRAS SUBIR A PLAYSTORE
Alarmas:
* En la página de la sesión, arriba a la derecha poner alarmas a modo recordatorio
Medallas:
* Mayor número de pasos.
Notas Diario:
* Funcionalidad
Maps:
* Funcionalidad
Mejoras:
- Si elimino la última serie del último ejercicio borro el ejercicio
* Iconos nuevos de caritas
Yoga:
- https://github.com/rebeccaestes/yoga_api/blob/master/yoga_api.json
- https://thenounproject.com/icon/yoga-81538/
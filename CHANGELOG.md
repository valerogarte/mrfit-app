# Changelog

---

## [1.0.0] – 2025-05-16

### Added

- **Gestión de rutinas y sesiones**
  - Creación, edición y eliminación de rutinas de entrenamiento.
  - Organización de rutinas en grupos y planes personalizados.
  - Gestión de sesiones dentro de cada rutina, con posibilidad de editar título y dificultad.
  - Reordenar y eliminar sesiones de entrenamiento.

- **Ejercicios**
  - Búsqueda avanzada de ejercicios por nombre, músculo, equipamiento y categoría.
  - Visualización de detalles, historial y estadísticas de cada ejercicio.
  - Añadir ejercicios personalizados a sesiones y entrenamientos.
  - Seguimiento de series realizadas, repeticiones, peso y dificultad (RER).

- **Entrenamientos**
  - Registro de entrenamientos realizados, con inicio y fin, cálculo de calorías y volumen.
  - Visualización de entrenamientos pasados y detalles completos.
  - Integración con temporizador y avisos de voz durante el entrenamiento.
  - Finalización de entrenamientos con resumen visual y animaciones de recompensa.

- **Estadísticas y progreso**
  - Estadísticas de actividad física diaria: pasos, calorías, minutos activos.
  - Gráficas de progreso semanal y mensual.
  - Visualización de récords personales y medallas obtenidas.
  - Seguimiento de recuperación muscular y fatiga por grupo muscular.

- **Salud y medidas**
  - Registro y consulta de peso, altura y metabolismo basal.
  - Visualización de sueño diario y sesiones de descanso.
  - Integración con Google Fit/Health Connect para importar datos de salud (pasos, sueño, peso, etc.).

- **Configuración y personalización**
  - Configuración de datos personales: fecha de nacimiento, género, altura, experiencia, unidades, etc.
  - Ajustes de voz del entrenador, volumen y avisos personalizados.
  - Selección de objetivos diarios y semanales (pasos, calorías, tiempo de entrenamiento).
  - Respaldo y restauración de datos mediante archivos locales y sFTP.
  - Integración (en desarrollo) con Smartwatch.

- **Interfaz de usuario**
  - Interfaz intuitiva y moderna, con animaciones y componentes visuales personalizados.
  - Soporte para temas de color y accesibilidad.
  - Navegación sencilla entre pantallas principales: inicio, rutinas, estadísticas, configuración.

- **Modelos y lógica de datos**
  - **Usuario**: CRUD en SQLite (`load`, `set*`), backup/exportación e importación SFTP, Health Connect, cache local, récords y medallas.
  - **Rutina & Sesión**: serialización JSON, renombrado, archivado, reordenamiento, dificultad, inserción y eliminación de ejercicios.
  - **EjercicioPersonalizado & SeriePersonalizada**: CRUD de series, clonación de plantilla, cálculo de volumen y tiempo por serie, métodos `save`/`delete`.
  - **Entrenamiento & EjercicioRealizado**: registro de inicio/fin, cálculo de calorías (Kcal), MR-points, métricas de recuperación, integración Health Connect, eliminaciones seguras.
  - **ModeloDatos**: búsqueda y filtros avanzados de ejercicios, mapeo de implicación muscular, opciones de dificultad y helpers i18n.
  - **Cache y logs**
    - Registro de errores y actividades con `Logger`.
    - Almacenamiento en caché de datos de usuario y récords con `CustomCache`.
  - **Inactividad y sueño**
    - Integración con `UsageStats` para leer franjas de inactividad y sesiones de sueño.
    - Filtrado y fusión de slots con múltiples tipos de datos de sueño.

### Changed
- Initial version

### Fixed
- Initial version
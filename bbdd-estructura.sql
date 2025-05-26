-- --------------------------------------------------------
-- Host:                         E:\laragon\www\mrfit\back\src\mrfit.db
-- Versión del servidor:         3.39.4
-- SO del servidor:              
-- HeidiSQL Versión:             12.5.0.6677
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES  */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Volcando estructura para tabla mrfit.accounts_historiallesiones
CREATE TABLE IF NOT EXISTS "accounts_historiallesiones" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(255) NOT NULL, "fecha_inicio" date NOT NULL, "fecha_fin" date NOT NULL, "usuario_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "musculo_id" bigint NOT NULL REFERENCES "ejercicios_musculo" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.accounts_medidacorporal
CREATE TABLE IF NOT EXISTS "accounts_medidacorporal" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "fecha" date NOT NULL, "clave" varchar(100) NOT NULL, "valor" real NOT NULL, "unidades" varchar(20) NOT NULL, "usuario_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.accounts_rutina
CREATE TABLE IF NOT EXISTS "accounts_rutina" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.accounts_volumenmaximo
CREATE TABLE IF NOT EXISTS "accounts_volumenmaximo" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "fecha" date NOT NULL, "volumen" integer unsigned NOT NULL CHECK ("volumen" >= 0), "musculo_id" bigint NOT NULL REFERENCES "ejercicios_musculo" ("id") DEFERRABLE INITIALLY DEFERRED, "usuario_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.auth_group
CREATE TABLE IF NOT EXISTS "auth_group" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(150) NOT NULL UNIQUE);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.auth_group_permissions
CREATE TABLE IF NOT EXISTS "auth_group_permissions" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "group_id" integer NOT NULL REFERENCES "auth_group" ("id") DEFERRABLE INITIALLY DEFERRED, "permission_id" integer NOT NULL REFERENCES "auth_permission" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.auth_permission
CREATE TABLE IF NOT EXISTS "auth_permission" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "content_type_id" integer NOT NULL REFERENCES "django_content_type" ("id") DEFERRABLE INITIALLY DEFERRED, "codename" varchar(100) NOT NULL, "name" varchar(255) NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.auth_user
CREATE TABLE IF NOT EXISTS "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "password" varchar(128) NOT NULL, "last_login" datetime NULL, "is_superuser" bool NOT NULL, "username" varchar(150) NOT NULL UNIQUE, "first_name" varchar(150) NOT NULL, "last_name" varchar(150) NOT NULL, "email" varchar(254) NOT NULL, "is_staff" bool NOT NULL, "is_active" bool NOT NULL, "date_joined" datetime NOT NULL, "altura" integer unsigned NULL CHECK ("altura" >= 0), "aviso_10_segundos" bool NOT NULL, "aviso_cuenta_atras" bool NOT NULL, "entrenador_activo" bool NOT NULL, "entrenador_voz" varchar(255) NOT NULL, "experiencia" varchar(12) NOT NULL, "fecha_nacimiento" date NULL, "genero" varchar(10) NULL, "hora_fin_sueno" time NULL, "hora_inicio_sueno" time NULL, "objetivo_entrenamiento_semanal" integer unsigned NOT NULL CHECK ("objetivo_entrenamiento_semanal" >= 0), "objetivo_kcal" integer unsigned NOT NULL CHECK ("objetivo_kcal" >= 0), "objetivo_pasos_diarios" integer unsigned NOT NULL CHECK ("objetivo_pasos_diarios" >= 0), "objetivo_tiempo_entrenamiento" integer unsigned NOT NULL CHECK ("objetivo_tiempo_entrenamiento" >= 0), "primer_dia_semana" integer unsigned NOT NULL CHECK ("primer_dia_semana" >= 0), "rutina_actual_id" bigint NULL REFERENCES "rutinas_rutina" ("id") DEFERRABLE INITIALLY DEFERRED, "unidad_distancia" varchar(10) NOT NULL, "unidad_tamano" varchar(10) NOT NULL, "unidades_peso" varchar(10) NOT NULL, "entrenador_volumen" smallint unsigned NOT NULL CHECK ("entrenador_volumen" >= 0));

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.auth_user_equipo_en_casa
CREATE TABLE IF NOT EXISTS "auth_user_equipo_en_casa" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "equipamiento_id" bigint NOT NULL REFERENCES "ejercicios_equipamiento" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.auth_user_groups
CREATE TABLE IF NOT EXISTS "auth_user_groups" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "group_id" integer NOT NULL REFERENCES "auth_group" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.auth_user_user_permissions
CREATE TABLE IF NOT EXISTS "auth_user_user_permissions" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "permission_id" integer NOT NULL REFERENCES "auth_permission" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.custom_cache_cacheentry
CREATE TABLE IF NOT EXISTS "custom_cache_cacheentry" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "key" varchar(50) NOT NULL UNIQUE, "value" text NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.django_admin_log
CREATE TABLE IF NOT EXISTS "django_admin_log" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "object_id" text NULL, "object_repr" varchar(200) NOT NULL, "action_flag" smallint unsigned NOT NULL CHECK ("action_flag" >= 0), "change_message" text NOT NULL, "content_type_id" integer NULL REFERENCES "django_content_type" ("id") DEFERRABLE INITIALLY DEFERRED, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "action_time" datetime NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.django_content_type
CREATE TABLE IF NOT EXISTS "django_content_type" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "app_label" varchar(100) NOT NULL, "model" varchar(100) NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.django_migrations
CREATE TABLE IF NOT EXISTS "django_migrations" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "app" varchar(255) NOT NULL, "name" varchar(255) NOT NULL, "applied" datetime NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.django_session
CREATE TABLE IF NOT EXISTS "django_session" ("session_key" varchar(40) NOT NULL PRIMARY KEY, "session_data" text NOT NULL, "expire_date" datetime NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.ejercicios_categoria
CREATE TABLE IF NOT EXISTS "ejercicios_categoria" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(100) NOT NULL, "imagen" varchar(100) NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.ejercicios_dificultad
CREATE TABLE IF NOT EXISTS "ejercicios_dificultad" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(100) NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.ejercicios_ejercicio
CREATE TABLE IF NOT EXISTS "ejercicios_ejercicio" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "nombre" varchar(100) NOT NULL, "imagen_uno" varchar(100) NULL, "imagen_dos" varchar(100) NULL, "imagen_movimiento" varchar(100) NULL, "realizar_por_extremidad" bool NOT NULL, "influencia_peso_corporal" real NOT NULL, "riesgo_lesion" varchar(20) NOT NULL, "tiempo_fase_concentrica" real NOT NULL, "tiempo_fase_excentrica" real NOT NULL, "tiempo_fase_isometrica" real NOT NULL, "rm_max_medio" real NOT NULL, "rm_record_mundial" real NOT NULL, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "categoria_id" bigint NULL REFERENCES "ejercicios_categoria" ("id") DEFERRABLE INITIALLY DEFERRED, "dificultad_id" bigint NULL REFERENCES "ejercicios_dificultad" ("id") DEFERRABLE INITIALLY DEFERRED, "equipamiento_id" bigint NULL REFERENCES "ejercicios_equipamiento" ("id") DEFERRABLE INITIALLY DEFERRED, "mecanica_id" bigint NULL REFERENCES "ejercicios_mecanica" ("id") DEFERRABLE INITIALLY DEFERRED, "tipo_fuerza_id" bigint NULL REFERENCES "ejercicios_tipofuerza" ("id") DEFERRABLE INITIALLY DEFERRED, "progresion_peso" real NOT NULL, "copyright" varchar(255) NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.ejercicios_ejerciciomusculo
CREATE TABLE IF NOT EXISTS "ejercicios_ejerciciomusculo" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "tipo" varchar(1) NOT NULL, "porcentaje_implicacion" integer unsigned NOT NULL CHECK ("porcentaje_implicacion" >= 0), "ejercicio_id" bigint NOT NULL REFERENCES "ejercicios_ejercicio" ("id") DEFERRABLE INITIALLY DEFERRED, "musculo_id" bigint NOT NULL REFERENCES "ejercicios_musculo" ("id") DEFERRABLE INITIALLY DEFERRED, "descripcion_implicacion" text NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.ejercicios_equipamiento
CREATE TABLE IF NOT EXISTS "ejercicios_equipamiento" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(100) NOT NULL, "imagen" varchar(100) NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.ejercicios_errorcomun
CREATE TABLE IF NOT EXISTS "ejercicios_errorcomun" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "texto" text NOT NULL, "ejercicio_id" bigint NOT NULL REFERENCES "ejercicios_ejercicio" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.ejercicios_instruccion
CREATE TABLE IF NOT EXISTS "ejercicios_instruccion" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "texto" text NOT NULL, "ejercicio_id" bigint NOT NULL REFERENCES "ejercicios_ejercicio" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.ejercicios_mecanica
CREATE TABLE IF NOT EXISTS "ejercicios_mecanica" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(100) NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.ejercicios_musculo
CREATE TABLE IF NOT EXISTS "ejercicios_musculo" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(100) NOT NULL, "imagen" varchar(100) NULL, "imagen_frontal" varchar(100) NULL, "imagen_trasera" varchar(100) NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.ejercicios_tipofuerza
CREATE TABLE IF NOT EXISTS "ejercicios_tipofuerza" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(100) NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.ejercicios_tituloadicional
CREATE TABLE IF NOT EXISTS "ejercicios_tituloadicional" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(100) NOT NULL, "ejercicio_id" bigint NOT NULL REFERENCES "ejercicios_ejercicio" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.entrenamiento_ejerciciorealizado
CREATE TABLE IF NOT EXISTS "entrenamiento_ejerciciorealizado" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "ejercicio_id" bigint NULL REFERENCES "ejercicios_ejercicio" ("id") DEFERRABLE INITIALLY DEFERRED, "entrenamiento_id" bigint NULL REFERENCES "entrenamiento_entrenamiento" ("id") DEFERRABLE INITIALLY DEFERRED, "peso_orden" integer NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.entrenamiento_entrenamiento
CREATE TABLE IF NOT EXISTS "entrenamiento_entrenamiento" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "inicio" datetime NOT NULL, "fin" datetime NULL, "peso_usuario" real NULL, "sensacion" integer NULL, "sesion_id" bigint NULL REFERENCES "rutinas_sesion" ("id") DEFERRABLE INITIALLY DEFERRED, "usuario_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "kcal_consumidas" real NULL, "id_health_connect" varchar(255) NULL, "titulo" varchar(255) NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.entrenamiento_serierealizada
CREATE TABLE IF NOT EXISTS "entrenamiento_serierealizada" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "repeticiones" integer NOT NULL, "peso" real NOT NULL, "velocidad_repeticion" real NOT NULL, "descanso" integer NOT NULL, "rer" integer NOT NULL, "repeticiones_objetivo" integer NULL, "peso_objetivo" real NULL, "inicio" datetime NOT NULL, "fin" datetime NULL, "realizada" bool NOT NULL, "deleted" bool NOT NULL, "extra" bool NOT NULL, "ejercicio_realizado_id" bigint NULL REFERENCES "entrenamiento_ejerciciorealizado" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.nutricion_diferenciacalorica
CREATE TABLE IF NOT EXISTS "nutricion_diferenciacalorica" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "fecha" date NOT NULL, "kcal" real NOT NULL, "usuario_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.rutinas_ejerciciopersonalizado
CREATE TABLE IF NOT EXISTS "rutinas_ejerciciopersonalizado" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "peso_orden" real NOT NULL, "ejercicio_id" bigint NULL REFERENCES "ejercicios_ejercicio" ("id") DEFERRABLE INITIALLY DEFERRED, "sesion_id" bigint NULL REFERENCES "rutinas_sesion" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.rutinas_grupo
CREATE TABLE IF NOT EXISTS "rutinas_grupo" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(255) NOT NULL, "peso" integer NOT NULL, "descripcion" text NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.rutinas_rutina
CREATE TABLE IF NOT EXISTS "rutinas_rutina" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(200) NOT NULL, "descripcion" text NULL, "imagen" varchar(100) NULL, "fecha_creacion" datetime NOT NULL, "usuario_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "grupo_id" bigint NULL REFERENCES "rutinas_grupo" ("id") DEFERRABLE INITIALLY DEFERRED, "peso" integer NOT NULL, "dificultad" integer NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.rutinas_rutina_usuarios_con_rutina_actual
CREATE TABLE IF NOT EXISTS "rutinas_rutina_usuarios_con_rutina_actual" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "rutina_id" bigint NOT NULL REFERENCES "rutinas_rutina" ("id") DEFERRABLE INITIALLY DEFERRED, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.rutinas_seriepersonalizada
CREATE TABLE IF NOT EXISTS "rutinas_seriepersonalizada" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "repeticiones" integer NOT NULL, "peso" real NOT NULL, "velocidad_repeticion" real NOT NULL, "descanso" integer NOT NULL, "rer" integer NOT NULL, "ejercicio_personalizado_id" bigint NULL REFERENCES "rutinas_ejerciciopersonalizado" ("id") DEFERRABLE INITIALLY DEFERRED);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.rutinas_sesion
CREATE TABLE IF NOT EXISTS "rutinas_sesion" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(200) NOT NULL, "orden" integer NOT NULL, "rutina_id" bigint NULL REFERENCES "rutinas_rutina" ("id") DEFERRABLE INITIALLY DEFERRED, "dificultad" integer NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.unidades_unidaddistancia
CREATE TABLE IF NOT EXISTS "unidades_unidaddistancia" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(50) NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.unidades_unidadpeso
CREATE TABLE IF NOT EXISTS "unidades_unidadpeso" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(50) NOT NULL);

-- La exportación de datos fue deseleccionada.

-- Volcando estructura para tabla mrfit.unidades_unidadtamano
CREATE TABLE IF NOT EXISTS "unidades_unidadtamano" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "titulo" varchar(50) NOT NULL);

-- La exportación de datos fue deseleccionada.

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;

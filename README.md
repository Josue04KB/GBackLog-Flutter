# GameBacklog

Aplicación Android desarrollada con Flutter para que una persona gestione su
colección de videojuegos y registre sus sesiones de juego desde la nube.

## Problema y usuarios

La aplicación ayuda a jugadores que quieren saber qué videojuegos tienen,
en qué plataforma los juegan, cuál es su estado y cuánto tiempo han dedicado
a cada título. El flujo principal es: crear o iniciar sesión, consultar el
catálogo personal, agregar un videojuego y registrar una sesión de juego.

## Pantallas principales

- Registro con usuario, correo y contraseña; inicio de sesión con correo y contraseña.
- Catálogo personal y exploración del catálogo global.
- Configuración y consulta de plataformas maestras.
- Registro y consulta de sesiones de juego; pulsación prolongada para editar o eliminar.
- Perfil de usuario, cambio de contraseña y cierre de sesión.

La barra inferior conecta **Backlog** (biblioteca personal), **Explorar**
(catálogo para agregar juegos) y **Configuración**. La lupa de Mi Colección
busca por nombre entre los juegos de la biblioteca y se combina con el filtro
de estado. La búsqueda y los filtros se conservan al cambiar de pestaña.

## Modelo de datos

La aplicación usa dos entidades maestras y una entidad transaccional:

| Entidad | Propósito | Relación |
| --- | --- | --- |
| `videojuegos` | Juegos que forman parte de la colección del usuario. | Un videojuego puede tener muchas sesiones. |
| `plataformas` | Consolas, PC u otros medios donde se juega. | Una plataforma puede tener muchas sesiones. |
| `sesiones_juego` | Registro de minutos y notas de una partida. | Guarda `videojuego_id` y `plataforma_id`. |

También se consulta `catalogo_global` para mostrar títulos disponibles antes
de agregarlos a la colección personal.

## Servicio remoto y seguridad

Supabase proporciona autenticación, base de datos y almacenamiento de
imágenes. El inicio de sesión, registro y cierre de sesión usan el SDK oficial
de Supabase. La aplicación no guarda datos de negocio para funcionar sin
conexión.

Antes de una demostración se debe comprobar que las políticas RLS de Supabase
permitan a cada usuario acceder únicamente a los registros que le corresponden.
No se deben subir contraseñas, claves de servicio ni cuentas de demostración al
repositorio.

Para habilitar la edición y eliminación de sesiones, consulta la
[guía de permisos de Supabase](supabase/README.md) y el SQL incluido allí.

El registro envía el nombre de usuario al trigger de perfiles ya configurado;
consulta [registro con usuario](supabase/registration.md) para verificarlo.

## Arquitectura y herramientas

El proyecto se organiza en capas de presentación, dominio y datos:

- Presentación: pantallas Flutter, `ChangeNotifier` y `provider`.
- Dominio: modelos, contrato `GameRepository` y el caso de uso
  `RegistrarSesionUseCase`.
- Datos: implementación del repositorio y servicio remoto de Supabase.
- Navegación: `go_router` protege las rutas que requieren una sesión válida.

Herramientas principales: Flutter, Dart, Supabase, `provider`, `go_router`,
`intl` e `image_picker`.

## Ejecutar el proyecto

1. Instalar Flutter y un emulador o dispositivo Android.
2. Ejecutar `flutter pub get` desde la raíz del proyecto.
3. Revisar la configuración de Supabase en
   `lib/core/config/supabase_config.dart` para usar el proyecto remoto de la
   demostración.
4. Ejecutar `flutter run`.

Para generar un APK de depuración:

```bash
flutter build apk --debug
```

Para ejecutar las pruebas automatizadas sin depender de una API activa:

```bash
flutter test
```

## Lista de comprobación para la demostración

1. Crear una cuenta o iniciar sesión con una cuenta de demostración.
2. Consultar videojuegos y plataformas.
3. Agregar un videojuego a la colección.
4. Registrar una sesión y comprobar que aparece al volver a consultarla.
5. Mostrar una validación de formulario o un error de red y su reintento.
6. Cerrar sesión y comprobar que no se puede volver a una ruta protegida.

## Entrega

Antes de entregar, completar el documento de la segunda etapa con el tema,
usuarios, pantallas, entidades, relaciones, operaciones, servicio remoto,
arquitectura, herramientas y evidencias. Agregar allí la URL del repositorio
del equipo y no inventar enlaces ni credenciales.

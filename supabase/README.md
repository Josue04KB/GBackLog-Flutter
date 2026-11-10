# Permisos para editar y eliminar sesiones

La app permite mantener presionada una tarjeta y elegir **Editar** o **Eliminar**.
La edición conserva el juego, la plataforma y la fecha original; cambia minutos y
notas. La plataforma se elige en Editar juego, debajo del estado, y se aplica a
las nuevas sesiones sin alterar el historial. El borrado requiere confirmación.
La pantalla actualiza sus totales solo
cuando Supabase confirma que modificó la fila.

No se necesitan tablas, columnas, funciones RPC ni activar Realtime. Se utiliza
la tabla existente `public.sesiones_juego`. Las capturas del usuario confirman
que ambas tablas tienen `user_id` y RLS activo. En sesiones ya existen SELECT
e INSERT propios, pero faltan UPDATE y DELETE. No se ha ejecutado SQL contra
el proyecto remoto desde este repositorio.

## Qué comprobar en Supabase

1. Abre el SQL Editor de tu proyecto y ejecuta esta consulta de solo lectura:

```sql
select tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('sesiones_juego', 'videojuegos')
order by tablename, policyname;

select relname, relrowsecurity
from pg_class
where oid in ('public.sesiones_juego'::regclass, 'public.videojuegos'::regclass);

select
  has_table_privilege('authenticated', 'public.sesiones_juego', 'SELECT') as puede_leer,
  has_table_privilege('authenticated', 'public.sesiones_juego', 'UPDATE') as puede_editar,
  has_table_privilege('authenticated', 'public.sesiones_juego', 'DELETE') as puede_eliminar;
```

2. Si RLS está activo y ya existen permisos de `SELECT`, `UPDATE` y `DELETE`
   (o una política `ALL`) para las sesiones de juegos del usuario conectado,
   no necesitas agregar otras políticas. Para `UPDATE`, la condición de
   `WITH CHECK` también debe permitir el registro actualizado.
3. Para la configuración mostrada, abre
   [session_permissions.sql](session_permissions.sql), copia todo su contenido
   actualizado y ejecútalo en una consulta nueva del SQL Editor con **Run**.
   El script agrega UPDATE y DELETE con `sesiones_juego.user_id = auth.uid()`,
   igual que las políticas originales. Conserva SELECT e INSERT y limpia las
   políticas con prefijo `gb_sessions_` de la versión anterior del archivo,
   si se llegaron a aplicar. Puede ejecutarse otra vez.
   También corrige la política existente `Permitir actualizar videojuegos`,
   que en la captura tiene condiciones `true`, para exigir
   `videojuegos.user_id = auth.uid()` antes y después de actualizar.
4. La cuenta debe poder consultar sus juegos en `videojuegos` y las plataformas
   disponibles, como ya requiere el registro de sesiones. Conserva esos permisos.

Las políticas permisivas existentes se combinan con OR: por eso el script
modifica la política permisiva de videojuegos en lugar de añadir otra junto
a ella. No desactives RLS para resolver un permiso faltante. El script no
elimina registros. Si aparece un error, la transacción debe revertirse completa;
no ejecutes solo una parte. El nombre de la política de videojuegos debe
coincidir con el mostrado en la captura.

## Comprobación después de configurarlo

Ejecuta de nuevo la primera consulta por separado. Deben aparecer cuatro
políticas de sesiones: SELECT, INSERT, UPDATE y DELETE. La política UPDATE de
videojuegos debe mostrar la comprobación de `user_id` en ambas condiciones,
en lugar de `true`.

Desde la app, crea una sesión de prueba, edítala y vuelve a abrir la pantalla
para verificar que persistió. Elimínala y comprueba el contador y el tiempo
total. Con otra cuenta, comprueba que no puedes ver ni modificar sesiones
ajenas. Si el servidor no permite el cambio o ya no existe la fila, la app
muestra un error y conserva los datos visibles para evitar un falso éxito.

Las pruebas locales cubren el cliente y usan datos simulados; no certifican las
políticas instaladas en el proyecto remoto.

Conserva el archivo SQL como respaldo. Flutter no lo ejecuta al iniciar la app
ni al compilar el APK; se aplica manualmente en el SQL Editor.

Referencias oficiales:
- [Políticas RLS, UPDATE y SELECT](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [DELETE con RLS en Flutter](https://supabase.com/docs/reference/dart/delete)

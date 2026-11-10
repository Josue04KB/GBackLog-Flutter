# Edición de plataformas

1. Abre **Supabase → SQL Editor → New query**.
2. Copia **todo** el contenido de [platform_edit.sql](platform_edit.sql).
3. Pulsa **Run**. El resultado esperado es `Success. No rows returned`.
4. Abre la app actualizada, ve a Configuración y pulsa el lápiz a la izquierda de una plataforma creada por tu cuenta.
5. Modifica nombre, fabricante o formato y pulsa **Guardar cambios**. Comprueba también un juego asociado y registra una sesión.

El archivo se conserva en el proyecto, pero Flutter **no lo ejecuta automáticamente**.
No hemos aplicado cambios al proyecto Supabase remoto desde aquí.

## Qué instala

Una función `editar_plataforma` y permisos SELECT/UPDATE para filas propias.
El nombre de la plataforma también se actualiza en los juegos de la misma cuenta,
porque `videojuegos.plataforma` almacena texto. El guardado es una sola transacción:
un error revierte ambos cambios. Las sesiones conservan su `plataforma_id`,
fecha y minutos.

La función utiliza `security invoker`, respeta RLS y verifica `auth.uid()`.
No necesita tablas nuevas, columnas nuevas, Realtime ni claves de servicio.
Las plataformas compartidas (`user_id is null`) y las de otra cuenta no se pueden
editar desde esta función. No asignes todas las plataformas compartidas a una
cuenta para evitar permisos: si necesitas personalizar una, crea una propia.

Los permisos existentes de INSERT y DELETE se conservan. Las políticas permisivas
se suman: este archivo no elimina ni corrige otras políticas amplias que pudieran
existir. La función comprueba el propietario incluso si hubiera políticas amplias.

## Si falla

- **Edición todavía no disponible:** comprueba que ejecutaste el archivo completo
  en el mismo proyecto usado por la app.
- **No tienes permiso:** comprueba que la plataforma pertenece a la cuenta actual
  y que no hay políticas restrictivas adicionales.
- **Ya existe un registro:** usa otro nombre. Si dos plataformas disponibles ya
  tienen el mismo nombre, resuelve esa ambigüedad antes de renombrar, porque los
  juegos solo guardan el nombre.
- **Sin conexión:** los datos del formulario permanecen escritos para reintentar.

Para revisar políticas (solo lectura):

```sql
select tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename in ('plataformas', 'videojuegos')
order by tablename, policyname;
```

Las pruebas de Flutter usan un servidor simulado; no verifican las políticas
reales de tu proyecto. Prueba además con una segunda cuenta: no debe poder
editar plataformas ajenas.

Referencias: [funciones de base de datos](https://supabase.com/docs/guides/database/functions)
y [políticas RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).

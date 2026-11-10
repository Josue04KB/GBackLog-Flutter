# Registro con nombre de usuario

La app solicita Usuario, correo y contraseña. El usuario se valida con 3–30
caracteres (letras A–Z/a–z, números, puntos y guiones bajos), quitando espacios
al principio y al final. Se conserva la contraseña tal como fue escrita.

El registro llama a `auth.signUp` con `data: {'username': username}`. Esto
coincide con el trigger que el usuario ya instaló: `handle_new_user()` lee
`new.raw_user_meta_data->>'username'` y crea `public.profiles`. No hace falta
crear otra tabla ni insertar el perfil desde Flutter, incluso si aún no hay
sesión porque está activada la confirmación de correo.

Si Supabase devuelve una sesión, la app abre la biblioteca. Si requiere
confirmación, muestra el aviso y abre el inicio de sesión. El acceso sigue
usando correo y contraseña. En Perfil y Configuración se muestra el username
de Auth; para cuentas antiguas sin ese metadata se usa la parte del correo
anterior a `@`, igual que el respaldo del SQL proporcionado. No se ofrece
edición de username en este cambio ni sincronización de cambios manuales
realizados solamente en la tabla profiles.

La restricción UNIQUE de `profiles.username` verifica los duplicados en el
servidor. Si un conflicto u otro fallo del trigger provoca `Database error
saving new user`, el formulario conserva los campos y sugiere probar otro
usuario. Ese mensaje de Supabase por sí solo no demuestra que sea un duplicado;
si persiste, revisar los logs de Auth y Postgres. No se consulta la lista de
usuarios ni se habilita lectura anónima para comprobar disponibilidad.

El SQL proporcionado incluye SELECT con `using (true)` para `authenticated`:
permite leer todos los perfiles, incluida su columna email. Si los perfiles
deben ser privados, esa política debe limitarse a `auth.uid() = id` en lugar
de `true`. La app no necesita leer perfiles de otras cuentas para registrarse.
No se ha modificado la base de datos remota ni sus políticas desde aquí.

Para verificarlo en el proyecto real, registra una cuenta de prueba con un
usuario nuevo, confirma el correo si se solicita y comprueba en profiles que
el id coincide con Auth y que username contiene el valor elegido. Las pruebas
automatizadas usan un servidor HTTP simulado y no ejecutan el trigger remoto.

Referencias:
- [Registro y metadata en Flutter](https://supabase.com/docs/reference/dart/auth-signup)
- [Perfiles y triggers de Auth](https://supabase.com/docs/guides/auth/managing-user-data)

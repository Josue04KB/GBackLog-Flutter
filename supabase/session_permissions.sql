-- Ejecutar manualmente en el SQL Editor del proyecto.
-- Ajustado a las políticas mostradas por el usuario:
-- ambas tablas tienen user_id, RLS activo y permisos para authenticated.
-- sesiones_juego ya tiene SELECT e INSERT propios; faltan UPDATE y DELETE.
begin;

-- Limpia únicamente las políticas de la versión anterior de este archivo,
-- si se llegaron a aplicar. Conserva las políticas originales del proyecto.
drop policy if exists gb_sessions_select_own_game on public.sesiones_juego;
drop policy if exists gb_sessions_insert_own_game on public.sesiones_juego;
drop policy if exists gb_sessions_update_own_game on public.sesiones_juego;
drop policy if exists gb_sessions_delete_own_game on public.sesiones_juego;

create policy gb_sessions_update_own_game
on public.sesiones_juego for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy gb_sessions_delete_own_game
on public.sesiones_juego for delete to authenticated
using ((select auth.uid()) = user_id);

-- La captura muestra esta política con USING (true) y WITH CHECK (true).
-- Restringe la actualización a los videojuegos del usuario conectado.
alter policy "Permitir actualizar videojuegos"
on public.videojuegos
to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

commit;

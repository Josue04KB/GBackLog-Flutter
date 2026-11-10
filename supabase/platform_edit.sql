-- Ejecutar UNA VEZ en Supabase > SQL Editor > New query > Run.
-- Este archivo no se ejecuta automáticamente desde Flutter.
-- Modelo existente: plataformas.user_id, videojuegos.user_id y videojuegos.plataforma (texto).
begin;

alter table public.plataformas enable row level security;
grant select, update on public.plataformas to authenticated;
grant select, update on public.videojuegos to authenticated;

-- Se conservan las demás políticas; estas solo permiten filas propias.
drop policy if exists gb_platforms_select_available on public.plataformas;
create policy gb_platforms_select_available
  on public.plataformas for select to authenticated
  using (user_id = (select auth.uid()) or user_id is null);

drop policy if exists gb_platforms_update_own on public.plataformas;
create policy gb_platforms_update_own
  on public.plataformas for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists gb_games_select_own_for_platform on public.videojuegos;
create policy gb_games_select_own_for_platform
  on public.videojuegos for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists gb_games_update_own_for_platform on public.videojuegos;
create policy gb_games_update_own_for_platform
  on public.videojuegos for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- SECURITY INVOKER: conserva los permisos y RLS de la persona conectada.
-- Ambas actualizaciones pertenecen a la misma transacción: si falla una,
-- se revierte todo. No cambia los IDs ni borra sesiones.
create or replace function public.editar_plataforma(
  p_id bigint,
  p_nombre text,
  p_fabricante text,
  p_formato text
) returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_original public.plataformas%rowtype;
  v_updated public.plataformas%rowtype;
begin
  if v_user is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  p_nombre := btrim(p_nombre);
  p_fabricante := btrim(p_fabricante);
  p_formato := btrim(p_formato);
  if p_nombre is null or char_length(p_nombre) not between 2 and 80
     or p_fabricante is null or char_length(p_fabricante) not between 2 and 80
     or p_formato is null or char_length(p_formato) not between 2 and 80 then
    raise exception 'Invalid platform fields' using errcode = '23514';
  end if;

  select * into v_original from public.plataformas
  where id = p_id and user_id = v_user for update;
  if not found then
    raise exception 'Platform not found or not owned' using errcode = '42501';
  end if;

  if p_nombre is distinct from v_original.nombre then
    -- Los juegos identifican la plataforma por nombre: evita renombres ambiguos.
    if exists (
      select 1 from public.plataformas p
      where p.id <> p_id and (p.user_id = v_user or p.user_id is null)
        and lower(btrim(p.nombre)) in (lower(p_nombre), lower(btrim(v_original.nombre)))
    ) then
      raise exception 'Ambiguous platform name' using errcode = '23505';
    end if;
  end if;

  update public.plataformas
    set nombre = p_nombre, fabricante = p_fabricante, formato_default = p_formato
    where id = p_id and user_id = v_user
    returning * into v_updated;
  if not found then
    raise exception 'Platform update denied' using errcode = '42501';
  end if;

  if p_nombre is distinct from v_original.nombre then
    update public.videojuegos set plataforma = p_nombre
      where user_id = v_user
        and lower(btrim(plataforma)) = lower(btrim(v_original.nombre));
    -- Si alguna política restrictiva impide actualizar un juego visible,
    -- revierte también el cambio de plataforma.
    if exists (
      select 1 from public.videojuegos
      where user_id = v_user and lower(btrim(plataforma)) = lower(btrim(v_original.nombre))
        and plataforma is distinct from p_nombre
    ) then
      raise exception 'Game update denied' using errcode = '42501';
    end if;
  end if;
  return to_jsonb(v_updated);
end;
$$;

revoke all on function public.editar_plataforma(bigint, text, text, text) from public, anon;
grant execute on function public.editar_plataforma(bigint, text, text, text) to authenticated;
notify pgrst, 'reload schema';
commit;

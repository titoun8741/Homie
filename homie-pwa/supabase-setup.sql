-- =========================================================
-- Homie : à coller dans Supabase → SQL Editor → New query → Run
-- =========================================================

-- 1. Tables
create table if not exists public.couples (
  id          uuid primary key default gen_random_uuid(),
  code        text unique not null,
  data        jsonb not null default '{}'::jsonb,
  updated_by  text,
  updated_at  timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

create table if not exists public.members (
  couple_id   uuid not null references public.couples(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  role        text not null check (role in ('a','b')),
  created_at  timestamptz not null default now(),
  primary key (couple_id, user_id),
  unique (user_id),
  unique (couple_id, role)
);

-- 2. Sécurité : chacun ne voit que son propre espace
alter table public.couples enable row level security;
alter table public.members enable row level security;

create or replace function public.my_couple_id()
returns uuid language sql stable security definer set search_path = public as $$
  select couple_id from public.members where user_id = auth.uid() limit 1
$$;

drop policy if exists "lire mon couple" on public.couples;
create policy "lire mon couple" on public.couples
  for select to authenticated using (id = public.my_couple_id());

drop policy if exists "modifier mon couple" on public.couples;
create policy "modifier mon couple" on public.couples
  for update to authenticated using (id = public.my_couple_id()) with check (id = public.my_couple_id());

drop policy if exists "voir les membres de mon couple" on public.members;
create policy "voir les membres de mon couple" on public.members
  for select to authenticated using (couple_id = public.my_couple_id());

-- 3. Créer un espace (la personne devient « a ») et renvoyer le code d'invitation
create or replace function public.create_couple(p_data jsonb)
returns json language plpgsql security definer set search_path = public as $$
declare v_code text; v_id uuid;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from members where user_id = auth.uid()) then raise exception 'deja dans un couple'; end if;
  loop
    v_code := 'HOMIE-' || upper(substr(md5(random()::text || clock_timestamp()::text), 1, 6));
    exit when not exists (select 1 from couples where code = v_code);
  end loop;
  insert into couples (code, data) values (v_code, coalesce(p_data, '{}'::jsonb)) returning id into v_id;
  insert into members (couple_id, user_id, role) values (v_id, auth.uid(), 'a');
  return json_build_object('id', v_id, 'code', v_code, 'role', 'a');
end $$;

-- 4. Rejoindre un espace avec le code (la personne devient « b »)
create or replace function public.join_couple(p_code text)
returns json language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_code text;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if exists (select 1 from members where user_id = auth.uid()) then raise exception 'deja dans un couple'; end if;
  select id, code into v_id, v_code from couples where code = upper(trim(p_code));
  if v_id is null then raise exception 'code invalide'; end if;
  if (select count(*) from members where couple_id = v_id) >= 2 then raise exception 'complet'; end if;
  insert into members (couple_id, user_id, role) values (v_id, auth.uid(), 'b');
  update couples set data = jsonb_set(data, '{joined}', 'true'::jsonb), updated_by = 'server', updated_at = now() where id = v_id;
  return json_build_object('id', v_id, 'code', v_code, 'role', 'b');
end $$;

revoke all on function public.create_couple(jsonb) from public, anon;
revoke all on function public.join_couple(text) from public, anon;
grant execute on function public.create_couple(jsonb) to authenticated;
grant execute on function public.join_couple(text) to authenticated;

-- 5. Temps réel : les changements de l'un apparaissent chez l'autre
do $$ begin
  alter publication supabase_realtime add table public.couples;
exception when duplicate_object then null; end $$;

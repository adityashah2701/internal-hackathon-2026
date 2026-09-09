-- Migration: 20260909000001_create_profiles_and_rbac.sql
-- Description: Create user_role enum, profiles table, triggers, and Row Level Security policies

-- 1. Create Role Enum
create type public.user_role as enum (
  'customer',
  'worker',
  'cooperative_admin',
  'federation_admin'
);

-- 2. Create Profiles Table
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null default '',
  phone_number text not null default '',
  role public.user_role not null default 'customer',
  is_onboarded boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3. Create Indexes for High Performance RLS and Filtering
create index profiles_role_idx on public.profiles (role);
create index profiles_is_onboarded_idx on public.profiles (is_onboarded);

-- 4. Enable and Force Row Level Security (RLS)
alter table public.profiles enable row level security;
alter table public.profiles force row level security;

-- 5. RLS Policies
-- Users can view their own profile (cached auth.uid() lookup)
create policy profiles_select_own on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

-- Users can insert their own profile with customer or worker role only
create policy profiles_insert_own on public.profiles
  for insert
  to authenticated
  with check (
    (select auth.uid()) = id 
    and role in ('customer'::public.user_role, 'worker'::public.user_role)
  );

-- Users can update their own profile fields
create policy profiles_update_own on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- 6. Trigger: Prevent Self-Escalation of Roles on Profile Update
create or replace function public.check_profile_role_update()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  if new.role is distinct from old.role then
    -- Allow administrative updates from SQL Editor (postgres superuser), service_role, or direct scripts
    if current_user in ('postgres', 'supabase_admin') or auth.role() in ('service_role', 'supabase_admin') or auth.uid() is null then
      new.updated_at := now();
      return new;
    end if;

    -- During initial onboarding (is_onboarded = false), users can self-select customer or worker
    if old.is_onboarded = false and new.role in ('customer'::public.user_role, 'worker'::public.user_role) then
      new.updated_at := now();
      return new;
    end if;

    -- Forbid all other client-side role modifications and self-escalations
    raise exception 'Unauthorized: Users cannot modify their assigned role.'
      using errcode = '42501';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists tr_check_profile_role_update on public.profiles;
drop trigger if exists on_profile_role_update on public.profiles;

create trigger tr_check_profile_role_update
  before update on public.profiles
  for each row execute procedure public.check_profile_role_update();

-- 7. Trigger: Auto-create Profile on Auth Signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name, role, is_onboarded)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    case 
      when new.raw_user_meta_data->>'role' = 'worker' then 'worker'::public.user_role
      else 'customer'::public.user_role
    end,
    false
  )
  on conflict (id) do update set
    email = excluded.email,
    updated_at = now();
  return new;
end;
$$;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

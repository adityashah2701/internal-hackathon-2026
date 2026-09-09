-- Migration: 20260909000002_worker_verification_and_cooperatives.sql
-- Description: Create cooperatives, worker_profiles, worker_documents tables, storage bucket, and RLS policies.

-- 1. Helper function to check if current user is an admin or officer
create or replace function public.is_admin_or_officer()
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid())
      and role in ('cooperative_admin', 'federation_admin')
  );
$$;

-- 2. Create Cooperatives Table
create table if not exists public.cooperatives (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null unique,
  district text not null,
  state text not null,
  registration_number text,
  contact_email text,
  contact_phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists cooperatives_state_district_idx on public.cooperatives (state, district);

alter table public.cooperatives enable row level security;
alter table public.cooperatives force row level security;

-- Drop and recreate cooperatives policies
drop policy if exists cooperatives_select_all on public.cooperatives;
drop policy if exists cooperatives_admin_modify on public.cooperatives;

create policy cooperatives_select_all on public.cooperatives
  for select
  to authenticated
  using (true);

create policy cooperatives_admin_modify on public.cooperatives
  for all
  to authenticated
  using ((select public.is_admin_or_officer()))
  with check ((select public.is_admin_or_officer()));

-- 3. Create Worker Profiles Table
create table if not exists public.worker_profiles (
  id uuid primary key references public.profiles(id) on delete cascade,
  cooperative_id uuid references public.cooperatives(id) on delete set null,
  skills text[] not null default '{}',
  experience_years int not null default 0 check (experience_years >= 0 and experience_years <= 60),
  daily_rate_inr int not null default 500 check (daily_rate_inr >= 0),
  service_area text not null default '',
  bio text not null default '',
  verification_status text not null default 'unsubmitted'
    check (verification_status in ('unsubmitted', 'pending', 'approved', 'rejected')),
  rejection_reason text,
  verified_at timestamptz,
  verified_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists worker_profiles_coop_idx on public.worker_profiles (cooperative_id);
create index if not exists worker_profiles_status_idx on public.worker_profiles (verification_status);

alter table public.worker_profiles enable row level security;
alter table public.worker_profiles force row level security;

-- Drop and recreate worker_profiles policies
drop policy if exists worker_profiles_select on public.worker_profiles;
drop policy if exists worker_profiles_insert_own on public.worker_profiles;
drop policy if exists worker_profiles_update_own on public.worker_profiles;
drop policy if exists worker_profiles_update_admin on public.worker_profiles;

create policy worker_profiles_select on public.worker_profiles
  for select
  to authenticated
  using (
    (select auth.uid()) = id
    or (select public.is_admin_or_officer())
    or verification_status = 'approved'
  );

create policy worker_profiles_insert_own on public.worker_profiles
  for insert
  to authenticated
  with check (
    (select auth.uid()) = id
  );

create policy worker_profiles_update_own on public.worker_profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check (
    (select auth.uid()) = id
    and verification_status in ('unsubmitted', 'pending')
  );

create policy worker_profiles_update_admin on public.worker_profiles
  for update
  to authenticated
  using ((select public.is_admin_or_officer()))
  with check ((select public.is_admin_or_officer()));

-- 4. Create Worker Documents Table
create table if not exists public.worker_documents (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.profiles(id) on delete cascade,
  document_type text not null check (document_type in ('aadhaar', 'trade_certificate', 'voter_id', 'pan')),
  file_name text not null,
  file_path text not null,
  file_size int not null default 0,
  mime_type text not null default 'application/octet-stream',
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);

create index if not exists worker_documents_worker_id_idx on public.worker_documents (worker_id);

alter table public.worker_documents enable row level security;
alter table public.worker_documents force row level security;

-- Drop and recreate worker_documents policies
drop policy if exists worker_documents_select on public.worker_documents;
drop policy if exists worker_documents_insert_own on public.worker_documents;
drop policy if exists worker_documents_delete_own on public.worker_documents;

create policy worker_documents_select on public.worker_documents
  for select
  to authenticated
  using (
    (select auth.uid()) = worker_id
    or (select public.is_admin_or_officer())
  );

create policy worker_documents_insert_own on public.worker_documents
  for insert
  to authenticated
  with check (
    (select auth.uid()) = worker_id
  );

create policy worker_documents_delete_own on public.worker_documents
  for delete
  to authenticated
  using (
    (select auth.uid()) = worker_id
  );

-- 5. Update Profiles Table SELECT Policy so Admins can inspect Worker Profiles
drop policy if exists profiles_select_own on public.profiles;
drop policy if exists profiles_select_unified on public.profiles;

create policy profiles_select_unified on public.profiles
  for select
  to authenticated
  using (
    (select auth.uid()) = id
    or (select public.is_admin_or_officer())
    or role = 'worker'
  );

-- 6. Configure Storage Bucket for KYC Documents
insert into storage.buckets (id, name, public)
values ('kyc-documents', 'kyc-documents', false)
on conflict (id) do nothing;

-- Drop and recreate storage policies
drop policy if exists storage_kyc_worker_insert on storage.objects;
drop policy if exists storage_kyc_select on storage.objects;
drop policy if exists storage_kyc_worker_delete on storage.objects;

create policy storage_kyc_worker_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'kyc-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy storage_kyc_select on storage.objects
  for select to authenticated
  using (
    bucket_id = 'kyc-documents'
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (select public.is_admin_or_officer())
    )
  );

create policy storage_kyc_worker_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'kyc-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- 7. Seed Initial Cooperatives
insert into public.cooperatives (name, code, district, state, registration_number, contact_email, contact_phone)
values
  (
    'Shramik Kalyan Labour Cooperative Society',
    'SKLCS-MH-01',
    'Pune',
    'Maharashtra',
    'MH/PUN/COOP/2021/8492',
    'pune.kalyan@sahayog.coop',
    '+91 20 2567 8901'
  ),
  (
    'Sahakar Nirman Workers Union',
    'SNWU-KA-02',
    'Bengaluru Urban',
    'Karnataka',
    'KA/BLR/COOP/2020/5120',
    'blr.nirman@sahayog.coop',
    '+91 80 2234 5678'
  ),
  (
    'Lokseva Artisan Cooperative Federation',
    'LACF-DL-03',
    'Central Delhi',
    'Delhi',
    'DL/CEN/COOP/2019/3301',
    'delhi.lokseva@sahayog.coop',
    '+91 11 2389 4455'
  )
on conflict (code) do nothing;

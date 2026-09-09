-- Migration: 20260909000003_bookings_and_enhancements.sql
-- Description: Add bookings table, worker availability & hourly rate columns, worker-documents bucket, and RLS policies.

-- 1. Enhance Worker Profiles with Availability and Hourly Rate
alter table public.worker_profiles
  add column if not exists is_available boolean not null default true,
  add column if not exists hourly_rate_inr int not null default 150 check (hourly_rate_inr >= 0);

create index if not exists worker_profiles_availability_idx on public.worker_profiles (is_available);

-- 2. Update worker_documents check constraint to include police_verification and cooperative_id
alter table public.worker_documents
  drop constraint if exists worker_documents_document_type_check;

alter table public.worker_documents
  add constraint worker_documents_document_type_check
  check (document_type in ('aadhaar', 'trade_certificate', 'voter_id', 'pan', 'police_verification', 'cooperative_id'));

-- 3. Configure 'worker-documents' Storage Bucket alongside 'kyc-documents'
insert into storage.buckets (id, name, public)
values ('worker-documents', 'worker-documents', false)
on conflict (id) do nothing;

drop policy if exists storage_worker_docs_insert on storage.objects;
drop policy if exists storage_worker_docs_select on storage.objects;
drop policy if exists storage_worker_docs_delete on storage.objects;

create policy storage_worker_docs_insert on storage.objects
  for insert to authenticated
  with check (
    bucket_id in ('worker-documents', 'kyc-documents')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy storage_worker_docs_select on storage.objects
  for select to authenticated
  using (
    bucket_id in ('worker-documents', 'kyc-documents')
    and (
      (storage.foldername(name))[1] = (select auth.uid())::text
      or (select public.is_admin_or_officer())
    )
  );

create policy storage_worker_docs_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id in ('worker-documents', 'kyc-documents')
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- 4. Create Bookings Table
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  tracking_code text not null unique,
  customer_id uuid not null references public.profiles(id) on delete cascade,
  worker_id uuid references public.profiles(id) on delete set null,
  cooperative_id uuid references public.cooperatives(id) on delete set null,
  service_category text not null,
  service_title text not null,
  service_description text not null default '',
  scheduled_date date not null default current_date,
  time_slot text not null default 'Morning (9 AM - 1 PM)',
  service_address text not null,
  is_urgent boolean not null default false,
  base_fare int not null default 300 check (base_fare >= 0),
  welfare_fee int not null default 30 check (welfare_fee >= 0),
  total_amount int not null default 330 check (total_amount >= 0),
  status text not null default 'requested'
    check (status in ('requested', 'assigned', 'in_progress', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 5. Bookings Indexes
create index if not exists bookings_customer_idx on public.bookings (customer_id);
create index if not exists bookings_worker_idx on public.bookings (worker_id);
create index if not exists bookings_coop_idx on public.bookings (cooperative_id);
create index if not exists bookings_status_idx on public.bookings (status);
create index if not exists bookings_date_idx on public.bookings (scheduled_date);

-- 6. Bookings RLS
alter table public.bookings enable row level security;
alter table public.bookings force row level security;

drop policy if exists bookings_select on public.bookings;
drop policy if exists bookings_insert_customer on public.bookings;
drop policy if exists bookings_update on public.bookings;

create policy bookings_select on public.bookings
  for select
  to authenticated
  using (
    (select auth.uid()) = customer_id
    or (select auth.uid()) = worker_id
    or (select public.is_admin_or_officer())
    or (
      worker_id is null
      and exists (
        select 1 from public.profiles
        where id = (select auth.uid()) and role = 'worker'
      )
    )
  );

create policy bookings_insert_customer on public.bookings
  for insert
  to authenticated
  with check (
    (select auth.uid()) = customer_id
  );

create policy bookings_update on public.bookings
  for update
  to authenticated
  using (
    (select auth.uid()) = customer_id
    or (select auth.uid()) = worker_id
    or (select public.is_admin_or_officer())
  )
  with check (
    (select auth.uid()) = customer_id
    or (select auth.uid()) = worker_id
    or (select public.is_admin_or_officer())
  );

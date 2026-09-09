-- Migration: 20260910000001_marketplace_complete_schema.sql
-- Description: Complete marketplace schema — federations, service catalog, payments,
--   invoices, reviews, notifications, welfare, booking lifecycle, geo-location,
--   state transition validation, and full RLS.
--
-- IMPORTANT: This migration extends the existing schema (migrations 000001–000003).
--   It does NOT drop or recreate any existing table.

-- ============================================================================
-- 1. FEDERATIONS — State-level governance body
-- ============================================================================

create table if not exists public.federations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null unique,
  state text not null,
  contact_email text,
  contact_phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists federations_state_idx on public.federations (state);

alter table public.federations enable row level security;
alter table public.federations force row level security;

create policy federations_select_all on public.federations
  for select to authenticated using (true);

create policy federations_admin_modify on public.federations
  for all to authenticated
  using ((select public.is_admin_or_officer()))
  with check ((select public.is_admin_or_officer()));

-- Link cooperatives to federation
alter table public.cooperatives
  add column if not exists federation_id uuid references public.federations(id) on delete set null;

create index if not exists cooperatives_federation_idx on public.cooperatives (federation_id);

-- Seed a default federation
insert into public.federations (name, code, state, contact_email)
values (
  'Maharashtra State Labour Cooperative Federation',
  'MSLCF-MH-01',
  'Maharashtra',
  'federation@sahayog.coop'
)
on conflict (code) do nothing;

-- ============================================================================
-- 2. SERVICE CATALOG — Categories and Services (DB-backed, not hardcoded)
-- ============================================================================

create table if not exists public.service_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon_name text not null default 'build_rounded',
  description text not null default '',
  is_active boolean not null default true,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

alter table public.service_categories enable row level security;
alter table public.service_categories force row level security;

create policy service_categories_select_all on public.service_categories
  for select to authenticated using (true);

create policy service_categories_admin_modify on public.service_categories
  for all to authenticated
  using ((select public.is_admin_or_officer()))
  with check ((select public.is_admin_or_officer()));

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.service_categories(id) on delete cascade,
  name text not null,
  description text not null default '',
  base_price_inr int not null default 300 check (base_price_inr >= 0),
  required_skills text[] not null default '{}',
  estimated_duration_minutes int not null default 60,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists services_category_idx on public.services (category_id);

alter table public.services enable row level security;
alter table public.services force row level security;

create policy services_select_all on public.services
  for select to authenticated using (true);

create policy services_admin_modify on public.services
  for all to authenticated
  using ((select public.is_admin_or_officer()))
  with check ((select public.is_admin_or_officer()));

-- ============================================================================
-- 3. PLATFORM CONFIG — Centralized configuration
-- ============================================================================

create table if not exists public.platform_config (
  key text primary key,
  value_json jsonb not null default '{}',
  description text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.platform_config enable row level security;
alter table public.platform_config force row level security;

create policy platform_config_select_all on public.platform_config
  for select to authenticated using (true);

-- Only service_role / postgres can modify config
-- No authenticated INSERT/UPDATE/DELETE policy = denied by RLS

-- Seed platform configuration
insert into public.platform_config (key, value_json, description) values
  ('welfare_contribution_pct', '{"value": 10}', 'Welfare pool contribution percentage deducted from each booking'),
  ('emergency_surcharge_inr', '{"value": 100}', 'Additional surcharge in INR for emergency/urgent bookings'),
  ('max_search_radius_km', '{"value": 25}', 'Maximum radius in km for worker discovery search'),
  ('booking_expiry_hours', '{"value": 24}', 'Hours after which an unaccepted booking expires')
on conflict (key) do nothing;

-- ============================================================================
-- 4. GEO-LOCATION — Add latitude/longitude to worker_profiles
-- ============================================================================

alter table public.worker_profiles
  add column if not exists is_available boolean not null default true,
  add column if not exists hourly_rate_inr int not null default 150,
  add column if not exists latitude double precision,
  add column if not exists longitude double precision,
  add column if not exists location_updated_at timestamptz;

-- Partial index for fast geo queries on verified, available workers
create index if not exists worker_profiles_geo_available_idx
  on public.worker_profiles (latitude, longitude)
  where verification_status = 'approved' and is_available = true
    and latitude is not null and longitude is not null;

-- ============================================================================
-- 5. WORKER AVAILABILITY — Weekly schedule
-- ============================================================================

create table if not exists public.worker_availability (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references public.profiles(id) on delete cascade,
  day_of_week int not null check (day_of_week between 0 and 6), -- 0=Sunday
  start_time time not null,
  end_time time not null,
  is_active boolean not null default true,
  constraint worker_availability_no_overlap unique (worker_id, day_of_week, start_time)
);

create index if not exists worker_availability_worker_idx on public.worker_availability (worker_id);

alter table public.worker_availability enable row level security;
alter table public.worker_availability force row level security;

create policy worker_availability_select on public.worker_availability
  for select to authenticated
  using (
    (select auth.uid()) = worker_id
    or (select public.is_admin_or_officer())
  );

create policy worker_availability_insert_own on public.worker_availability
  for insert to authenticated
  with check ((select auth.uid()) = worker_id);

create policy worker_availability_update_own on public.worker_availability
  for update to authenticated
  using ((select auth.uid()) = worker_id)
  with check ((select auth.uid()) = worker_id);

create policy worker_availability_delete_own on public.worker_availability
  for delete to authenticated
  using ((select auth.uid()) = worker_id);

-- ============================================================================
-- 6. BOOKINGS — Expand status set + add geo & service reference columns
-- ============================================================================

-- Drop old constraint and add expanded status values
alter table public.bookings
  drop constraint if exists bookings_status_check;

alter table public.bookings
  add constraint bookings_status_check
  check (status in (
    'requested', 'accepted', 'scheduled', 'in_progress',
    'completed', 'payment_confirmed', 'reviewed',
    'rejected', 'cancelled', 'expired'
  ));

-- Add new columns
alter table public.bookings
  add column if not exists service_id uuid references public.services(id) on delete set null,
  add column if not exists customer_latitude double precision,
  add column if not exists customer_longitude double precision,
  add column if not exists accepted_at timestamptz,
  add column if not exists completed_at timestamptz,
  add column if not exists cancellation_reason text;

create index if not exists bookings_service_idx on public.bookings (service_id);

-- ============================================================================
-- 7. BOOKING STATUS HISTORY — Audit trail
-- ============================================================================

create table if not exists public.booking_status_history (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  from_status text,
  to_status text not null,
  changed_by uuid references public.profiles(id) on delete set null,
  note text,
  created_at timestamptz not null default now()
);

create index if not exists booking_status_history_booking_idx
  on public.booking_status_history (booking_id);

alter table public.booking_status_history enable row level security;
alter table public.booking_status_history force row level security;

create policy booking_status_history_select on public.booking_status_history
  for select to authenticated
  using (
    exists (
      select 1 from public.bookings b
      where b.id = booking_id
        and (
          (select auth.uid()) = b.customer_id
          or (select auth.uid()) = b.worker_id
          or (select public.is_admin_or_officer())
        )
    )
  );

-- INSERT is done by trigger only — no direct user insert policy

-- ============================================================================
-- 8. PAYMENTS — Payment records
-- ============================================================================

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  amount_inr int not null check (amount_inr >= 0),
  payment_method text not null default 'razorpay',
  gateway_order_id text,
  gateway_payment_id text,
  gateway_signature text,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'completed', 'failed', 'refunded')),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists payments_booking_idx on public.payments (booking_id);
create index if not exists payments_status_idx on public.payments (status);

alter table public.payments enable row level security;
alter table public.payments force row level security;

-- Customers and workers can see payments for their bookings; admins see all
create policy payments_select on public.payments
  for select to authenticated
  using (
    exists (
      select 1 from public.bookings b
      where b.id = booking_id
        and (
          (select auth.uid()) = b.customer_id
          or (select auth.uid()) = b.worker_id
          or (select public.is_admin_or_officer())
        )
    )
  );

-- Only service_role (Edge Functions) can INSERT/UPDATE payments
-- No authenticated INSERT/UPDATE policy = denied by RLS for regular users

-- ============================================================================
-- 9. INVOICES — Generated per completed booking
-- ============================================================================

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_number text not null unique,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  customer_id uuid not null references public.profiles(id),
  worker_id uuid references public.profiles(id),
  service_description text not null,
  base_amount_inr int not null check (base_amount_inr >= 0),
  welfare_contribution_inr int not null check (welfare_contribution_inr >= 0),
  total_amount_inr int not null check (total_amount_inr >= 0),
  payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid', 'paid', 'refunded')),
  issued_at timestamptz not null default now()
);

create index if not exists invoices_booking_idx on public.invoices (booking_id);
create index if not exists invoices_customer_idx on public.invoices (customer_id);

alter table public.invoices enable row level security;
alter table public.invoices force row level security;

create policy invoices_select on public.invoices
  for select to authenticated
  using (
    (select auth.uid()) = customer_id
    or (select auth.uid()) = worker_id
    or (select public.is_admin_or_officer())
  );

-- ============================================================================
-- 10. WELFARE CONTRIBUTIONS — Per-booking deductions
-- ============================================================================

create table if not exists public.welfare_contributions (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  worker_id uuid not null references public.profiles(id),
  cooperative_id uuid references public.cooperatives(id),
  amount_inr int not null check (amount_inr >= 0),
  contribution_type text not null default 'booking_deduction'
    check (contribution_type in ('booking_deduction', 'manual_contribution')),
  created_at timestamptz not null default now()
);

create index if not exists welfare_contributions_worker_idx on public.welfare_contributions (worker_id);
create index if not exists welfare_contributions_booking_idx on public.welfare_contributions (booking_id);

alter table public.welfare_contributions enable row level security;
alter table public.welfare_contributions force row level security;

create policy welfare_contributions_select on public.welfare_contributions
  for select to authenticated
  using (
    (select auth.uid()) = worker_id
    or (select public.is_admin_or_officer())
  );

-- ============================================================================
-- 11. REVIEWS — One per completed booking
-- ============================================================================

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id),
  worker_id uuid not null references public.profiles(id),
  rating int not null check (rating between 1 and 5),
  comment text not null default '',
  created_at timestamptz not null default now(),
  constraint reviews_one_per_booking unique (booking_id)
);

create index if not exists reviews_worker_idx on public.reviews (worker_id);
create index if not exists reviews_reviewer_idx on public.reviews (reviewer_id);

alter table public.reviews enable row level security;
alter table public.reviews force row level security;

-- Anyone authenticated can read reviews (public transparency)
create policy reviews_select_all on public.reviews
  for select to authenticated using (true);

-- Only the booking's customer can create a review (enforced + booking must be completed/paid)
create policy reviews_insert_customer on public.reviews
  for insert to authenticated
  with check (
    (select auth.uid()) = reviewer_id
    and exists (
      select 1 from public.bookings b
      where b.id = booking_id
        and b.customer_id = (select auth.uid())
        and b.status in ('payment_confirmed', 'completed', 'reviewed')
    )
  );

-- ============================================================================
-- 12. NOTIFICATIONS — In-app event notifications
-- ============================================================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  event_type text not null,
  reference_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_unread_idx
  on public.notifications (user_id, is_read) where is_read = false;
create index if not exists notifications_user_created_idx
  on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;
alter table public.notifications force row level security;

create policy notifications_select_own on public.notifications
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy notifications_update_own on public.notifications
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- ============================================================================
-- 13. SERVER-SIDE BOOKING STATE TRANSITION VALIDATION
-- ============================================================================

create or replace function public.validate_booking_transition()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  -- Skip validation if status hasn't changed
  if old.status = new.status then
    new.updated_at := now();
    return new;
  end if;

  -- Allow service_role / postgres to bypass for administrative corrections
  if current_user in ('postgres', 'supabase_admin') or auth.role() = 'service_role' then
    -- Still record the history
    insert into public.booking_status_history (booking_id, from_status, to_status, changed_by)
    values (new.id, old.status, new.status, auth.uid());
    new.updated_at := now();
    return new;
  end if;

  -- Validate allowed transitions
  if not (
    (old.status = 'requested'           and new.status in ('accepted', 'rejected', 'cancelled', 'expired')) or
    (old.status = 'accepted'            and new.status in ('scheduled', 'in_progress', 'cancelled')) or
    (old.status = 'scheduled'           and new.status in ('in_progress', 'cancelled')) or
    (old.status = 'in_progress'         and new.status in ('completed', 'cancelled')) or
    (old.status = 'completed'           and new.status in ('payment_confirmed')) or
    (old.status = 'payment_confirmed'   and new.status in ('reviewed'))
  ) then
    raise exception 'Invalid booking status transition: % -> %', old.status, new.status
      using errcode = '42501';
  end if;

  -- Record transition in audit history
  insert into public.booking_status_history (booking_id, from_status, to_status, changed_by)
  values (new.id, old.status, new.status, auth.uid());

  -- Set timestamps for key transitions
  if new.status = 'accepted' then
    new.accepted_at := now();
  elsif new.status = 'completed' then
    new.completed_at := now();
  end if;

  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists tr_validate_booking_transition on public.bookings;

create trigger tr_validate_booking_transition
  before update on public.bookings
  for each row execute procedure public.validate_booking_transition();

-- ============================================================================
-- 14. NOTIFICATION TRIGGERS — Auto-create on booking events
-- ============================================================================

create or replace function public.notify_booking_status_change()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  v_title text;
  v_body text;
  v_target_user_id uuid;
begin
  -- Skip if status hasn't changed
  if old.status = new.status then
    return new;
  end if;

  -- Notify customer about status changes made by worker/admin
  if new.status in ('accepted', 'rejected', 'in_progress', 'completed') then
    v_target_user_id := new.customer_id;
    v_title := case new.status
      when 'accepted' then 'Booking Accepted'
      when 'rejected' then 'Booking Rejected'
      when 'in_progress' then 'Service Started'
      when 'completed' then 'Service Completed'
    end;
    v_body := case new.status
      when 'accepted' then 'A worker has accepted your booking ' || new.tracking_code
      when 'rejected' then 'Your booking ' || new.tracking_code || ' was not accepted'
      when 'in_progress' then 'Your service ' || new.tracking_code || ' has started'
      when 'completed' then 'Your service ' || new.tracking_code || ' is complete. Please proceed to payment.'
    end;

    insert into public.notifications (user_id, title, body, event_type, reference_id)
    values (v_target_user_id, v_title, v_body, 'booking_' || new.status, new.id);
  end if;

  -- Notify worker when booking is assigned or payment confirmed
  if new.worker_id is not null and new.status in ('payment_confirmed') then
    insert into public.notifications (user_id, title, body, event_type, reference_id)
    values (
      new.worker_id,
      'Payment Confirmed',
      'Payment for booking ' || new.tracking_code || ' has been confirmed. Earnings credited.',
      'payment_confirmed',
      new.id
    );
  end if;

  return new;
end;
$$;

drop trigger if exists tr_notify_booking_status on public.bookings;

create trigger tr_notify_booking_status
  after update on public.bookings
  for each row execute procedure public.notify_booking_status_change();

-- Notify worker on verification status change
create or replace function public.notify_verification_status_change()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  if old.verification_status is distinct from new.verification_status then
    if new.verification_status = 'approved' then
      insert into public.notifications (user_id, title, body, event_type, reference_id)
      values (
        new.id,
        'Verification Approved',
        'Congratulations! Your worker profile has been verified. You can now receive bookings.',
        'verification_approved',
        new.id
      );
    elsif new.verification_status = 'rejected' then
      insert into public.notifications (user_id, title, body, event_type, reference_id)
      values (
        new.id,
        'Verification Update Required',
        'Your verification was not approved. Please check the feedback and resubmit.',
        'verification_rejected',
        new.id
      );
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists tr_notify_verification_status on public.worker_profiles;

create trigger tr_notify_verification_status
  after update on public.worker_profiles
  for each row execute procedure public.notify_verification_status_change();

-- ============================================================================
-- 15. HAVERSINE DISTANCE FUNCTION — For geo-location queries
-- ============================================================================

create or replace function public.haversine_distance_km(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
)
returns double precision
language sql
immutable
as $$
  select 6371 * 2 * asin(sqrt(
    sin(radians(lat2 - lat1) / 2) ^ 2 +
    cos(radians(lat1)) * cos(radians(lat2)) *
    sin(radians(lon2 - lon1) / 2) ^ 2
  ));
$$;

-- ============================================================================
-- 16. WORKER DISCOVERY FUNCTION — Find nearby verified workers
-- ============================================================================

create or replace function public.find_nearby_workers(
  p_lat double precision,
  p_lng double precision,
  p_skill text default null,
  p_radius_km double precision default 25,
  p_limit int default 20,
  p_offset int default 0
)
returns table (
  worker_id uuid,
  full_name text,
  skills text[],
  experience_years int,
  hourly_rate_inr int,
  daily_rate_inr int,
  cooperative_name text,
  rating_avg numeric,
  review_count bigint,
  distance_km double precision
)
language sql
stable
as $$
  select
    wp.id as worker_id,
    p.full_name,
    wp.skills,
    wp.experience_years,
    wp.hourly_rate_inr,
    wp.daily_rate_inr,
    c.name as cooperative_name,
    coalesce(avg(r.rating), 0) as rating_avg,
    count(r.id) as review_count,
    public.haversine_distance_km(p_lat, p_lng, wp.latitude, wp.longitude) as distance_km
  from public.worker_profiles wp
  join public.profiles p on p.id = wp.id
  left join public.cooperatives c on c.id = wp.cooperative_id
  left join public.reviews r on r.worker_id = wp.id
  where
    wp.verification_status = 'approved'
    and wp.is_available = true
    and wp.latitude is not null
    and wp.longitude is not null
    and public.haversine_distance_km(p_lat, p_lng, wp.latitude, wp.longitude) <= p_radius_km
    and (p_skill is null or p_skill = any(wp.skills))
  group by wp.id, p.full_name, wp.skills, wp.experience_years,
           wp.hourly_rate_inr, wp.daily_rate_inr, c.name, wp.latitude, wp.longitude
  order by distance_km asc
  limit p_limit
  offset p_offset;
$$;

-- ============================================================================
-- 17. FEDERATION ANALYTICS FUNCTION — Server-side aggregation
-- ============================================================================

create or replace function public.get_federation_metrics()
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'total_workers', (select count(*) from public.worker_profiles),
    'verified_workers', (select count(*) from public.worker_profiles where verification_status = 'approved'),
    'pending_verifications', (select count(*) from public.worker_profiles where verification_status = 'pending'),
    'active_cooperatives', (select count(*) from public.cooperatives),
    'completed_bookings', (select count(*) from public.bookings where status in ('completed', 'payment_confirmed', 'reviewed')),
    'total_service_value_inr', coalesce((select sum(total_amount) from public.bookings where status in ('completed', 'payment_confirmed', 'reviewed')), 0),
    'total_welfare_pool_inr', coalesce((select sum(amount_inr) from public.welfare_contributions), 0),
    'total_bookings', (select count(*) from public.bookings),
    'active_workers', (select count(*) from public.worker_profiles where is_available = true and verification_status = 'approved')
  );
$$;

-- ============================================================================
-- 18. SEED SERVICE CATALOG — Real service data (matching existing hardcoded list)
-- ============================================================================

-- Insert categories
insert into public.service_categories (name, icon_name, description, sort_order) values
  ('Electrician',       'flash_on_rounded',               'Electrical wiring, repairs, and installations',          1),
  ('Plumber',           'water_drop_rounded',             'Pipe repair, fitting, and drainage solutions',            2),
  ('Carpenter',         'handyman_rounded',               'Wood work, furniture repair, and installations',          3),
  ('Cleaning',          'cleaning_services_rounded',      'Deep cleaning, sanitization, and upholstery care',        4),
  ('Caregiver',         'volunteer_activism_rounded',     'Elderly care, patient assistance, and companionship',     5),
  ('Appliance Repair',  'devices_other_rounded',          'Repair and servicing of home appliances',                 6),
  ('Painter',           'format_paint_rounded',           'Interior and exterior painting and finishing',             7)
on conflict (name) do nothing;

-- Insert services for each category
-- Electrician services
insert into public.services (category_id, name, base_price_inr, required_skills) values
  ((select id from public.service_categories where name = 'Electrician'), 'MCB & Switchboard Repair',            350, '{Electrician}'),
  ((select id from public.service_categories where name = 'Electrician'), 'Ceiling Fan Installation & Repair',   350, '{Electrician}'),
  ((select id from public.service_categories where name = 'Electrician'), 'Complete House Wiring Diagnostics',   350, '{Electrician}'),
  ((select id from public.service_categories where name = 'Electrician'), 'Inverter & Backup Battery Setup',     350, '{Electrician}'),
  ((select id from public.service_categories where name = 'Electrician'), 'Lighting & Chandelier Fixtures',      350, '{Electrician}');

-- Plumber services
insert into public.services (category_id, name, base_price_inr, required_skills) values
  ((select id from public.service_categories where name = 'Plumber'), 'Pipe Leakage & Burst Diagnostics',       350, '{Plumber}'),
  ((select id from public.service_categories where name = 'Plumber'), 'Tap & Shower Fitting Replacement',       350, '{Plumber}'),
  ((select id from public.service_categories where name = 'Plumber'), 'Drain Cleaning & Blockage Clearing',     350, '{Plumber}'),
  ((select id from public.service_categories where name = 'Plumber'), 'Water Tank Valve & Motor Repair',        350, '{Plumber}'),
  ((select id from public.service_categories where name = 'Plumber'), 'Sanitary Ware & Commode Installation',   350, '{Plumber}');

-- Carpenter services
insert into public.services (category_id, name, base_price_inr, required_skills) values
  ((select id from public.service_categories where name = 'Carpenter'), 'Door Lock, Latch & Hinge Alignment',   400, '{Carpenter}'),
  ((select id from public.service_categories where name = 'Carpenter'), 'Furniture Assembly & Repair',           400, '{Carpenter}'),
  ((select id from public.service_categories where name = 'Carpenter'), 'Modular Kitchen Cabinet Fixes',         400, '{Carpenter}'),
  ((select id from public.service_categories where name = 'Carpenter'), 'Custom Wooden Shelving',                400, '{Carpenter}'),
  ((select id from public.service_categories where name = 'Carpenter'), 'Window Frame & Mesh Repairs',           400, '{Carpenter}');

-- Cleaning services
insert into public.services (category_id, name, base_price_inr, required_skills) values
  ((select id from public.service_categories where name = 'Cleaning'), 'Deep Home Sanitation',                   450, '{Cleaning}'),
  ((select id from public.service_categories where name = 'Cleaning'), 'Kitchen Exhaust & Degreasing',           450, '{Cleaning}'),
  ((select id from public.service_categories where name = 'Cleaning'), 'Bathroom Scrubbing & Scaling',           450, '{Cleaning}'),
  ((select id from public.service_categories where name = 'Cleaning'), 'Sofa & Upholstery Shampooing',           450, '{Cleaning}'),
  ((select id from public.service_categories where name = 'Cleaning'), 'Post-Renovation Clean-up',               450, '{Cleaning}');

-- Caregiver services
insert into public.services (category_id, name, base_price_inr, required_skills) values
  ((select id from public.service_categories where name = 'Caregiver'), 'Elderly Day Assistance & Vitals',       500, '{Caregiver}'),
  ((select id from public.service_categories where name = 'Caregiver'), 'Post-Operative Patient Care',           500, '{Caregiver}'),
  ((select id from public.service_categories where name = 'Caregiver'), 'Physiotherapy Assistance',              500, '{Caregiver}'),
  ((select id from public.service_categories where name = 'Caregiver'), 'Companion & Mobility Support',          500, '{Caregiver}'),
  ((select id from public.service_categories where name = 'Caregiver'), 'Emergency Medical Escort',              500, '{Caregiver}');

-- Appliance Repair services
insert into public.services (category_id, name, base_price_inr, required_skills) values
  ((select id from public.service_categories where name = 'Appliance Repair'), 'Washing Machine Diagnostics',    400, '{Appliance Repair}'),
  ((select id from public.service_categories where name = 'Appliance Repair'), 'Refrigerator Gas & Cooling Fix', 400, '{Appliance Repair}'),
  ((select id from public.service_categories where name = 'Appliance Repair'), 'Microwave Oven Repair',          400, '{Appliance Repair}'),
  ((select id from public.service_categories where name = 'Appliance Repair'), 'RO Water Purifier Service & Filter', 400, '{Appliance Repair}'),
  ((select id from public.service_categories where name = 'Appliance Repair'), 'AC Servicing & Gas Refill',       400, '{Appliance Repair}');

-- Painter services
insert into public.services (category_id, name, base_price_inr, required_skills) values
  ((select id from public.service_categories where name = 'Painter'), 'Single Room Waterproof Emulsion',         450, '{Painter}'),
  ((select id from public.service_categories where name = 'Painter'), 'Full Home Interior Painting',             450, '{Painter}'),
  ((select id from public.service_categories where name = 'Painter'), 'Wall Crack Filling & Putty Work',         450, '{Painter}'),
  ((select id from public.service_categories where name = 'Painter'), 'Wood & Metal Enamel Polish',              450, '{Painter}'),
  ((select id from public.service_categories where name = 'Painter'), 'Exterior Weatherproof Coat',              450, '{Painter}');

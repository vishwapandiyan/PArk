-- Updated Supabase schema for Smart Parking App with ML integration

-- users table
create table if not exists public.users (
  id uuid primary key,
  name text not null,
  email text not null unique,
  phone text not null,
  age int,
  role text check (role in ('driver','owner')) not null,
  license_url text,
  land_proof_url text,
  dimensions text,
  address text,
  is_verified boolean
);

-- parking_slots table with new amenities
create table if not exists public.parking_slots (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.users(id) on delete cascade,
  address text not null,
  latitude double precision not null,
  longitude double precision not null,
  dimensions text,
  photos text[] default '{}',
  pricing jsonb default '{}'::jsonb,
  available_durations text[] default '{}',
  time_from text,
  time_to text,
  rating double precision,
  review_count int default 0,
  has_shelter boolean default false,
  has_cctv boolean default false,
  has_ev_charging boolean default false
);

-- bookings table
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.users(id) on delete cascade,
  owner_id uuid not null references public.users(id) on delete cascade,
  slot_id uuid not null references public.parking_slots(id) on delete cascade,
  start_time timestamptz not null,
  end_time timestamptz not null,
  duration text,
  price double precision not null default 0,
  status text check (status in ('pending','confirmed','active','completed')) not null default 'pending'
);

-- Storage buckets for documents and photos
insert into storage.buckets (id, name, public) values ('documents','documents', true) on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('photos','photos', true) on conflict (id) do nothing;

-- Enable Row Level Security (RLS)
alter table public.users enable row level security;
alter table public.parking_slots enable row level security;
alter table public.bookings enable row level security;

-- Users RLS: everyone can read; owners can update own row
create policy "Users read all" on public.users for select using (true);
create policy "User update self" on public.users
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- Slots RLS: read all; owner can manage their slots
create policy "Slots read all" on public.parking_slots for select using (true);
create policy "Slots insert owner" on public.parking_slots
  for insert to authenticated with check (exists (select 1 from public.users u where u.id = auth.uid() and u.role = 'owner'));
create policy "Slots update owner" on public.parking_slots
  for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- Bookings RLS: driver/owner can read their bookings; driver creates; owner updates status
create policy "Bookings read by parties" on public.bookings
  for select using (driver_id = auth.uid() or owner_id = auth.uid());
create policy "Bookings insert by driver" on public.bookings
  for insert to authenticated with check (driver_id = auth.uid());
create policy "Bookings update by parties" on public.bookings
  for update to authenticated using (driver_id = auth.uid() or owner_id = auth.uid());

-- Storage policies: public read, authenticated write
create policy "Public read documents" on storage.objects
  for select using (bucket_id in ('documents','photos'));
create policy "Auth write documents" on storage.objects
  for insert to authenticated with check (bucket_id in ('documents','photos'));
create policy "Auth update documents" on storage.objects
  for update to authenticated using (bucket_id in ('documents','photos'));

-- Sample data for testing
insert into public.users (id, name, email, phone, role) values 
  ('550e8400-e29b-41d4-a716-446655440000', 'John Driver', 'john@example.com', '+1234567890', 'driver'),
  ('550e8400-e29b-41d4-a716-446655440001', 'Jane Owner', 'jane@example.com', '+1234567891', 'owner')
on conflict (id) do nothing;

insert into public.parking_slots (owner_id, address, latitude, longitude, dimensions, pricing, available_durations, has_shelter, has_cctv, has_ev_charging) values
  ('550e8400-e29b-41d4-a716-446655440001', '123 Main St, Downtown', 40.7128, -74.0060, '5m x 2.5m', '{"hour": 2.5, "day": 15}', ARRAY['hour', 'day'], true, true, false),
  ('550e8400-e29b-41d4-a716-446655440001', '456 Park Ave, Midtown', 40.7589, -73.9851, '6m x 3m', '{"hour": 3.0, "day": 20}', ARRAY['hour', 'day', 'month'], false, true, true)
on conflict do nothing;

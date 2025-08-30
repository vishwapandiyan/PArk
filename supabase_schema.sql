-- Updated Supabase schema for Smart Parking App with ML integration

-- car_models table for Indian cars
create table if not exists public.car_models (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  brand text not null,
  length float not null,
  width float not null,
  height float not null,
  wheelbase float not null,
  created_at timestamptz default now()
);

-- users table
create table if not exists public.users (
  id uuid primary key,
  name text not null,
  email text not null unique,
  phone text not null,
  dob date,
  role text check (role in ('driver','owner')) not null,
  license_url text,
  land_proof_url text,
  car_model_id uuid references public.car_models(id),
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
alter table public.car_models enable row level security;
alter table public.users enable row level security;
alter table public.parking_slots enable row level security;
alter table public.bookings enable row level security;
alter table public.parking_spaces enable row level security;
alter table public.transactions enable row level security;
alter table public.wallets enable row level security;

-- Car models RLS: everyone can read
create policy "Car models read all" on public.car_models for select using (true);

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

-- Parking spaces RLS: owners can manage their spaces, everyone can read
create policy "Parking spaces read all" on public.parking_spaces for select using (true);
create policy "Parking spaces insert owner" on public.parking_spaces
  for insert to authenticated with check (owner_id = auth.uid());
create policy "Parking spaces update owner" on public.parking_spaces
  for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy "Parking spaces delete owner" on public.parking_spaces
  for delete to authenticated using (owner_id = auth.uid());

-- Transactions RLS: users can read their own transactions, authenticated can insert
create policy "Transactions read own" on public.transactions
  for select using (user_id = auth.uid());
create policy "Transactions insert auth" on public.transactions
  for insert to authenticated with check (user_id = auth.uid());

-- Wallets RLS: users can read and update their own wallet
create policy "Wallets read own" on public.wallets
  for select using (user_id = auth.uid());
create policy "Wallets update own" on public.wallets
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Wallets insert own" on public.wallets
  for insert to authenticated with check (user_id = auth.uid());

-- Storage policies: public read, authenticated write
create policy "Public read documents" on storage.objects
  for select using (bucket_id in ('documents','photos'));
create policy "Auth write documents" on storage.objects
  for insert to authenticated with check (bucket_id in ('documents','photos'));
create policy "Auth update documents" on storage.objects
  for update to authenticated using (bucket_id in ('documents','photos'));

-- Sample Indian car models data with comprehensive selection
insert into public.car_models (id, name, brand, length, width, height, wheelbase) values
  -- Maruti Suzuki
  ('650e8400-e29b-41d4-a716-446655440000', 'Swift 2024', 'Maruti Suzuki', 3.845, 1.735, 1.530, 2.450),
  ('650e8400-e29b-41d4-a716-446655440001', 'Baleno 2024', 'Maruti Suzuki', 3.990, 1.745, 1.500, 2.520),
  ('650e8400-e29b-41d4-a716-446655440015', 'Alto K10 2024', 'Maruti Suzuki', 3.530, 1.490, 1.475, 2.360),
  ('650e8400-e29b-41d4-a716-446655440016', 'WagonR 2024', 'Maruti Suzuki', 3.655, 1.620, 1.675, 2.435),
  ('650e8400-e29b-41d4-a716-446655440017', 'Dzire 2024', 'Maruti Suzuki', 3.995, 1.735, 1.515, 2.450),
  ('650e8400-e29b-41d4-a716-446655440018', 'Vitara Brezza 2024', 'Maruti Suzuki', 3.995, 1.790, 1.640, 2.500),
  ('650e8400-e29b-41d4-a716-446655440019', 'Ertiga 2024', 'Maruti Suzuki', 4.395, 1.735, 1.690, 2.740),
  ('650e8400-e29b-41d4-a716-446655440020', 'XL6 2024', 'Maruti Suzuki', 4.445, 1.775, 1.700, 2.740),
  
  -- Hyundai
  ('650e8400-e29b-41d4-a716-446655440002', 'i20 2024', 'Hyundai', 3.995, 1.775, 1.505, 2.580),
  ('650e8400-e29b-41d4-a716-446655440003', 'Creta 2024', 'Hyundai', 4.300, 1.790, 1.635, 2.610),
  ('650e8400-e29b-41d4-a716-446655440014', 'Venue 2024', 'Hyundai', 3.995, 1.770, 1.617, 2.500),
  ('650e8400-e29b-41d4-a716-446655440021', 'Grand i10 Nios 2024', 'Hyundai', 3.805, 1.680, 1.520, 2.450),
  ('650e8400-e29b-41d4-a716-446655440022', 'Aura 2024', 'Hyundai', 3.995, 1.680, 1.520, 2.450),
  ('650e8400-e29b-41d4-a716-446655440023', 'Alcazar 2024', 'Hyundai', 4.500, 1.790, 1.675, 2.760),
  ('650e8400-e29b-41d4-a716-446655440024', 'Tucson 2024', 'Hyundai', 4.630, 1.865, 1.665, 2.755),
  
  -- Honda
  ('650e8400-e29b-41d4-a716-446655440004', 'City 2024', 'Honda', 4.549, 1.748, 1.489, 2.600),
  ('650e8400-e29b-41d4-a716-446655440005', 'Civic 2024', 'Honda', 4.656, 1.799, 1.433, 2.700),
  ('650e8400-e29b-41d4-a716-446655440025', 'Amaze 2024', 'Honda', 3.995, 1.695, 1.501, 2.470),
  ('650e8400-e29b-41d4-a716-446655440026', 'Jazz 2024', 'Honda', 3.994, 1.694, 1.544, 2.530),
  ('650e8400-e29b-41d4-a716-446655440027', 'City e:HEV 2024', 'Honda', 4.549, 1.748, 1.489, 2.600),
  
  -- Tata
  ('650e8400-e29b-41d4-a716-446655440006', 'Nexon 2024', 'Tata', 3.993, 1.811, 1.607, 2.498),
  ('650e8400-e29b-41d4-a716-446655440007', 'Harrier 2024', 'Tata', 4.598, 1.894, 1.706, 2.741),
  ('650e8400-e29b-41d4-a716-446655440028', 'Punch 2024', 'Tata', 3.827, 1.742, 1.615, 2.445),
  ('650e8400-e29b-41d4-a716-446655440029', 'Altroz 2024', 'Tata', 3.988, 1.754, 1.505, 2.501),
  ('650e8400-e29b-41d4-a716-446655440030', 'Tigor 2024', 'Tata', 3.993, 1.677, 1.532, 2.450),
  ('650e8400-e29b-41d4-a716-446655440031', 'Safari 2024', 'Tata', 4.661, 1.894, 1.786, 2.741),
  ('650e8400-e29b-41d4-a716-446655440032', 'Nexon EV 2024', 'Tata', 3.993, 1.811, 1.607, 2.498),
  
  -- Mahindra
  ('650e8400-e29b-41d4-a716-446655440008', 'XUV300 2024', 'Mahindra', 3.995, 1.821, 1.627, 2.600),
  ('650e8400-e29b-41d4-a716-446655440009', 'Scorpio-N 2024', 'Mahindra', 4.662, 1.917, 1.857, 2.750),
  ('650e8400-e29b-41d4-a716-446655440033', 'XUV700 2024', 'Mahindra', 4.695, 1.890, 1.755, 2.750),
  ('650e8400-e29b-41d4-a716-446655440034', 'Bolero 2024', 'Mahindra', 3.995, 1.745, 1.880, 2.680),
  ('650e8400-e29b-41d4-a716-446655440035', 'XUV400 2024', 'Mahindra', 4.200, 1.821, 1.634, 2.600),
  ('650e8400-e29b-41d4-a716-446655440036', 'Thar 2024', 'Mahindra', 3.985, 1.820, 1.844, 2.450),
  
  -- Volkswagen
  ('650e8400-e29b-41d4-a716-446655440010', 'Polo 2024', 'Volkswagen', 3.971, 1.682, 1.469, 2.470),
  ('650e8400-e29b-41d4-a716-446655440011', 'Virtus 2024', 'Volkswagen', 4.561, 1.752, 1.507, 2.651),
  ('650e8400-e29b-41d4-a716-446655440037', 'Taigun 2024', 'Volkswagen', 4.221, 1.760, 1.612, 2.651),
  
  -- Skoda
  ('650e8400-e29b-41d4-a716-446655440012', 'Kushaq 2024', 'Skoda', 4.225, 1.760, 1.612, 2.651),
  ('650e8400-e29b-41d4-a716-446655440013', 'Slavia 2024', 'Skoda', 4.541, 1.752, 1.487, 2.651),
  ('650e8400-e29b-41d4-a716-446655440038', 'Superb 2024', 'Skoda', 4.869, 1.864, 1.469, 2.841),
  
  -- Kia
  ('650e8400-e29b-41d4-a716-446655440039', 'Sonet 2024', 'Kia', 3.995, 1.790, 1.642, 2.500),
  ('650e8400-e29b-41d4-a716-446655440040', 'Seltos 2024', 'Kia', 4.315, 1.800, 1.645, 2.610),
  ('650e8400-e29b-41d4-a716-446655440041', 'Carens 2024', 'Kia', 4.540, 1.800, 1.708, 2.780),
  
  -- Toyota
  ('650e8400-e29b-41d4-a716-446655440042', 'Glanza 2024', 'Toyota', 3.990, 1.745, 1.500, 2.520),
  ('650e8400-e29b-41d4-a716-446655440043', 'Urban Cruiser Hyryder 2024', 'Toyota', 4.365, 1.795, 1.635, 2.600),
  ('650e8400-e29b-41d4-a716-446655440044', 'Innova Crysta 2024', 'Toyota', 4.735, 1.830, 1.795, 2.750),
  ('650e8400-e29b-41d4-a716-446655440045', 'Fortuner 2024', 'Toyota', 4.795, 1.855, 1.835, 2.745),
  
  -- Nissan
  ('650e8400-e29b-41d4-a716-446655440046', 'Magnite 2024', 'Nissan', 3.994, 1.758, 1.572, 2.500),
  ('650e8400-e29b-41d4-a716-446655440047', 'Kicks 2024', 'Nissan', 4.384, 1.813, 1.656, 2.673),
  
  -- Renault
  ('650e8400-e29b-41d4-a716-446655440048', 'Kwid 2024', 'Renault', 3.679, 1.579, 1.478, 2.423),
  ('650e8400-e29b-41d4-a716-446655440049', 'Triber 2024', 'Renault', 3.990, 1.739, 1.643, 2.636),
  ('650e8400-e29b-41d4-a716-446655440050', 'Kiger 2024', 'Renault', 3.991, 1.750, 1.598, 2.500)
on conflict (id) do nothing;

-- Sample data for testing
insert into public.users (id, name, email, phone, role, dob, car_model_id) values 
  ('550e8400-e29b-41d4-a716-446655440000', 'John Driver', 'john@example.com', '+1234567890', 'driver', '1995-05-15', '650e8400-e29b-41d4-a716-446655440000'),
  ('550e8400-e29b-41d4-a716-446655440001', 'Jane Owner', 'jane@example.com', '+1234567891', 'owner', '1988-12-20', null)
on conflict (id) do nothing;

-- Sample wallets for users
insert into public.wallets (user_id, balance) values
  ('550e8400-e29b-41d4-a716-446655440000', 1500), -- Driver with 1500 fake currency
  ('550e8400-e29b-41d4-a716-446655440001', 2000)  -- Owner with 2000 fake currency
on conflict (user_id) do nothing;

-- Sample parking spaces for owner
insert into public.parking_spaces (
  id, owner_id, slot_number, place_name, address, latitude, longitude, 
  length, width, height, has_ev_charging, has_shelter, has_cctv,
  available_from, available_to, rental_duration_from, rental_duration_to,
  rental_mode, price_per_unit, is_premium, total_bookings, current_bookings
) values
  (
    '750e8400-e29b-41d4-a716-446655440000',
    '550e8400-e29b-41d4-a716-446655440001',
    'PS001',
    'Downtown Premium Parking',
    '123 Main St, Downtown Commercial Area',
    12.9716, 77.5946, -- Bangalore coordinates
    5.5, 3.0, 2.5,
    true, true, true, -- EV + Shelter + CCTV (Premium)
    '08:00:00', '20:00:00',
    '2024-01-01', '2024-12-31',
    'hourly', 120, true, 25, 3
  ),
  (
    '750e8400-e29b-41d4-a716-446655440001',
    '550e8400-e29b-41d4-a716-446655440001',
    'PS002',
    'City Center Basic Parking',
    '456 Park Avenue, City Center',
    12.9758, 77.6012, -- Bangalore coordinates
    4.5, 2.8, 2.2,
    false, false, true, -- Only CCTV (Normal)
    '06:00:00', '22:00:00',
    '2024-01-01', '2024-12-31',
    'hourly', 35, false, 12, 1
  ),
  (
    '750e8400-e29b-41d4-a716-446655440002',
    '550e8400-e29b-41d4-a716-446655440001',
    'PS003',
    'Residential Monthly Parking',
    '789 Residential Complex, Whitefield',
    12.9698, 77.7500, -- Bangalore coordinates
    6.0, 3.5, 2.8,
    true, true, false, -- EV + Shelter (Premium)
    '00:00:00', '23:59:59',
    '2024-01-01', '2024-12-31',
    'monthly', 20000, true, 8, 0
  )
on conflict (id) do nothing;

-- Sample transactions for wallet
insert into public.transactions (user_id, transaction_type, amount, description) values
  ('550e8400-e29b-41d4-a716-446655440000', 'credit', 500, 'Welcome bonus'),
  ('550e8400-e29b-41d4-a716-446655440000', 'debit', 120, 'Parking payment - Downtown Premium'),
  ('550e8400-e29b-41d4-a716-446655440001', 'credit', 1000, 'Welcome bonus'),
  ('550e8400-e29b-41d4-a716-446655440001', 'credit', 120, 'Parking income - Downtown Premium')
on conflict do nothing;

insert into public.parking_slots (owner_id, address, latitude, longitude, dimensions, pricing, available_durations, has_shelter, has_cctv, has_ev_charging) values
  ('550e8400-e29b-41d4-a716-446655440001', '123 Main St, Downtown', 40.7128, -74.0060, '5m x 2.5m', '{"hour": 2.5, "day": 15}', ARRAY['hour', 'day'], true, true, false),
  ('550e8400-e29b-41d4-a716-446655440001', '456 Park Ave, Midtown', 40.7589, -73.9851, '6m x 3m', '{"hour": 3.0, "day": 20}', ARRAY['hour', 'day', 'month'], false, true, true)
on conflict do nothing;

-- parking_spaces table for owner's parking spaces
create table if not exists public.parking_spaces (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.users(id) on delete cascade,
  slot_number text not null,
  place_name text not null,
  address text not null,
  latitude double precision not null,
  longitude double precision not null,
  length float not null, -- in meters
  width float not null, -- in meters
  height float not null, -- in meters
  land_proof_url text,
  place_image_url text,
  
  -- Facilities (boolean flags)
  has_ev_charging boolean default false,
  has_shelter boolean default false,
  has_cctv boolean default false,
  
  -- Availability and timing
  available_from time not null,
  available_to time not null,
  rental_duration_from date not null,
  rental_duration_to date not null,
  
  -- Pricing and mode
  rental_mode text check (rental_mode in ('hourly','monthly','yearly')) not null,
  price_per_unit integer not null, -- price in fake currency
  is_premium boolean default false,
  
  -- Status
  is_active boolean default true,
  is_paused boolean default false,
  
  -- Booking stats
  total_bookings integer default 0,
  current_bookings integer default 0,
  
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- transactions table for wallet system
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  transaction_type text check (transaction_type in ('credit','debit')) not null,
  amount integer not null, -- amount in fake currency
  description text not null,
  reference_id uuid, -- can reference booking_id or parking_space_id
  created_at timestamptz default now()
);

-- wallets table to track user balances
create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  balance integer default 1000, -- starting with 1000 fake currency
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Update existing parking_slots table to work with new system
alter table if exists public.parking_slots add column if not exists space_id uuid references public.parking_spaces(id);

-- SQL Functions for wallet operations
CREATE OR REPLACE FUNCTION add_wallet_balance(user_id_param UUID, amount_param INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE wallets 
  SET balance = balance + amount_param, updated_at = NOW()
  WHERE user_id = user_id_param;
  
  IF NOT FOUND THEN
    INSERT INTO wallets (user_id, balance) VALUES (user_id_param, 1000 + amount_param);
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION deduct_wallet_balance(user_id_param UUID, amount_param INTEGER)
RETURNS VOID AS $$
BEGIN
  UPDATE wallets 
  SET balance = balance - amount_param, updated_at = NOW()
  WHERE user_id = user_id_param AND balance >= amount_param;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Insufficient balance or wallet not found';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Debug: Check if car models were inserted
-- You can run this query in Supabase SQL editor to verify the data
-- SELECT COUNT(*) as total_car_models FROM car_models;
-- SELECT brand, COUNT(*) as model_count FROM car_models GROUP BY brand ORDER BY brand;

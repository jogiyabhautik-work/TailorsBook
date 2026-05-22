-- Migration: Fix missing columns across all tables
-- Safely adds columns that may not exist if migrations were partially applied

-- ============ PAYMENTS ============
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'payments' and column_name = 'customer_id') then
    alter table public.payments add column customer_id uuid references public.customers(id) on delete set null;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'payments' and column_name = 'user_id') then
    alter table public.payments add column user_id uuid references auth.users(id) on delete set null;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'payments' and column_name = 'payment_date') then
    alter table public.payments add column payment_date timestamptz not null default now();
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'payments' and column_name = 'created_at') then
    alter table public.payments add column created_at timestamptz not null default now();
  end if;
end $$;

-- RLS
alter table public.payments enable row level security;
drop policy if exists "Users can manage their own payments" on public.payments;
create policy "Users can manage their own payments" on public.payments
    using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ============ ORDER ITEMS ============
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'order_items' and column_name = 'alteration_notes') then
    alter table public.order_items add column alteration_notes text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'order_items' and column_name = 'fabric_details') then
    alter table public.order_items add column fabric_details text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'order_items' and column_name = 'reference_image_url') then
    alter table public.order_items add column reference_image_url text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'order_items' and column_name = 'deleted_at') then
    alter table public.order_items add column deleted_at timestamptz;
  end if;
end $$;

-- ============ ORDERS ============
do $$
begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orders' and column_name = 'worker_id') then
    alter table public.orders add column worker_id uuid references public.workers(id) on delete set null;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orders' and column_name = 'order_token') then
    alter table public.orders add column order_token text;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orders' and column_name = 'status_history') then
    alter table public.orders add column status_history jsonb not null default '[]'::jsonb;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orders' and column_name = 'deleted_at') then
    alter table public.orders add column deleted_at timestamptz;
  end if;
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'orders' and column_name = 'last_modified_at') then
    alter table public.orders add column last_modified_at timestamptz default now();
  end if;
end $$;

-- ============ STATUS CHECK CONSTRAINTS ============
-- Fix orders status check to include all valid statuses
alter table public.orders drop constraint if exists orders_status_check;
alter table public.orders add constraint orders_status_check
  check (status in ('pending', 'stitching', 'trialing', 'alteration', 'ready', 'delivered', 'cancelled'));

-- Fix order_items status check to include all valid statuses
do $$
begin
  if exists (
    select 1 from information_schema.table_constraints
    where table_schema = 'public' and table_name = 'order_items' and constraint_name = 'order_items_status_check'
  ) then
    alter table public.order_items drop constraint order_items_status_check;
  end if;
end $$;
alter table public.order_items add constraint order_items_status_check
  check (status in ('pending', 'stitching', 'trialing', 'alteration', 'ready', 'delivered', 'cancelled'));

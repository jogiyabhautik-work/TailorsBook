-- TailorsBook Final Stabilization Migration
-- Ensures all required tables, columns, and policies are present safely.
-- Run this if any tables or columns are missing.

-- 1. App Update Table
CREATE TABLE IF NOT EXISTS public.app_update (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version TEXT NOT NULL,
    build_number INTEGER NOT NULL,
    force_update BOOLEAN DEFAULT FALSE,
    release_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Notification Logs Table
CREATE TABLE IF NOT EXISTS public.notification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Worker Tables (If missing)
CREATE TABLE IF NOT EXISTS public.workers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tailor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    salary_type TEXT NOT NULL CHECK (salary_type IN ('monthly', 'piece_rate')),
    monthly_rate NUMERIC(10, 2) DEFAULT 0.0,
    joining_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.worker_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL,
    worker_id UUID REFERENCES public.workers(id) ON DELETE CASCADE NOT NULL,
    assigned_by UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL DEFAULT 'assigned' CHECK (status IN ('assigned', 'in_progress', 'completed', 'received')),
    product_rates JSONB NOT NULL DEFAULT '{}'::jsonb,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    received_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.worker_earnings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id UUID REFERENCES public.workers(id) ON DELETE CASCADE NOT NULL,
    assignment_id UUID REFERENCES public.worker_assignments(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    earning_date DATE DEFAULT CURRENT_DATE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.worker_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id UUID REFERENCES public.workers(id) ON DELETE CASCADE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    payment_type TEXT NOT NULL CHECK (payment_type IN ('salary', 'advance')),
    payment_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.worker_work_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id UUID REFERENCES public.workers(id) ON DELETE CASCADE NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER DEFAULT 1 NOT NULL,
    rate_per_piece NUMERIC(10, 2) NOT NULL,
    total_amount NUMERIC(10, 2) GENERATED ALWAYS AS (quantity * rate_per_piece) STORED,
    work_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Ensure RLS is enabled for missing tables
ALTER TABLE public.app_update ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_work_log ENABLE ROW LEVEL SECURITY;

-- 5. Safe Policies (DROP IF EXISTS then CREATE)
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Public can read app_update" ON public.app_update;
    DROP POLICY IF EXISTS "Users can read own notification_logs" ON public.notification_logs;
    DROP POLICY IF EXISTS "Users can insert own notification_logs" ON public.notification_logs;
    DROP POLICY IF EXISTS "Users can update own notification_logs" ON public.notification_logs;
END $$;

CREATE POLICY "Public can read app_update" ON public.app_update FOR SELECT USING (true);
CREATE POLICY "Users can read own notification_logs" ON public.notification_logs FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own notification_logs" ON public.notification_logs FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own notification_logs" ON public.notification_logs FOR UPDATE USING (user_id = auth.uid());

-- Ensure worker policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can manage their own workers" ON public.workers;
    DROP POLICY IF EXISTS "Users can manage worker assignments" ON public.worker_assignments;
    DROP POLICY IF EXISTS "Users can manage worker earnings" ON public.worker_earnings;
    DROP POLICY IF EXISTS "Users can manage worker payments" ON public.worker_payments;
    DROP POLICY IF EXISTS "Users can manage worker work logs" ON public.worker_work_log;
END $$;

CREATE POLICY "Users can manage their own workers" ON public.workers FOR ALL USING (tailor_id = auth.uid());
CREATE POLICY "Users can manage worker assignments" ON public.worker_assignments FOR ALL USING (assigned_by = auth.uid());
CREATE POLICY "Users can manage worker earnings" ON public.worker_earnings FOR ALL USING (EXISTS (SELECT 1 FROM public.workers WHERE workers.id = worker_earnings.worker_id AND workers.tailor_id = auth.uid()));
CREATE POLICY "Users can manage worker payments" ON public.worker_payments FOR ALL USING (EXISTS (SELECT 1 FROM public.workers WHERE workers.id = worker_payments.worker_id AND workers.tailor_id = auth.uid()));
CREATE POLICY "Users can manage worker work logs" ON public.worker_work_log FOR ALL USING (EXISTS (SELECT 1 FROM public.workers WHERE workers.id = worker_work_log.worker_id AND workers.tailor_id = auth.uid()));

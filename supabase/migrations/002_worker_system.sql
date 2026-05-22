-- SQL Schema for Worker Management System in Supabase

-- 1. Workers table
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

-- 2. Worker work log (for piece-rate tracking)
CREATE TABLE IF NOT EXISTS public.worker_work_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id UUID REFERENCES public.workers(id) ON DELETE CASCADE NOT NULL,
    item_name TEXT NOT NULL, -- e.g., 'Shirt', 'Pant'
    quantity INTEGER DEFAULT 1 NOT NULL,
    rate_per_piece NUMERIC(10, 2) NOT NULL,
    total_amount NUMERIC(10, 2) GENERATED ALWAYS AS (quantity * rate_per_piece) STORED,
    work_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Worker payments (Salary & Advances)
CREATE TABLE IF NOT EXISTS public.worker_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id UUID REFERENCES public.workers(id) ON DELETE CASCADE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    payment_type TEXT NOT NULL CHECK (payment_type IN ('salary', 'advance')),
    payment_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. RLS (Row Level Security)
ALTER TABLE public.workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_work_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.worker_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own workers" ON public.workers
    FOR ALL USING (tailor_id = auth.uid());

CREATE POLICY "Users can manage work logs for their workers" ON public.worker_work_log
    FOR ALL USING (EXISTS (SELECT 1 FROM public.workers WHERE workers.id = worker_work_log.worker_id AND workers.tailor_id = auth.uid()));

CREATE POLICY "Users can manage payments for their workers" ON public.worker_payments
    FOR ALL USING (EXISTS (SELECT 1 FROM public.workers WHERE workers.id = worker_payments.worker_id AND workers.tailor_id = auth.uid()));

-- Migration: Add Measurement Templates, Measurement Records, Marketplace Templates, and Shop Expenses

-- 1. Create measurement_templates
CREATE TABLE IF NOT EXISTS public.measurement_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    tailor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    measurements JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create measurement_records
CREATE TABLE IF NOT EXISTS public.measurement_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE NOT NULL,
    customer_name TEXT NOT NULL,
    template_id TEXT NOT NULL, -- Stored as text to match either UUID or system template IDs like 'sys_blouse'
    template_name TEXT NOT NULL,
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    values JSONB NOT NULL DEFAULT '{}'::jsonb,
    stitching_instructions TEXT,
    tailor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create templates (for marketplace and sharing)
DROP TABLE IF EXISTS public.templates CASCADE;

CREATE TABLE IF NOT EXISTS public.templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    fitting_style TEXT,
    stitching_notes TEXT,
    measurements JSONB NOT NULL DEFAULT '{}'::jsonb,
    is_public BOOLEAN DEFAULT FALSE,
    download_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create shop_expenses
CREATE TABLE IF NOT EXISTS public.shop_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tailor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    category TEXT,
    notes TEXT,
    receipt_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.measurement_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.measurement_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_expenses ENABLE ROW LEVEL SECURITY;

-- Safety Drop and Create Policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Users can manage their own measurement templates" ON public.measurement_templates;
    DROP POLICY IF EXISTS "Users can manage their own measurement records" ON public.measurement_records;
    DROP POLICY IF EXISTS "Anyone can read public marketplace templates" ON public.templates;
    DROP POLICY IF EXISTS "Users can manage their own templates" ON public.templates;
    DROP POLICY IF EXISTS "Users can manage their own shop expenses" ON public.shop_expenses;
END $$;

-- 1. Policies for measurement_templates
CREATE POLICY "Users can manage their own measurement templates" 
ON public.measurement_templates 
FOR ALL USING (tailor_id = auth.uid()) WITH CHECK (tailor_id = auth.uid());

-- 2. Policies for measurement_records
CREATE POLICY "Users can manage their own measurement records" 
ON public.measurement_records 
FOR ALL USING (tailor_id = auth.uid()) WITH CHECK (tailor_id = auth.uid());

-- 3. Policies for templates (Marketplace)
CREATE POLICY "Anyone can read public marketplace templates" 
ON public.templates 
FOR SELECT USING (is_public = true OR user_id = auth.uid());

CREATE POLICY "Users can manage their own templates" 
ON public.templates 
FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 4. Policies for shop_expenses
CREATE POLICY "Users can manage their own shop expenses" 
ON public.shop_expenses 
FOR ALL USING (tailor_id = auth.uid()) WITH CHECK (tailor_id = auth.uid());

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_mt_tailor ON public.measurement_templates(tailor_id);
CREATE INDEX IF NOT EXISTS idx_mr_tailor ON public.measurement_records(tailor_id);
CREATE INDEX IF NOT EXISTS idx_mr_customer ON public.measurement_records(customer_id);
CREATE INDEX IF NOT EXISTS idx_templates_user ON public.templates(user_id);
CREATE INDEX IF NOT EXISTS idx_templates_public ON public.templates(is_public);
CREATE INDEX IF NOT EXISTS idx_se_tailor ON public.shop_expenses(tailor_id);

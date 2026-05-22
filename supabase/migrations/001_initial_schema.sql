-- ==========================================
-- FABRIC MANAGEMENT SYSTEM SCHEMA
-- ==========================================

-- 1. Shop Inventory (fabrics)
CREATE TABLE public.fabrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shop_id UUID NOT NULL, -- Ties to the authenticated tailor/shop owner
    name TEXT NOT NULL,
    fabric_type TEXT NOT NULL,
    color TEXT NOT NULL,
    quantity_meters NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    unit_price_per_meter NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Customer Provided Inventory (customer_fabrics)
CREATE TABLE public.customer_fabrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL, -- Should reference public.customers(id) if a hard FK is desired
    order_id UUID NOT NULL,    -- Should reference public.orders(id)
    fabric_type TEXT NOT NULL,
    color TEXT NOT NULL,
    quantity_meters NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    used_meters NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    notes TEXT,
    is_returned BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Order Item to Fabric Junction (order_item_fabrics)
CREATE TABLE public.order_item_fabrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_item_id UUID NOT NULL, -- Should reference public.order_items(id) ON DELETE CASCADE
    fabric_source TEXT NOT NULL CHECK (fabric_source IN ('SHOP', 'CUSTOMER')),
    shop_fabric_id UUID REFERENCES public.fabrics(id) ON DELETE SET NULL,
    customer_fabric_id UUID REFERENCES public.customer_fabrics(id) ON DELETE SET NULL,
    meters_allocated NUMERIC(10, 2) NOT NULL DEFAULT 0.0,
    purpose TEXT NOT NULL DEFAULT 'Main',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- ==========================================
-- WORKER ASSIGNMENT & PERFORMANCE SCHEMA
-- ==========================================

-- 4. Worker Assignments (worker_assignments)
CREATE TABLE public.worker_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_item_id UUID NOT NULL, -- Should reference public.order_items(id) ON DELETE CASCADE
    worker_id UUID NOT NULL,     -- Should reference public.workers(id) ON DELETE CASCADE
    status TEXT NOT NULL DEFAULT 'assigned' CHECK (status IN ('assigned', 'in_progress', 'completed', 'reassigned')),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    rework_count INTEGER NOT NULL DEFAULT 0,
    expected_completion_date TIMESTAMP WITH TIME ZONE
);

-- ==========================================
-- INDEXES FOR PERFORMANCE
-- ==========================================
CREATE INDEX idx_fabrics_shop ON public.fabrics(shop_id);
CREATE INDEX idx_cust_fabrics_cust ON public.customer_fabrics(customer_id);
CREATE INDEX idx_oif_order_item ON public.order_item_fabrics(order_item_id);
CREATE INDEX idx_wa_worker ON public.worker_assignments(worker_id);
CREATE INDEX idx_wa_order_item ON public.worker_assignments(order_item_id);

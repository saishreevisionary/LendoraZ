-- ========================================================
-- LENDORAZ ROLE-BASED ACCESS CONTROL SCHEMA (PRODUCTION-READY)
-- ========================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- 1. Core Structures
-- ==========================================

CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'inactive')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY, -- Matches auth.users.id
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE, -- Nullable for Super Admins
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  avatar_url TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'inactive')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 2. RBAC Tables
-- ==========================================

CREATE TABLE IF NOT EXISTS public.roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL, -- 'super_admin', 'company_owner', 'manager', 'collection_agent', 'accountant', 'customer'
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE IF NOT EXISTS public.permissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL, -- e.g. 'smart_collection_dashboard', 'ai_risk_prediction', etc.
  name TEXT NOT NULL,
  description TEXT
);

CREATE TABLE IF NOT EXISTS public.role_permissions (
  role_id UUID REFERENCES public.roles(id) ON DELETE CASCADE,
  permission_id UUID REFERENCES public.permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  role_id UUID REFERENCES public.roles(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

-- ==========================================
-- 3. Company Sub-Entities (People)
-- ==========================================

CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL, -- Nullable if not registered online yet
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  pan_number TEXT,
  aadhaar_number TEXT,
  credit_score INT DEFAULT 650,
  risk_level TEXT NOT NULL DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high')),
  address TEXT,
  geo_location JSONB, -- { "lat": double, "lng": double }
  assigned_agent_id UUID REFERENCES public.users(id) ON DELETE SET NULL, -- Maps to a Collection Agent user
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(company_id, phone)
);

CREATE TABLE IF NOT EXISTS public.agents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  phone TEXT,
  zone TEXT,
  status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS public.managers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  department TEXT
);

CREATE TABLE IF NOT EXISTS public.accountants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  employee_code TEXT
);

-- ==========================================
-- 4. Financial Domain
-- ==========================================

CREATE TABLE IF NOT EXISTS public.loans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE NOT NULL,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  principal_amount NUMERIC(15, 2) NOT NULL,
  interest_rate_annual NUMERIC(5, 2) NOT NULL,
  term_months INT NOT NULL,
  monthly_installment NUMERIC(15, 2) NOT NULL,
  remaining_balance NUMERIC(15, 2) NOT NULL,
  paid_balance NUMERIC(15, 2) DEFAULT 0.00,
  start_date DATE NOT NULL,
  due_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'defaulted', 'settled', 'closed')),
  collateral_type TEXT,
  collateral_details JSONB,
  missed_dues INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.collections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID REFERENCES public.loans(id) ON DELETE CASCADE NOT NULL,
  agent_id UUID REFERENCES public.users(id) ON DELETE SET NULL NOT NULL, -- Agent User who collected
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  amount NUMERIC(15, 2) NOT NULL,
  collection_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'upi', 'bank_transfer', 'cheque')),
  status TEXT NOT NULL DEFAULT 'success' CHECK (status IN ('success', 'pending', 'failed')),
  receipt_uuid UUID DEFAULT uuid_generate_v4(),
  notes TEXT,
  voice_note_url TEXT,
  geo_location JSONB, -- { "lat": double, "lng": double }
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  collection_id UUID REFERENCES public.collections(id) ON DELETE SET NULL, -- Linked collection if agent-led
  customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE NOT NULL,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  amount NUMERIC(15, 2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'success' CHECK (status IN ('success', 'pending', 'failed')),
  payment_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.receipts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  payment_id UUID REFERENCES public.payments(id) ON DELETE CASCADE NOT NULL,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  receipt_number TEXT UNIQUE NOT NULL,
  amount NUMERIC(15, 2) NOT NULL,
  file_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 5. Modules & Utilities
-- ==========================================

CREATE TABLE IF NOT EXISTS public.documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE NOT NULL,
  loan_id UUID REFERENCES public.loans(id) ON DELETE CASCADE,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  document_type TEXT NOT NULL CHECK (document_type IN ('aadhaar', 'pan', 'photo', 'promissory_note', 'agreement')),
  file_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.gold_loans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID REFERENCES public.loans(id) ON DELETE CASCADE NOT NULL,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  weight_grams NUMERIC(8, 3) NOT NULL,
  purity_karats INT NOT NULL CHECK (purity_karats BETWEEN 18 AND 24),
  valuation_amount NUMERIC(15, 2) NOT NULL,
  release_status TEXT DEFAULT 'pledged' CHECK (release_status IN ('pledged', 'released', 'auctioned')),
  item_images TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.chit_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  group_name TEXT NOT NULL UNIQUE,
  total_value NUMERIC(15, 2) NOT NULL,
  max_members INT NOT NULL,
  contribution_monthly NUMERIC(15, 2) NOT NULL,
  duration_months INT NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.crm_leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  requested_amount NUMERIC(15, 2),
  status TEXT NOT NULL DEFAULT 'new_lead' CHECK (status IN ('new_lead', 'contacted', 'interested', 'approved', 'rejected', 'converted')),
  assigned_to UUID REFERENCES public.users(id) ON DELETE SET NULL, -- Lead assigned to agent/user
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'unread' CHECK (status IN ('unread', 'read')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  actor_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_id TEXT,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.system_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 6. Helper Functions for RLS
-- ==========================================

CREATE OR REPLACE FUNCTION public.get_user_company_id()
RETURNS UUID AS $$
BEGIN
  RETURN (SELECT company_id FROM public.users WHERE id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT r.code 
    FROM public.user_roles ur 
    JOIN public.roles r ON ur.role_id = r.id 
    WHERE ur.user_id = auth.uid()
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.has_permission(perm_code TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM public.user_roles ur
    JOIN public.role_permissions rp ON ur.role_id = rp.role_id
    JOIN public.permissions p ON rp.permission_id = p.id
    WHERE ur.user_id = auth.uid() AND p.code = perm_code
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ==========================================
-- 7. Row Level Security Policies
-- ==========================================

-- Enable RLS on all tables
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.managers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accountants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gold_loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chit_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Dynamic Policies

-- Super Admin Bypass helper (returns true if current user is super_admin)
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (public.get_user_role() = 'super_admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 1. COMPANIES
CREATE POLICY "Super Admins manage all companies" ON public.companies
  FOR ALL USING (public.is_super_admin());

CREATE POLICY "Users view own company" ON public.companies
  FOR SELECT USING (id = public.get_user_company_id());


-- 2. USERS
CREATE POLICY "Super Admins manage all users" ON public.users
  FOR ALL USING (public.is_super_admin());

CREATE POLICY "Users view company-wide users" ON public.users
  FOR SELECT USING (company_id = public.get_user_company_id());

CREATE POLICY "Users update own profile" ON public.users
  FOR UPDATE USING (id = auth.uid());


-- 3. RBAC METADATA
CREATE POLICY "Read permissions allowed for all" ON public.permissions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Read roles allowed for all" ON public.roles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Read role_permissions allowed for all" ON public.role_permissions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Read user_roles allowed for all" ON public.user_roles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Super admin manages roles and permissions" ON public.roles FOR ALL USING (public.is_super_admin());
CREATE POLICY "Super admin manages permissions config" ON public.permissions FOR ALL USING (public.is_super_admin());
CREATE POLICY "Super admin maps role permissions" ON public.role_permissions FOR ALL USING (public.is_super_admin());
CREATE POLICY "Company Owner / Super Admin manage user roles" ON public.user_roles
  FOR ALL USING (public.is_super_admin() OR public.get_user_role() = 'company_owner');


-- 4. CUSTOMERS
CREATE POLICY "Customers view self" ON public.customers
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Agents view assigned customers" ON public.customers
  FOR SELECT USING (company_id = public.get_user_company_id() AND (assigned_agent_id = auth.uid() OR public.get_user_role() IN ('company_owner', 'manager', 'accountant')));

CREATE POLICY "Staff manages customers" ON public.customers
  FOR ALL USING (
    public.is_super_admin() OR 
    (company_id = public.get_user_company_id() AND public.get_user_role() IN ('company_owner', 'manager'))
  );


-- 5. LOANS
CREATE POLICY "Customers view own loans" ON public.loans
  FOR SELECT USING (
    customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid())
  );

CREATE POLICY "Agents view assigned loans" ON public.loans
  FOR SELECT USING (
    company_id = public.get_user_company_id() AND 
    (customer_id IN (SELECT id FROM public.customers WHERE assigned_agent_id = auth.uid()) 
     OR public.get_user_role() IN ('company_owner', 'manager', 'accountant'))
  );

CREATE POLICY "Owners and managers manage loans" ON public.loans
  FOR ALL USING (
    public.is_super_admin() OR 
    (company_id = public.get_user_company_id() AND public.get_user_role() IN ('company_owner', 'manager'))
  );


-- 6. COLLECTIONS
CREATE POLICY "Agents insert and view own collections" ON public.collections
  FOR ALL USING (
    company_id = public.get_user_company_id() AND 
    (agent_id = auth.uid() OR public.get_user_role() IN ('company_owner', 'manager', 'accountant'))
  );

CREATE POLICY "Super Admin manage collections" ON public.collections FOR ALL USING (public.is_super_admin());


-- 7. PAYMENTS & RECEIPTS
CREATE POLICY "Customers view own payments" ON public.payments
  FOR SELECT USING (customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid()));

CREATE POLICY "Staff view company payments" ON public.payments
  FOR ALL USING (
    public.is_super_admin() OR 
    (company_id = public.get_user_company_id() AND public.get_user_role() IN ('company_owner', 'manager', 'accountant', 'collection_agent'))
  );

CREATE POLICY "Customers view own receipts" ON public.receipts
  FOR SELECT USING (payment_id IN (SELECT id FROM public.payments WHERE customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid())));

CREATE POLICY "Staff view company receipts" ON public.receipts
  FOR ALL USING (
    public.is_super_admin() OR 
    (company_id = public.get_user_company_id() AND public.get_user_role() IN ('company_owner', 'manager', 'accountant', 'collection_agent'))
  );


-- 8. DOCUMENTS, GOLD LOANS, CHIT GROUPS, CRM LEADS, NOTIFICATIONS, AUDIT LOGS
CREATE POLICY "Documents policy" ON public.documents
  FOR ALL USING (
    public.is_super_admin() OR
    (company_id = public.get_user_company_id() AND (
      public.get_user_role() IN ('company_owner', 'manager') OR
      (public.get_user_role() = 'collection_agent' AND customer_id IN (SELECT id FROM public.customers WHERE assigned_agent_id = auth.uid())) OR
      (public.get_user_role() = 'customer' AND customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid()))
    ))
  );

CREATE POLICY "Gold Loans policy" ON public.gold_loans
  FOR ALL USING (
    public.is_super_admin() OR
    (company_id = public.get_user_company_id() AND public.get_user_role() IN ('company_owner', 'manager', 'accountant', 'collection_agent'))
  );

CREATE POLICY "Chit Groups policy" ON public.chit_groups
  FOR ALL USING (
    public.is_super_admin() OR
    (company_id = public.get_user_company_id() AND public.get_user_role() IN ('company_owner', 'manager', 'accountant', 'collection_agent'))
  );

CREATE POLICY "CRM Leads policy" ON public.crm_leads
  FOR ALL USING (
    public.is_super_admin() OR
    (company_id = public.get_user_company_id() AND (
      public.get_user_role() IN ('company_owner', 'manager') OR
      (public.get_user_role() = 'collection_agent') -- Allowed full access for leads
    ))
  );

CREATE POLICY "Notifications owner policy" ON public.notifications
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Audit Logs policy" ON public.audit_logs
  FOR SELECT USING (
    public.is_super_admin() OR 
    (company_id = public.get_user_company_id() AND public.get_user_role() = 'company_owner')
  );

CREATE POLICY "Super Admins manage system settings" ON public.system_settings
  FOR ALL USING (public.is_super_admin());

CREATE POLICY "All authenticated users view system settings" ON public.system_settings
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow public profiles inserts during signup" ON public.users
  FOR INSERT WITH CHECK (true);

-- ==========================================
-- 8. Automatically Map Profiles Trigger
-- ==========================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  default_role_id UUID;
  default_role_code TEXT;
  target_company_id UUID;
BEGIN
  -- Determine role from user metadata
  default_role_code := COALESCE(new.raw_user_meta_data->>'role', 'collection_agent');
  SELECT id INTO default_role_id FROM public.roles WHERE code = default_role_code;
  
  -- If role doesn't exist in roles metadata, default to collection_agent role
  IF default_role_id IS NULL THEN
    SELECT id INTO default_role_id FROM public.roles WHERE code = 'collection_agent';
  END IF;

  -- Read company_id from user metadata if provided, otherwise assign to first company
  IF new.raw_user_meta_data->>'company_id' IS NOT NULL THEN
    target_company_id := (new.raw_user_meta_data->>'company_id')::UUID;
  ELSE
    SELECT id INTO target_company_id FROM public.companies LIMIT 1;
  END IF;

  INSERT INTO public.users (id, company_id, email, full_name, status)
  VALUES (
    new.id,
    CASE WHEN default_role_code = 'super_admin' THEN NULL ELSE target_company_id END,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', new.email),
    'active'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name;

  INSERT INTO public.user_roles (user_id, role_id)
  VALUES (new.id, default_role_id)
  ON CONFLICT (user_id, role_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Bind trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- 9. Privileges and Access Control
-- ==========================================

-- Grant schema usage to standard database API roles
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- Set default privileges for any future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO service_role;

-- Explicit table-level privileges for authenticated users under RLS guard
GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.roles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.permissions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.role_permissions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_roles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.customers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.agents TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.managers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.accountants TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.loans TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.collections TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payments TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.receipts TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.documents TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.gold_loans TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.chit_groups TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.crm_leads TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.audit_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.system_settings TO authenticated;

-- Grant selective read-only table access to anonymous users (non-logged-in sessions)
GRANT SELECT ON public.permissions TO anon;
GRANT SELECT ON public.roles TO anon;
GRANT SELECT ON public.role_permissions TO anon;
GRANT SELECT ON public.user_roles TO anon;
GRANT SELECT ON public.users TO anon;

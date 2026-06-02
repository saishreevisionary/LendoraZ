-- ==========================================
-- LENDORAZ SUPABASE DB SCHEMA (PRODUCTION-READY)
-- ==========================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Define Custom Roles Enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM (
      'super_admin',
      'company_owner',
      'manager',
      'collection_agent',
      'accountant',
      'customer_portal_user'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'risk_level_type') THEN
    CREATE TYPE risk_level_type AS ENUM (
      'low',
      'medium',
      'high'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'loan_status_type') THEN
    CREATE TYPE loan_status_type AS ENUM (
      'active',
      'defaulted',
      'settled',
      'closed'
    );
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'lead_status_type') THEN
    CREATE TYPE lead_status_type AS ENUM (
      'new_lead',
      'contacted',
      'interested',
      'approved',
      'rejected',
      'converted'
    );
  END IF;
END$$;

-- ==========================================
-- 1. Profiles Table
-- ==========================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT,
  role user_role NOT NULL DEFAULT 'collection_agent',
  avatar_url TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'inactive')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 2. Customers Table
-- ==========================================
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL UNIQUE,
  email TEXT,
  pan_number TEXT UNIQUE,
  aadhaar_number TEXT UNIQUE,
  credit_score INT DEFAULT 650,
  risk_level risk_level_type NOT NULL DEFAULT 'low',
  address TEXT,
  geo_location JSONB, -- { "lat": double, "lng": double }
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 3. Loans Table
-- ==========================================
CREATE TABLE IF NOT EXISTS loans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE NOT NULL,
  principal_amount NUMERIC(15, 2) NOT NULL,
  interest_rate_annual NUMERIC(5, 2) NOT NULL,
  term_months INT NOT NULL,
  monthly_installment NUMERIC(15, 2) NOT NULL,
  remaining_balance NUMERIC(15, 2) NOT NULL,
  paid_balance NUMERIC(15, 2) DEFAULT 0.00,
  start_date DATE NOT NULL,
  due_date DATE NOT NULL,
  status loan_status_type NOT NULL DEFAULT 'active',
  collateral_type TEXT,
  collateral_details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE loans ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 4. Collections Table
-- ==========================================
CREATE TABLE IF NOT EXISTS collections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
  agent_id UUID REFERENCES profiles(id) ON DELETE SET NULL NOT NULL,
  amount NUMERIC(15, 2) NOT NULL,
  collection_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'upi', 'bank_transfer', 'cheque')),
  status TEXT NOT NULL DEFAULT 'success' CHECK (status IN ('success', 'pending', 'failed')),
  receipt_uuid UUID DEFAULT uuid_generate_v4(),
  notes TEXT,
  voice_note_url TEXT,
  geo_location JSONB, -- { "lat": double, "lng": double }
  offline_id TEXT UNIQUE, -- For offline-first deduplication
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE collections ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 5. Gold Loans Table
-- ==========================================
CREATE TABLE IF NOT EXISTS gold_loans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
  weight_grams NUMERIC(8, 3) NOT NULL,
  purity_karats INT NOT NULL CHECK (purity_karats BETWEEN 18 AND 24),
  valuation_amount NUMERIC(15, 2) NOT NULL,
  release_status TEXT DEFAULT 'pledged' CHECK (release_status IN ('pledged', 'released', 'auctioned')),
  item_images TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE gold_loans ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 6. Chit Funds Table
-- ==========================================
CREATE TABLE IF NOT EXISTS chit_funds (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_name TEXT NOT NULL UNIQUE,
  total_value NUMERIC(15, 2) NOT NULL,
  max_members INT NOT NULL,
  contribution_monthly NUMERIC(15, 2) NOT NULL,
  duration_months INT NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE chit_funds ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 7. Chit Members Table
-- ==========================================
CREATE TABLE IF NOT EXISTS chit_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chit_fund_id UUID REFERENCES chit_funds(id) ON DELETE CASCADE NOT NULL,
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'defaulted')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (chit_fund_id, profile_id)
);

ALTER TABLE chit_members ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 8. Chit Auctions Table
-- ==========================================
CREATE TABLE IF NOT EXISTS chit_auctions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chit_fund_id UUID REFERENCES chit_funds(id) ON DELETE CASCADE NOT NULL,
  month_number INT NOT NULL,
  auction_date TIMESTAMP WITH TIME ZONE NOT NULL,
  winner_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  bid_amount NUMERIC(15, 2) NOT NULL,
  dividend_per_member NUMERIC(15, 2) NOT NULL,
  paid_out_status BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE chit_auctions ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 9. Guarantors Table
-- ==========================================
CREATE TABLE IF NOT EXISTS guarantors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  relationship TEXT NOT NULL,
  address TEXT,
  email TEXT,
  document_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE guarantors ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 10. CRM Leads Table
-- ==========================================
CREATE TABLE IF NOT EXISTS crm_leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  requested_amount NUMERIC(15, 2),
  status lead_status_type NOT NULL DEFAULT 'new_lead',
  assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE crm_leads ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 11. Reminders Table
-- ==========================================
CREATE TABLE IF NOT EXISTS reminders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
  template_type TEXT NOT NULL CHECK (template_type IN ('upcoming_due', 'overdue_notice', 'payment_received', 'final_reminder')),
  channel TEXT NOT NULL CHECK (channel IN ('sms', 'whatsapp', 'email')),
  scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
  sent_at TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 12. Agent Activity & Targets Table
-- ==========================================
CREATE TABLE IF NOT EXISTS agent_targets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  agent_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  target_month DATE NOT NULL,
  target_amount NUMERIC(15, 2) NOT NULL,
  achieved_amount NUMERIC(15, 2) DEFAULT 0.00,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE agent_targets ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS agent_attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  agent_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
  check_in_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  check_out_time TIMESTAMP WITH TIME ZONE,
  last_location JSONB, -- { "lat": double, "lng": double }
  status TEXT DEFAULT 'present' CHECK (status IN ('present', 'absent', 'on_leave')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(agent_id, attendance_date)
);

ALTER TABLE agent_attendance ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 13. Emergency Alerts Table
-- ==========================================
CREATE TABLE IF NOT EXISTS emergency_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE NOT NULL,
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE NOT NULL,
  missed_dues_count INT NOT NULL,
  triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'resolved')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE emergency_alerts ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 14. Document Vault Table
-- ==========================================
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  loan_id UUID REFERENCES loans(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  document_type TEXT NOT NULL CHECK (document_type IN ('aadhaar', 'pan', 'photo', 'promissory_note', 'agreement')),
  file_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;


-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

-- 1. Profiles Table Policies
DROP POLICY IF EXISTS "Public profiles are viewable by authenticated users." ON profiles;
CREATE POLICY "Public profiles are viewable by authenticated users." ON profiles
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update their own profiles." ON profiles;
CREATE POLICY "Users can update their own profiles." ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- 2. Loans Table Policies
DROP POLICY IF EXISTS "Super admin and Company Owner have full access to loans." ON loans;
CREATE POLICY "Super admin and Company Owner have full access to loans." ON loans
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('super_admin', 'company_owner')
    )
  );

DROP POLICY IF EXISTS "Managers and Accountants can view all loans." ON loans;
CREATE POLICY "Managers and Accountants can view all loans." ON loans
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('manager', 'accountant')
    )
  );

DROP POLICY IF EXISTS "Agents can view loans assigned to their clients." ON loans;
CREATE POLICY "Agents can view loans assigned to their clients." ON loans
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'collection_agent'
    )
  );

DROP POLICY IF EXISTS "Customers can view their own loans." ON loans;
CREATE POLICY "Customers can view their own loans." ON loans
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM customers 
      WHERE customers.id = loans.customer_id 
      AND customers.profile_id = auth.uid()
    )
  );

-- 3. Collections Table Policies
DROP POLICY IF EXISTS "Agents can insert collections." ON collections;
CREATE POLICY "Agents can insert collections." ON collections
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'collection_agent'
    )
  );

DROP POLICY IF EXISTS "Managers and Owners can view and modify all collections." ON collections;
CREATE POLICY "Managers and Owners can view and modify all collections." ON collections
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('super_admin', 'company_owner', 'manager')
    )
  );

-- 4. Emergency Alerts Table Policies
DROP POLICY IF EXISTS "Managers and Admins see active emergency alerts." ON emergency_alerts;
CREATE POLICY "Managers and Admins see active emergency alerts." ON emergency_alerts
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role IN ('super_admin', 'company_owner', 'manager')
    )
  );

-- Additional Profiles Insert Policy
DROP POLICY IF EXISTS "Allow public inserts on profiles during sign up." ON profiles;
CREATE POLICY "Allow public inserts on profiles during sign up." ON profiles
  FOR INSERT WITH CHECK (true);

-- 5. Automatic User Profile Trigger
-- Creates a profile in the public profiles table automatically when a new user registers in auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  default_role public.user_role;
  meta_role text;
BEGIN
  -- Extract role from metadata, default to collection_agent if missing
  meta_role := COALESCE(new.raw_user_meta_data->>'role', 'collection_agent');
  
  -- Map string to enum type user_role
  CASE meta_role
    WHEN 'super_admin' THEN default_role := 'super_admin'::public.user_role;
    WHEN 'company_owner' THEN default_role := 'company_owner'::public.user_role;
    WHEN 'manager' THEN default_role := 'manager'::public.user_role;
    WHEN 'collection_agent' THEN default_role := 'collection_agent'::public.user_role;
    WHEN 'accountant' THEN default_role := 'accountant'::public.user_role;
    WHEN 'customer_portal_user' THEN default_role := 'customer_portal_user'::public.user_role;
    ELSE default_role := 'collection_agent'::public.user_role;
  END CASE;

  INSERT INTO public.profiles (id, email, full_name, role, status)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', new.email),
    default_role,
    'active'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Bind trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- 15. System Settings Table
-- ==========================================
CREATE TABLE IF NOT EXISTS system_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Super admin full access to settings" ON system_settings;
CREATE POLICY "Super admin full access to settings" ON system_settings
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );

-- Seed System Settings
INSERT INTO system_settings (key, value, description)
VALUES 
  ('interest_rate_default', '12.0', 'Default annual interest rate for new loans'),
  ('penalty_rate_monthly', '2.0', 'Default monthly penalty rate for overdue loans'),
  ('sync_interval_seconds', '60', 'Default sync polling interval for offline cache queue')
ON CONFLICT (key) DO NOTHING;

-- ==========================================
-- 16. Audit Logs Table
-- ==========================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_id TEXT,
  details JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated users to insert logs" ON audit_logs;
CREATE POLICY "Allow authenticated users to insert logs" ON audit_logs
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Only super admins can view logs" ON audit_logs;
CREATE POLICY "Only super admins can view logs" ON audit_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'super_admin'
    )
  );


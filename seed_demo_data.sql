-- ==========================================
-- LENDORAZ MOCK DATA SEEDING SCRIPT (RBAC UPDATE)
-- ==========================================

-- Clean existing records to prevent unique key errors on re-runs
TRUNCATE TABLE 
  public.audit_logs,
  public.notifications,
  public.crm_leads,
  public.chit_groups,
  public.gold_loans,
  public.documents,
  public.receipts,
  public.payments,
  public.collections,
  public.loans,
  public.customers,
  public.agents,
  public.managers,
  public.accountants,
  public.user_roles,
  public.role_permissions,
  public.permissions,
  public.roles,
  public.users,
  public.companies
  CASCADE;

-- Clear auth records for our test users to ensure fresh credentials
DELETE FROM auth.users WHERE email IN (
  'admin@lendoraz.com', 
  'owner@lendoraz.com', 
  'manager@lendoraz.com', 
  'agent@lendoraz.com', 
  'accountant@lendoraz.com', 
  'customer@lendoraz.com'
) OR id IN (
  '675da47d-16d0-4523-aebe-e38245a67dec',
  '22222222-2222-3333-4444-555566667777',
  '33333333-2222-3333-4444-555566667777',
  '55555555-6666-7777-8888-999999999999',
  '44444444-2222-3333-4444-555566667777',
  'a06c1111-2222-3333-4444-555566667777'
);

-- ==========================================
-- 1. Seed Company
-- ==========================================
INSERT INTO public.companies (id, name, status)
VALUES ('99999999-9999-9999-9999-999999999999', 'LendoraZ Ltd.', 'active');

-- ==========================================
-- 2. Seed Roles
-- ==========================================
INSERT INTO public.roles (id, code, name, description)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'super_admin', 'Super Admin', 'Platform Owner with full control over all companies.'),
  ('22222222-2222-2222-2222-222222222222', 'company_owner', 'Company Owner', 'Owner of the lending company with full tenant-level permissions.'),
  ('33333333-3333-3333-3333-333333333333', 'manager', 'Manager', 'Manages daily lending operations, assignments, and reports.'),
  ('44444444-4444-4444-4444-444444444444', 'collection_agent', 'Collection Agent', 'Field collection staff with restricted access to assigned customers.'),
  ('55555555-5555-5555-5555-555555555555', 'accountant', 'Accountant', 'Handles financial ledger, transactions, and statements.'),
  ('66666666-6666-6666-6666-666666666666', 'customer', 'Customer', 'Borrower accessing their own loan info and payment options.'),
  -- Future roles:
  ('77777777-7777-7777-7777-777777777777', 'branch_manager', 'Branch Manager', 'Future Role: Manages specific branch.'),
  ('88888888-8888-8888-8888-888888888888', 'recovery_officer', 'Recovery Officer', 'Future Role: Handles defaults and collection escalations.'),
  ('99999999-9999-9999-9999-999999999998', 'auditor', 'Auditor', 'Future Role: Verifies transaction logs and compliance.'),
  ('99999999-9999-9999-9999-999999999997', 'call_center_executive', 'Call Center Executive', 'Future Role: Tele-collections.');

-- ==========================================
-- 3. Seed Permissions
-- ==========================================
INSERT INTO public.permissions (code, name, description)
VALUES
  ('smart_collection_dashboard', 'Smart Collection Dashboard', 'Access owner/manager KPIs & summaries.'),
  ('ai_risk_prediction', 'AI Risk Prediction', 'View AI models and predictions of overdue risk.'),
  ('automated_reminders', 'Automated Reminders', 'Create/trigger SMS/WhatsApp templates.'),
  ('agent_management', 'Agent Management', 'Create, update, track agent profiles and locations.'),
  ('route_planner', 'Route Planner', 'Get field route optimization for collection tasks.'),
  ('voice_collection', 'Voice Collection', 'Transcribe and submit payment collections via speech.'),
  ('customer_timeline', 'Customer Timeline', 'Access customer interaction log stream.'),
  ('digital_receipts', 'Digital Receipts', 'Generate, store, and view digital payments slips.'),
  ('penalty_automation', 'Penalty Automation', 'Configure penalty fees and late terms.'),
  ('document_vault', 'Document Vault', 'Upload/view Aadhaar, PAN, and agreements.'),
  ('gold_loan_module', 'Gold Loan Module', 'Appraise and manage gold collateral items.'),
  ('chit_fund_module', 'Chit Fund Module', 'Manage savings groups, bids, and auctions.'),
  ('family_network', 'Family Network', 'Map co-borrowers and family contacts.'),
  ('collection_heat_map', 'Collection Heat Map', 'Visually analyze collection geographic hotspots.'),
  ('whatsapp_integration', 'WhatsApp Integration', 'Send reminders and templates directly to customer chat.'),
  ('customer_portal', 'Customer Portal', 'Access self-service loans desk.'),
  ('finance_crm', 'Finance CRM', 'Enter and track credit leads.'),
  ('emergency_alerts', 'Emergency Alerts', 'Receive urgent alerts for high missed dues count.'),
  ('predictive_cash_flow', 'Predictive Cash Flow', 'View historical collection flow analytics.'),
  ('reports', 'Reports', 'Generate and export finance reports.'),
  ('offline_mode', 'Offline Mode', 'Store data locally and queue writes when offline.');

-- ==========================================
-- 4. Map Permissions to Roles
-- ==========================================

-- Helper variables to hold role ids
DO $$
DECLARE
  v_owner UUID := '22222222-2222-2222-2222-222222222222';
  v_manager UUID := '33333333-3333-3333-3333-333333333333';
  v_agent UUID := '44444444-4444-4444-4444-444444444444';
  v_accountant UUID := '55555555-5555-5555-5555-555555555555';
  v_customer UUID := '66666666-6666-6666-6666-666666666666';
  v_perm RECORD;
BEGIN
  -- Company Owner gets ALL permissions
  FOR v_perm IN SELECT id FROM public.permissions LOOP
    INSERT INTO public.role_permissions (role_id, permission_id) VALUES (v_owner, v_perm.id);
  END LOOP;

  -- Manager permissions (everything except billing/subscription configurations)
  FOR v_perm IN SELECT id, code FROM public.permissions LOOP
    INSERT INTO public.role_permissions (role_id, permission_id) VALUES (v_manager, v_perm.id);
  END LOOP;

  -- Agent permissions (Restricted)
  INSERT INTO public.role_permissions (role_id, permission_id)
  SELECT v_agent, id FROM public.permissions 
  WHERE code IN (
    'ai_risk_prediction', 'automated_reminders', 'route_planner', 
    'voice_collection', 'customer_timeline', 'digital_receipts', 
    'document_vault', 'gold_loan_module', 'chit_fund_module', 
    'family_network', 'whatsapp_integration', 'finance_crm', 
    'emergency_alerts', 'reports', 'offline_mode'
  );

  -- Accountant permissions (Restricted to Ledger & Finances)
  INSERT INTO public.role_permissions (role_id, permission_id)
  SELECT v_accountant, id FROM public.permissions 
  WHERE code IN (
    'digital_receipts', 'gold_loan_module', 'chit_fund_module', 
    'predictive_cash_flow', 'reports', 'offline_mode'
  );

  -- Customer permissions (Self Service Only)
  INSERT INTO public.role_permissions (role_id, permission_id)
  SELECT v_customer, id FROM public.permissions 
  WHERE code IN (
    'customer_timeline', 'digital_receipts', 'document_vault', 
    'customer_portal', 'reports', 'offline_mode'
  );
END $$;

-- ==========================================
-- 5. Seed Auth Users (Default Password: password123)
-- ==========================================
-- Standard bcrypt hash for 'password123'
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, aud, role)
VALUES
  ('675da47d-16d0-4523-aebe-e38245a67dec', 'admin@lendoraz.com', '$2a$10$7EqJtDQegSLWhgAC170oKo94Y5MrxN1pY95/hhyzRYU5t6.1d5Ieq', now(), '{"provider":"email","providers":["email"]}', '{"full_name":"SSV Super Admin","role":"super_admin"}', 'authenticated', 'authenticated'),
  ('22222222-2222-3333-4444-555566667777', 'owner@lendoraz.com', '$2a$10$7EqJtDQegSLWhgAC170oKo94Y5MrxN1pY95/hhyzRYU5t6.1d5Ieq', now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Rajesh Singhal (Owner)","role":"company_owner","company_id":"99999999-9999-9999-9999-999999999999"}', 'authenticated', 'authenticated'),
  ('33333333-2222-3333-4444-555566667777', 'manager@lendoraz.com', '$2a$10$7EqJtDQegSLWhgAC170oKo94Y5MrxN1pY95/hhyzRYU5t6.1d5Ieq', now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Sarah D''Souza (Manager)","role":"manager","company_id":"99999999-9999-9999-9999-999999999999"}', 'authenticated', 'authenticated'),
  ('55555555-6666-7777-8888-999999999999', 'agent@lendoraz.com', '$2a$10$7EqJtDQegSLWhgAC170oKo94Y5MrxN1pY95/hhyzRYU5t6.1d5Ieq', now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Rohan Naik (Agent)","role":"collection_agent","company_id":"99999999-9999-9999-9999-999999999999"}', 'authenticated', 'authenticated'),
  ('44444444-2222-3333-4444-555566667777', 'accountant@lendoraz.com', '$2a$10$7EqJtDQegSLWhgAC170oKo94Y5MrxN1pY95/hhyzRYU5t6.1d5Ieq', now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Nisha Iyer (Accountant)","role":"accountant","company_id":"99999999-9999-9999-9999-999999999999"}', 'authenticated', 'authenticated'),
  ('a06c1111-2222-3333-4444-555566667777', 'customer@lendoraz.com', '$2a$10$7EqJtDQegSLWhgAC170oKo94Y5MrxN1pY95/hhyzRYU5t6.1d5Ieq', now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Ravi Kumar (Customer)","role":"customer","company_id":"99999999-9999-9999-9999-999999999999"}', 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- Explicitly seed public.users and public.user_roles to ensure the references exist 
-- even if auth.users already existed and trigger did not fire on INSERT conflict.
INSERT INTO public.users (id, company_id, email, full_name, status)
VALUES
  ('675da47d-16d0-4523-aebe-e38245a67dec', NULL, 'admin@lendoraz.com', 'SSV Super Admin', 'active'),
  ('22222222-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 'owner@lendoraz.com', 'Rajesh Singhal (Owner)', 'active'),
  ('33333333-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 'manager@lendoraz.com', 'Sarah D''Souza (Manager)', 'active'),
  ('55555555-6666-7777-8888-999999999999', '99999999-9999-9999-9999-999999999999', 'agent@lendoraz.com', 'Rohan Naik (Agent)', 'active'),
  ('44444444-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 'accountant@lendoraz.com', 'Nisha Iyer (Accountant)', 'active'),
  ('a06c1111-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 'customer@lendoraz.com', 'Ravi Kumar (Customer)', 'active')
ON CONFLICT (id) DO UPDATE SET
  company_id = EXCLUDED.company_id,
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  status = EXCLUDED.status;

INSERT INTO public.user_roles (user_id, role_id)
VALUES
  ('675da47d-16d0-4523-aebe-e38245a67dec', '11111111-1111-1111-1111-111111111111'), -- super_admin
  ('22222222-2222-3333-4444-555566667777', '22222222-2222-2222-2222-222222222222'), -- company_owner
  ('33333333-2222-3333-4444-555566667777', '33333333-3333-3333-3333-333333333333'), -- manager
  ('55555555-6666-7777-8888-999999999999', '44444444-4444-4444-4444-444444444444'), -- collection_agent
  ('44444444-2222-3333-4444-555566667777', '55555555-5555-5555-5555-555555555555'), -- accountant
  ('a06c1111-2222-3333-4444-555566667777', '66666666-6666-6666-6666-666666666666')  -- customer
ON CONFLICT (user_id, role_id) DO NOTHING;

-- ==========================================
-- 6. Seed Sub-Role Information Profiles
-- ==========================================
INSERT INTO public.agents (user_id, company_id, name, phone, zone, status)
VALUES ('55555555-6666-7777-8888-999999999999', '99999999-9999-9999-9999-999999999999', 'Rohan Naik (Agent)', '+91 99999 88888', 'East Bengaluru', 'active');

INSERT INTO public.managers (user_id, company_id, name, department)
VALUES ('33333333-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 'Sarah D''Souza (Manager)', 'Retail Loans');

INSERT INTO public.accountants (user_id, company_id, name, employee_code)
VALUES ('44444444-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 'Nisha Iyer (Accountant)', 'ACC-2026-99');

-- ==========================================
-- 7. Seed Customers, Loans & Financial Data
-- ==========================================
-- Note that customer user Ravi is linked to user_id. Other customers are just database rows for offline/agent-led tracking.
INSERT INTO public.customers (id, user_id, company_id, full_name, phone, email, pan_number, aadhaar_number, credit_score, risk_level, address, geo_location, assigned_agent_id)
VALUES
  ('a06c1111-2222-3333-4444-555566667777', 'a06c1111-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 'Ravi Kumar (Customer)', '+91 98765 43210', 'customer@lendoraz.com', 'ABCDE1234F', '1234-5678-9012', 720, 'low', 'Flat 402, Skyline Towers, Indiranagar, Bengaluru', '{"lat": 12.9716, "lng": 77.5946}', '55555555-6666-7777-8888-999999999999'),
  ('a06c2222-3333-4444-5555-666677778888', NULL, '99999999-9999-9999-9999-999999999999', 'Ananya Sharma', '+91 98765 00123', 'ananya@gmail.com', 'FGHIJ5678K', '5678-9012-3456', 610, 'medium', 'Sector 15, HSR Layout, Bengaluru', '{"lat": 12.9141, "lng": 77.6413}', '55555555-6666-7777-8888-999999999999'),
  ('a06c3333-4444-5555-6666-777788889999', NULL, '99999999-9999-9999-9999-999999999999', 'Vikram Malhotra', '+91 91234 56789', 'vikram@yahoo.com', 'KLMNO9012P', '9012-3456-7890', 480, 'high', 'B-302, Green Glen Layout, Bellandur, Bengaluru', '{"lat": 12.9279, "lng": 77.6822}', '55555555-6666-7777-8888-999999999999')
ON CONFLICT (company_id, phone) DO NOTHING;

-- Seed Loans
INSERT INTO public.loans (id, customer_id, company_id, principal_amount, interest_rate_annual, term_months, monthly_installment, remaining_balance, paid_balance, start_date, due_date, status, collateral_type, missed_dues)
VALUES
  ('b06c1111-2222-3333-4444-555566667777', 'a06c1111-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 500000.00, 12.0, 24, 23536.00, 320000.00, 180000.00, '2025-06-01', '2027-06-01', 'active', 'gold', 0),
  ('b06c2222-3333-4444-5555-666677778888', 'a06c2222-3333-4444-5555-666677778888', '99999999-9999-9999-9999-999999999999', 200000.00, 15.0, 12, 18051.00, 90255.00, 126357.00, '2025-11-01', '2026-11-01', 'active', 'none', 2),
  ('b06c3333-4444-5555-6666-777788889999', 'a06c3333-4444-5555-6666-777788889999', '99999999-9999-9999-9999-999999999999', 150000.00, 18.0, 12, 13750.00, 110000.00, 27500.00, '2026-01-01', '2027-01-01', 'defaulted', 'chit', 5)
ON CONFLICT (id) DO NOTHING;

-- Seed Collections
INSERT INTO public.collections (id, loan_id, agent_id, company_id, amount, collection_date, payment_method, status, receipt_uuid, notes, geo_location)
VALUES
  ('c06c1111-2222-3333-4444-555566667777', 'b06c1111-2222-3333-4444-555566667777', '55555555-6666-7777-8888-999999999999', '99999999-9999-9999-9999-999999999999', 23536.00, '2026-06-02 10:00:00+00', 'upi', 'success', '861a457c-d38a-4469-80fb-129b008d745e', 'Paid via PhonePe successfully.', '{"lat": 12.9719, "lng": 77.5937}'),
  ('c06c2222-3333-4444-5555-666677778888', 'b06c2222-3333-4444-5555-666677778888', '55555555-6666-7777-8888-999999999999', '99999999-9999-9999-9999-999999999999', 10000.00, '2026-06-01 15:30:00+00', 'cash', 'success', '91a27e7f-71ba-4433-a309-8b0bbcb4b8d7', 'Part payment collected in cash.', '{"lat": 12.9145, "lng": 77.6410}')
ON CONFLICT (id) DO NOTHING;

-- Seed Payments (Corresponds to collections)
INSERT INTO public.payments (id, collection_id, customer_id, company_id, amount, status, payment_date)
VALUES
  ('33f01111-2222-3333-4444-555566667777', 'c06c1111-2222-3333-4444-555566667777', 'a06c1111-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 23536.00, 'success', '2026-06-02 10:00:00+00'),
  ('33f02222-3333-4444-5555-666677778888', 'c06c2222-3333-4444-5555-666677778888', 'a06c2222-3333-4444-5555-666677778888', '99999999-9999-9999-9999-999999999999', 10000.00, 'success', '2026-06-01 15:30:00+00')
ON CONFLICT (id) DO NOTHING;

-- Seed Receipts
INSERT INTO public.receipts (id, payment_id, company_id, receipt_number, amount)
VALUES
  ('44f01111-2222-3333-4444-555566667777', '33f01111-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 'REC-2026-100234', 23536.00),
  ('44f02222-3333-4444-5555-666677778888', '33f02222-3333-4444-5555-666677778888', '99999999-9999-9999-9999-999999999999', 'REC-2026-100235', 10000.00)
ON CONFLICT (id) DO NOTHING;

-- Seed CRM Leads
INSERT INTO public.crm_leads (id, company_id, full_name, phone, email, requested_amount, status, assigned_to, notes)
VALUES
  ('e06c1111-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 'Kartik Aaryan', '+91 88990 12345', 'kartik@gmail.com', 300000.00, 'new_lead', '55555555-6666-7777-8888-999999999999', 'Applied online for Business Expansion.'),
  ('e06c2222-3333-4444-5555-666677778888', '99999999-9999-9999-9999-999999999999', 'Meera Sen', '+91 77665 43210', 'meera@gmail.com', 100000.00, 'contacted', '55555555-6666-7777-8888-999999999999', 'Called customer, requested documents.'),
  ('e06c3333-4444-5555-6666-777788889999', '99999999-9999-9999-9999-999999999999', 'Sanjay Dutt', '+91 99009 88776', 'sanjay@rediff.com', 750000.00, 'approved', '55555555-6666-7777-8888-999999999999', 'Documents verified, pending signature.')
ON CONFLICT (id) DO NOTHING;

-- Seed Gold Loans
INSERT INTO public.gold_loans (id, loan_id, company_id, weight_grams, purity_karats, valuation_amount, release_status, item_images)
VALUES
  ('106c1111-2222-3333-4444-555566667777', 'b06c1111-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 120.500, 22, 780000.00, 'pledged', ARRAY['https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?q=80&w=400'])
ON CONFLICT (id) DO NOTHING;

-- Seed Chit Groups
INSERT INTO public.chit_groups (id, company_id, group_name, total_value, max_members, contribution_monthly, duration_months, status)
VALUES
  ('c0001111-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 'Indiranagar Premium Savings', 1000000.00, 20, 50000.00, 20, 'active')
ON CONFLICT (id) DO NOTHING;

-- Seed Documents
INSERT INTO public.documents (id, customer_id, loan_id, company_id, name, document_type, file_url)
VALUES
  ('900c1111-2222-3333-4444-555566667777', 'a06c1111-2222-3333-4444-555566667777', 'b06c1111-2222-3333-4444-555566667777', '99999999-9999-9999-9999-999999999999', 'Promissory Note - Ravi', 'promissory_note', 'https://lendoraz.com/vault/note_ravi.pdf')
ON CONFLICT (id) DO NOTHING;

-- Seed Notifications
INSERT INTO public.notifications (id, user_id, company_id, title, message, status)
VALUES
  ('f00c1111-2222-3333-4444-555566667777', '55555555-6666-7777-8888-999999999999', '99999999-9999-9999-9999-999999999999', 'Daily Route Seeding', 'Your route planner for Indiranagar is ready.', 'unread')
ON CONFLICT (id) DO NOTHING;

-- Seed System Settings
INSERT INTO public.system_settings (key, value, description)
VALUES
  ('interest_rate_default', '12.0', 'Default annual interest rate for new loans'),
  ('penalty_rate_monthly', '2.0', 'Default monthly penalty rate for overdue loans'),
  ('sync_interval_seconds', '60', 'Default sync polling interval for offline cache queue')
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description;

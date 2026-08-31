-- Create Supabase SQL migration script for a Tally-style Chart of Accounts

-- 1. Create account_groups table
CREATE TABLE IF NOT EXISTS public.account_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    parent_id UUID REFERENCES public.account_groups(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('asset', 'liability', 'income', 'expense')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS) on account_groups
ALTER TABLE public.account_groups ENABLE ROW LEVEL SECURITY;

-- Create policy for public access or authenticated users (adjust as needed for your app)
CREATE POLICY "Enable read access for all users" ON public.account_groups FOR SELECT USING (true);
CREATE POLICY "Enable insert/update/delete for authenticated users" ON public.account_groups FOR ALL USING (auth.role() = 'authenticated');

-- 2. Create ledgers table
CREATE TABLE IF NOT EXISTS public.ledgers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    group_id UUID NOT NULL REFERENCES public.account_groups(id) ON DELETE RESTRICT,
    opening_balance NUMERIC(15, 2) DEFAULT 0.00 NOT NULL,
    current_balance NUMERIC(15, 2) DEFAULT 0.00 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS) on ledgers
ALTER TABLE public.ledgers ENABLE ROW LEVEL SECURITY;

-- Create policy for ledgers
CREATE POLICY "Enable read access for all users" ON public.ledgers FOR SELECT USING (true);
CREATE POLICY "Enable insert/update/delete for authenticated users" ON public.ledgers FOR ALL USING (auth.role() = 'authenticated');

-- 3. Insert default primary groups
-- Primary groups: Assets, Liabilities, Income, Expenses
INSERT INTO public.account_groups (id, name, parent_id, type) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Assets', NULL, 'asset'),
    ('a0000000-0000-0000-0000-000000000002', 'Liabilities', NULL, 'liability'),
    ('a0000000-0000-0000-0000-000000000003', 'Income', NULL, 'income'),
    ('a0000000-0000-0000-0000-000000000004', 'Expenses', NULL, 'expense')
ON CONFLICT (name) DO NOTHING;

-- Sub-groups: Sundry Debtors, Sundry Creditors (under Liabilities or Assets), Cash-in-Hand, Bank Accounts (under Assets)
INSERT INTO public.account_groups (id, name, parent_id, type) VALUES
    ('a0000000-0000-0000-0000-000000000005', 'Sundry Debtors', 'a0000000-0000-0000-0000-000000000001', 'asset'),
    ('a0000000-0000-0000-0000-000000000006', 'Sundry Creditors', 'a0000000-0000-0000-0000-000000000002', 'liability'),
    ('a0000000-0000-0000-0000-000000000007', 'Cash-in-Hand', 'a0000000-0000-0000-0000-000000000001', 'asset'),
    ('a0000000-0000-0000-0000-000000000008', 'Bank Accounts', 'a0000000-0000-0000-0000-000000000001', 'asset')
ON CONFLICT (name) DO NOTHING;

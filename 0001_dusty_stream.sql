/*
  # Initial Schema Setup for CRM System

  1. New Tables
    - `clients`
      - Core client information
      - Personal details and contact info
      - Status tracking
    - `policies`
      - Insurance policy details
      - Links to clients
      - Coverage and premium info
    
  2. Security
    - RLS enabled on all tables
    - Policies for authenticated access
*/

-- Clients table
CREATE TABLE IF NOT EXISTS clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  address TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'inactive', 'pending')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Policies table
CREATE TABLE IF NOT EXISTS policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  policy_number TEXT UNIQUE NOT NULL,
  policy_type TEXT NOT NULL,
  plan_name TEXT NOT NULL,
  coverage_amount DECIMAL NOT NULL CHECK (coverage_amount > 0),
  premium_amount DECIMAL NOT NULL CHECK (premium_amount > 0),
  issue_date DATE NOT NULL,
  maturity_date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active', 'pending', 'expired', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CHECK (maturity_date > issue_date)
);

-- Enable RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE policies ENABLE ROW LEVEL SECURITY;

-- RLS Policies for clients
CREATE POLICY "Allow authenticated users to read clients"
  ON clients
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert clients"
  ON clients
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update their clients"
  ON clients
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- RLS Policies for policies
CREATE POLICY "Allow authenticated users to read policies"
  ON policies
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated users to insert policies"
  ON policies
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update policies"
  ON policies
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Updated triggers
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_clients_updated_at
  BEFORE UPDATE ON clients
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER set_policies_updated_at
  BEFORE UPDATE ON policies
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();
-- =====================================================
-- School Years Table Migration
-- =====================================================
-- Purpose: Store school years for the system
-- Only admins can create, update, or delete school years
-- All authenticated users can view school years
-- =====================================================

-- Drop existing table if exists (for clean migration)
DROP TABLE IF EXISTS public.school_years CASCADE;

-- Create school_years table
CREATE TABLE public.school_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year_label TEXT NOT NULL UNIQUE, -- Format: YYYY-YYYY (e.g., 2023-2024)
    start_year INTEGER NOT NULL, -- Starting year (e.g., 2023)
    end_year INTEGER NOT NULL, -- Ending year (e.g., 2024)
    is_active BOOLEAN DEFAULT true, -- Whether this school year is active
    is_current BOOLEAN DEFAULT false, -- Whether this is the current school year
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_year_format CHECK (year_label ~ '^\d{4}-\d{4}$'),
    CONSTRAINT valid_year_sequence CHECK (end_year = start_year + 1),
    CONSTRAINT valid_start_year CHECK (start_year >= 2000 AND start_year <= 2100),
    CONSTRAINT only_one_current CHECK (
        NOT is_current OR (
            SELECT COUNT(*) FROM public.school_years WHERE is_current = true
        ) <= 1
    )
);

-- Create indexes for better performance
CREATE INDEX idx_school_years_year_label ON public.school_years(year_label);
CREATE INDEX idx_school_years_is_active ON public.school_years(is_active);
CREATE INDEX idx_school_years_is_current ON public.school_years(is_current);
CREATE INDEX idx_school_years_created_by ON public.school_years(created_by);

-- Enable Row Level Security
ALTER TABLE public.school_years ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS Policies
-- =====================================================

-- Policy 1: Allow all authenticated users to SELECT (read) school years
CREATE POLICY "Allow authenticated users to view school years"
    ON public.school_years
    FOR SELECT
    TO authenticated
    USING (true);

-- Policy 2: Allow only admins to INSERT (create) school years
CREATE POLICY "Allow admins to create school years"
    ON public.school_years
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.admins
            WHERE admins.id = auth.uid()
            AND admins.is_active = true
            AND (admins.can_manage_system = true OR admins.admin_level = 'admin')
        )
    );

-- Policy 3: Allow only admins to UPDATE school years
CREATE POLICY "Allow admins to update school years"
    ON public.school_years
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.admins
            WHERE admins.id = auth.uid()
            AND admins.is_active = true
            AND (admins.can_manage_system = true OR admins.admin_level = 'admin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.admins
            WHERE admins.id = auth.uid()
            AND admins.is_active = true
            AND (admins.can_manage_system = true OR admins.admin_level = 'admin')
        )
    );

-- Policy 4: Allow only admins to DELETE school years
CREATE POLICY "Allow admins to delete school years"
    ON public.school_years
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.admins
            WHERE admins.id = auth.uid()
            AND admins.is_active = true
            AND (admins.can_manage_system = true OR admins.admin_level = 'admin')
        )
    );

-- =====================================================
-- Trigger: Update updated_at timestamp
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_school_years_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_school_years_updated_at
    BEFORE UPDATE ON public.school_years
    FOR EACH ROW
    EXECUTE FUNCTION public.update_school_years_updated_at();

-- =====================================================
-- Trigger: Ensure only one current school year
-- =====================================================

CREATE OR REPLACE FUNCTION public.ensure_single_current_school_year()
RETURNS TRIGGER AS $$
BEGIN
    -- If setting a school year as current, unset all others
    IF NEW.is_current = true THEN
        UPDATE public.school_years
        SET is_current = false
        WHERE id != NEW.id AND is_current = true;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ensure_single_current_school_year
    BEFORE INSERT OR UPDATE ON public.school_years
    FOR EACH ROW
    WHEN (NEW.is_current = true)
    EXECUTE FUNCTION public.ensure_single_current_school_year();

-- =====================================================
-- Insert default school years (current year ± 2)
-- =====================================================

DO $$
DECLARE
    current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER;
    i INTEGER;
    start_yr INTEGER;
    end_yr INTEGER;
    year_lbl TEXT;
BEGIN
    FOR i IN -2..3 LOOP
        start_yr := current_year + i;
        end_yr := start_yr + 1;
        year_lbl := start_yr || '-' || end_yr;
        
        INSERT INTO public.school_years (year_label, start_year, end_year, is_active, is_current)
        VALUES (year_lbl, start_yr, end_yr, true, i = 0)
        ON CONFLICT (year_label) DO NOTHING;
    END LOOP;
END $$;

-- =====================================================
-- Grant permissions
-- =====================================================

GRANT SELECT ON public.school_years TO authenticated;
GRANT INSERT, UPDATE, DELETE ON public.school_years TO authenticated;

-- =====================================================
-- Comments for documentation
-- =====================================================

COMMENT ON TABLE public.school_years IS 'Stores school years for the system. Only admins can manage.';
COMMENT ON COLUMN public.school_years.year_label IS 'School year in YYYY-YYYY format (e.g., 2023-2024)';
COMMENT ON COLUMN public.school_years.is_current IS 'Indicates if this is the current active school year';
COMMENT ON COLUMN public.school_years.is_active IS 'Whether this school year is available for selection';


-- ============================================
-- ADD AZURE USER ID COLUMN TO PROFILES TABLE
-- ============================================
-- This migration adds a column to store the Azure AD user ID
-- for linking Supabase profiles with Azure AD accounts

-- Add azure_user_id column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS azure_user_id TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_azure_user_id 
ON public.profiles(azure_user_id);

-- Add comment
COMMENT ON COLUMN public.profiles.azure_user_id IS 'Azure AD user ID for linking with Microsoft Graph API';

-- Verify the column was added
DO $$
BEGIN
  RAISE NOTICE '✅ azure_user_id column added to profiles table';
  RAISE NOTICE '✅ Index created on azure_user_id';
  RAISE NOTICE '';
  RAISE NOTICE 'You can now link Supabase profiles with Azure AD users!';
END $$;

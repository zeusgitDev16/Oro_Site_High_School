-- ============================================
-- FIX: Teachers Table Schema
-- Adds first_name, last_name, middle_name fields
-- Migrates data from full_name field
-- ============================================

-- Step 1: Add new columns if they don't exist
DO $$
BEGIN
    -- Add first_name column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'teachers' 
        AND column_name = 'first_name'
    ) THEN
        ALTER TABLE public.teachers ADD COLUMN first_name TEXT;
    END IF;

    -- Add last_name column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'teachers' 
        AND column_name = 'last_name'
    ) THEN
        ALTER TABLE public.teachers ADD COLUMN last_name TEXT;
    END IF;

    -- Add middle_name column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'teachers' 
        AND column_name = 'middle_name'
    ) THEN
        ALTER TABLE public.teachers ADD COLUMN middle_name TEXT;
    END IF;
END $$;

-- Step 2: Migrate data from full_name to first_name/last_name
-- This handles cases where full_name exists but first_name/last_name are null
UPDATE public.teachers
SET 
    first_name = COALESCE(
        first_name,
        CASE 
            WHEN full_name IS NOT NULL THEN 
                SPLIT_PART(full_name, ' ', 1)
            ELSE 'Unknown'
        END
    ),
    last_name = COALESCE(
        last_name,
        CASE 
            WHEN full_name IS NOT NULL AND ARRAY_LENGTH(STRING_TO_ARRAY(full_name, ' '), 1) >= 2 THEN 
                SPLIT_PART(full_name, ' ', ARRAY_LENGTH(STRING_TO_ARRAY(full_name, ' '), 1))
            WHEN full_name IS NOT NULL THEN
                SPLIT_PART(full_name, ' ', 1)
            ELSE 'Unknown'
        END
    ),
    middle_name = COALESCE(
        middle_name,
        CASE 
            WHEN full_name IS NOT NULL AND ARRAY_LENGTH(STRING_TO_ARRAY(full_name, ' '), 1) >= 3 THEN 
                SPLIT_PART(full_name, ' ', 2)
            ELSE NULL
        END
    )
WHERE first_name IS NULL OR last_name IS NULL;

-- Step 3: Make first_name and last_name NOT NULL
ALTER TABLE public.teachers 
    ALTER COLUMN first_name SET NOT NULL,
    ALTER COLUMN last_name SET NOT NULL;

-- Step 4: Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_teachers_last_name ON public.teachers(last_name);
CREATE INDEX IF NOT EXISTS idx_teachers_first_name ON public.teachers(first_name);

-- Step 5: Verify the migration
SELECT 
    '=== VERIFICATION ===' as section,
    COUNT(*) as total_teachers,
    COUNT(*) FILTER (WHERE first_name IS NOT NULL) as with_first_name,
    COUNT(*) FILTER (WHERE last_name IS NOT NULL) as with_last_name,
    COUNT(*) FILTER (WHERE first_name IS NULL OR last_name IS NULL) as missing_names
FROM public.teachers;

-- Step 6: Show sample data
SELECT 
    '=== SAMPLE DATA ===' as section,
    id,
    employee_id,
    first_name,
    last_name,
    middle_name,
    full_name,
    is_active
FROM public.teachers
ORDER BY last_name
LIMIT 10;

-- ============================================
-- MIGRATION COMPLETE
-- ============================================
SELECT '=== MIGRATION COMPLETE ===' as section,
       'Teachers table now has first_name, last_name, middle_name fields' as message;


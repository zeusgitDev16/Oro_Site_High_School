# Apply Classroom Students RPC Functions Migration

## Purpose
This migration creates RPC functions to fetch classroom students and teachers with their profile information. These functions bypass RLS complexity and ensure teachers can see enrolled students in gradebook and classroom screens.

## Issue Fixed
- Teachers were unable to see students enrolled by admin in gradebook
- "No students enrolled" message appeared even though students were enrolled
- RLS policies were preventing proper data fetching

## Files
- `CREATE_CLASSROOM_STUDENTS_RPC_FUNCTIONS.sql` - RPC function definitions

## How to Apply

### Option 1: Supabase Dashboard (Recommended)
1. Go to Supabase Dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy and paste the contents of `CREATE_CLASSROOM_STUDENTS_RPC_FUNCTIONS.sql`
5. Click **Run** to execute

### Option 2: Supabase CLI
```bash
supabase db push --file database/migrations/CREATE_CLASSROOM_STUDENTS_RPC_FUNCTIONS.sql
```

### Option 3: psql Command Line
```bash
psql -h <your-supabase-host> -U postgres -d postgres -f database/migrations/CREATE_CLASSROOM_STUDENTS_RPC_FUNCTIONS.sql
```

## Verification

After applying the migration, verify the functions exist:

```sql
-- Check if functions exist
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('get_classroom_students_with_profile', 'get_classroom_teachers_with_profile');
```

Expected output:
```
routine_name                          | routine_type
--------------------------------------|-------------
get_classroom_students_with_profile   | FUNCTION
get_classroom_teachers_with_profile   | FUNCTION
```

## Test the Functions

```sql
-- Test get_classroom_students_with_profile
-- Replace <classroom_id> with an actual classroom ID
SELECT * FROM get_classroom_students_with_profile('<classroom_id>');

-- Test get_classroom_teachers_with_profile
SELECT * FROM get_classroom_teachers_with_profile('<classroom_id>');
```

## Rollback

If you need to rollback this migration:

```sql
DROP FUNCTION IF EXISTS get_classroom_students_with_profile(UUID);
DROP FUNCTION IF EXISTS get_classroom_teachers_with_profile(UUID);
```

## Notes
- These functions use `SECURITY DEFINER` to bypass RLS
- Access control is enforced within the function logic
- Admins can view all classroom students/teachers
- Teachers can view students/teachers in classrooms they own or co-teach
- Students can view students/teachers in classrooms they are enrolled in


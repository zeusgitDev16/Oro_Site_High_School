# 📋 How to Apply Assignment Time Columns Migration

## **Migration File**: `add_assignment_time_columns.sql`

---

## **Option 1: Apply via Supabase Dashboard (Recommended)**

### **Steps**:

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your project: `aezycreative@gmail.com's Project`

2. **Navigate to SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "New query"

3. **Copy Migration SQL**
   - Open `database/migrations/add_assignment_time_columns.sql`
   - Copy the entire contents

4. **Paste and Run**
   - Paste the SQL into the editor
   - Click "Run" button
   - Wait for success message

5. **Verify Migration**
   - Run verification queries (included at bottom of migration file)
   - Check that columns exist:
     ```sql
     SELECT column_name, data_type, is_nullable
     FROM information_schema.columns
     WHERE table_name = 'assignments' 
     AND column_name IN ('start_time', 'end_time');
     ```

---

## **Option 2: Apply via Supabase CLI**

### **Prerequisites**:
- Supabase CLI installed: `npm install -g supabase`
- Logged in: `supabase login`

### **Steps**:

1. **Link to Project**
   ```bash
   supabase link --project-ref fhqzohvtioosycaafnij
   ```

2. **Apply Migration**
   ```bash
   supabase db push
   ```

---

## **Option 3: Apply via Supabase Tool (from code)**

### **Steps**:

1. **Run from Flutter app** (one-time setup):
   ```dart
   final supabase = Supabase.instance.client;
   
   // Read migration file
   final migrationSql = await rootBundle.loadString(
     'database/migrations/add_assignment_time_columns.sql'
   );
   
   // Execute migration
   await supabase.rpc('exec_sql', params: {'sql': migrationSql});
   ```

---

## **Verification**

After applying the migration, verify it worked:

### **1. Check Columns Exist**
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'assignments' 
AND column_name IN ('start_time', 'end_time');
```

**Expected Output**:
```
column_name | data_type                   | is_nullable
------------|----------------------------|------------
start_time  | timestamp with time zone   | YES
end_time    | timestamp with time zone   | YES
```

### **2. Check Constraint Exists**
```sql
SELECT constraint_name, check_clause
FROM information_schema.check_constraints
WHERE constraint_name = 'check_assignment_timeline';
```

**Expected Output**:
```
constraint_name           | check_clause
--------------------------|------------------
check_assignment_timeline | (start_time IS NULL OR ...)
```

### **3. Check Indexes Exist**
```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'assignments'
AND indexname LIKE '%time%';
```

**Expected Output**:
```
indexname                          | indexdef
-----------------------------------|------------------
idx_assignments_start_time         | CREATE INDEX ...
idx_assignments_end_time           | CREATE INDEX ...
idx_assignments_active_time_range  | CREATE INDEX ...
```

### **4. Test Helper Function**
```sql
SELECT public.get_assignment_status(
  now() - INTERVAL '1 day',  -- start_time (past)
  now() + INTERVAL '7 days', -- due_date (future)
  now() + INTERVAL '14 days', -- end_time (future)
  true                        -- allow_late
);
```

**Expected Output**: `'active'`

---

## **Rollback (if needed)**

If you need to rollback this migration:

```sql
-- Drop helper function
DROP FUNCTION IF EXISTS public.get_assignment_status;

-- Drop indexes
DROP INDEX IF EXISTS public.idx_assignments_start_time;
DROP INDEX IF EXISTS public.idx_assignments_end_time;
DROP INDEX IF EXISTS public.idx_assignments_active_time_range;

-- Drop constraint
ALTER TABLE public.assignments
DROP CONSTRAINT IF EXISTS check_assignment_timeline;

-- Drop columns
ALTER TABLE public.assignments
DROP COLUMN IF EXISTS start_time,
DROP COLUMN IF EXISTS end_time;
```

---

## **Next Steps**

After successful migration:
1. ✅ Proceed to **Task 2**: Update Assignment Service
2. ✅ Update Flutter app to use new columns
3. ✅ Test assignment creation with time fields

---

## **Notes**

- **Backward Compatible**: Existing assignments will have `start_time = NULL` and `end_time = NULL`, meaning they are visible immediately and never expire.
- **No Data Loss**: This migration only adds columns, it doesn't modify or delete existing data.
- **Safe to Run Multiple Times**: Uses `IF NOT EXISTS` clauses to prevent errors if run multiple times.


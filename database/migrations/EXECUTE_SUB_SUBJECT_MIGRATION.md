# 🚀 HOW TO EXECUTE SUB-SUBJECT MIGRATION

**Date:** 2025-11-28  
**Estimated Time:** 5-10 minutes  
**Risk Level:** 🟢 LOW (Safe, Idempotent, Backward Compatible)

---

## 📋 **PRE-EXECUTION CHECKLIST**

Before running the migration, verify:

- [ ] You have admin access to Supabase dashboard
- [ ] You have backed up the database (optional but recommended)
- [ ] No other migrations are currently running
- [ ] You have read the SUB_SUBJECT_MIGRATION_SUMMARY.md file

---

## 🎯 **EXECUTION STEPS**

### **Option 1: Supabase SQL Editor (RECOMMENDED)**

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard
   - Select your project: `aezycreative@gmail.com's Project`
   - Click on **SQL Editor** in the left sidebar

2. **Execute Step 1: Schema Changes**
   - Click **New Query**
   - Copy the entire contents of `ADD_SUB_SUBJECT_TYPES_AND_ENROLLMENT.sql`
   - Paste into SQL Editor
   - Click **Run** (or press Ctrl+Enter)
   - ✅ Wait for success message: "MIGRATION STEP 1 COMPLETE"

3. **Execute Step 2: RPC Functions**
   - Click **New Query**
   - Copy the entire contents of `ADD_SUB_SUBJECT_RPC_FUNCTIONS.sql`
   - Paste into SQL Editor
   - Click **Run**
   - ✅ Wait for success message: "MIGRATION STEP 2 COMPLETE"

4. **Execute Step 3: RLS Policies**
   - Click **New Query**
   - Copy the entire contents of `ADD_SUB_SUBJECT_RLS_POLICIES.sql`
   - Paste into SQL Editor
   - Click **Run**
   - ✅ Wait for success message: "MIGRATION STEP 3 COMPLETE"

5. **Verify Migration**
   - Run the verification queries from SUB_SUBJECT_MIGRATION_SUMMARY.md
   - Check that all columns, tables, functions, and policies exist

---

### **Option 2: Command Line (psql)**

If you prefer command line:

```bash
# Connect to your Supabase database
psql "postgresql://postgres:[YOUR-PASSWORD]@[YOUR-PROJECT-REF].supabase.co:5432/postgres"

# Execute migrations in order
\i database/migrations/ADD_SUB_SUBJECT_TYPES_AND_ENROLLMENT.sql
\i database/migrations/ADD_SUB_SUBJECT_RPC_FUNCTIONS.sql
\i database/migrations/ADD_SUB_SUBJECT_RLS_POLICIES.sql

# Exit
\q
```

---

## ✅ **EXPECTED OUTPUT**

After each step, you should see:

### **Step 1 Output:**
```
NOTICE:  ✅ Added subject_type column to classroom_subjects
NOTICE:  ✅ Added is_sub_subject_grade column to student_grades
NOTICE:  ✅ Created student_subject_enrollments table with indexes and RLS enabled
NOTICE:  ✅✅✅ MIGRATION STEP 1 COMPLETE: Schema changes applied successfully
NOTICE:  Next steps: Run STEP 2 (RPC Functions) and STEP 3 (RLS Policies)
```

### **Step 2 Output:**
```
NOTICE:  ✅✅✅ MIGRATION STEP 2 COMPLETE: RPC functions created successfully
```

### **Step 3 Output:**
```
NOTICE:  ✅ Created RLS policies for student_subject_enrollments table
NOTICE:  ✅ Enhanced can_manage_student_grade function to support sub-subjects
NOTICE:  ✅ Created additional RLS policies for classroom_subjects table
NOTICE:  ✅✅✅ MIGRATION STEP 3 COMPLETE: RLS policies created successfully
NOTICE:  🎉 SUB-SUBJECT TREE ENHANCEMENT MIGRATION COMPLETE!
NOTICE:  
NOTICE:  📋 SUMMARY:
NOTICE:    ✅ Added subject_type column to classroom_subjects
NOTICE:    ✅ Added is_sub_subject_grade column to student_grades
NOTICE:    ✅ Created student_subject_enrollments table
NOTICE:    ✅ Created 6 RPC functions for sub-subject management
NOTICE:    ✅ Created 7 RLS policies for security
NOTICE:    ✅ Enhanced can_manage_student_grade for sub-subjects
```

---

## 🧪 **POST-EXECUTION VERIFICATION**

Run these queries to verify everything is working:

### **1. Check Schema Changes**
```sql
-- Should return 1 row
SELECT COUNT(*) FROM information_schema.columns
WHERE table_name = 'classroom_subjects' AND column_name = 'subject_type';

-- Should return 1 row
SELECT COUNT(*) FROM information_schema.columns
WHERE table_name = 'student_grades' AND column_name = 'is_sub_subject_grade';

-- Should return 1 row
SELECT COUNT(*) FROM information_schema.tables
WHERE table_name = 'student_subject_enrollments';
```

### **2. Check RPC Functions**
```sql
-- Should return 6 rows
SELECT proname FROM pg_proc
WHERE proname IN (
  'initialize_mapeh_sub_subjects',
  'compute_parent_subject_grade',
  'enroll_student_in_tle',
  'self_enroll_in_tle',
  'get_student_tle_enrollment',
  'bulk_enroll_students_in_tle'
);
```

### **3. Check RLS Policies**
```sql
-- Should return 5 rows
SELECT COUNT(*) FROM pg_policies
WHERE tablename = 'student_subject_enrollments';

-- Should return at least 2 new policies
SELECT policyname FROM pg_policies
WHERE tablename = 'classroom_subjects'
  AND (policyname LIKE '%MAPEH%' OR policyname LIKE '%TLE%');
```

### **4. Test MAPEH Initialization (Optional)**
```sql
-- Create a test MAPEH subject
INSERT INTO classroom_subjects (
  classroom_id,
  subject_name,
  subject_type,
  is_active,
  created_by
) VALUES (
  (SELECT id FROM classrooms LIMIT 1),  -- Use any existing classroom
  'MAPEH',
  'mapeh_parent',
  true,
  auth.uid()
) RETURNING id;

-- Initialize MAPEH sub-subjects (replace with actual IDs)
SELECT initialize_mapeh_sub_subjects(
  '[classroom_id]'::UUID,
  '[mapeh_subject_id]'::UUID,
  auth.uid()
);

-- Verify 4 sub-subjects were created
SELECT subject_name, subject_type
FROM classroom_subjects
WHERE parent_subject_id = '[mapeh_subject_id]'::UUID;
-- Should return: Music, Arts, Physical Education (PE), Health
```

---

## 🚨 **TROUBLESHOOTING**

### **Error: "column already exists"**
**Solution:** This is normal! The migration is idempotent. The column was already added in a previous run. Continue to next step.

### **Error: "function already exists"**
**Solution:** This is normal! The migration uses `CREATE OR REPLACE FUNCTION`. Continue to next step.

### **Error: "policy already exists"**
**Solution:** This is normal! The migration uses `DROP POLICY IF EXISTS`. Continue to next step.

### **Error: "permission denied"**
**Solution:** Make sure you're connected as the `postgres` user or a user with SUPERUSER privileges.

### **Error: "relation does not exist"**
**Solution:** Make sure you ran Step 1 before Step 2 and Step 3. The migrations must be run in order.

---

## 🎉 **SUCCESS!**

If all steps completed without errors, you have successfully:

✅ Added sub-subject type support to the database  
✅ Created TLE enrollment tracking system  
✅ Implemented MAPEH auto-initialization  
✅ Enhanced grade computation for parent subjects  
✅ Secured all new features with RLS policies  

**Next:** Update the Dart/Flutter code to use the new database features!

---

## 📞 **NEED HELP?**

If you encounter any issues:

1. Check the error message carefully
2. Review the SUB_SUBJECT_MIGRATION_SUMMARY.md file
3. Run the verification queries to see what's missing
4. If needed, use the rollback plan in SUB_SUBJECT_MIGRATION_SUMMARY.md

**The migration is designed to be safe and reversible!** 🛡️


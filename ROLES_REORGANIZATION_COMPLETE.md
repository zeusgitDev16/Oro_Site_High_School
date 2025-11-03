# ✅ Roles Table Reorganization Complete!

## 📋 Summary

Updated the `roles` table structure and added support for new role types.

---

## 🎯 Changes Made

### **1. Renamed Role**
- ✅ `coordinator` → `ict_coordinator` (ID 5)

### **2. Added New Roles**
- ✅ `grade_coordinator` (ID 6) - NEW
- ✅ `hybrid` (ID 7) - NEW

### **3. Created New Table**
- ✅ `grade_coordinators` table with RLS policies

### **4. Updated AuthService**
- ✅ Added `_createGradeCoordinatorRecord()` method
- ✅ Updated role mapping to use new IDs

---

## 📊 Final Role Structure

| ID | Role Name | Description | Table |
|----|-----------|-------------|-------|
| 1 | admin | System administrators | (none) |
| 2 | teacher | Regular teachers | teachers |
| 3 | student | Students | students |
| 4 | parent | Parents/Guardians | parents |
| 5 | ict_coordinator | ICT Coordinators | ict_coordinators |
| 6 | grade_coordinator | Grade Level Coordinators | grade_coordinators |
| 7 | hybrid | Multi-role users | hybrid_users |

---

## 🚀 How to Apply

### **Step 1: Run SQL Script**

1. Open **Supabase Dashboard** → **SQL Editor**
2. Open `UPDATE_ROLES_TABLE.sql`
3. Copy entire contents
4. Paste into SQL Editor
5. Click **"Run"**

**Expected Output**:
```
✅ Updated role ID 5: coordinator → ict_coordinator
✅ Added/Updated role ID 6: grade_coordinator
✅ Added/Updated role ID 7: hybrid
✅ grade_coordinators table created with RLS policies
✅ ROLES TABLE UPDATE COMPLETE!
```

### **Step 2: Verify in Supabase**

1. Go to **Table Editor** → **roles** table
2. Should see 7 roles:
   - 1 = admin
   - 2 = teacher
   - 3 = student
   - 4 = parent
   - 5 = ict_coordinator (renamed)
   - 6 = grade_coordinator (new)
   - 7 = hybrid (new)

### **Step 3: Run Additional Tables Script (If Not Done)**

If you haven't run `CREATE_ADDITIONAL_ROLE_TABLES.sql` yet:

1. Open `CREATE_ADDITIONAL_ROLE_TABLES.sql`
2. Run in SQL Editor
3. This creates: `ict_coordinators`, `hybrid_users`, `parents`, `parent_student_links`

### **Step 4: Test**

1. **Hot restart** your Flutter app
2. **Login** with different role accounts
3. **Check console** for role-specific record creation
4. **Verify** in database

---

## 🔧 Grade Coordinator Table Structure

```sql
grade_coordinators
├─ id (UUID, FK to profiles)
├─ employee_id (TEXT, unique)
├─ first_name, last_name, middle_name
├─ grade_level (INT, 7-12)
├─ department (TEXT, default 'Academic Affairs')
├─ subjects (JSONB array)
├─ is_also_teaching (BOOLEAN, default true)
├─ responsibilities (JSONB array)
├─ managed_sections (JSONB array)
├─ phone, office_location
├─ is_active (BOOLEAN)
└─ created_at, updated_at (TIMESTAMPTZ)
```

---

## 📝 Default Values

### **Grade Coordinators**
```dart
{
  'employee_id': 'GC-{timestamp}',
  'grade_level': 7, // Default
  'department': 'Academic Affairs',
  'subjects': [], // Empty array
  'is_also_teaching': true,
  'responsibilities': ['Grade Level Management', 'Student Affairs'],
  'managed_sections': [],
  'is_active': true,
}
```

---

## 🧪 Testing Guide

### **Test 1: Verify Roles Table**
```sql
SELECT * FROM roles ORDER BY id;
```

**Expected**: 7 rows with correct names

### **Test 2: Test ICT Coordinator Login**
```
1. Create user with role_id = 5
2. Login
3. Check console:
   🔧 Creating role-specific record for: ict_coordinator (role_id: 5)
   ✅ ICT Coordinator record created successfully!
4. Verify:
   SELECT * FROM ict_coordinators;
```

### **Test 3: Test Grade Coordinator Login**
```
1. Create user with role_id = 6
2. Login
3. Check console:
   🔧 Creating role-specific record for: grade_coordinator (role_id: 6)
   ✅ Grade Coordinator record created successfully!
4. Verify:
   SELECT * FROM grade_coordinators;
```

### **Test 4: Test Hybrid User Login**
```
1. Create user with role_id = 7
2. Login
3. Check console:
   🔧 Creating role-specific record for: hybrid (role_id: 7)
   ✅ Hybrid user record created successfully!
4. Verify:
   SELECT * FROM hybrid_users;
```

---

## ✅ Verification Queries

### **Check All Roles**
```sql
SELECT 
    id,
    name,
    CASE 
        WHEN id = 1 THEN 'System administrators'
        WHEN id = 2 THEN 'Regular teachers'
        WHEN id = 3 THEN 'Students'
        WHEN id = 4 THEN 'Parents/Guardians'
        WHEN id = 5 THEN 'ICT Coordinators'
        WHEN id = 6 THEN 'Grade Level Coordinators'
        WHEN id = 7 THEN 'Hybrid users'
    END AS description
FROM roles
ORDER BY id;
```

### **Check All Role Tables**
```sql
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) AS columns
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN (
    'teachers', 'students', 'parents', 
    'ict_coordinators', 'grade_coordinators', 'hybrid_users'
  )
ORDER BY table_name;
```

### **Check User with Role Details**
```sql
SELECT 
    p.id,
    p.email,
    p.full_name,
    r.name AS role,
    CASE 
        WHEN t.id IS NOT NULL THEN 'teachers'
        WHEN s.id IS NOT NULL THEN 'students'
        WHEN par.id IS NOT NULL THEN 'parents'
        WHEN ict.id IS NOT NULL THEN 'ict_coordinators'
        WHEN gc.id IS NOT NULL THEN 'grade_coordinators'
        WHEN hyb.id IS NOT NULL THEN 'hybrid_users'
        ELSE 'none'
    END AS role_table
FROM profiles p
LEFT JOIN roles r ON p.role_id = r.id
LEFT JOIN teachers t ON p.id = t.id
LEFT JOIN students s ON p.id = s.id
LEFT JOIN parents par ON p.id = par.id
LEFT JOIN ict_coordinators ict ON p.id = ict.id
LEFT JOIN grade_coordinators gc ON p.id = gc.id
LEFT JOIN hybrid_users hyb ON p.id = hyb.id
WHERE p.is_active = TRUE
ORDER BY r.id, p.full_name;
```

---

## 🎯 Benefits

### **1. Clear Role Separation**
- ✅ ICT Coordinator vs Grade Coordinator distinction
- ✅ Hybrid users for multi-role scenarios
- ✅ Each role has specific responsibilities

### **2. Flexible Architecture**
- ✅ Easy to add more roles in future
- ✅ Role-specific data in separate tables
- ✅ Clean database design

### **3. Automatic Record Creation**
- ✅ All roles auto-create records on login
- ✅ No manual intervention needed
- ✅ Works for all authentication methods

---

## 📁 Files Created/Modified

### **Created**
1. ✅ `UPDATE_ROLES_TABLE.sql` - SQL script to update roles
2. ✅ `ROLES_REORGANIZATION_COMPLETE.md` - This documentation

### **Modified**
1. ✅ `lib/services/auth_service.dart` - Updated role mapping

---

## 🚀 Next Steps

1. **Run** `UPDATE_ROLES_TABLE.sql` in Supabase
2. **Verify** roles table has 7 roles
3. **Run** `CREATE_ADDITIONAL_ROLE_TABLES.sql` (if not done)
4. **Hot restart** your app
5. **Test** with different role accounts
6. **Verify** records are created correctly

---

## ⚠️ Important Notes

### **Existing Users**
- Users with `role_id = 5` will automatically use the renamed `ict_coordinator` role
- No data migration needed
- Existing profiles remain unchanged

### **New Users**
- Will be assigned correct role_id based on email or manual selection
- Role-specific records will be created automatically on first login

### **RLS Policies**
- All new tables have RLS enabled
- Users can INSERT/UPDATE their own records
- Admins can manage all records

---

**Status**: ✅ Complete and Ready to Deploy  
**Impact**: Organized role structure with clear separation  
**Next**: Run SQL script and test!

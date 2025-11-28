# 📋 SUB-SUBJECT TREE ENHANCEMENT PLAN

**Feature:** Revise sub-subject tree system for MAPEH and TLE with different types
**Status:** 🔄 PLANNING PHASE
**Date:** 2025-11-28

---

## 🎯 **OBJECTIVES**

### **1. Remove Sub-Subject Tree from Most Subjects**
- Remove sub-subject capability from all subjects EXCEPT:
  - ✅ **MAPEH** (Music, Arts, Physical Education, Health)
  - ✅ **TLE** (Technology and Livelihood Education)

### **2. MAPEH Sub-Subject Structure (Prerequisite Type)**
- **Hardcoded sub-subjects** (constant and unchangeable):
  1. Music
  2. Arts
  3. Physical Education (PE)
  4. Health
- Each sub-subject can have **different assigned teachers**
- Sub-subjects are recorded in database (not just UI)
- **Grading System:**
  - Each sub-subject has separate grading (same computation as current gradebook)
  - Final MAPEH grade = Average of 4 sub-subject transmuted grades
  - Example: Music (86) + Arts (83) + PE (80) + Health (75) = 324 / 4 = **81 final**

### **3. TLE Sub-Subject Structure (Free-Form Type)**
- **Four main components** (admin can add sub-subjects under these):
  1. **Home Economics** - Cookery, beauty care, housekeeping, commercial cooking
  2. **Agri-Fishery Arts** - Crop production, animal production, food fish processing
  3. **Industrial Arts** - Carpentry, plumbing, masonry, automotive servicing
  4. **ICT** - Computer hardware servicing
- **Grade-level structure:**
  - Grades 4-6: Basic home skills from all four components
  - Grades 7-8: Common competencies in each component
  - Grades 9-10: Specialized exploratory courses with entrepreneurship focus
  - Senior High: Further specialization, job-ready focus
- Admin has **free will** to add custom sub-subjects under TLE
- Each sub-subject can have **different assigned teachers**

---

## 📊 **DATABASE SCHEMA CHANGES**

### **Current Schema: `classroom_subjects` Table**
```sql
CREATE TABLE classroom_subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  classroom_id UUID NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
  subject_name TEXT NOT NULL,
  subject_code TEXT,
  description TEXT,
  teacher_id UUID REFERENCES profiles(id),
  parent_subject_id UUID REFERENCES classroom_subjects(id),  -- For sub-subjects
  course_id BIGINT REFERENCES courses(id),  -- Backward compatibility
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID
);
```

### **NEW: Add `subject_type` Column**
```sql
-- Add subject_type column to distinguish between different sub-subject behaviors
ALTER TABLE classroom_subjects
ADD COLUMN subject_type TEXT DEFAULT 'standard' 
CHECK (subject_type IN ('standard', 'mapeh_parent', 'mapeh_sub', 'tle_parent', 'tle_sub'));

-- Add index for performance
CREATE INDEX idx_classroom_subjects_type ON classroom_subjects(subject_type);
CREATE INDEX idx_classroom_subjects_parent ON classroom_subjects(parent_subject_id);
```

**Subject Type Values:**
- `standard` - Regular subjects (Filipino, English, Math, Science, etc.) - NO sub-subjects
- `mapeh_parent` - MAPEH parent subject
- `mapeh_sub` - MAPEH sub-subjects (Music, Arts, PE, Health)
- `tle_parent` - TLE parent subject
- `tle_sub` - TLE sub-subjects (custom, admin-defined)

---

## 🔄 **GRADING SYSTEM CHANGES**

### **Current: `student_grades` Table**
```sql
CREATE TABLE student_grades (
  id UUID PRIMARY KEY,
  student_id UUID NOT NULL,
  classroom_id UUID NOT NULL,
  course_id BIGINT,  -- OLD system
  subject_id UUID REFERENCES classroom_subjects(id),  -- NEW system
  quarter SMALLINT CHECK (quarter >= 1 AND quarter <= 4),
  initial_grade NUMERIC NOT NULL,
  transmuted_grade NUMERIC NOT NULL,
  adjusted_grade NUMERIC,
  plus_points NUMERIC DEFAULT 0,
  extra_points NUMERIC DEFAULT 0,
  -- ... other columns
);
```

### **NEW: Add `is_sub_subject_grade` Column**
```sql
-- Add flag to distinguish sub-subject grades from parent subject grades
ALTER TABLE student_grades
ADD COLUMN is_sub_subject_grade BOOLEAN DEFAULT false;

-- Add index for performance
CREATE INDEX idx_student_grades_sub_subject ON student_grades(is_sub_subject_grade);
```

**Grading Logic:**
1. **Sub-subject grades** (Music, Arts, PE, Health, TLE components):
   - Stored with `is_sub_subject_grade = true`
   - `subject_id` points to the sub-subject
   - Computed using standard gradebook formula

2. **Parent subject grades** (MAPEH, TLE):
   - Stored with `is_sub_subject_grade = false`
   - `subject_id` points to the parent subject
   - **Auto-computed** as average of sub-subject transmuted grades
   - Formula: `SUM(sub_subject_transmuted_grades) / COUNT(sub_subjects)`

---

## 🔧 **RPC FUNCTIONS NEEDED**

### **1. Auto-Compute Parent Subject Grade**
```sql
CREATE OR REPLACE FUNCTION compute_parent_subject_grade(
  p_student_id UUID,
  p_classroom_id UUID,
  p_parent_subject_id UUID,
  p_quarter INT
)
RETURNS NUMERIC AS $$
DECLARE
  v_avg_grade NUMERIC;
BEGIN
  -- Get average of all sub-subject transmuted grades
  SELECT AVG(transmuted_grade)
  INTO v_avg_grade
  FROM student_grades sg
  JOIN classroom_subjects cs ON sg.subject_id = cs.id
  WHERE sg.student_id = p_student_id
    AND sg.classroom_id = p_classroom_id
    AND sg.quarter = p_quarter
    AND sg.is_sub_subject_grade = true
    AND cs.parent_subject_id = p_parent_subject_id
    AND cs.is_active = true;
  
  RETURN COALESCE(ROUND(v_avg_grade, 0), 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### **2. Initialize MAPEH Sub-Subjects**
```sql
CREATE OR REPLACE FUNCTION initialize_mapeh_sub_subjects(
  p_classroom_id UUID,
  p_mapeh_subject_id UUID,
  p_created_by UUID
)
RETURNS VOID AS $$
DECLARE
  v_sub_subjects TEXT[] := ARRAY['Music', 'Arts', 'Physical Education (PE)', 'Health'];
  v_sub_name TEXT;
BEGIN
  -- Insert hardcoded MAPEH sub-subjects
  FOREACH v_sub_name IN ARRAY v_sub_subjects
  LOOP
    INSERT INTO classroom_subjects (
      classroom_id,
      subject_name,
      subject_type,
      parent_subject_id,
      is_active,
      created_by
    ) VALUES (
      p_classroom_id,
      v_sub_name,
      'mapeh_sub',
      p_mapeh_subject_id,
      true,
      p_created_by
    )
    ON CONFLICT DO NOTHING;  -- Prevent duplicates
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 🎨 **UI/UX CHANGES**

### **1. Subject Selection in Classroom Editor**
- When admin adds **MAPEH**:
  - Automatically create 4 sub-subjects (Music, Arts, PE, Health)
  - Show sub-subjects in tree view
  - Allow teacher assignment for each sub-subject
  - **Prevent deletion** of MAPEH sub-subjects (hardcoded)

- When admin adds **TLE**:
  - Show "Add Sub-Subject" button
  - Allow admin to add custom sub-subjects
  - Show sub-subjects in tree view
  - Allow teacher assignment for each sub-subject
  - **Allow deletion** of TLE sub-subjects (free-form)

- For **other subjects** (Filipino, Math, Science, etc.):
  - **Hide** "Add Sub-Subject" button
  - No sub-subject tree capability

### **2. Assignment Creation**
- When creating assignment in MAPEH classroom:
  - Show dropdown: "MAPEH (All)" or individual sub-subjects (Music, Arts, PE, Health)
  - Teacher can create assignment for specific sub-subject

- When creating assignment in TLE classroom:
  - Show dropdown: "TLE (All)" or individual sub-subjects (custom list)
  - Teacher can create assignment for specific sub-subject

### **3. Gradebook Display**
- **MAPEH Gradebook:**
  - Show columns for: Music, Arts, PE, Health, **MAPEH (Final)**
  - Each sub-subject shows individual transmuted grade
  - MAPEH (Final) column shows auto-computed average
  - Example row: `Diaz | 86 | 83 | 80 | 75 | 81`

- **TLE Gradebook:**
  - Show columns for each TLE sub-subject + **TLE (Final)**
  - Each sub-subject shows individual transmuted grade
  - TLE (Final) column shows auto-computed average

---

## ⚠️ **RLS POLICY CONSIDERATIONS**

### **Current RLS Policies (No Changes Needed)**
The existing RLS policies already handle:
- ✅ Teachers can view/manage subjects in their classrooms
- ✅ Admins can manage all subjects
- ✅ Students can view subjects in enrolled classrooms
- ✅ `parent_subject_id` relationships are already supported

### **New RLS Policies Needed**
```sql
-- Prevent deletion of MAPEH hardcoded sub-subjects
CREATE POLICY "prevent_mapeh_sub_deletion"
  ON classroom_subjects FOR DELETE
  USING (
    subject_type != 'mapeh_sub'  -- Cannot delete MAPEH sub-subjects
  );

-- Allow admins to manage TLE sub-subjects
CREATE POLICY "admins_manage_tle_subs"
  ON classroom_subjects FOR ALL
  USING (
    is_admin(auth.uid()) OR subject_type != 'tle_sub'
  );
```

---

## 📝 **MIGRATION STEPS**

### **Phase 1: Database Schema**
1. ✅ Add `subject_type` column to `classroom_subjects`
2. ✅ Add `is_sub_subject_grade` column to `student_grades`
3. ✅ Create indexes for performance
4. ✅ Create RPC functions for grade computation
5. ✅ Create RPC function for MAPEH initialization
6. ✅ Update RLS policies

### **Phase 2: Backend Services**
1. ✅ Update `ClassroomSubjectService` to handle subject types
2. ✅ Update `DepEdGradeService` to compute parent subject grades
3. ✅ Create service methods for MAPEH/TLE sub-subject management
4. ✅ Update assignment service to filter by sub-subject

### **Phase 3: UI Components**
1. ✅ Update classroom editor to show/hide sub-subject buttons
2. ✅ Update subject tree widget to display MAPEH/TLE sub-subjects
3. ✅ Update assignment creation dialog to show sub-subject dropdown
4. ✅ Update gradebook to display sub-subject columns + parent column

### **Phase 4: Data Migration**
1. ✅ Backfill existing MAPEH subjects with sub-subjects
2. ✅ Set `subject_type` for existing subjects
3. ✅ Migrate existing grades to new structure

---

## ✅ **IMPLEMENTATION CHECKLIST**

- [ ] Create database migration SQL file
- [ ] Test migration on development database
- [ ] Update Dart models (`ClassroomSubject`, `StudentGrade`)
- [ ] Update service layer (`ClassroomSubjectService`, `DepEdGradeService`)
- [ ] Update UI components (classroom editor, gradebook, assignments)
- [ ] Test MAPEH sub-subject creation and grading
- [ ] Test TLE sub-subject creation and grading
- [ ] Test grade computation for parent subjects
- [ ] Test RLS policies
- [ ] Create comprehensive documentation

---

## 🔍 **DETAILED IMPLEMENTATION ANALYSIS**

### **A. MAPEH Grading Flow**

**Scenario:** Student "Diaz" in Grade 7 Amanpulo, Quarter 1

1. **Teacher creates assignments:**
   - Music teacher creates "Music Performance" (Performance Task, 50 points)
   - Arts teacher creates "Drawing Project" (Performance Task, 40 points)
   - PE teacher creates "Physical Fitness Test" (Performance Task, 30 points)
   - Health teacher creates "Health Quiz" (Written Work, 20 points)

2. **Student submits and gets graded:**
   - Music: 43/50 → Transmuted: **86**
   - Arts: 33/40 → Transmuted: **83**
   - PE: 24/30 → Transmuted: **80**
   - Health: 15/20 → Transmuted: **75**

3. **Grade computation:**
   ```sql
   -- Each sub-subject grade is stored separately
   INSERT INTO student_grades (student_id, subject_id, quarter, transmuted_grade, is_sub_subject_grade)
   VALUES
     ('diaz_id', 'music_id', 1, 86, true),
     ('diaz_id', 'arts_id', 1, 83, true),
     ('diaz_id', 'pe_id', 1, 80, true),
     ('diaz_id', 'health_id', 1, 75, true);

   -- Parent MAPEH grade is auto-computed
   SELECT compute_parent_subject_grade('diaz_id', 'classroom_id', 'mapeh_id', 1);
   -- Returns: (86 + 83 + 80 + 75) / 4 = 81

   -- Store parent grade
   INSERT INTO student_grades (student_id, subject_id, quarter, transmuted_grade, is_sub_subject_grade)
   VALUES ('diaz_id', 'mapeh_id', 1, 81, false);
   ```

4. **Gradebook display:**
   ```
   | Student | Music | Arts | PE | Health | MAPEH (Final) |
   |---------|-------|------|----|---------| -------------|
   | Diaz    |  86   |  83  | 80 |   75    |      81      |
   ```

### **B. TLE Grading Flow (Similar to MAPEH)**

**Scenario:** Student "Reyes" in Grade 9, Quarter 2, TLE has 3 sub-subjects

1. **Admin created TLE sub-subjects:**
   - "Cookery" (under Home Economics)
   - "Carpentry" (under Industrial Arts)
   - "Computer Hardware Servicing" (under ICT)

2. **Student gets graded:**
   - Cookery: **88**
   - Carpentry: **85**
   - Computer Hardware Servicing: **90**

3. **Grade computation:**
   ```sql
   -- TLE final grade = (88 + 85 + 90) / 3 = 87.67 → 88 (rounded)
   ```

### **C. Assignment Filtering Logic**

**Current:** Assignments are filtered by `subject_id`
```dart
// Current implementation
final assignments = await supabase
  .from('assignments')
  .select()
  .eq('classroom_id', classroomId)
  .eq('subject_id', subjectId)  // Filters by specific subject
  .eq('quarter_no', quarter);
```

**NEW:** Need to handle parent/sub-subject filtering
```dart
// NEW implementation
Future<List<Assignment>> getAssignmentsForSubject({
  required String classroomId,
  required String subjectId,
  required int quarter,
  bool includeSubSubjects = false,
}) async {
  // Check if subject has sub-subjects
  final subject = await getSubjectById(subjectId);

  if (includeSubSubjects && (subject.subjectType == 'mapeh_parent' || subject.subjectType == 'tle_parent')) {
    // Get all sub-subject IDs
    final subSubjects = await getSubSubjects(subjectId);
    final subSubjectIds = subSubjects.map((s) => s.id).toList();

    // Fetch assignments for parent AND all sub-subjects
    return await supabase
      .from('assignments')
      .select()
      .eq('classroom_id', classroomId)
      .in_('subject_id', [subjectId, ...subSubjectIds])
      .eq('quarter_no', quarter);
  } else {
    // Regular subject or specific sub-subject
    return await supabase
      .from('assignments')
      .select()
      .eq('classroom_id', classroomId)
      .eq('subject_id', subjectId)
      .eq('quarter_no', quarter);
  }
}
```

---

## 🚨 **POTENTIAL CONFLICTS & SOLUTIONS**

### **Conflict 1: Existing MAPEH Subjects**
**Problem:** Some classrooms may already have MAPEH without sub-subjects

**Solution:** Data migration script
```sql
-- Find all existing MAPEH subjects
UPDATE classroom_subjects
SET subject_type = 'mapeh_parent'
WHERE subject_name ILIKE '%MAPEH%'
  AND parent_subject_id IS NULL;

-- Auto-create sub-subjects for existing MAPEH
DO $$
DECLARE
  mapeh_record RECORD;
BEGIN
  FOR mapeh_record IN
    SELECT id, classroom_id, created_by
    FROM classroom_subjects
    WHERE subject_type = 'mapeh_parent'
  LOOP
    PERFORM initialize_mapeh_sub_subjects(
      mapeh_record.classroom_id,
      mapeh_record.id,
      mapeh_record.created_by
    );
  END LOOP;
END $$;
```

### **Conflict 2: Existing Grades for MAPEH**
**Problem:** Students may have existing MAPEH grades without sub-subject breakdown

**Solution:** Keep existing grades, mark as legacy
```sql
-- Add legacy flag
ALTER TABLE student_grades
ADD COLUMN is_legacy_grade BOOLEAN DEFAULT false;

-- Mark existing MAPEH grades as legacy
UPDATE student_grades sg
SET is_legacy_grade = true
WHERE EXISTS (
  SELECT 1 FROM classroom_subjects cs
  WHERE cs.id = sg.subject_id
    AND cs.subject_type = 'mapeh_parent'
);
```

**UI Handling:**
- Legacy grades: Show single MAPEH column (no sub-subjects)
- New grades: Show Music, Arts, PE, Health + MAPEH (Final)

### **Conflict 3: RLS Policy for `can_manage_student_grade()`**
**Problem:** Existing RLS uses `can_manage_student_grade(subject_id)` which may not handle sub-subjects

**Solution:** Update RLS function to check parent subject
```sql
CREATE OR REPLACE FUNCTION can_manage_student_grade(
  p_subject_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_can_manage BOOLEAN := false;
  v_parent_id UUID;
BEGIN
  -- Check if user can manage this subject directly
  SELECT EXISTS (
    SELECT 1 FROM classroom_subjects cs
    WHERE cs.id = p_subject_id
      AND (
        cs.teacher_id = auth.uid()  -- Subject teacher
        OR EXISTS (  -- Classroom owner
          SELECT 1 FROM classrooms c
          WHERE c.id = cs.classroom_id
            AND c.teacher_id = auth.uid()
        )
        OR is_admin(auth.uid())  -- Admin
      )
  ) INTO v_can_manage;

  -- If not, check parent subject (for sub-subjects)
  IF NOT v_can_manage THEN
    SELECT parent_subject_id INTO v_parent_id
    FROM classroom_subjects
    WHERE id = p_subject_id;

    IF v_parent_id IS NOT NULL THEN
      -- Recursively check parent
      RETURN can_manage_student_grade(v_parent_id);
    END IF;
  END IF;

  RETURN v_can_manage;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 📐 **GRADEBOOK UI MOCKUP**

### **MAPEH Gradebook (Expanded View)**
```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Gradebook: Grade 7 Amanpulo • MAPEH                          [Q1] [Q2] [Q3] [Q4] │
├─────────────────────────────────────────────────────────────────────────────┤
│ Legend: 🟢 Graded | 🟡 Submitted | 🔴 Missing | ⚪ Not Started              │
├─────────────────────────────────────────────────────────────────────────────┤
│ Student          │ Music │ Arts │ PE  │ Health │ MAPEH (Final) │ Actions   │
├──────────────────┼───────┼──────┼─────┼────────┼───────────────┼───────────┤
│ Diaz, Ace Nathan │  86   │  83  │ 80  │   75   │      81       │ [Compute] │
│ Reyes, Nicko     │  90   │  88  │ 85  │   82   │      86       │ [Compute] │
│ Villa, Renz      │  --   │  --  │ --  │   --   │      --       │ [Compute] │
└─────────────────────────────────────────────────────────────────────────────┘

📊 Sub-Subject Breakdown:
  • Music (Teacher: Ms. Santos)      - 5 assignments
  • Arts (Teacher: Mr. Cruz)         - 4 assignments
  • PE (Teacher: Coach Reyes)        - 3 assignments
  • Health (Teacher: Ms. Garcia)     - 6 assignments
```

### **Assignment Creation Dialog (MAPEH)**
```
┌─────────────────────────────────────────────────────────────┐
│ Create Assignment                                           │
├─────────────────────────────────────────────────────────────┤
│ Title: [Music Performance Assessment                     ]  │
│                                                             │
│ Subject: [MAPEH ▼]                                          │
│   ├─ MAPEH (All Sub-Subjects)                              │
│   ├─ Music                          ← Selected             │
│   ├─ Arts                                                   │
│   ├─ Physical Education (PE)                               │
│   └─ Health                                                 │
│                                                             │
│ Type: [Performance Task ▼]                                  │
│ Quarter: [Q1 ▼]                                             │
│ Points: [50                                              ]  │
│                                                             │
│ [Cancel]                                        [Create]    │
└─────────────────────────────────────────────────────────────┘
```

---

## ✅ **FINAL IMPLEMENTATION PLAN**

### **Step 1: Database Migration (Priority: HIGH)**
- File: `database/migrations/ADD_SUB_SUBJECT_TYPES_AND_GRADING.sql`
- Add `subject_type` column
- Add `is_sub_subject_grade` column
- Create RPC functions
- Update RLS policies
- Migrate existing MAPEH subjects

### **Step 2: Dart Models (Priority: HIGH)**
- Update `ClassroomSubject` model with `subjectType` field
- Update `StudentGrade` model with `isSubSubjectGrade` field
- Add enum `SubjectType` (standard, mapeh_parent, mapeh_sub, tle_parent, tle_sub)

### **Step 3: Service Layer (Priority: HIGH)**
- Update `ClassroomSubjectService`:
  - `initializeMAPEHSubSubjects()`
  - `addTLESubSubject()`
  - `getSubSubjects(parentSubjectId)`
- Update `DepEdGradeService`:
  - `computeParentSubjectGrade()`
  - `saveSubSubjectGrade()`

### **Step 4: UI Components (Priority: MEDIUM)**
- Update `ClassroomEditorWidget`:
  - Show/hide "Add Sub-Subject" button based on subject type
  - Auto-create MAPEH sub-subjects when MAPEH is added
- Update `GradebookGridPanel`:
  - Display sub-subject columns
  - Display parent subject column (auto-computed)
- Update `AssignmentCreationDialog`:
  - Show sub-subject dropdown for MAPEH/TLE

### **Step 5: Testing (Priority: HIGH)**
- Test MAPEH sub-subject creation
- Test TLE sub-subject creation
- Test grade computation for parent subjects
- Test assignment filtering by sub-subject
- Test gradebook display with sub-subjects
- Test RLS policies

---

**Next Step:** Create the database migration file `ADD_SUB_SUBJECT_TYPES_AND_GRADING.sql`


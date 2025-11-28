# 🎨 SUB-SUBJECT TREE VISUAL SUMMARY

**Feature:** MAPEH & TLE Sub-Subject Tree Enhancement
**Date:** 2025-11-28

---

## 📊 **SUBJECT HIERARCHY COMPARISON**

### **BEFORE (Current System)**
```
Classroom: Grade 7 Amanpulo
├─ Filipino (can have sub-subjects ❌)
├─ English (can have sub-subjects ❌)
├─ Mathematics (can have sub-subjects ❌)
├─ Science (can have sub-subjects ❌)
├─ MAPEH (can have sub-subjects ✅)
│   └─ (No predefined structure)
└─ TLE (can have sub-subjects ✅)
    └─ (No predefined structure)
```

### **AFTER (New System)**
```
Classroom: Grade 7 Amanpulo
├─ Filipino (NO sub-subjects) ❌
├─ English (NO sub-subjects) ❌
├─ Mathematics (NO sub-subjects) ❌
├─ Science (NO sub-subjects) ❌
├─ MAPEH (Hardcoded sub-subjects) ✅
│   ├─ Music (Teacher: Ms. Santos)
│   ├─ Arts (Teacher: Mr. Cruz)
│   ├─ Physical Education (PE) (Teacher: Coach Reyes)
│   └─ Health (Teacher: Ms. Garcia)
└─ TLE (Free-form sub-subjects) ✅
    ├─ Cookery (Teacher: Chef Diaz)
    ├─ Carpentry (Teacher: Mr. Villa)
    └─ Computer Hardware Servicing (Teacher: Mr. Reyes)
```

---

## 🎯 **MAPEH SUB-SUBJECT STRUCTURE**

### **Type:** Prerequisite (Hardcoded)

```
┌─────────────────────────────────────────────────────────────┐
│                         MAPEH                               │
│                    (Parent Subject)                         │
│                  subject_type: 'mapeh_parent'               │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│     Music     │   │     Arts      │   │      PE       │
│ (Sub-Subject) │   │ (Sub-Subject) │   │ (Sub-Subject) │
│ subject_type: │   │ subject_type: │   │ subject_type: │
│  'mapeh_sub'  │   │  'mapeh_sub'  │   │  'mapeh_sub'  │
│               │   │               │   │               │
│ Teacher:      │   │ Teacher:      │   │ Teacher:      │
│ Ms. Santos    │   │ Mr. Cruz      │   │ Coach Reyes   │
└───────────────┘   └───────────────┘   └───────────────┘
        │
        ▼
┌───────────────┐
│    Health     │
│ (Sub-Subject) │
│ subject_type: │
│  'mapeh_sub'  │
│               │
│ Teacher:      │
│ Ms. Garcia    │
└───────────────┘
```

**Characteristics:**
- ✅ **Constant:** Always 4 sub-subjects (Music, Arts, PE, Health)
- ✅ **Unchangeable:** Cannot add/remove sub-subjects
- ✅ **Auto-created:** When MAPEH is added to classroom
- ✅ **Separate teachers:** Each sub-subject can have different teacher
- ✅ **Separate grading:** Each sub-subject has own gradebook
- ✅ **Auto-computed parent:** MAPEH grade = Average of 4 sub-subjects

---

## 🔧 **TLE SUB-SUBJECT STRUCTURE**

### **Type:** Free-Form (Admin-Defined)

```
┌─────────────────────────────────────────────────────────────┐
│                          TLE                                │
│                    (Parent Subject)                         │
│                  subject_type: 'tle_parent'                 │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│    Cookery    │   │   Carpentry   │   │  Computer HW  │
│ (Sub-Subject) │   │ (Sub-Subject) │   │ (Sub-Subject) │
│ subject_type: │   │ subject_type: │   │ subject_type: │
│   'tle_sub'   │   │   'tle_sub'   │   │   'tle_sub'   │
│               │   │               │   │               │
│ Component:    │   │ Component:    │   │ Component:    │
│ Home Econ     │   │ Industrial    │   │     ICT       │
│               │   │     Arts      │   │               │
│ Teacher:      │   │ Teacher:      │   │ Teacher:      │
│ Chef Diaz     │   │ Mr. Villa     │   │ Mr. Reyes     │
└───────────────┘   └───────────────┘   └───────────────┘
```

**Four Main Components:**
1. **Home Economics** - Cookery, beauty care, housekeeping, commercial cooking
2. **Agri-Fishery Arts** - Crop production, animal production, food fish processing
3. **Industrial Arts** - Carpentry, plumbing, masonry, automotive servicing
4. **ICT** - Computer hardware servicing

**Characteristics:**
- ✅ **Flexible:** Admin can add custom sub-subjects
- ✅ **Deletable:** Admin can remove TLE sub-subjects
- ✅ **Component-based:** Sub-subjects belong to one of 4 main components
- ✅ **Separate teachers:** Each sub-subject can have different teacher
- ✅ **Separate grading:** Each sub-subject has own gradebook
- ✅ **Auto-computed parent:** TLE grade = Average of all TLE sub-subjects

---

## 📈 **GRADING FLOW DIAGRAM**

### **MAPEH Grading Example**

```
Student: Ace Nathan Diaz
Classroom: Grade 7 Amanpulo
Quarter: Q1

┌─────────────────────────────────────────────────────────────┐
│                    ASSIGNMENTS                              │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ Music Perf.   │   │ Drawing Proj. │   │ Fitness Test  │
│ 43/50 points  │   │ 33/40 points  │   │ 24/30 points  │
│               │   │               │   │               │
│ Component: PT │   │ Component: PT │   │ Component: PT │
│ Quarter: Q1   │   │ Quarter: Q1   │   │ Quarter: Q1   │
└───────────────┘   └───────────────┘   └───────────────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ Music Grade   │   │  Arts Grade   │   │   PE Grade    │
│ Initial: 86.0 │   │ Initial: 82.5 │   │ Initial: 80.0 │
│ Transmuted:86 │   │ Transmuted:83 │   │ Transmuted:80 │
└───────────────┘   └───────────────┘   └───────────────┘
        │
        ▼
┌───────────────┐
│ Health Quiz   │
│ 15/20 points  │
│               │
│ Component: WW │
│ Quarter: Q1   │
└───────────────┘
        │
        ▼
┌───────────────┐
│ Health Grade  │
│ Initial: 75.0 │
│ Transmuted:75 │
└───────────────┘
        │
        └───────────────────┐
                            ▼
        ┌───────────────────────────────────────┐
        │   COMPUTE PARENT SUBJECT GRADE        │
        │                                       │
        │   Music:  86                          │
        │   Arts:   83                          │
        │   PE:     80                          │
        │   Health: 75                          │
        │   ─────────────                       │
        │   Total:  324                         │
        │   Average: 324 / 4 = 81               │
        └───────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────────┐
        │      MAPEH FINAL GRADE: 81            │
        │   (Stored in student_grades table)    │
        │   is_sub_subject_grade: false         │
        └───────────────────────────────────────┘
```

---

## 🗄️ **DATABASE STRUCTURE**

### **classroom_subjects Table**
```sql
┌──────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
│      id      │ subject_name │ subject_type │ parent_id    │  teacher_id  │
├──────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ mapeh-001    │ MAPEH        │ mapeh_parent │ NULL         │ NULL         │
│ music-001    │ Music        │ mapeh_sub    │ mapeh-001    │ santos-id    │
│ arts-001     │ Arts         │ mapeh_sub    │ mapeh-001    │ cruz-id      │
│ pe-001       │ PE           │ mapeh_sub    │ mapeh-001    │ reyes-id     │
│ health-001   │ Health       │ mapeh_sub    │ mapeh-001    │ garcia-id    │
│ tle-001      │ TLE          │ tle_parent   │ NULL         │ NULL         │
│ cookery-001  │ Cookery      │ tle_sub      │ tle-001      │ diaz-id      │
│ carpentry-01 │ Carpentry    │ tle_sub      │ tle-001      │ villa-id     │
│ filipino-001 │ Filipino     │ standard     │ NULL         │ ramos-id     │
│ english-001  │ English      │ standard     │ NULL         │ santos-id    │
└──────────────┴──────────────┴──────────────┴──────────────┴──────────────┘
```

### **student_grades Table**
```sql
┌──────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
│  student_id  │  subject_id  │   quarter    │ transmuted   │ is_sub_grade │
├──────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ diaz-id      │ music-001    │      1       │     86       │     true     │
│ diaz-id      │ arts-001     │      1       │     83       │     true     │
│ diaz-id      │ pe-001       │      1       │     80       │     true     │
│ diaz-id      │ health-001   │      1       │     75       │     true     │
│ diaz-id      │ mapeh-001    │      1       │     81       │    false     │ ← Auto-computed
│ diaz-id      │ cookery-001  │      1       │     88       │     true     │
│ diaz-id      │ carpentry-01 │      1       │     85       │     true     │
│ diaz-id      │ tle-001      │      1       │     87       │    false     │ ← Auto-computed
│ diaz-id      │ filipino-001 │      1       │     90       │    false     │
└──────────────┴──────────────┴──────────────┴──────────────┴──────────────┘
```

---

## ✅ **KEY BENEFITS**

1. ✅ **Compliance with DepEd Standards**
   - MAPEH has 4 distinct components as per curriculum
   - TLE follows K-12 structure with specialization tracks

2. ✅ **Flexibility for Schools**
   - MAPEH structure is standardized (no confusion)
   - TLE allows customization based on school resources

3. ✅ **Accurate Grading**
   - Each component has separate gradebook
   - Parent grade is mathematically accurate (average)
   - No manual computation needed

4. ✅ **Teacher Specialization**
   - Each sub-subject can have dedicated teacher
   - Music teacher handles only Music assignments
   - PE teacher handles only PE assignments

5. ✅ **Clear Reporting**
   - SF9 forms show detailed breakdown
   - Parents see individual component grades
   - Administrators can track per-component performance

---

## 🎯 **IMPLEMENTATION READY**

The plan is comprehensive and addresses:
- ✅ Database schema changes
- ✅ RLS policy updates
- ✅ Backend service modifications
- ✅ UI/UX enhancements
- ✅ Data migration strategy
- ✅ Conflict resolution
- ✅ Testing scenarios

**Next Step:** Proceed with database migration file creation.


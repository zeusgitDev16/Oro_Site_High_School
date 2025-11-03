# 🎯 Final Role → Dashboard Mapping

## 📊 Complete Role Routing Logic

| Role ID | Role Name | Dashboard | Reasoning |
|---------|-----------|-----------|-----------|
| 1 | **admin** | **Admin Dashboard** | Full system administration |
| 2 | **teacher** | **Teacher Dashboard** | Basic teaching features |
| 3 | **student** | **Student Dashboard** | Student learning features |
| 4 | **parent** | **Parent Dashboard** | Parent monitoring features |
| 5 | **ict_coordinator** | **Admin Dashboard** | System/tech management (admin role) |
| 6 | **grade_coordinator** | **Teacher Dashboard** | Teaching + grade-level coordination |
| 7 | **hybrid** | **Teacher Dashboard** | Teaching + admin features |

---

## 🎯 Key Distinctions

### **Admin-Type Roles** (Admin Dashboard)
1. **admin** (role_id = 1)
   - Full system administration
   - User management, system settings
   - All admin features

2. **ict_coordinator** (role_id = 5)
   - System and technology management
   - ICT infrastructure, technical support
   - Admin dashboard with tech focus

### **Teacher-Type Roles** (Teacher Dashboard)
1. **teacher** (role_id = 2)
   - Basic teaching features
   - Course management, grading
   - No coordinator or admin features

2. **grade_coordinator** (role_id = 6)
   - All teacher features
   - **+ Coordinator mode** (grade-level management)
   - Manages students in specific grade level

3. **hybrid** (role_id = 7)
   - All teacher features
   - **+ Admin features** (user management, system access)
   - Can switch between teaching and admin tasks

---

## 🔑 Feature Access Matrix

| Feature | Admin | ICT Coord | Teacher | Grade Coord | Hybrid |
|---------|-------|-----------|---------|-------------|--------|
| **Admin Dashboard** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Teacher Dashboard** | ❌ | ❌ | ✅ | ✅ | ✅ |
| User Management | ✅ | ✅ | ❌ | ❌ | ✅ |
| System Settings | ✅ | ✅ | ❌ | ❌ | ✅ |
| Course Management | ✅ | ✅ | ✅ | ✅ | ✅ |
| Grading | ❌ | ❌ | ✅ | ✅ | ✅ |
| Coordinator Mode | ❌ | ❌ | ❌ | ✅ | ❌ |
| ICT Systems | ❌ | ✅ | ❌ | ❌ | ❌ |

---

## 📝 Routing Logic (Code)

```dart
switch (userRole.toLowerCase()) {
  case 'admin':
    return AdminDashboardScreen();  // Full admin
    
  case 'ict_coordinator':
    return AdminDashboardScreen();  // ICT = Admin
    
  case 'teacher':
    return TeacherDashboardScreen();  // Basic teacher
    
  case 'grade_coordinator':
    return TeacherDashboardScreen();  // Teacher + coordinator mode
    
  case 'hybrid':
    return TeacherDashboardScreen();  // Teacher + admin features
    
  case 'student':
    return StudentDashboardScreen();
    
  case 'parent':
    return ParentDashboardScreen();
}
```

---

## 🎓 Role Hierarchy

```
┌─────────────────────────────────────┐
│         ADMIN DASHBOARD             │
│  ┌──────────┐    ┌──────────────┐  │
│  │  Admin   │    │ ICT Coord    │  │
│  │ (Full)   │    │ (Tech Focus) │  │
│  └──────────┘    └──────────────┘  │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│        TEACHER DASHBOARD            │
│  ┌──────────┐  ┌──────────┐  ┌────┐│
│  │ Teacher  │  │  Grade   │  │Hyb-││
│  │ (Basic)  │  │  Coord   │  │rid ││
│  │          │  │ (+Coord) │  │(+Ad││
│  └─���────────┘  └──────────┘  └────┘│
└─────────────────────────────────────┘
```

---

## 🔍 Use Cases

### **Scenario 1: ICT Coordinator Login**
```
User: ICT_Coordinator@school.com
Role: ict_coordinator (role_id = 5)
Dashboard: Admin Dashboard ✅
Features: System management, user management, ICT systems
```

### **Scenario 2: Grade Coordinator Login**
```
User: grade7_coordinator@school.com
Role: grade_coordinator (role_id = 6)
Dashboard: Teacher Dashboard ✅
Features: Teaching, grading, + coordinator mode for Grade 7
```

### **Scenario 3: Hybrid User Login**
```
User: principal_teacher@school.com
Role: hybrid (role_id = 7)
Dashboard: Teacher Dashboard ✅
Features: Teaching, grading, + admin features (user management)
```

### **Scenario 4: Regular Teacher Login**
```
User: teacher@school.com
Role: teacher (role_id = 2)
Dashboard: Teacher Dashboard ✅
Features: Teaching, grading only (no coordinator or admin)
```

---

## ✅ What Was Fixed

### **Before (WRONG)**
```dart
case 'ict_coordinator':
  return TeacherDashboardScreen();  // ❌ Wrong!
```

### **After (CORRECT)**
```dart
case 'ict_coordinator':
  return AdminDashboardScreen();  // ✅ Correct!
```

---

## 🧪 Testing Guide

### **Test 1: ICT Coordinator**
1. Login with `ICT_Coordinator@...`
2. Should see: **Admin Dashboard** ✅
3. Should have: System management features

### **Test 2: Grade Coordinator**
1. Login with grade coordinator account
2. Should see: **Teacher Dashboard** ✅
3. Should have: Coordinator mode option

### **Test 3: Hybrid User**
1. Login with hybrid account
2. Should see: **Teacher Dashboard** ✅
3. Should have: Admin features in menu

### **Test 4: Regular Teacher**
1. Login with teacher account
2. Should see: **Teacher Dashboard** ✅
3. Should NOT have: Coordinator or admin features

---

## 📊 Summary

### **Admin Dashboard Users**
- ✅ admin (full system admin)
- ✅ ict_coordinator (tech/system admin)

### **Teacher Dashboard Users**
- ✅ teacher (basic features)
- ✅ grade_coordinator (+ coordinator mode)
- ✅ hybrid (+ admin features)

### **Other Dashboards**
- ✅ student → Student Dashboard
- ✅ parent → Parent Dashboard

---

**Status**: ✅ Fixed and Ready to Test  
**Impact**: ICT Coordinators now route to Admin Dashboard  
**Next**: Hot restart app and test ICT Coordinator login

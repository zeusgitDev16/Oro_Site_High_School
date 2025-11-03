# 🧭 TEACHER NAVIGATION LOGIC - IMPLEMENTATION GUIDE

## Overview

Implemented a smart navigation system that remembers where the user came from (Dashboard or Profile) and returns them to the correct screen when they press the back button.

---

## ✅ How It Works

### **1. Origin Tracking**
Each screen accepts an `origin` parameter:
- `'dashboard'` - User came from the main dashboard
- `'profile'` - User came from the profile screen

### **2. Back Button Behavior**
- **From Dashboard → Screen → Back** = Returns to Dashboard
- **From Profile → Screen → Back** = Returns to Profile

---

## 📋 Implementation Pattern

### **Step 1: Add Origin Parameter to Screen**

```dart
class MyCoursesScreen extends StatefulWidget {
  final String origin; // 'dashboard' or 'profile'
  
  const MyCoursesScreen({super.key, this.origin = 'dashboard'});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}
```

### **Step 2: Import Required Screens**

```dart
import 'package:oro_site_high_school/screens/teacher/teacher_dashboard_screen.dart';
import 'package:oro_site_high_school/screens/teacher/profile/teacher_profile_screen.dart';
```

### **Step 3: Wrap Scaffold with WillPopScope**

```dart
@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      // Navigate back to the origin screen
      if (widget.origin == 'profile') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TeacherProfileScreen(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TeacherDashboardScreen(),
          ),
        );
      }
      return false; // Prevent default pop behavior
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Same logic as onWillPop
            if (widget.origin == 'profile') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherProfileScreen(),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherDashboardScreen(),
                ),
              );
            }
          },
        ),
      ),
      body: // Your body content
    ),
  );
}
```

---

## 🎯 Screens to Update

### **✅ Already Implemented:**
1. **MyCoursesScreen** - Complete with origin tracking

### **🔄 Need to Implement:**
2. **MyStudentsScreen**
3. **GradeEntryScreen**
4. **AttendanceMainScreen**
5. **MyAssignmentsScreen**
6. **MyResourcesScreen**
7. **MessagesScreen**
8. **ReportsMainScreen**

---

## 📝 Navigation from Dashboard

In `teacher_dashboard_screen.dart`, screens are called with `origin: 'dashboard'` (default):

```dart
// Example from dashboard
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MyCoursesScreen(), // Uses default 'dashboard'
  ),
);
```

---

## 📝 Navigation from Profile

In `teacher_profile_screen.dart`, screens are called with `origin: 'profile'`:

```dart
// Example from profile
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MyCoursesScreen(origin: 'profile'),
  ),
);
```

---

## 🔄 Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    NAVIGATION FLOW                          │
└─────────────────────────────────────────────────────────────┘

SCENARIO 1: From Dashboard
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   Dashboard  │ ──────> │  My Courses  │ ──────> │   Dashboard  │
│              │  Click  │ (origin:     │  Back   │              │
│              │  Courses│  'dashboard')│  Button │              │
└──────────────┘         └──────────────┘         └──────────────┘

SCENARIO 2: From Profile
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   Profile    │ ──────> │  My Courses  │ ──────> │   Profile    │
│              │  Click  │ (origin:     │  Back   │              │
│              │  Courses│  'profile')  │  Button │              │
└──────────────┘         └──────────────┘         └──────────────┘
```

---

## 🎨 User Experience

### **Before Implementation:**
- ❌ User in Profile → Clicks Courses → Back button → Goes to Dashboard (wrong!)
- ❌ Inconsistent navigation experience

### **After Implementation:**
- ✅ User in Profile → Clicks Courses → Back button → Returns to Profile (correct!)
- ✅ User in Dashboard → Clicks Courses → Back button → Returns to Dashboard (correct!)
- ✅ Consistent and intuitive navigation

---

## 🛠️ Quick Implementation Checklist

For each screen that needs updating:

- [ ] Add `final String origin;` parameter
- [ ] Add `origin = 'dashboard'` as default value
- [ ] Import `TeacherDashboardScreen` and `TeacherProfileScreen`
- [ ] Wrap `Scaffold` with `WillPopScope`
- [ ] Implement `onWillPop` with conditional navigation
- [ ] Override `leading` in AppBar with custom back button
- [ ] Test from both Dashboard and Profile

---

## 📊 Implementation Status

| Screen | Status | Notes |
|--------|--------|-------|
| MyCoursesScreen | ✅ Complete | Fully implemented |
| MyStudentsScreen | ⏳ Pending | Need to add origin logic |
| GradeEntryScreen | ⏳ Pending | Need to add origin logic |
| AttendanceMainScreen | ⏳ Pending | Need to add origin logic |
| MyAssignmentsScreen | ⏳ Pending | Need to add origin logic |
| MyResourcesScreen | ⏳ Pending | Need to add origin logic |
| MessagesScreen | ⏳ Pending | Need to add origin logic |
| ReportsMainScreen | ⏳ Pending | Need to add origin logic |

---

## 🎯 Benefits

1. **Intuitive Navigation** - Users return to where they came from
2. **Better UX** - No confusion about navigation flow
3. **Consistent Behavior** - Same pattern across all screens
4. **Easy to Maintain** - Simple, repeatable pattern
5. **Scalable** - Easy to add to new screens

---

## 🚀 Next Steps

1. Apply the same pattern to remaining 7 screens
2. Test navigation from both Dashboard and Profile
3. Verify back button behavior on all screens
4. Document any edge cases or special scenarios

---

**Status**: ✅ Pattern Established - Ready for Full Implementation

**Completed**: MyCoursesScreen  
**Remaining**: 7 screens

---

**Document Version**: 1.0  
**Last Updated**: Current Session  
**Implementation**: Teacher Portal Navigation Logic

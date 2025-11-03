# STUDENT SIDE - EXECUTION ROADMAP
## Step-by-Step Implementation Guide

---

## 🎯 OBJECTIVE

Complete the student side by implementing Profile & Settings (Phase 7) and Final Polish (Phase 8), bringing the student side from 75% to 100% completion.

---

## 📋 EXECUTION PLAN

---

## **PHASE 7: PROFILE & SETTINGS**

### **MILESTONE 7.1: Profile Logic Foundation**
**Estimated Time**: 30 minutes

#### **Task 7.1.1: Create Student Profile Logic**
**File**: `lib/flow/student/student_profile_logic.dart`

**Implementation**:
```dart
import 'package:flutter/material.dart';

class StudentProfileLogic extends ChangeNotifier {
  // Sidebar selection (0=Profile, 1=Settings, 2=Security)
  int _sidebarSelectedIndex = 0;
  
  // Mock student data
  final Map<String, dynamic> _studentData = {
    'studentId': 'S-2024-001',
    'lrn': '123456789012',
    'firstName': 'Juan',
    'lastName': 'Dela Cruz',
    'middleName': 'Santos',
    'email': 'juan.delacruz@oshs.edu.ph',
    'phone': '+63 912 345 6789',
    'gradeLevel': 'Grade 7',
    'section': '7-Diamond',
    'adviser': 'Maria Santos',
    'enrollmentDate': 'August 15, 2024',
    'birthDate': 'January 15, 2010',
    'address': 'Cagayan de Oro City',
    'guardian': 'Pedro Dela Cruz',
    'guardianPhone': '+63 912 345 6780',
    'bio': 'I am a Grade 7 student passionate about mathematics and science. I enjoy learning new things and participating in school activities.',
  };
  
  // Getters
  int get sidebarSelectedIndex => _sidebarSelectedIndex;
  Map<String, dynamic> get studentData => _studentData;
  
  // Methods
  void setSidebarIndex(int index) {
    _sidebarSelectedIndex = index;
    notifyListeners();
  }
  
  void updateStudentData(Map<String, dynamic> updates) {
    _studentData.addAll(updates);
    notifyListeners();
  }
}
```

**Checklist**:
- [ ] Create file
- [ ] Add imports
- [ ] Define class extending ChangeNotifier
- [ ] Add mock student data
- [ ] Add sidebar selection state
- [ ] Add getters and methods
- [ ] Test compilation

---

#### **Task 7.1.2: Create Student Settings Logic**
**File**: `lib/flow/student/student_settings_logic.dart`

**Implementation**:
```dart
import 'package:flutter/material.dart';

class StudentSettingsLogic extends ChangeNotifier {
  // Settings state
  Map<String, dynamic> _settings = {
    'notifications': {
      'assignments': true,
      'grades': true,
      'messages': true,
      'announcements': true,
    },
    'display': {
      'theme': 'light', // light, dark, auto
      'language': 'en', // en, fil
    },
    'privacy': {
      'showProfile': true,
      'showGrades': false,
    },
  };
  
  // Getters
  Map<String, dynamic> get settings => _settings;
  
  bool getNotificationSetting(String key) {
    return _settings['notifications'][key] ?? false;
  }
  
  String getDisplaySetting(String key) {
    return _settings['display'][key] ?? '';
  }
  
  bool getPrivacySetting(String key) {
    return _settings['privacy'][key] ?? false;
  }
  
  // Methods
  void toggleNotification(String key) {
    _settings['notifications'][key] = !_settings['notifications'][key];
    notifyListeners();
  }
  
  void setDisplaySetting(String key, String value) {
    _settings['display'][key] = value;
    notifyListeners();
  }
  
  void togglePrivacy(String key) {
    _settings['privacy'][key] = !_settings['privacy'][key];
    notifyListeners();
  }
  
  void saveSettings() {
    // TODO: Save to backend when ready
    notifyListeners();
  }
}
```

**Checklist**:
- [ ] Create file
- [ ] Add imports
- [ ] Define class extending ChangeNotifier
- [ ] Add settings state
- [ ] Add getters
- [ ] Add toggle methods
- [ ] Test compilation

---

### **MILESTONE 7.2: Profile Screen UI**
**Estimated Time**: 2 hours

#### **Task 7.2.1: Create Profile Screen Structure**
**File**: `lib/screens/student/profile/student_profile_screen.dart`

**Strategy**: Copy `teacher_profile_screen.dart` and adapt for student

**Key Changes**:
1. Replace "Teacher" with "Student"
2. Replace "Employee ID" with "LRN"
3. Replace "Department" with "Grade Level"
4. Replace "Position" with "Section"
5. Update mock data
6. Change color accent from blue to green
7. Update navigation imports

**Checklist**:
- [ ] Create profile directory
- [ ] Copy teacher profile screen
- [ ] Update class name
- [ ] Update imports
- [ ] Change terminology
- [ ] Update mock data
- [ ] Change colors (blue → green)
- [ ] Test compilation
- [ ] Test navigation

---

#### **Task 7.2.2: Implement Profile Tabs**

**Tabs to Implement**:
1. **About Tab**: Bio, interests, achievements
2. **Info Tab**: Personal information (LRN, email, phone, address, guardian)
3. **Academic Tab**: Grade level, section, adviser, enrolled courses
4. **Statistics Tab**: GPA, attendance rate, assignments completed
5. **Schedule Tab**: Weekly class schedule

**Checklist**:
- [ ] About tab content
- [ ] Info tab content
- [ ] Academic tab content
- [ ] Statistics tab content
- [ ] Schedule tab content
- [ ] Tab navigation works
- [ ] Content displays correctly

---

#### **Task 7.2.3: Implement Profile Sidebar**

**Sidebar Items**:
1. Profile (default selected)
2. Settings
3. Security

**Checklist**:
- [ ] Profile sidebar layout
- [ ] Selection state works
- [ ] Switches between Profile/Settings/Security
- [ ] Visual feedback on selection

---

### **MILESTONE 7.3: Supporting Screens**
**Estimated Time**: 1.5 hours

#### **Task 7.3.1: Create Edit Profile Screen**
**File**: `lib/screens/student/profile/edit_profile_screen.dart`

**Features**:
- Edit bio
- Edit phone number
- Edit address
- Edit guardian contact
- Save/Cancel buttons

**Checklist**:
- [ ] Create file
- [ ] Add form fields
- [ ] Add validation
- [ ] Add save button
- [ ] Add cancel button
- [ ] Test save functionality
- [ ] Test cancel functionality

---

#### **Task 7.3.2: Create Settings Screen**
**File**: `lib/screens/student/profile/settings_screen.dart`

**Sections**:
1. Notifications (toggles)
2. Display (dropdowns)
3. Privacy (toggles)
4. App preferences

**Checklist**:
- [ ] Create file
- [ ] Add notification toggles
- [ ] Add display dropdowns
- [ ] Add privacy toggles
- [ ] Add save button
- [ ] Test toggle functionality
- [ ] Test save functionality

---

### **MILESTONE 7.4: Dashboard Integration**
**Estimated Time**: 1 hour

#### **Task 7.4.1: Update Avatar Click Behavior**
**File**: `lib/screens/student/dashboard/student_dashboard_screen.dart`

**Current Code** (lines ~400-450):
```dart
Widget _buildProfileAvatarWithDropdown() {
  return Container(
    decoration: BoxDecoration(...),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => _showComingSoonSnackbar('Profile'), // ❌ WRONG
          child: CircleAvatar(...),
        ),
        PopupMenuButton<String>(
          itemBuilder: (context) => [
            PopupMenuItem(value: 'profile', ...), // ❌ REMOVE
            PopupMenuItem(value: 'settings', ...), // ❌ REMOVE
            PopupMenuItem(value: 'logout', ...),   // ✅ KEEP
          ],
        ),
      ],
    ),
  );
}
```

**New Code**:
```dart
Widget _buildProfileAvatarWithDropdown() {
  return Container(
    decoration: BoxDecoration(...),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentProfileScreen(),
            ),
          ), // ✅ NAVIGATE TO PROFILE
          child: CircleAvatar(...),
        ),
        PopupMenuButton<String>(
          itemBuilder: (context) => [
            PopupMenuItem(value: 'logout', ...), // ✅ ONLY LOGOUT
          ],
          onSelected: (value) {
            if (value == 'logout') {
              showLogoutDialog(context);
            }
          },
        ),
      ],
    ),
  );
}
```

**Checklist**:
- [ ] Add import for StudentProfileScreen
- [ ] Change avatar onTap to navigate
- [ ] Remove 'profile' menu item
- [ ] Remove 'settings' menu item
- [ ] Keep only 'logout' menu item
- [ ] Remove profile/settings handling in onSelected
- [ ] Test avatar click
- [ ] Test dropdown

---

#### **Task 7.4.2: Update Profile Navigation in Sidebar**
**File**: `lib/screens/student/dashboard/student_dashboard_screen.dart`

**Current Code** (line ~200):
```dart
else if (index == 8) {
  // Profile
  _showComingSoonSnackbar('Profile'); // ❌ WRONG
}
```

**New Code**:
```dart
else if (index == 8) {
  // Profile
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const StudentProfileScreen(),
    ),
  ); // ✅ NAVIGATE TO PROFILE
}
```

**Checklist**:
- [ ] Update profile navigation
- [ ] Test sidebar profile click
- [ ] Verify navigation works

---

## **PHASE 8: FINAL POLISH**

### **MILESTONE 8.1: Help & Calendar**
**Estimated Time**: 1 hour

#### **Task 8.1.1: Create Student Help Dialog**
**File**: `lib/screens/student/dialogs/student_help_dialog.dart`

**Strategy**: Copy teacher help dialog pattern, adapt for student

**Help Sections**:
1. Viewing Courses
2. Submitting Assignments
3. Checking Grades
4. Viewing Attendance
5. Sending Messages
6. Reading Announcements
7. Contact Support

**Checklist**:
- [ ] Create dialogs directory if needed
- [ ] Create help dialog file
- [ ] Add help sections
- [ ] Add navigation examples
- [ ] Test dialog display

---

#### **Task 8.1.2: Wire Up Help Feature**
**File**: `lib/screens/student/dashboard/student_dashboard_screen.dart`

**Current Code** (line ~210):
```dart
else if (index == 9) {
  // Help
  _showComingSoonSnackbar('Help'); // ❌ WRONG
}
```

**New Code**:
```dart
else if (index == 9) {
  // Help
  showStudentHelpDialog(context); // ✅ SHOW HELP DIALOG
}
```

**Checklist**:
- [ ] Add import for help dialog
- [ ] Update help navigation
- [ ] Test help click
- [ ] Verify dialog displays

---

#### **Task 8.1.3: Wire Up Calendar Feature**
**File**: `lib/screens/student/dashboard/student_dashboard_screen.dart`

**Current Code** (line ~205):
```dart
else if (index == 7) {
  // Calendar
  _showComingSoonSnackbar('Calendar'); // ❌ WRONG
}
```

**New Code**:
```dart
else if (index == 7) {
  // Calendar
  showDialog(
    context: context,
    builder: (_) => const CalendarDialog(),
  ); // ✅ SHOW CALENDAR DIALOG
}
```

**Checklist**:
- [ ] Update calendar navigation
- [ ] Test calendar click
- [ ] Verify dialog displays

---

### **MILESTONE 8.2: Navigation Consistency**
**Estimated Time**: 1 hour

#### **Task 8.2.1: Verify Back Navigation**

**Files to Check**:
- `student_courses_screen.dart`
- `student_assignments_screen.dart`
- `student_grades_screen.dart`
- `student_attendance_screen.dart`
- `student_messages_screen.dart`
- `student_announcements_screen.dart`

**Checklist**:
- [ ] All screens have back button
- [ ] Back button navigates correctly
- [ ] No navigation loops
- [ ] No orphaned screens

---

#### **Task 8.2.2: Test Profile Navigation**

**Test Scenarios**:
1. Dashboard → Profile (avatar click)
2. Dashboard → Profile (sidebar click)
3. Profile → Courses → Back to Profile
4. Profile → Assignments → Back to Profile
5. Profile → Grades → Back to Profile
6. Profile → Edit Profile → Back to Profile
7. Profile → Settings → Back to Profile

**Checklist**:
- [ ] Avatar click works
- [ ] Sidebar click works
- [ ] Can navigate to other screens from profile
- [ ] Can navigate back to profile
- [ ] No navigation issues

---

### **MILESTONE 8.3: Comprehensive Testing**
**Estimated Time**: 1 hour

#### **Task 8.3.1: Feature Testing**

**Dashboard Tests**:
- [ ] All sidebar items navigate correctly
- [ ] Avatar click goes to profile
- [ ] Dropdown shows only logout
- [ ] Logout works correctly
- [ ] Calendar opens dialog
- [ ] Help opens dialog
- [ ] Notifications badge shows count
- [ ] Messages badge shows count

**Profile Tests**:
- [ ] Profile screen displays
- [ ] All 5 tabs work
- [ ] Profile sidebar switches content
- [ ] Edit profile opens
- [ ] Settings opens
- [ ] Security tab displays
- [ ] Can navigate back to dashboard

**Feature Tests**:
- [ ] Courses display and navigate
- [ ] Assignments submit and display
- [ ] Grades show correctly
- [ ] Attendance records display
- [ ] Messages send and receive
- [ ] Announcements filter and display

---

#### **Task 8.3.2: Integration Testing**

**Teacher-Student Relationship Tests**:
- [ ] Course data flows correctly
- [ ] Assignment data flows correctly
- [ ] Grade data flows correctly
- [ ] Attendance data flows correctly
- [ ] Message data flows correctly
- [ ] Announcement data flows correctly

**Navigation Tests**:
- [ ] All navigation paths work
- [ ] No broken links
- [ ] No console errors
- [ ] No navigation loops
- [ ] Back button works everywhere

---

### **MILESTONE 8.4: Documentation**
**Estimated Time**: 30 minutes

#### **Task 8.4.1: Create Completion Documents**

**Documents to Create**:
1. `STUDENT_PHASE_7_COMPLETE.md` - Profile & Settings completion
2. `STUDENT_PHASE_8_COMPLETE.md` - Final polish completion
3. `STUDENT_SIDE_COMPLETE.md` - Overall completion summary

**Checklist**:
- [ ] Document Phase 7 completion
- [ ] Document Phase 8 completion
- [ ] Document overall completion
- [ ] List all files created
- [ ] List all files modified
- [ ] Document testing results
- [ ] Add screenshots (optional)

---

#### **Task 8.4.2: Update Progress Documents**

**Documents to Update**:
1. `OVERALL_PROGRESS.md` - Update student side progress
2. `FINAL_PROJECT_STATUS.md` - Update overall project status

**Checklist**:
- [ ] Update student side percentage
- [ ] Update phase completion status
- [ ] Update file counts
- [ ] Update feature counts

---

## 📊 PROGRESS TRACKING

### **Phase 7 Progress**
```
Milestone 7.1: Profile Logic         [░░░░░░░░░░] 0%
Milestone 7.2: Profile Screen UI     [░░░░░░░░░░] 0%
Milestone 7.3: Supporting Screens    [░░░░░░░░░░] 0%
Milestone 7.4: Dashboard Integration [░░░░░░░░░░] 0%
```

### **Phase 8 Progress**
```
Milestone 8.1: Help & Calendar       [░░░░░░░░░░] 0%
Milestone 8.2: Navigation Consistency[░░░░░░░░░░] 0%
Milestone 8.3: Comprehensive Testing [░░░░░░░░░░] 0%
Milestone 8.4: Documentation         [░░░░░░░░░░] 0%
```

---

## 🎯 COMPLETION CRITERIA

### **Phase 7 Complete When**:
- ✅ All logic files created
- ✅ Profile screen displays correctly
- ✅ All tabs functional
- ✅ Edit profile works
- ✅ Settings works
- ✅ Avatar click navigates to profile
- ✅ Dropdown shows only logout

### **Phase 8 Complete When**:
- ✅ Help dialog functional
- ✅ Calendar feature wired up
- ✅ All navigation consistent
- ✅ All tests pass
- ✅ Documentation complete

### **Student Side 100% Complete When**:
- ✅ All 8 phases complete
- ✅ All features functional
- ✅ UI matches admin/teacher
- ✅ No console errors
- ✅ Ready for backend integration

---

## 🚀 EXECUTION ORDER

### **Recommended Order**:
1. ✅ Create logic files (Foundation)
2. ✅ Create profile screen (Core feature)
3. ✅ Create supporting screens (Complete profile)
4. ✅ Update dashboard (Integration)
5. ✅ Create help dialog (Polish)
6. ✅ Wire up features (Polish)
7. ✅ Test everything (Quality)
8. ✅ Document completion (Finalize)

### **Time Allocation**:
- Phase 7: 5 hours
- Phase 8: 3 hours
- **Total: 8 hours**

---

## 📝 NOTES

### **Important Reminders**:
- ⚠️ Don't modify admin/teacher files
- ⚠️ Don't modify existing student features
- ⚠️ Follow existing patterns
- ⚠️ Use mock data only
- ⚠️ Test after each milestone

### **Quality Standards**:
- ✅ UI/Logic separation maintained
- ✅ Files small and focused
- ✅ Code follows existing patterns
- ✅ No console errors
- ✅ Comprehensive testing

---

## 🎉 SUCCESS!

Upon completion:
- ✅ Student side 100% complete
- ✅ Matches admin/teacher design
- ✅ All features functional
- ✅ Ready for backend integration
- ✅ Excellent user experience

---

**Status**: Ready to Execute
**Next Action**: Start Milestone 7.1
**Estimated Completion**: 8 hours
**Priority**: HIGH

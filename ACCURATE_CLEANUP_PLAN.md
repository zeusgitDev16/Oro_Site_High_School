# 🧹 Accurate & Safe Cleanup Plan

## Phase 1: Delete Popup Files ✅ SAFE TO DELETE

### Files to Delete:
1. `lib/screens/admin/widgets/sections_popup.dart` - Sections management popup
2. `lib/screens/admin/widgets/attendance_popup.dart` - Attendance management popup

**Impact**: None - Already removed from navigation

---

## Phase 2: Delete Attendance Screens ✅ SAFE TO DELETE

### Entire Folder:
`lib/screens/admin/attendance/` containing:
1. `active_sessions_screen.dart`
2. `attendance_records_screen.dart`
3. `attendance_reports_screen.dart`
4. `create_attendance_session_screen.dart`
5. `scanning_permissions_screen.dart`

**Impact**: None - Not accessible from navigation

---

## Phase 3: Delete Attendance Reports ✅ SAFE TO DELETE

### File:
`lib/screens/admin/reports/attendance_reports_screen.dart`

**Impact**: None - Will remove from reports popup

---

## Phase 4: Clean Reports Popup ⚠️ NEEDS MODIFICATION

### File: `lib/screens/admin/widgets/reports_popup.dart`
**Action**: Remove attendance reports reference

---

## Phase 5: Clean Other Files ⚠️ CAREFUL - ANALYZE FIRST

### Files with Attendance/Sections References:
1. `lib/screens/admin/views/enhanced_home_view.dart` - Stats
2. `lib/screens/admin/views/teacher_overview_view.dart` - Performance metrics
3. `lib/screens/admin/help/help_screen.dart` - Help articles
4. `lib/screens/admin/notifications/notifications_screen.dart` - Notification types

**Action**: Remove attendance-related UI elements, keep core functionality

---

## Execution Order:
1. ✅ Delete popup files (Phase 1)
2. ✅ Delete attendance folder (Phase 2)
3. ✅ Delete attendance reports (Phase 3)
4. ⚠️ Modify reports popup (Phase 4)
5. ⚠️ Clean references in other files (Phase 5)

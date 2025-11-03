# Admin Popup Flow

## Overview
Simple, optimized click-based popup system for the admin dashboard.

## Features
✅ **Click to open** - Click sidebar item to open popup
✅ **Auto-switch** - Clicking different sidebar items automatically switches popups
✅ **Toggle** - Clicking the same item again closes the popup
✅ **Click outside to close** - Clicking anywhere outside closes the popup
✅ **Auto-close on navigation** - Popup closes when navigating to a new screen

## Usage

### In Sidebar Items
Already implemented in `admin_dashboard_screen.dart`. Just call the show popup method:

```dart
void _showCoursesPopup() {
  _popupFlow.showPopup(context, const CoursesPopup(), top: 150, index: 1);
}
```

### In Popup Widgets

#### To close popup when clicking an item:
```dart
import 'package:oro_site_high_school/flow/admin/popup_helper.dart';

// Simple close
PopupHelper.closePopup();
```

#### To navigate and close popup:
```dart
import 'package:oro_site_high_school/flow/admin/popup_helper.dart';

// Navigate to a screen and close popup
PopupHelper.navigateAndClosePopup(
  context,
  const CourseDetailScreen(),
);
```

#### To show a dialog and keep popup open:
```dart
import 'package:oro_site_high_school/flow/admin/popup_helper.dart';

// Show dialog (popup stays open)
PopupHelper.showDialogKeepPopup(
  context,
  const AddCourseDialog(),
);
```

## Example

See `courses_popup.dart` for a complete example:

```dart
Widget _buildCourseItem(String title, IconData icon) {
  return InkWell(
    onTap: () {
      // Close popup when clicking a course
      PopupHelper.closePopup();
      
      // Or navigate and close:
      // PopupHelper.navigateAndClosePopup(context, CourseDetailScreen());
    },
    child: Container(
      // ... course item UI
    ),
  );
}
```

## How It Works

1. **Click "Courses"** → Opens Courses popup
2. **Click "Goals"** → Automatically closes Courses, opens Goals
3. **Click "Courses" again** → Closes the popup (toggle)
4. **Click course item** → Closes popup (via `PopupHelper.closePopup()`)
5. **Click outside** → Closes popup
6. **Click "Add" button** → Shows dialog, popup stays open

## Benefits

- ✅ No blinking or flickering
- ✅ Smooth transitions between popups
- ✅ Simple and predictable behavior
- ✅ Easy to use in popup widgets
- ✅ Works on mobile and desktop

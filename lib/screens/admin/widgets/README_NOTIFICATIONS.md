# Admin Notification Panel - Developer Guide

## Quick Start

### Displaying the Notification Panel

```dart
// In your widget
final NotificationService _notificationService = NotificationService();

// Show the panel
showDialog(
  context: context,
  barrierColor: Colors.transparent,
  builder: (context) => Stack(
    children: [
      Positioned(
        top: 60,
        right: 20,
        child: AdminNotificationPanel(adminId: 'admin-1'),
      ),
    ],
  ),
);
```

### Getting Unread Count

```dart
final count = await _notificationService.getUnreadCount('admin-1');
```

### Creating a New Notification

```dart
final notification = AdminNotification(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  createdAt: DateTime.now(),
  recipientId: 'admin-1',
  title: 'New Enrollment',
  content: 'Student John Doe enrolled in Math 101',
  isRead: false,
  type: NotificationType.enrollment,
  senderName: 'John Doe',
  senderAvatar: 'JD',
  link: '/admin/users/john-doe',
);

await _notificationService.createAdminNotification(notification);
```

## Notification Types

```dart
enum NotificationType {
  enrollment,        // New student enrollments
  submission,        // Assignment submissions
  message,          // Student messages/queries
  systemAlert,      // System alerts
  courseCompletion, // Course completions
  attendance,       // Attendance issues
  gradeDispute,     // Grade disputes
  resourceRequest,  // Resource access requests
  assignmentCreated,// New assignments
  announcementPosted,// New announcements
}
```

## Customization

### Changing Panel Position

```dart
Positioned(
  top: 60,    // Distance from top
  right: 20,  // Distance from right
  child: AdminNotificationPanel(adminId: 'admin-1'),
)
```

### Changing Panel Size

Edit `admin_notification_panel.dart`:

```dart
Container(
  width: 420,  // Change width
  height: 600, // Change height
  // ...
)
```

### Adding Custom Notification Types

1. Add to `NotificationType` enum in `notification.dart`
2. Add icon mapping in `_getIconForType()`
3. Add color mapping in `_getColorForType()`
4. Add filter option if needed

### Customizing Colors

Edit the `_getColorForType()` method:

```dart
Color _getColorForType(NotificationType type) {
  switch (type) {
    case NotificationType.enrollment:
      return Colors.green; // Change this
    // ...
  }
}
```

## Integration with Real Database

### Supabase Setup

1. Create the `admin_notifications` table (see schema in main docs)
2. Remove mock data fallback in `notification_service.dart`
3. Update error handling to show actual errors

### Real-time Updates

```dart
// In NotificationService
void subscribeToNotifications(String adminId) {
  _supabase
    .from('admin_notifications')
    .stream(primaryKey: ['id'])
    .eq('recipient_id', adminId)
    .listen((data) {
      final notifications = data.map((item) => 
        AdminNotification.fromMap(item)
      ).toList();
      _notificationController.add(notifications);
    });
}
```

## Best Practices

1. **Always reload count after panel closes**
   ```dart
   await showDialog(...);
   _loadNotificationCount();
   ```

2. **Handle errors gracefully**
   ```dart
   try {
     await _notificationService.markAsRead(id);
   } catch (e) {
     // Show error message to user
   }
   ```

3. **Use proper admin ID**
   - Get from auth service
   - Don't hardcode 'admin-1'

4. **Optimize queries**
   - Only fetch unread count, not all notifications
   - Use pagination for large lists

5. **Test with various data**
   - Empty state
   - Single notification
   - Many notifications
   - Long content

## Common Issues

### Panel appears behind other widgets
- Increase `barrierColor` opacity
- Check z-index/stack order

### Notifications not updating
- Ensure state is being updated with `setState()`
- Check that service methods are being called

### Performance issues
- Implement pagination
- Limit notification list size
- Use `ListView.builder` (already implemented)

## API Reference

### AdminNotificationPanel

**Props:**
- `adminId` (required): String - The admin user ID

**Methods:**
- None (internal state management)

### NotificationService

**Methods:**
- `getAdminNotifications(String adminId)` → `Future<List<AdminNotification>>`
- `getUnreadAdminNotifications(String adminId)` → `Future<List<AdminNotification>>`
- `getUnreadCount(String adminId)` → `Future<int>`
- `markAsRead(String notificationId)` → `Future<void>`
- `markAllAsRead(String adminId)` → `Future<void>`
- `deleteNotification(String notificationId)` → `Future<void>`
- `createAdminNotification(AdminNotification)` → `Future<AdminNotification>`

## Examples

### Custom Notification Badge

```dart
Stack(
  children: [
    IconButton(
      icon: Icon(Icons.notifications),
      onPressed: _showNotifications,
    ),
    if (unreadCount > 0)
      Positioned(
        right: 8,
        top: 8,
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$unreadCount',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ),
      ),
  ],
)
```

### Filtering Notifications

```dart
// Get only submissions
final submissions = notifications
  .where((n) => n.type == NotificationType.submission)
  .toList();

// Get unread only
final unread = notifications
  .where((n) => !n.isRead)
  .toList();

// Get from last 24 hours
final recent = notifications
  .where((n) => 
    DateTime.now().difference(n.createdAt).inHours < 24
  )
  .toList();
```

### Triggering Notifications

```dart
// When student enrolls
void onStudentEnroll(Student student, Course course) {
  final notification = AdminNotification(
    id: generateId(),
    createdAt: DateTime.now(),
    recipientId: adminId,
    title: 'New Student Enrollment',
    content: '${student.name} enrolled in ${course.name}',
    isRead: false,
    type: NotificationType.enrollment,
    senderName: student.name,
    senderAvatar: student.initials,
    link: '/admin/users/${student.id}',
  );
  
  _notificationService.createAdminNotification(notification);
}
```

## Testing Checklist

- [ ] Panel opens on icon click
- [ ] Unread count displays correctly
- [ ] Notifications load and display
- [ ] Filtering works for all types
- [ ] Mark as read updates UI
- [ ] Mark all as read works
- [ ] Delete notification works
- [ ] Swipe to delete works
- [ ] Tab switching works
- [ ] To-do tab shows correct items
- [ ] Settings dialog opens
- [ ] Panel closes properly
- [ ] Count updates after closing
- [ ] Empty state displays
- [ ] Long content truncates
- [ ] Timestamps format correctly
- [ ] Colors match notification types
- [ ] Icons display correctly
- [ ] Responsive on different screens

---

For more detailed information, see `ADMIN_NOTIFICATION_SYSTEM.md`

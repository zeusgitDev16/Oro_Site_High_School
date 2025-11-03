# 📬 NEO LMS-Style Messaging System for Admin

## Overview

This messaging system is designed to match the **NEO LMS** (CypherLearning) student experience, adapted for admin use. It uses **dialog-based UI** instead of full-screen navigation, keeping users on the dashboard while managing messages.

---

## 🎯 Key Features

### ✅ Implemented

1. **Inbox Dialog** - Dropdown from inbox icon
   - Shows list of received messages
   - Unread count badge
   - Mark all read
   - New message button
   - See all / Configure options

2. **Message Detail Dialog** - View full message
   - From/To fields with avatars
   - Subject and body
   - Reply/Forward/Delete actions
   - Navigation arrows (previous/next message)
   - "and X more" for large recipient lists

3. **Compose Message Dialog** - Send messages
   - To field with user picker
   - Broadcast to roles (All Students, All Teachers, etc.)
   - Subject and body fields
   - Reply/Forward pre-fill
   - Monitoring notice

4. **Admin Broadcast** - Send to multiple users at once
   - Select roles (All Students = 1846+ users)
   - Select individual users
   - Mix roles and individuals
   - Shows total recipient count

---

## 📁 File Structure

```
lib/
├── flow/admin/messages/
│   └── messages_state.dart          # State management & models
├── screens/admin/
│   ├── dialogs/
│   │   ├── inbox_dialog.dart        # Inbox dropdown
│   │   ├── message_detail_dialog.dart  # Message viewer
│   │   ├── compose_message_dialog.dart # Message composer
│   │   └── message_helper.dart      # Helper functions
│   └── messages/
│       └── messages_screen.dart     # Full screen (legacy, optional)
```

---

## 🚀 Usage

### 1. Open Inbox

Click the **inbox icon** (📧) in the dashboard top bar:

```dart
// In admin_dashboard_screen.dart
IconButton(
  icon: Icon(Icons.mail_outline),
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => InboxDialog(state: _messagesState),
    );
  },
)
```

### 2. Send Message to User (from Profile)

Add "Message" button to user profiles:

```dart
// In user_profile_screen.dart
ElevatedButton.icon(
  icon: Icon(Icons.mail_outline),
  label: Text('Message'),
  onPressed: () {
    showDialog(
      context: context,
      builder: (_) => ComposeMessageDialog(
        state: messagesState,
        // TODO: Pre-select this user
      ),
    );
  },
)
```

### 3. Broadcast to All Users

Click "New message" in inbox, then select roles:

```dart
// Roles available:
- All Students
- All Teachers
- All Parents
- All Administrators
- All Managers
- All Staff
```

---

## 🎨 UI Components

### Inbox Dialog

```
┌─────────────────────────────────────┐
│ 📧 Inbox                         ✕  │
├─────────────────────────────────────┤
│ [Avatar] yeet                    ●  │
│          Apr 5, 3:07 pm             │
├─────────────────────────────────────┤
│ [Avatar] Leopoldo Pangilinan Jr. ✓  │
│          Access to MS Office...     │
│          Mar 7, 10:26 am            │
├─────────────────────────────────────┤
│ ≡ See all  ✓ Mark all  + New  ⚙    │
└─────────────────────────────────────┘
```

### Message Detail Dialog

```
┌──────────────────────────────────────────────┐
│ Message from Leopoldo Pangilinan Jr.     ✕  │
├──────────────────────────────────────────────┤
│ Access to MS Office Applications             │
│                                              │
│ From: [Avatar] Leopoldo @ Mar 7, 10:26 am   │
│ To: [Avatars] Ely, Angelo, Rhey and 1846... │
│                                              │
│ Good Day!                                    │
│ Please be informed that all teachers...      │
│                                              │
│ ◄ 1 of 3  [Reply] [Forward] [Delete]  ►     │
└──────────────────────────────────────────────┘
```

### Compose Dialog

```
┌──────────────────────────────────────────────┐
│ New message                               ✕  │
├────────────────────────────────��─────────────┤
│ To: [Chip: Ms. Cruz ✕] [+ Add recipient]    │
│                                              │
│ Broadcast to roles:                          │
│ [All Students] [All Teachers] [All Parents]  │
│                                              │
│ Subject: ___________________________         │
│                                              │
│ Message:                                     │
│ ┌──────────────────────────────────────┐    │
│ │                                      │    │
│ │                                      │    │
│ └──────────────────────────────────────┘    │
│                                              │
│ (your school monitors communications...)     │
│                                              │
│                    [Cancel]  [Send]          │
└──────────────────────────────────────────────┘
```

---

## 📊 Data Models

### Thread
```dart
class Thread {
  String id;
  String subject;
  List<User> participants;
  List<Msg> messages;
  Set<String> labels;
  bool pinned;
  bool starred;
  bool archived;
  bool locked;
  bool isAnnouncement;
  bool requireAck;
  bool sentByAdmin;
  bool isDraft;
  int unreadCount;
  DateTime lastMessageAt;
}
```

### Message (Msg)
```dart
class Msg {
  String id;
  User author;
  String body;
  DateTime createdAt;
}
```

### User
```dart
class User {
  String id;
  String name;
  String initials;
}
```

---

## 🔧 Admin-Specific Features

### 1. Broadcast to Roles

Admin can send one message to thousands of users:

```dart
// Example: Send to all students
_selectedRoles.add('All Students');
// This generates 1846 mock recipients
```

### 2. Message Monitoring

All messages show:
> "(your school monitors communications for offensive language)"

### 3. Read Receipts (Future)

Track who has read messages:
```dart
class Receipt {
  String userId;
  DateTime readAt;
  DateTime? acknowledgedAt;
}
```

### 4. Templates (Future)

Quick responses for common messages:
```dart
class Template {
  String id;
  String name;
  String body;
}
```

---

## 🎯 Differences from Student View

| Feature | Student | Admin |
|---------|---------|-------|
| **Inbox Access** | Inbox icon | Inbox icon (same) |
| **Send Messages** | To individuals only | To individuals + broadcast to roles |
| **Recipient Count** | 1-10 users | 1-1000+ users |
| **Message Detail** | Reply/Forward/Delete | Reply/Forward/Delete (same) |
| **Moderation** | ❌ No | ✅ Can delete any message |
| **Templates** | ❌ No | ✅ Canned responses |
| **Read Receipts** | ❌ Cannot see | ✅ Can see who read |

---

## 🚧 Future Enhancements

### Phase 2: Chat System

Separate real-time chat (different from messages):
- Side drawer overlay
- 1-on-1 conversations
- Online status indicators
- Typing indicators
- Mute conversations

### Phase 3: Advanced Features

- [ ] Cc/Bcc fields
- [ ] Rich text editor (bold, italic, lists)
- [ ] File attachments
- [ ] Schedule send
- [ ] Require acknowledgment
- [ ] Message templates library
- [ ] Search messages
- [ ] Filter by label/folder
- [ ] Export message logs
- [ ] Audit trail

---

## 📝 How to Test

1. **Open Inbox**
   - Click inbox icon in dashboard
   - Should see 3 mock messages
   - Badge shows unread count

2. **View Message**
   - Click any message in inbox
   - Should open detail dialog
   - See From/To/Subject/Body
   - Try Reply/Forward/Delete

3. **Send New Message**
   - Click "New message" in inbox
   - Select "All Students" role
   - Enter subject and body
   - Click Send
   - Should see "Broadcast sent to 1846 recipients"

4. **Mark as Read**
   - Click "Mark all read" in inbox
   - Badge should disappear

---

## 🐛 Known Issues

1. **No backend integration** - All data is mock/in-memory
2. **No real-time updates** - Messages don't auto-refresh
3. **No user search** - User picker shows fixed list
4. **No file attachments** - Only text messages
5. **No rich text** - Plain text only

---

## 🔗 Integration Points

### Where to Add "Message" Button

1. **User Profile Screen**
```dart
ElevatedButton.icon(
  icon: Icon(Icons.mail_outline),
  label: Text('Message'),
  onPressed: () => MessageHelper.messageUser(context, state, user),
)
```

2. **User List/Directory**
```dart
IconButton(
  icon: Icon(Icons.mail_outline),
  onPressed: () => MessageHelper.messageUser(context, state, user),
)
```

3. **Course Participants**
```dart
// Add message icon next to each participant
```

---

## 📚 References

- **NEO LMS**: https://www.neolms.com/
- **CypherLearning**: https://www.cypherlearning.com/
- **STI College**: Uses NEO LMS for student portal

---

## ✅ Checklist

- [x] Inbox dialog with message list
- [x] Message detail dialog with Reply/Forward/Delete
- [x] Compose dialog with user picker
- [x] Broadcast to roles (All Students, etc.)
- [x] Unread count badge
- [x] Mark all read
- [x] "and X more" for large recipient lists
- [x] Monitoring notice
- [x] Dialog-based (no full-screen navigation)
- [ ] Backend integration (Supabase)
- [ ] Real-time updates
- [ ] File attachments
- [ ] Rich text editor
- [ ] Templates library
- [ ] Read receipts
- [ ] Search/filter

---

## 🎓 For Developers

### Adding New Features

1. **State** - Add to `messages_state.dart`
2. **UI** - Create dialog in `screens/admin/dialogs/`
3. **Wire** - Connect in `admin_dashboard_screen.dart`

### Testing

```bash
# Run app
flutter run

# Hot reload after changes
r

# Hot restart
R
```

### Debugging

```dart
// Add print statements in state
print('Sending message to ${recipients.length} users');

// Check unread count
print('Unread: ${_messagesState.allThreads.fold(0, (sum, t) => sum + t.unreadCount)}');
```

---

**Last Updated**: 2024
**Version**: 1.0.0
**Status**: ✅ UI Complete, Backend Pending

# Student Messaging & Notification System - Test Guide

## 🚀 Quick Start

```bash
flutter run
```

## 🧪 Test Scenarios

### 1. Test Messages via Icon Button

**Steps**:
1. Login as Student
2. Look at top right corner of dashboard
3. Click the **mail icon** (envelope)
4. ✅ Verify: Messages screen opens with three-column layout

**Expected Result**:
- Three columns display (folders, threads, messages)
- 5 message threads visible
- 2 unread badges showing

### 2. Test Messages via Sidebar

**Steps**:
1. From dashboard, click **"Messages"** in left sidebar
2. ✅ Verify: Same messages screen opens

**Expected Result**:
- Identical to icon button navigation
- Same three-column layout

### 3. Test Notifications via Icon Button

**Steps**:
1. From dashboard, look at top right
2. Click the **bell icon** (notifications)
3. ✅ Verify: Notifications screen opens

**Expected Result**:
- Filter chips at top
- Statistics cards (Total: 6, Unread: 2)
- 6 notification cards display

### 4. Test Message Folders

**In Messages Screen**:
- Click **"All"** → Should show 5 threads
- Click **"Unread"** → Should show 2 threads (with blue dots)
- Click **"Starred"** → Should show 1 thread (with star icon)
- Click **"Archived"** → Should show 1 thread
- Click **"Sent"** → Should show 0 threads (no sent messages yet)

### 5. Test Message Compose

**Steps**:
1. Click **"Compose"** button (top of left sidebar OR in header)
2. Click **"Add teacher"** chip
3. Select a teacher (e.g., "Maria Santos")
4. Enter subject: "Test Message"
5. Enter message: "This is a test message"
6. Click **"Send"**
7. ✅ Verify: Success message appears
8. ✅ Verify: New thread appears in thread list

### 6. Test Message Reply

**Steps**:
1. Click on first thread "Assignment Feedback - Math Quiz 3"
2. Read the message from Maria Santos
3. Type a reply in the composer at bottom: "Thank you for the feedback!"
4. Click **send icon**
5. ✅ Verify: Your reply appears in the conversation
6. ✅ Verify: Reply has blue background (student message)
7. ✅ Verify: Teacher message has gray background

### 7. Test Message Actions

**Star a Thread**:
1. Select any thread
2. Click **star icon** in header
3. ✅ Verify: Star becomes filled/yellow
4. Go to "Starred" folder
5. ✅ Verify: Thread appears there

**Archive a Thread**:
1. Select any thread
2. Click **archive icon** in header
3. ✅ Verify: Thread moves to Archived folder
4. Go to "Archived" folder
5. ✅ Verify: Thread appears there

**Delete a Thread**:
1. Select any thread
2. Click **delete icon** in header
3. Confirm deletion
4. ✅ Verify: Thread disappears from list

### 8. Test Message Search

**Steps**:
1. In messages screen, find search bar (top of middle column)
2. Type "quiz"
3. ✅ Verify: Only threads with "quiz" in subject/content show
4. Clear search
5. ✅ Verify: All threads return

### 9. Test Notification Filters

**In Notifications Screen**:
- Click **"All"** → Shows all 6 notifications
- Click **"Unread"** → Shows 2 unread (with blue dots)
- Click **"Grades"** → Shows grade-related notifications
- Click **"Assignments"** → Shows assignment-related notifications
- Click **"Attendance"** → Shows attendance notifications
- Click **"Announcements"** → Shows announcement notifications

### 10. Test Mark as Read

**Single Notification**:
1. Find an unread notification (has blue dot)
2. Click on it
3. ✅ Verify: Blue dot disappears
4. ✅ Verify: Unread count decreases

**All Notifications**:
1. Click **"Mark all read"** button (top right)
2. ✅ Verify: All blue dots disappear
3. ✅ Verify: Unread count becomes 0
4. ✅ Verify: Success message appears

### 11. Test Unread Badges

**In Dashboard**:
1. Check notification icon (bell)
2. ✅ Verify: Red badge shows unread count (5)
3. Check messages icon (mail)
4. ✅ Verify: Blue badge shows unread count (3)

**After Reading**:
1. Open notifications, mark all as read
2. Return to dashboard
3. ✅ Verify: Notification badge disappears
4. Open messages, read unread threads
5. Return to dashboard
6. ✅ Verify: Messages badge updates

### 12. Test Labels

**In Messages Screen**:
1. Look at left sidebar under "LABELS"
2. Click **"Teachers"** label (blue)
3. ✅ Verify: Only teacher-related threads show
4. Click **"Important"** label (red)
5. ✅ Verify: Filters by important messages
6. Click **"Assignments"** label (green)
7. ✅ Verify: Filters by assignment-related messages

## ✅ Expected Mock Data

### Messages (5 threads)
1. **Assignment Feedback - Math Quiz 3** (Unread, Maria Santos)
2. **Reminder: Science Project Due Date** (Unread, Juan Cruz)
3. **Great work on your essay!** (Read, Starred, Ana Reyes)
4. **Attendance Follow-up** (Read, Maria Santos, 3 messages)
5. **Class Schedule Change** (Read, Archived, Pedro Santos)

### Notifications (6 items)
1. **New Grade Posted** (Unread, Grades)
2. **Assignment Due Soon** (Unread, Assignments)
3. **New Message from Teacher** (Read, Messages)
4. **Attendance Marked** (Read, Attendance)
5. **New Announcement** (Read, Announcements)
6. **Assignment Feedback** (Read, Assignments)

## 🐛 Troubleshooting

### Messages don't display
- Check console for errors
- Verify you're logged in as Student
- Try clicking Messages in sidebar instead of icon

### Notifications don't display
- Verify you're on Student dashboard
- Check that mock data is loaded
- Look for navigation errors in console

### Icon buttons don't work
- Verify imports in dashboard file
- Check that screens are properly created
- Look for navigation errors

### Compose dialog doesn't open
- Check that dialog file exists
- Verify imports are correct
- Look for dialog-related errors

## 📝 Notes

- All data is mock data (no backend)
- Messages and notifications are pre-populated
- Compose creates local threads only
- Unread counts update in real-time
- Same UI/UX as teacher/admin messaging

## 🎯 Success Criteria

✅ Icon buttons navigate to screens  
✅ Three-column layout displays  
✅ Folders filter correctly  
✅ Compose dialog works  
✅ Reply functionality works  
✅ Star/Archive/Delete work  
✅ Search filters threads  
✅ Notifications display  
✅ Filters work correctly  
✅ Mark as read works  
✅ Unread badges update  
✅ Labels filter correctly  

## 🎉 All Tests Passing?

If all tests pass, the messaging and notification system is working correctly and aligned with teacher/admin implementation!

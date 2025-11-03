# Phase 6 Setup Instructions

## 🚀 Run the Application

No new dependencies were added in Phase 6, so you can run directly:

```bash
flutter run
```

## 🧪 Test Phase 6 Features

### 1. Login as Student
- Click "Log In" button
- Click "Log in with Office 365"
- Select "Student" user type

### 2. Test Messages

#### Navigate to Messages
- Click "Messages" in the left sidebar
- You should see the three-column messages screen

#### Check Layout
- **Left Column**: Folders (All, Unread, Starred, Archived)
- **Middle Column**: Thread list with 5 conversations
- **Right Column**: Message view (select a thread to view)

#### Test Features
- Click "Unread" folder → Should show 2 unread threads
- Click "Starred" folder → Should show 1 starred thread
- Click "Archived" folder → Should show 1 archived thread
- Click "All" folder → Should show all 5 threads

#### View Conversation
- Click on first thread "Assignment Feedback - Math Quiz 3"
- Verify message displays from Maria Santos
- Check unread badge disappears

#### Send Reply
- Type a message in the reply box at bottom
- Click send button
- Verify message appears in conversation
- Check success notification

#### Test Actions
- Click star icon in header → Thread becomes starred
- Click archive icon → Thread becomes archived
- Search "quiz" → Should filter threads

### 3. Test Announcements

#### Navigate to Announcements
- Click "Announcements" in the left sidebar
- You should see the announcements feed

#### Check Feed
- Verify 8 announcement cards display
- Check unread indicators (blue dots on 2 announcements)
- Verify type badges (School, Class, Urgent)
- Check priority indicators (HIGH badge on urgent items)

#### Test Filters
- Click "All" chip → Shows all 8 announcements
- Click "School" chip → Shows 4 school announcements
- Click "Class" chip → Shows 3 class announcements
- Click "Urgent" chip → Shows 1 urgent announcement

#### View Announcement
- Click "Read More" on first announcement
- Verify dialog opens with full content
- Check author and timestamp display
- Verify blue dot disappears (marked as read)

#### Test Attachments
- View "Upcoming Quarterly Exam Schedule" announcement
- Verify "exam_schedule.pdf" attachment shows
- Click download icon
- Check download notification appears

### 4. Verify Data

#### Messages Data (5 threads)
1. **Assignment Feedback - Math Quiz 3** (Unread)
   - From: Maria Santos (Teacher)
   - 1 message

2. **Reminder: Science Project Due Date** (Unread)
   - From: Juan Cruz (Teacher)
   - 1 message

3. **Great work on your essay!** (Read, Starred)
   - From: Ana Reyes (Teacher)
   - 2 messages (conversation)

4. **Attendance Follow-up** (Read)
   - From: Maria Santos (Teacher)
   - 3 messages (conversation)

5. **Class Schedule Change** (Read, Archived)
   - From: Pedro Santos (Teacher)
   - 1 message

#### Announcements Data (8 items)
1. **Upcoming Quarterly Exam Schedule** (School, High, Unread)
   - Has attachment: exam_schedule.pdf

2. **Math 7 - Quiz 4 Postponed** (Class, Medium, Unread)
   - Course: Mathematics 7

3. **URGENT: Class Suspension Tomorrow** (Urgent, High, Read)
   - Urgent type with red badge

4. **Science Fair Registration Now Open** (School, Medium, Read)
   - Has 2 attachments

5. **English 7 - Essay Submission Extended** (Class, Low, Read)
   - Course: English 7

6. **Parent-Teacher Conference Schedule** (School, Medium, Read)
   - Has attachment

7. **Filipino 7 - Tula Submission Reminder** (Class, High, Read)
   - Course: Filipino 7

8. **School Library New Books Available** (School, Low, Read)
   - Has attachment

## ✅ Expected Results

### Messages Screen
- Three-column layout displays correctly
- Folders filter threads properly
- Thread list shows sender info and previews
- Unread badges display (2 unread)
- Message bubbles show correctly (teacher vs student)
- Reply functionality works
- Star/Archive actions work
- Search filters threads

### Announcements Screen
- Feed layout displays correctly
- Filter chips work (All, School, Class, Urgent)
- Announcement cards show all info
- Priority indicators display (HIGH badge)
- Type badges show (School, Class, Urgent)
- Unread indicators show (blue dots)
- Mark as read works
- Dialog view shows full content
- Attachments display with download button

## 🐛 Troubleshooting

### If messages don't display:
- Check console for errors
- Verify you're on the Student dashboard
- Try clicking "Messages" again

### If announcements don't load:
- Verify you're on the Student dashboard
- Check that mock data is loaded
- Look for navigation errors in console

### If reply doesn't work:
- Verify text is entered in reply box
- Check that thread is selected
- Look for send button click handler

## 📝 Notes

- All data is mock data (no backend calls)
- Messages and announcements are pre-populated
- Reply messages are added to local state only
- Download attachments shows notification only (no actual download)
- Unread counts update when viewing messages/announcements

## 🎯 What's Working

✅ Three-column messages layout  
✅ Folder navigation (All, Unread, Starred, Archived)  
✅ Thread list with sender info  
✅ Message conversation view  
✅ Reply functionality  
✅ Star/Archive actions  
✅ Search messages  
✅ Announcements feed  
✅ Filter by type (All, School, Class, Urgent)  
✅ Priority indicators  
✅ Mark as read  
✅ Expandable content dialog  
✅ Attachments display  

## 🔜 Coming Next (Phase 7+)

- Profile and settings
- Final polish and integration
- Performance optimization
- Error handling improvements

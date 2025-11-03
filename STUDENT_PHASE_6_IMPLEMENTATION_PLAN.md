# STUDENT SIDE - PHASE 6 IMPLEMENTATION PLAN
## Messages & Announcements

---

## ✅ Files Created So Far

### **1. Interactive Logic (COMPLETE)**
- ✅ **`lib/flow/student/student_messages_logic.dart`** - Messages state management
- ✅ **`lib/flow/student/student_announcements_logic.dart`** - Announcements state management

---

## 📋 Remaining Files to Create

### **2. UI Screens (TO BE CREATED)**

#### **Messages Screen**
- **`lib/screens/student/messages/student_messages_screen.dart`**
  - Three-column layout (folders, thread list, message view)
  - Folders: All, Unread, Starred, Archived
  - Thread list with sender info
  - Message conversation view
  - Reply functionality
  - Search messages

#### **Announcements Screen**
- **`lib/screens/student/announcements/student_announcements_screen.dart`**
  - Feed-style layout
  - Filter by type (All, School, Class, Urgent)
  - Announcement cards with priority indicators
  - Mark as read functionality
  - Attachments download
  - Timestamp display

### **3. Dashboard Integration (TO BE UPDATED)**
- **`lib/screens/student/dashboard/student_dashboard_screen.dart`**
  - Wire up "Messages" navigation (index 5)
  - Wire up "Announcements" navigation (index 6)

---

## 🎨 UI Design Specifications

### **Messages Screen Layout**

```
┌─────────────────────────────────────────────────────────────┐
│ Messages                                    [Compose] [Back] │
├──────────┬──────────────────┬──────────────────────────────┤
│ Folders  │  Thread List     │  Message View                │
│          │                  │                              │
│ All      │ ┌──────────────┐ │ ┌──────────────────────────┐│
│ Unread   │ │ Maria Santos │ │ │ Assignment Feedback      ││
│ Starred  │ │ Assignment.. │ │ │ From: Maria Santos       ││
│ Archived │ │ 2h ago    [1]│ │ ├──────��───────────────────┤│
│          │ └──────────────┘ │ │ Hi Juan! I reviewed...   ││
│          │ ┌──────────────┐ │ │                          ││
│          │ │ Juan Cruz    │ │ │ [Reply Box]              ││
│          │ │ Reminder...  │ │ └──────────────────────────┘│
│          │ │ 5h ago    [1]│ │                              │
│          │ └──────────────┘ │                              │
└──────────┴──────────────────┴──────────────────────────────┘
```

### **Announcements Screen Layout**

```
┌─────────────────────────────────────────────────────────────┐
│ Announcements                                        [Back]  │
├─────────────────────────────────────────────────────────────┤
│ Filter: [All ▼] [School] [Class] [Urgent]                  │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🔴 URGENT: Class Suspension Tomorrow                    │ │
│ │ Principal's Office • 5h ago                             │ │
│ │ Due to inclement weather, classes are suspended...      │ │
│ │ [Read More]                                             │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 📚 Math 7 - Quiz 4 Postponed                            │ │
│ │ Maria Santos • 3h ago                                   │ │
│ │ Good day class! Quiz 4 on Geometry has been...          │ │
│ │ [Read More]                                             │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Mock Data Summary

### **Messages (5 threads)**
1. **Assignment Feedback - Math Quiz 3** (Unread, from Maria Santos)
2. **Reminder: Science Project Due Date** (Unread, from Juan Cruz)
3. **Great work on your essay!** (Read, Starred, from Ana Reyes, 2 replies)
4. **Attendance Follow-up** (Read, from Maria Santos, 3 messages)
5. **Class Schedule Change** (Read, Archived, from Pedro Santos)

### **Announcements (8 items)**
1. **Upcoming Quarterly Exam Schedule** (School, High priority, Unread)
2. **Math 7 - Quiz 4 Postponed** (Class, Medium priority, Unread)
3. **URGENT: Class Suspension Tomorrow** (Urgent, High priority, Read)
4. **Science Fair Registration Now Open** (School, Medium priority, Read)
5. **English 7 - Essay Submission Extended** (Class, Low priority, Read)
6. **Parent-Teacher Conference Schedule** (School, Medium priority, Read)
7. **Filipino 7 - Tula Submission Reminder** (Class, High priority, Read)
8. **School Library New Books Available** (School, Low priority, Read)

---

## 🔗 Teacher-Student Relationship

### **Messages Flow**
```
TEACHER SIDE                          STUDENT SIDE
─────────���───────────────────────────────────────────────────
1. Teacher sends message              → Student receives in inbox
   - Assignment feedback              
   - Reminders                        
   - Follow-ups                       

2. Student reads message              → Marked as read
   - Views content                    

3. Student replies                    → Teacher receives reply
   - Asks questions                   
   - Acknowledges                     

4. Conversation continues             → Thread updated
   - Back and forth                   
```

### **Announcements Flow**
```
TEACHER/ADMIN SIDE                    STUDENT SIDE
─────────────────────────────────────────────────────────────
1. Teacher/Admin creates announcement → Student sees in feed
   - School-wide                      
   - Class-specific                   
   - Urgent alerts                    

2. Announcement published             → Appears in student feed
   - With priority                    
   - With attachments                 

3. Student reads announcement         → Marked as read
   - Views content                    
   - Downloads attachments            
```

---

## ✅ Features to Implement

### **Messages Screen**
- ✅ Three-column layout (folders, threads, messages)
- ✅ Folder navigation (All, Unread, Starred, Archived)
- ✅ Thread list with unread badges
- ✅ Message conversation view
- ✅ Reply functionality
- ✅ Star/Archive actions
- ✅ Search messages
- ✅ Sender information display
- ✅ Timestamp formatting

### **Announcements Screen**
- ✅ Feed-style layout
- ✅ Filter by type (All, School, Class, Urgent)
- ✅ Priority indicators (High, Medium, Low)
- ✅ Unread badges
- ✅ Mark as read
- ✅ Expandable content
- ✅ Attachments list with download
- ✅ Author and role display
- ✅ Course context (for class announcements)

---

## 🎯 Implementation Steps

### **Step 1: Create Messages Screen** ✅ LOGIC DONE
1. Create `student_messages_screen.dart`
2. Implement three-column layout
3. Add folder navigation
4. Build thread list
5. Create message view
6. Add reply functionality
7. Implement star/archive actions

### **Step 2: Create Announcements Screen** ✅ LOGIC DONE
1. Create `student_announcements_screen.dart`
2. Implement feed layout
3. Add filter chips
4. Build announcement cards
5. Add priority indicators
6. Implement mark as read
7. Add attachments section

### **Step 3: Update Dashboard**
1. Wire up Messages navigation (index 5)
2. Wire up Announcements navigation (index 6)
3. Update unread counts in badges

---

## 📝 Code Structure

### **Messages Logic (COMPLETE)**
```dart
class StudentMessagesLogic extends ChangeNotifier {
  // State
  - _threads (5 mock threads)
  - _selectedFolder
  - _searchQuery
  - _selectedThreadId
  
  // Methods
  - getFilteredThreads()
  - getThreadById()
  - getUnreadCount()
  - selectThread()
  - toggleStar()
  - toggleArchive()
  - sendReply()
  - setFolder()
  - setSearchQuery()
  - loadMessages()
}
```

### **Announcements Logic (COMPLETE)**
```dart
class StudentAnnouncementsLogic extends ChangeNotifier {
  // State
  - _announcements (8 mock items)
  - _selectedFilter
  
  // Methods
  - getFilteredAnnouncements()
  - getAnnouncementById()
  - getUnreadCount()
  - markAsRead()
  - setFilter()
  - loadAnnouncements()
}
```

---

## 🔌 Backend Integration Points

### **Messages Service (Future)**
```dart
// MessageService
Future<List<Message>> getStudentMessages(String studentId)
Future<Message> getMessageById(int messageId)
Future<void> sendReply(int threadId, String content)
Future<void> markAsRead(int threadId)
Future<void> toggleStar(int threadId)
Future<void> toggleArchive(int threadId)
```

### **Announcements Service (Future)**
```dart
// AnnouncementService
Future<List<Announcement>> getStudentAnnouncements(String studentId)
Future<Announcement> getAnnouncementById(int announcementId)
Future<void> markAnnouncementAsRead(int announcementId)
Future<List<String>> getAttachments(int announcementId)
```

---

## 📈 Progress Status

**Phase 6 Progress**: 40% Complete

**Completed**:
- ✅ Messages interactive logic
- ✅ Announcements interactive logic
- ✅ Mock data structure
- ✅ State management

**Remaining**:
- ⏳ Messages UI screen
- ⏳ Announcements UI screen
- ⏳ Dashboard integration
- ⏳ Testing and polish

---

## 🎉 Next Steps

1. **Create Messages Screen UI** - Three-column layout with folders, threads, and message view
2. **Create Announcements Screen UI** - Feed layout with filters and priority indicators
3. **Update Dashboard** - Wire up navigation for both screens
4. **Test Integration** - Verify all features work correctly
5. **Document Completion** - Create Phase 6 complete summary

---

**Note**: Due to token limitations, the UI screens need to be created in the next session. The interactive logic is complete and ready to be connected to the UI components.

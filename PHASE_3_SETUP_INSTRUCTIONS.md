# Phase 3 Setup Instructions

## 🚀 Run the Application

No new dependencies were added in Phase 3, so you can run directly:

```bash
flutter run
```

## 🧪 Test Phase 3 Features

### 1. Login as Student
- Click "Log In" button
- Click "Log in with Office 365"
- Select "Student" user type

### 2. Navigate to Assignments
- Click "Assignments" in the left sidebar
- You should see 5 assignments with different statuses

### 3. Check Statistics
- **Total**: 5 assignments
- **Submitted**: 1 (Math Homework - graded)
- **Due Soon**: 1 (Math Quiz 3 - due tomorrow)
- **Missing**: 1 (Filipino Tula - overdue)

### 4. Test Filters
- Select "Due Soon" → Shows Math Quiz 3
- Select "Submitted" → Shows Math Homework
- Select "Missing" → Shows Filipino Tula
- Select "Graded" → Shows Math Homework
- Select "All" → Shows all 5 assignments

### 5. Test Sorting
- Sort by "Due Date" (default)
- Sort by "Course"
- Sort by "Status"

### 6. View Assignment Details
- Click on "Math Quiz 3: Integers"
- Verify:
  - Gradient header with assignment info
  - Markdown-rendered instructions
  - Teacher attachments (2 files)
  - Requirements card
  - "Start Submission" button

### 7. Test Submission Flow
- Click "Start Submission"
- Type text in the text editor
- Click "Browse Files" to simulate file upload
- Add a link in the link section
- Click "Save Draft"
- Verify "Saved just now" appears in app bar
- Click "Submit Assignment"
- Confirm submission in dialog
- Verify success message

### 8. Test Draft Functionality
- Go back to assignments list
- Click "Science Project: Solar System Model"
- Verify "Draft Saved" status
- Click "Continue Editing"
- Verify existing content loads (PowerPoint file)

### 9. Test Graded Assignment
- Go back to assignments list
- Click "Math Homework: Chapter 4 Review"
- Verify:
  - Grade display: 27/30 (90%)
  - Green color for good grade
  - Teacher feedback: "Excellent work! Minor error on problem 15..."
  - Graded by Maria Santos
  - Graded date

### 10. Test Missing Assignment
- Go back to assignments list
- Click "Filipino: Tula (Poem)"
- Verify:
  - Red "Missing Assignment" warning
  - "Submit Late" button (late submission allowed)
  - Overdue message

## ✅ Expected Results

### Assignments List
- All 5 assignments display correctly
- Status badges show correct colors and icons
- Due dates are color-coded (red for urgent, orange for soon)
- Statistics cards show correct counts
- Filters work properly
- Sorting works properly

### Assignment Details
- Instructions render with Markdown formatting
- Attachments show with download buttons
- Requirements card displays all info
- Submission section changes based on status

### Submission Screen
- Text editor works
- File upload simulation works
- Link addition works
- Draft saving works
- Submit button works
- Unsaved changes warning works

### Status Displays
- **Not Started**: Shows "Start Submission" button
- **Draft**: Shows "Continue Editing" button with last saved time
- **Submitted**: Shows confirmation with timestamp
- **Graded**: Shows score, percentage, and feedback
- **Missing**: Shows warning with late submission option

## 🐛 Troubleshooting

### If assignments don't display:
- Check console for errors
- Verify you're on the Student dashboard
- Try clicking "Assignments" again

### If submission doesn't work:
- Check that you've added some content (text, file, or link)
- Verify the confirmation dialog appears
- Check console for errors

### If draft doesn't save:
- Verify "Saved just now" appears in app bar
- Check that content persists when navigating away and back

## 📝 Notes

- All data is mock data (no backend calls)
- File upload is simulated (no actual file picker)
- Submissions are stored in memory (reset on app restart)
- Grades are pre-populated for demo purposes

## 🎯 What's Working

✅ Assignment list with filters and sorting  
✅ Assignment details with Markdown instructions  
✅ Submission interface (text, files, links)  
✅ Draft saving  
✅ Final submission  
✅ Status tracking  
✅ Grade display with feedback  
✅ Due date management  
✅ File and link management  

## 🔜 Coming Next (Phase 4)

- Grades overview screen
- Grade details by course
- Overall GPA calculation
- Grade trends
- Performance analytics

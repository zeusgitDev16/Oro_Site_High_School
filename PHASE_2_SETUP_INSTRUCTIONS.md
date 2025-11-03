# Phase 2 Setup Instructions

## 📦 Install Dependencies

Since we added `flutter_markdown` package, you need to install it:

```bash
flutter pub get
```

## 🚀 Run the Application

```bash
flutter run
```

## 🧪 Test Phase 2 Features

### 1. Login as Student
- Click "Log In" button
- Click "Log in with Office 365"
- Select "Student" user type

### 2. Navigate to Courses
- Click "My Courses" in the left sidebar
- You should see 4 enrolled courses:
  - Mathematics 7 (65% progress)
  - Science 7 (45% progress)
  - English 7 (70% progress)
  - Filipino 7 (55% progress)

### 3. Test Search and Filter
- Type "Math" in search bar → Should show only Mathematics 7
- Select "In Progress" filter → Should show courses with progress < 100%
- Select "Completed" filter → Should show no courses (none are 100% yet)

### 4. View Course Details
- Click on "Mathematics 7" card
- Verify course header displays with gradient background
- Check progress indicators (65%, 21/32 lessons, 5/8 modules)
- Switch between tabs:
  - Overview: Course description
  - Modules & Lessons: Module list
  - Assignments: Placeholder
  - Grades: Placeholder

### 5. Explore Modules
- Click "Modules & Lessons" tab
- Expand "Module 4: Basic Algebra"
- You should see 6 lessons
- Note completion status (checkmarks for completed lessons)

### 6. View Lesson Content
- Click on "Lesson 4: Evaluating Expressions"
- Verify Markdown content renders properly
- Check attachments section
- Try "Mark as Completed" button
- Use "Previous" and "Next" buttons to navigate

### 7. Verify Progress Updates
- Mark a few lessons as completed
- Go back to course details
- Verify module progress bar updated
- Go back to courses list
- Verify course progress percentage updated

## ✅ Expected Results

- All screens should load without errors
- Navigation should be smooth
- Progress tracking should work
- Markdown content should render with proper formatting
- Mock data should display correctly

## 🐛 Troubleshooting

### If you see "flutter_markdown not found" error:
```bash
flutter clean
flutter pub get
flutter run
```

### If courses don't display:
- Check console for errors
- Verify you're on the Student dashboard
- Try clicking "My Courses" again

### If lesson content doesn't render:
- Verify flutter_markdown package installed
- Check that lesson has 'content' field
- Look for Markdown parsing errors in console

## 📝 Notes

- All data is mock data (no backend calls)
- Progress is stored in memory (resets on app restart)
- Video player is placeholder (not functional yet)
- Attachments show download button but don't actually download

## 🎯 What's Working

✅ Course list with search and filter  
✅ Course details with tabs  
✅ Module organization  
✅ Lesson content viewing  
✅ Progress tracking  
✅ Lesson navigation  
✅ Completion marking  

## 🔜 Coming Next (Phase 3)

- Assignments list
- Assignment details
- Submission form
- File upload
- Status tracking

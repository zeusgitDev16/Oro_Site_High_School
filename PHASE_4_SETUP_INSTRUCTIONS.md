# Phase 4 Setup Instructions

## 🚀 Run the Application

No new dependencies were added in Phase 4, so you can run directly:

```bash
flutter run
```

## 🧪 Test Phase 4 Features

### 1. Login as Student
- Click "Log In" button
- Click "Log in with Office 365"
- Select "Student" user type

### 2. Navigate to Grades
- Click "Grades" in the left sidebar
- You should see the grades overview screen

### 3. Check Overall Performance
- **GPA**: 3.5 (4.0 scale)
- **Average Grade**: 90.25%
- **Total Courses**: 4
- **Performance Breakdown**:
  - Excellent: 2 courses (green)
  - Good: 2 courses (blue)
  - Needs Improvement: 0 courses (orange)

### 4. View Course Grades
You should see 4 courses:
- **Mathematics 7**: 92.5% (A) - Excellent status
- **Science 7**: 88.5% (B+) - Good status
- **English 7**: 94.0% (A) - Excellent status
- **Filipino 7**: 86.0% (B) - Good status

### 5. View Course Details
- Click on "Mathematics 7"
- Verify course header shows:
  - Current grade: 92.5%
  - Letter grade: A
  - Quarterly grades: Q1: 90.0%, Q2: 93.0%, Q3: 94.0%, Q4: --

### 6. Test Overview Tab
- Check grade trend chart (bar chart)
- Should show 3 bars for Q1, Q2, Q3
- Verify performance summary shows 3 components:
  - Written Works: 92.5%
  - Performance Tasks: 93.0%
  - Quarterly Assessment: 92.0%

### 7. Test Components Tab
- Click "Components" tab
- Verify 3 DepEd components display:
  - **Written Works**: 30% weight, 185/200 points, 92.5%
  - **Performance Tasks**: 50% weight, 93/100 points, 93.0%
  - **Quarterly Assessment**: 20% weight, 46/50 points, 92.0%
- Check progress bars and color coding

### 8. Test All Grades Tab
- Click "All Grades" tab
- Verify 3 graded assignments display:
  - Quiz 3: Integers - 45/50 (90%)
  - Problem Set 5 - 48/50 (96%)
  - Quiz 2: Fractions - 42/50 (84%)
- Check teacher feedback displays
- Verify graded dates

### 9. Test Other Courses
- Go back to grades overview
- Click "Science 7" - verify different data
- Click "English 7" - verify different data
- Click "Filipino 7" - verify different data

### 10. Check Recent Grades
- Scroll to "Recent Grades" section
- Verify 5 most recent grades across all courses
- Check color coding (green/orange/red based on percentage)

## ✅ Expected Results

### Grades Overview Screen
- Overall performance header with gradient background
- GPA and average grade display correctly
- Performance statistics show correct counts
- 4 course cards with color-coded borders
- Status badges show correct colors and icons
- Recent grades section shows 5 latest grades

### Course Details Screen
- Course header with gradient background
- Current grade and letter grade prominent
- Quarterly grades breakdown
- Three functional tabs
- Grade trend chart visualizes progress
- Components show DepEd-compliant breakdown
- Individual grades list with feedback

### Performance Indicators
- **Green** (Excellent): 90%+ grades
- **Blue** (Good): 85-89% grades
- **Orange** (Satisfactory): 80-84% grades
- **Red** (Needs Improvement): <80% grades

## 🐛 Troubleshooting

### If grades don't display:
- Check console for errors
- Verify you're on the Student dashboard
- Try clicking "Grades" again

### If course details don't load:
- Verify course ID is correct
- Check that mock data is loaded
- Look for navigation errors in console

### If charts don't render:
- Verify quarterly data exists
- Check that grade trend data is populated
- Ensure bar heights calculate correctly

## 📝 Notes

- All data is mock data (no backend calls)
- Grades are pre-populated for demo purposes
- GPA calculated on 4.0 scale
- DepEd grading system: 30% Written Works, 50% Performance Tasks, 20% Quarterly Assessment
- Quarterly grades: Q1, Q2, Q3 have data; Q4 is not yet graded

## 🎯 What's Working

✅ Overall performance dashboard with GPA  
✅ Course grades overview with status  
✅ Detailed course grades with tabs  
✅ Grade trend visualization  
✅ DepEd component breakdown  
✅ Individual assignment grades  
✅ Teacher feedback display  
✅ Recent grades section  
✅ Color-coded performance indicators  

## 🔜 Coming Next (Phase 5+)

- Attendance tracking
- Messages and announcements
- Profile and settings
- Calendar integration
- Notifications system

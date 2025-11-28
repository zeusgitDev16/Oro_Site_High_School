# 🎨 Sub-Subject UI Design Specification

## 📐 DESIGN LANGUAGE (Extracted from Existing Codebase)

### **Color Palette**
```dart
// Primary Colors
- Blue Primary: Colors.blue.shade700 (#1976D2)
- Blue Light: Colors.blue.shade100 (#BBDEFB)
- Blue Accent: Colors.blue.shade50 (#E3F2FD)
- Blue Border: Colors.blue.shade200 (#90CAF9)

// Secondary Colors
- Green Success: Colors.green.shade700 (#388E3C)
- Green Light: Colors.green.shade50 (#E8F5E9)
- Green Border: Colors.green.shade200 (#A5D6A7)

// Alert Colors
- Red Error: Colors.red.shade700 (#D32F2F)
- Red Light: Colors.red.shade50 (#FFEBEE)
- Orange Warning: Colors.orange.shade400 (#FFA726)

// Neutral Colors
- Grey Background: Colors.grey.shade100 (#F5F5F5)
- Grey Border: Colors.grey.shade300 (#E0E0E0)
- Grey Text: Colors.grey.shade600 (#757575)
- Grey Dark: Colors.grey.shade700 (#616161)
- White: Colors.white (#FFFFFF)
```

### **Typography**
```dart
// Headers
- Page Title: fontSize: 18, fontWeight: FontWeight.w600
- Section Title: fontSize: 14, fontWeight: FontWeight.w600
- Subsection: fontSize: 12, fontWeight: FontWeight.w600

// Body Text
- Normal: fontSize: 11, fontWeight: FontWeight.normal
- Small: fontSize: 10, fontWeight: FontWeight.normal
- Tiny: fontSize: 9, fontWeight: FontWeight.normal

// Labels
- Label: fontSize: 11, color: Colors.grey.shade600
- Sublabel: fontSize: 9, color: Colors.grey.shade700
```

### **Spacing**
```dart
// Padding
- Large: 16px
- Medium: 12px
- Small: 8px
- Tiny: 4px
- Extra Tiny: 2px

// Margins
- Between sections: 12px
- Between items: 6px
- Between elements: 4px
```

### **Border Radius**
```dart
- Cards: BorderRadius.circular(12)
- Buttons: BorderRadius.circular(8)
- Input Fields: BorderRadius.circular(6)
- Chips: BorderRadius.circular(4)
```

### **Elevation**
```dart
- Cards: elevation: 2
- Dialogs: elevation: 4
- Buttons: elevation: 0 (flat design)
```

### **Button Styles**
```dart
// Primary Action Button (Create/Save)
ElevatedButton.styleFrom(
  backgroundColor: Colors.blue.shade50,
  foregroundColor: Colors.blue.shade700,
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
)

// Success Button (Add/Enroll)
ElevatedButton.styleFrom(
  backgroundColor: Colors.green.shade50,
  foregroundColor: Colors.green.shade700,
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
)

// Danger Button (Remove/Delete)
ElevatedButton.styleFrom(
  backgroundColor: Colors.red.shade50,
  foregroundColor: Colors.red.shade700,
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
)
```

### **Input Field Style**
```dart
InputDecoration(
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  labelStyle: TextStyle(fontSize: 11),
  hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
)
```

### **Dropdown Style**
```dart
DropdownButtonFormField(
  decoration: InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  ),
  style: TextStyle(fontSize: 11, color: Colors.black87),
  itemHeight: 48,
)
```

### **DataTable Style**
```dart
DataTable(
  headingRowHeight: 80,
  dataRowMinHeight: 48,
  dataRowMaxHeight: 48,
  columnSpacing: 12,
  horizontalMargin: 12,
  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
  border: TableBorder.all(color: Colors.grey.shade300, width: 1),
)
```

### **Chip Style**
```dart
ChoiceChip(
  label: Text('Q1', style: TextStyle(fontSize: 11)),
  selected: selected,
  selectedColor: Colors.blue.shade100,
  backgroundColor: Colors.grey.shade100,
  labelStyle: TextStyle(
    color: selected ? Colors.blue.shade900 : Colors.grey.shade700,
    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
  ),
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
)
```

### **Card Style**
```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: EdgeInsets.all(20),
    child: child,
  ),
)
```

### **Dialog Style**
```dart
AlertDialog(
  title: Text('Dialog Title', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  content: SizedBox(
    width: 600, // Fixed width for consistency
    child: content,
  ),
  actions: [
    TextButton(onPressed: onCancel, child: Text('Cancel')),
    ElevatedButton(onPressed: onSave, child: Text('Save')),
  ],
)
```

---

## 🎯 COMPONENT-SPECIFIC DESIGNS

### **1. Subject List Item (with Sub-Subject Indicator)**
```dart
// Standard Subject
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: isSelected ? Colors.blue.shade50 : Colors.white,
    border: Border(left: BorderSide(
      color: isSelected ? Colors.blue.shade700 : Colors.transparent,
      width: 3,
    )),
  ),
  child: Row(
    children: [
      Icon(Icons.book, size: 16, color: Colors.grey.shade600),
      SizedBox(width: 8),
      Expanded(child: Text(subjectName, style: TextStyle(fontSize: 11))),
    ],
  ),
)

// MAPEH Parent (with expand icon)
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: Colors.blue.shade50,
    border: Border(left: BorderSide(color: Colors.blue.shade700, width: 3)),
  ),
  child: Row(
    children: [
      Icon(Icons.music_note, size: 16, color: Colors.blue.shade700),
      SizedBox(width: 8),
      Expanded(child: Text('MAPEH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 16),
    ],
  ),
)

// MAPEH Sub-Subject (indented)
Container(
  padding: EdgeInsets.only(left: 32, right: 12, top: 8, bottom: 8),
  decoration: BoxDecoration(
    color: isSelected ? Colors.blue.shade50 : Colors.white,
    border: Border(left: BorderSide(
      color: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
      width: 2,
    )),
  ),
  child: Row(
    children: [
      Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.grey.shade400),
      SizedBox(width: 6),
      Expanded(child: Text('Music', style: TextStyle(fontSize: 10))),
    ],
  ),
)
```

---

## 📊 LAYOUT PATTERNS

### **Two-Panel Layout** (Subject List + Details)
```
┌─────────────────────────────────────────────────────┐
│  Left Panel (300px)  │  Right Panel (Flexible)      │
│  ─────────────────── │  ──────────────────────────  │
│  Subject List        │  Subject Details/Management  │
│  - Standard Subjects │  - Teacher Assignment        │
│  - MAPEH (expandable)│  - Sub-Subject Management    │
│    - Music           │  - Enrollment Management     │
│    - Arts            │                              │
│    - PE              │                              │
│    - Health          │                              │
│  - TLE (expandable)  │                              │
│    - Cookery         │                              │
│    - ICT             │                              │
└─────────────────────────────────────────────────────┘
```

### **Three-Panel Layout** (Grade + Classroom + Subject)
```
┌──────────────────────────────────────────────────────────────┐
│ Left (240px) │ Middle (280px) │ Right (Flexible)            │
│ ──────────── │ ────────────── │ ──────────────────────────  │
│ Grade Levels │ Classrooms     │ Subject Management          │
│ - Grade 7    │ - 7-Amanpulo   │ - Subject List              │
│ - Grade 8    │ - 7-Boracay    │ - Sub-Subject Tree          │
│ - Grade 9    │                │ - Enrollment Management     │
└──────────────────────────────────────────────────────────────┘
```

---

**Next:** Implement UI components with this exact design language


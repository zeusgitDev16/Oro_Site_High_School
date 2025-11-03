# 🎓 ORO SITE HIGH SCHOOL (OSHS) - COMPREHENSIVE SYSTEM DEMO & FLOW
## PART 3: TECHNICAL IMPLEMENTATION DETAILS

## 📋 Overview
This document provides technical specifications, API details, database schema, and implementation guidelines for the OSHS system.

---

## 🗄️ Database Schema

### Core Tables Structure

```sql
-- Users and Authentication
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin', 'teacher', 'student', 'parent'),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Students Table (DepEd Compliant)
CREATE TABLE students (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  lrn VARCHAR(12) UNIQUE NOT NULL, -- DepEd LRN
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  middle_name VARCHAR(100),
  grade_level INT CHECK (grade_level BETWEEN 7 AND 12),
  section_id UUID REFERENCES sections(id),
  birth_date DATE,
  gender ENUM('M', 'F'),
  address TEXT,
  contact_number VARCHAR(20),
  mother_tongue VARCHAR(50), -- For MTB-MLE
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Courses Table (DepEd Aligned)
CREATE TABLE courses (
  id UUID PRIMARY KEY,
  code VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(100) NOT NULL,
  subject_type ENUM('CORE', 'SPECIALIZED', 'APPLIED', 'MAPEH_COMPONENT'),
  grade_level INT,
  units DECIMAL(3,1),
  school_year VARCHAR(9), -- Format: 2023-2024
  quarter INT CHECK (quarter BETWEEN 1 AND 4),
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Grades Table (DepEd Order No. 8)
CREATE TABLE grades (
  id UUID PRIMARY KEY,
  student_id UUID REFERENCES students(id),
  course_id UUID REFERENCES courses(id),
  quarter INT CHECK (quarter BETWEEN 1 AND 4),
  written_work DECIMAL(5,2), -- 30% weight
  performance_task DECIMAL(5,2), -- 50% weight
  quarterly_exam DECIMAL(5,2), -- 20% weight
  quarter_grade DECIMAL(5,2) GENERATED ALWAYS AS (
    (written_work * 0.30) + 
    (performance_task * 0.50) + 
    (quarterly_exam * 0.20)
  ) STORED,
  teacher_id UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Attendance Table (DepEd Codes)
CREATE TABLE attendance (
  id UUID PRIMARY KEY,
  student_id UUID REFERENCES students(id),
  course_id UUID REFERENCES courses(id),
  date DATE NOT NULL,
  status ENUM('P','A','L','E','S','SL','OL','UA'), -- DepEd codes
  time_in TIME,
  time_out TIME,
  remarks TEXT,
  recorded_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_attendance (student_id, course_id, date)
);

-- Parent-Student Relationship
CREATE TABLE parent_student (
  parent_id UUID REFERENCES users(id),
  student_id UUID REFERENCES students(id),
  relationship ENUM('Mother', 'Father', 'Guardian'),
  is_primary_contact BOOLEAN DEFAULT FALSE,
  PRIMARY KEY (parent_id, student_id)
);

-- Notifications Table
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  recipient_id UUID REFERENCES users(id),
  sender_id UUID REFERENCES users(id),
  type VARCHAR(50),
  title VARCHAR(255),
  message TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  link VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_recipient_read (recipient_id, is_read)
);
```

---

## 🔌 API Specifications

### Authentication Endpoints

```typescript
// Login
POST /api/auth/login
Request: {
  email: string,
  password: string
}
Response: {
  token: string,
  user: User,
  role: 'admin' | 'teacher' | 'student' | 'parent'
}

// Logout
POST /api/auth/logout
Headers: { Authorization: 'Bearer <token>' }
Response: { success: boolean }

// Refresh Token
POST /api/auth/refresh
Request: { refreshToken: string }
Response: { token: string, refreshToken: string }
```

### Course Management Endpoints

```typescript
// Create Course (Admin only)
POST /api/courses
Request: {
  code: string,
  name: string,
  gradeLevel: number,
  units: number,
  schoolYear: string,
  quarter: number
}
Response: Course

// Assign Teacher to Course
POST /api/courses/:courseId/assign-teacher
Request: {
  teacherId: string,
  sectionId: string,
  schedule: string
}
Response: CourseAssignment

// Enroll Students
POST /api/courses/:courseId/enroll
Request: {
  studentIds: string[],
  sectionId: string
}
Response: {
  enrolled: number,
  enrollments: Enrollment[]
}
```

### Grading Endpoints (DepEd Compliant)

```typescript
// Submit Grades
POST /api/grades
Request: {
  studentId: string,
  courseId: string,
  quarter: number,
  writtenWork: number,    // 0-100
  performanceTask: number, // 0-100
  quarterlyExam: number    // 0-100
}
Response: {
  quarterGrade: number, // Auto-calculated
  status: 'saved' | 'submitted'
}

// Get Student Grades
GET /api/students/:studentId/grades?quarter=1&schoolYear=2023-2024
Response: {
  grades: Grade[],
  average: number,
  ranking: number
}

// Generate Report Card (Form 138)
GET /api/students/:studentId/report-card/:quarter
Response: {
  pdfUrl: string,
  data: ReportCardData
}
```

### Attendance Endpoints

```typescript
// Record Attendance
POST /api/attendance
Request: {
  courseId: string,
  date: string,
  records: [{
    studentId: string,
    status: 'P'|'A'|'L'|'E'|'S'|'SL'|'OL'|'UA',
    timeIn?: string,
    timeOut?: string,
    remarks?: string
  }]
}
Response: {
  recorded: number,
  alerts: Alert[] // For absent students
}

// Get Attendance Summary
GET /api/students/:studentId/attendance/summary
Response: {
  totalDays: number,
  present: number,
  absent: number,
  late: number,
  attendanceRate: number,
  consecutiveAbsences: number
}
```

### Notification Endpoints

```typescript
// Get Notifications
GET /api/notifications?unread=true&limit=20
Response: {
  notifications: Notification[],
  unreadCount: number,
  totalCount: number
}

// Mark as Read
PUT /api/notifications/:id/read
Response: { success: boolean }

// Send Notification
POST /api/notifications
Request: {
  recipientIds: string[],
  type: string,
  title: string,
  message: string,
  link?: string
}
Response: {
  sent: number,
  notifications: Notification[]
}
```

---

## 🔄 Real-Time Integration

### WebSocket Events

```javascript
// Connection
const socket = io('wss://api.oshs.edu.ph', {
  auth: { token: localStorage.getItem('token') }
});

// Listen for notifications
socket.on('notification', (data) => {
  showNotification(data);
  updateBadgeCount();
});

// Listen for grade updates
socket.on('grade:updated', (data) => {
  if (data.studentId === currentStudent.id) {
    refreshGrades();
  }
});

// Listen for attendance alerts
socket.on('attendance:alert', (data) => {
  if (isParent && data.studentId === myChild.id) {
    showAttendanceAlert(data);
  }
});

// Listen for messages
socket.on('message:new', (data) => {
  updateMessageInbox(data);
  playNotificationSound();
});
```

### Server-Sent Events (Alternative)

```javascript
// For environments where WebSockets are restricted
const eventSource = new EventSource('/api/events');

eventSource.addEventListener('notification', (e) => {
  const data = JSON.parse(e.data);
  handleNotification(data);
});

eventSource.addEventListener('grade', (e) => {
  const data = JSON.parse(e.data);
  updateGradeDisplay(data);
});
```

---

## 📱 Mobile App Integration

### Flutter Configuration

```yaml
# pubspec.yaml additions
dependencies:
  # Core
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.0
  riverpod: ^2.0.0
  
  # Backend
  dio: ^5.0.0
  socket_io_client: ^2.0.0
  
  # Storage
  shared_preferences: ^2.0.0
  sqflite: ^2.0.0
  
  # Notifications
  firebase_messaging: ^14.0.0
  flutter_local_notifications: ^13.0.0
  
  # SMS
  telephony: ^0.2.0
  
  # Forms
  pdf: ^3.0.0
  printing: ^5.0.0
  
  # Authentication
  local_auth: ^2.0.0
```

### Push Notifications Setup

```dart
class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get token
    String? token = await _fcm.getToken();
    await saveTokenToServer(token);
    
    // Handle messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showLocalNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        payload: message.data,
      );
    });
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }
  
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    // Handle background notifications
    if (message.data['type'] == 'attendance_alert') {
      await showUrgentNotification(message);
    }
  }
}
```

---

## 🔐 Security Implementation

### Authentication Flow

```dart
class AuthService {
  static const String TOKEN_KEY = 'auth_token';
  static const String REFRESH_KEY = 'refresh_token';
  
  Future<User?> login(String email, String password) async {
    try {
      final response = await dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      // Save tokens
      await storage.write(TOKEN_KEY, response.data['token']);
      await storage.write(REFRESH_KEY, response.data['refreshToken']);
      
      // Setup interceptors
      dio.interceptors.add(AuthInterceptor());
      
      return User.fromJson(response.data['user']);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }
  
  Future<void> refreshToken() async {
    final refreshToken = await storage.read(REFRESH_KEY);
    final response = await dio.post('/api/auth/refresh', data: {
      'refreshToken': refreshToken,
    });
    
    await storage.write(TOKEN_KEY, response.data['token']);
  }
}
```

### Role-Based Access Control

```dart
class PermissionService {
  static bool canAccess(String feature, String role) {
    final permissions = {
      'admin': ['*'], // All permissions
      'teacher': [
        'view_own_courses',
        'manage_own_grades',
        'manage_own_attendance',
        'send_messages',
      ],
      'student': [
        'view_own_courses',
        'submit_assignments',
        'view_own_grades',
        'view_own_attendance',
      ],
      'parent': [
        'view_child_grades',
        'view_child_attendance',
        'send_messages',
        'view_reports',
      ],
    };
    
    final userPermissions = permissions[role] ?? [];
    return userPermissions.contains('*') || 
           userPermissions.contains(feature);
  }
}
```

---

## 🚀 Deployment Configuration

### Docker Setup

```dockerfile
# Dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:buster-slim
COPY --from=build /app/bin/server /app/bin/server
EXPOSE 8080
CMD ["/app/bin/server"]
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: oshs-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: oshs-backend
  template:
    metadata:
      labels:
        app: oshs-backend
    spec:
      containers:
      - name: backend
        image: oshs/backend:latest
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: oshs-secrets
              key: database-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: oshs-secrets
              key: jwt-secret
```

---

## 📊 Monitoring and Analytics

### Performance Metrics

```javascript
// Track API performance
const trackAPICall = async (endpoint, method, duration) => {
  await analytics.track('api_call', {
    endpoint,
    method,
    duration,
    timestamp: Date.now(),
    userId: getCurrentUserId(),
  });
};

// Track user actions
const trackUserAction = async (action, metadata) => {
  await analytics.track('user_action', {
    action,
    ...metadata,
    timestamp: Date.now(),
    sessionId: getSessionId(),
  });
};

// Monitor system health
const healthCheck = async () => {
  const checks = {
    database: await checkDatabase(),
    redis: await checkRedis(),
    storage: await checkStorage(),
    notifications: await checkNotificationService(),
  };
  
  return {
    status: Object.values(checks).every(c => c),
    checks,
    timestamp: Date.now(),
  };
};
```

---

## 🔧 Maintenance Scripts

### Database Maintenance

```sql
-- Archive old data
CREATE PROCEDURE archive_old_records()
BEGIN
  -- Archive attendance older than 2 years
  INSERT INTO attendance_archive 
  SELECT * FROM attendance 
  WHERE date < DATE_SUB(NOW(), INTERVAL 2 YEAR);
  
  DELETE FROM attendance 
  WHERE date < DATE_SUB(NOW(), INTERVAL 2 YEAR);
  
  -- Archive old notifications
  DELETE FROM notifications 
  WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY) 
  AND is_read = TRUE;
END;

-- Optimize tables
OPTIMIZE TABLE grades;
OPTIMIZE TABLE attendance;
OPTIMIZE TABLE notifications;
```

### Backup Strategy

```bash
#!/bin/bash
# Daily backup script

DATE=$(date +%Y%m%d)
BACKUP_DIR="/backups/oshs"

# Database backup
mysqldump -u $DB_USER -p$DB_PASS oshs > $BACKUP_DIR/db_$DATE.sql

# Compress
gzip $BACKUP_DIR/db_$DATE.sql

# Upload to cloud storage
aws s3 cp $BACKUP_DIR/db_$DATE.sql.gz s3://oshs-backups/

# Clean old local backups (keep 7 days)
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

# Send notification
curl -X POST $WEBHOOK_URL -d "Backup completed: db_$DATE.sql.gz"
```

---

## ✅ Testing Strategy

### Unit Tests

```dart
// Example grade calculation test
test('Grade calculation follows DepEd formula', () {
  final grade = GradeCalculator.calculate(
    writtenWork: 85,
    performanceTask: 90,
    quarterlyExam: 88,
  );
  
  expect(grade, equals(87.9)); // (85*0.3)+(90*0.5)+(88*0.2)
});
```

### Integration Tests

```dart
testWidgets('Complete enrollment flow', (WidgetTester tester) async {
  // Login as admin
  await tester.pumpWidget(MyApp());
  await login(tester, 'admin@oshs.edu.ph', 'password');
  
  // Create course
  await navigateTo(tester, '/courses');
  await createCourse(tester, 'MATH-7');
  
  // Assign teacher
  await assignTeacher(tester, 'Maria Santos');
  
  // Verify
  expect(find.text('Course created successfully'), findsOneWidget);
});
```

---

## 📝 Documentation

### API Documentation (OpenAPI)

```yaml
openapi: 3.0.0
info:
  title: OSHS API
  version: 1.0.0
  description: Oro Site High School Management System API

paths:
  /api/courses:
    post:
      summary: Create a new course
      tags: [Courses]
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Course'
      responses:
        201:
          description: Course created successfully
        401:
          description: Unauthorized
        403:
          description: Forbidden - Admin only
```

---

## 🎯 Final Checklist

### Pre-Deployment
- [ ] All DepEd forms tested
- [ ] SMS gateway configured
- [ ] SSL certificates installed
- [ ] Backup system tested
- [ ] Load testing completed
- [ ] Security audit passed
- [ ] Documentation complete

### Post-Deployment
- [ ] Monitor error rates
- [ ] Check performance metrics
- [ ] Verify backup execution
- [ ] Test notification delivery
- [ ] Validate report generation
- [ ] Confirm SMS delivery
- [ ] User acceptance testing

---

**End of Part 3 - Technical Implementation Complete**

## Summary

The OSHS system is now fully documented with:
1. **Part 1**: Complete workflow scenarios
2. **Part 2**: Feature analysis and improvements
3. **Part 3**: Technical implementation details

**Total Documentation**: 3 comprehensive parts covering all aspects of the system from user flows to technical implementation.
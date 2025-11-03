# ✅ Storage RLS Policy Fix

## 🎯 Problem

**Error**: RLS policy issue when uploading files

**Cause**: The storage bucket `course_files` doesn't have proper RLS policies to allow authenticated users to upload files.

**Your Account**: ICT Coordinator (which should have admin access)

---

## ✅ Solution

The storage bucket needs RLS policies that allow **ANY authenticated user** to upload, read, and delete files.

---

## 🚀 How to Fix

### **Step 1: Run SQL Script**
```
1. Open Supabase Dashboard → SQL Editor
2. Copy FIX_STORAGE_BUCKET_POLICIES.sql
3. Paste and Run
4. Verify success messages
```

### **Step 2: Verify Bucket Settings**
```
1. Go to Supabase Dashboard → Storage
2. Click on "course_files" bucket
3. Make sure it's set to PUBLIC
4. If not, click settings and enable "Public bucket"
```

### **Step 3: Test Upload**
```
1. Hot restart your app
2. Login with ICT Coordinator account
3. Go to Courses
4. Try uploading a file
5. Should work now! ✅
```

---

## 🔒 Policies Created

The SQL script creates these policies:

### **1. Upload Policy** ✅
```sql
Allow authenticated users to upload files
- Who: ANY authenticated user
- Action: INSERT (upload)
- Bucket: course_files
```

### **2. Read Policy** ✅
```sql
Allow authenticated users to read files
- Who: ANY authenticated user
- Action: SELECT (view/list)
- Bucket: course_files
```

### **3. Delete Policy** ✅
```sql
Allow authenticated users to delete files
- Who: ANY authenticated user
- Action: DELETE (remove)
- Bucket: course_files
```

### **4. Public Read Policy** ✅
```sql
Allow public to read files
- Who: Public (anyone)
- Action: SELECT (download)
- Bucket: course_files
```

---

## 👥 Who Can Upload?

After running the script, these users can upload:
- ✅ **Admin** users
- ✅ **ICT Coordinator** users (YOU!)
- ✅ **Teacher** users
- ✅ **Student** users
- ✅ **ANY authenticated user**

The policies don't check roles - they only check if the user is authenticated (logged in).

---

## 🔍 Troubleshooting

### **If still not working:**

1. **Check if bucket exists:**
   - Go to Storage → Should see "course_files"
   - If not, create it manually

2. **Check if bucket is public:**
   - Click on bucket → Settings
   - "Public bucket" should be enabled

3. **Check authentication:**
   - Make sure you're logged in
   - Check console for auth errors

4. **Check browser console:**
   - Open DevTools (F12)
   - Look for error messages
   - Share the error if still failing

---

## 📝 What the Script Does

1. ✅ Drops old policies (if any)
2. ✅ Creates 4 new policies for course_files bucket
3. ✅ Checks if bucket exists
4. ✅ Makes bucket public (if not already)
5. ✅ Verifies policies were created
6. ✅ Shows success messages

---

## ✅ Success Criteria

After running the script:
- [x] Policies created
- [x] Bucket is public
- [x] Upload works for ICT Coordinator
- [x] Upload works for Admin
- [x] Upload works for Teachers
- [x] Files appear in tabs
- [x] Download works
- [x] Delete works

---

**Run the SQL script to fix the RLS policies!** 🚀

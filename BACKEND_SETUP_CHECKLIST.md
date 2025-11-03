# ✅ BACKEND SETUP CHECKLIST

Use this checklist to track your progress setting up the backend.

---

## 📋 SETUP CHECKLIST

### Phase 1: Get Credentials

- [ ] **1.1** Go to Supabase Dashboard (https://supabase.com/dashboard)
- [ ] **1.2** Navigate to Settings → API
- [ ] **1.3** Copy Project URL
- [ ] **1.4** Copy anon/public key (the long one, 200+ characters)
- [ ] **1.5** Go to Azure Portal (https://portal.azure.com)
- [ ] **1.6** Find "Oro Site High School ELMS" app registration
- [ ] **1.7** Copy Application (client) ID

### Phase 2: Configure .env File

- [ ] **2.1** Open `.env` file in project root
- [ ] **2.2** Paste SUPABASE_URL
- [ ] **2.3** Paste SUPABASE_ANON_KEY (make sure it's complete!)
- [ ] **2.4** Paste AZURE_CLIENT_ID
- [ ] **2.5** Change `USE_MOCK_DATA=true` to `USE_MOCK_DATA=false`
- [ ] **2.6** Save the file

### Phase 3: Configure Azure in Supabase

- [ ] **3.1** Go to Supabase Dashboard → Authentication → Providers
- [ ] **3.2** Enable "Azure" provider
- [ ] **3.3** Enter Azure Tenant ID: `aezycreativegmail.onmicrosoft.com`
- [ ] **3.4** Enter Azure Client ID (same as in .env)
- [ ] **3.5** Create Azure Client Secret in Azure Portal
- [ ] **3.6** Copy and paste Client Secret in Supabase
- [ ] **3.7** Click Save

### Phase 4: Configure Redirect URL in Azure

- [ ] **4.1** In Azure Portal, go to your App Registration
- [ ] **4.2** Click "Authentication" in left menu
- [ ] **4.3** Click "+ Add a platform" → Web
- [ ] **4.4** Add redirect URI: `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`
- [ ] **4.5** Click Configure
- [ ] **4.6** Click Save

### Phase 5: Verify Database Tables

- [ ] **5.1** Go to Supabase Dashboard → Table Editor
- [ ] **5.2** Verify all 28 tables exist:
  - [ ] profiles
  - [ ] roles
  - [ ] students
  - [ ] parent_students
  - [ ] courses
  - [ ] course_assignments
  - [ ] enrollments
  - [ ] grades
  - [ ] attendance
  - [ ] attendance_sessions
  - [ ] scanner_data
  - [ ] scanner_sessions
  - [ ] assignments
  - [ ] submissions
  - [ ] announcements
  - [ ] notifications
  - [ ] messages
  - [ ] calendar_events
  - [ ] course_modules
  - [ ] lessons
  - [ ] permissions
  - [ ] role_permissions
  - [ ] section_assignments
  - [ ] coordinator_assignments
  - [ ] teacher_requests
  - [ ] batch_upload
  - [ ] activity_log
  - [ ] admin_notifications

### Phase 6: Test Connection

- [ ] **6.1** Run `flutter pub get` to ensure dependencies are installed
- [ ] **6.2** Run `flutter run`
- [ ] **6.3** Check console for "✅ Database connection successful"
- [ ] **6.4** Check console for "✅ Supabase initialized successfully"
- [ ] **6.5** Try logging in with test user

### Phase 7: Test Authentication

- [ ] **7.1** Try logging in with: `admin@aezycreativegmail.onmicrosoft.com`
- [ ] **7.2** Password: `OroSystem123#2025`
- [ ] **7.3** Verify you're redirected to admin dashboard
- [ ] **7.4** Try logging out
- [ ] **7.5** Try logging in with other test users

---

## 🎯 COMPLETION STATUS

**Total Steps:** 35  
**Completed:** _____ / 35

**Progress:** [___________________] 0%

---

## 📊 VERIFICATION TESTS

After completing all steps, verify these work:

### ✅ Connection Tests
- [ ] App starts without errors
- [ ] Console shows "Supabase initialized successfully"
- [ ] Console shows "Database connection successful"
- [ ] No error messages in console

### ✅ Authentication Tests
- [ ] Can open login screen
- [ ] Can click "Sign in with Azure AD"
- [ ] Redirects to Microsoft login page
- [ ] Can enter credentials
- [ ] Redirects back to app after login
- [ ] Shows correct dashboard for user role

### ✅ Data Tests
- [ ] Can see real data (not mock data)
- [ ] Data loads from Supabase
- [ ] Changes are saved to database
- [ ] Real-time updates work

---

## 🚨 COMMON ISSUES & SOLUTIONS

### Issue 1: "SUPABASE_URL not found"
**Cause:** `.env` file not in correct location  
**Solution:** Make sure `.env` is in project root: `c:\Users\User1\F_Dev\oro_site_high_school\.env`

### Issue 2: "Database connection failed"
**Cause:** Wrong credentials or network issue  
**Solution:** 
1. Verify SUPABASE_URL is correct
2. Verify SUPABASE_ANON_KEY is complete (200+ characters)
3. Check internet connection
4. Check Supabase project is active

### Issue 3: "Azure login redirects but doesn't work"
**Cause:** Redirect URL not configured  
**Solution:** 
1. Check redirect URL in Azure Portal matches Supabase
2. Format: `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`
3. Make sure to click Save in Azure Portal

### Issue 4: "User not found after login"
**Cause:** Profile not created in database  
**Solution:** 
1. Check if profiles table exists
2. Check if roles table has data
3. Try logging in again (profile should auto-create)

### Issue 5: "Mock data still showing"
**Cause:** `USE_MOCK_DATA` still set to true  
**Solution:** 
1. Open `.env` file
2. Change `USE_MOCK_DATA=true` to `USE_MOCK_DATA=false`
3. Restart the app

---

## 📞 NEED HELP?

If you're stuck after trying the solutions above:

1. **Check the detailed guide:** `SUPABASE_CREDENTIALS_GUIDE.md`
2. **Check Supabase logs:** Dashboard → Logs
3. **Check Azure logs:** Azure Portal → App Registration → Sign-in logs
4. **Check Flutter console:** Look for error messages

---

## 🎉 SUCCESS!

When you see all these ✅ in your console:

```
🚀 Initializing Supabase...
═══════════════════════════════════════════════════════
           ORO SITE HIGH SCHOOL ELMS
           Environment Configuration
═══════════════════════════════════════════════════════
Environment Type: PRODUCTION
───────────────────────────────────────────────────────
Supabase:
  ✓ URL: https://your-project.supabase.co
  ✓ Key: Configured
───────────────────────────────────────────────────────
Azure AD:
  ✓ Enabled: true
  ✓ Tenant: aezycreativegmail.onmicrosoft.com
  ✓ Client ID: Configured
───────────────────────────────────────────────────────
Features:
  ✓ Mock Data: false
  ✓ Offline Mode: true
  ✓ Real-time: true
───────────────────────────────────────────────────────
✅ Database connection successful
✅ Supabase initialized successfully
```

**🎊 CONGRATULATIONS! Your backend is fully connected! 🎊**

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Status:** Ready to Use

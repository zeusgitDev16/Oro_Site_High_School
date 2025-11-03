# 🔧 **Fix: Azure AD Consent Screen Error**

## **Good News!**
Microsoft authentication is working! The consent screen appearing means Azure AD is properly connected. Now we just need to fix the consent/redirect issue.

---

## **The Issues:**

1. **"Unverified" app warning** - Normal for development apps
2. **Error after accepting** - Likely a redirect or Supabase configuration issue

---

## **Solution Steps:**

### **Step 1: Check Supabase Azure Provider Status**

1. **Go to [Supabase Dashboard](https://app.supabase.com)**
2. **Navigate to:** Authentication → Providers → Azure
3. **Verify ALL these fields are filled:**

```yaml
Azure (AD) OAuth Client ID:
5ef49f61-b51d-4484-85e6-24c127d331ed

Azure (AD) OAuth Client Secret:
[YOUR CLIENT SECRET - MUST BE FILLED]

Azure (AD) Tenant URL:
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

**⚠️ IMPORTANT:** If the Client Secret is missing or expired, that's the problem!

---

### **Step 2: Generate New Client Secret (If Needed)**

1. **Go to [Azure Portal](https://portal.azure.com)**
2. **Sign in with:** `aezycreative@gmail.com`
3. **Navigate to:** Azure AD → App registrations → Oro Site High School ELMS
4. **Go to:** Certificates & secrets
5. **Check existing secrets:**
   - If expired or none exist, continue
   - If valid secret exists, skip to Step 3

6. **Create new secret:**
   - Click **New client secret**
   - Description: `Supabase Integration`
   - Expires: **24 months**
   - Click **Add**
   - **IMMEDIATELY COPY THE VALUE** (not the ID!)

Example of what to copy:
```
Secret Value: 8Q~8kL3xYz... (long string)  ← COPY THIS
Secret ID: abc-123-def...                   ← NOT THIS
```

---

### **Step 3: Update Supabase with Client Secret**

1. **Go back to Supabase Dashboard**
2. **Authentication → Providers → Azure**
3. **Paste the Client Secret Value**
4. **Verify all fields:**

```yaml
Enable Sign in with Azure: ✅ ON

Azure (AD) OAuth Client ID:
5ef49f61-b51d-4484-85e6-24c127d331ed

Azure (AD) OAuth Client Secret:
[PASTE YOUR SECRET VALUE HERE]

Azure (AD) Tenant URL:
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

5. **Click Save**
6. **Wait 30 seconds** for changes to propagate

---

### **Step 4: Fix URL Configuration in Supabase**

1. **Still in Supabase, go to:** Authentication → URL Configuration
2. **Set these values:**

```yaml
Site URL:
http://localhost:49719

Additional Redirect URLs:
http://localhost:49719
http://localhost:49719/
http://localhost:49719/#/
http://localhost:*
http://localhost:*/**
```

3. **Click Save**

---

### **Step 5: Verify Azure Redirect URI**

1. **In Azure Portal:** Your app → Authentication
2. **Verify this EXACT redirect URI exists:**
```
https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback
```
3. **Remove any other URIs** (especially localhost ones)
4. **Save**

---

### **Step 6: Clear Everything and Test**

1. **Clear browser data:**
   - Press `Ctrl + Shift + Delete`
   - Select "Cookies and other site data"
   - Select "Cached images and files"
   - Clear data

2. **Sign out of Microsoft (Important!):**
   - Go to https://login.microsoftonline.com
   - Sign out completely
   - Close all browser tabs

3. **Run your app with specific port:**
```bash
flutter clean
flutter pub get
flutter run -d chrome --web-port=49719
```

4. **Test login again:**
   - Click "Log in with Office 365"
   - Sign in with: `admin@aezycreativegmail.onmicrosoft.com`
   - Accept permissions
   - Should redirect back to your app

---

## **Debugging: Check Browser Console**

After clicking Accept, if it still fails:

1. **Open Browser Console** (F12)
2. **Check for errors like:**
   - `invalid_client` - Client secret is wrong
   - `redirect_uri_mismatch` - Redirect URI doesn't match
   - `unauthorized_client` - App not configured properly

3. **Check Network Tab:**
   - Look for the callback request
   - Check if it goes to Supabase
   - See what error is returned

---

## **Common Issues and Fixes:**

### **Issue 1: "Invalid client secret"**
**Fix:** Generate new secret in Azure, update in Supabase

### **Issue 2: "Redirect URI mismatch"**
**Fix:** Ensure Azure has ONLY: `https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback`

### **Issue 3: "User not created in Supabase"**
**Fix:** Check Supabase logs: Authentication → Logs

### **Issue 4: "Session not persisting"**
**Fix:** Check Supabase Site URL matches your localhost

---

## **Alternative: Publisher Verification (Optional)**

The "unverified" warning is normal for development. To remove it (optional):

1. **In Azure Portal:** Your app → Branding & properties
2. **Add Publisher domain:** Your verified domain
3. **Complete verification process** (requires domain ownership)

**Note:** This is NOT required for development/testing!

---

## **Quick Checklist:**

### **Azure Portal:**
- [ ] Client Secret is valid (not expired)
- [ ] Only Supabase callback in redirect URIs
- [ ] Permissions granted (User.Read, email, etc.)

### **Supabase Dashboard:**
- [ ] Azure provider enabled
- [ ] Client ID correct
- [ ] Client Secret filled and correct
- [ ] Tenant URL ends with `/v2.0`
- [ ] Site URL = `http://localhost:49719`

### **Browser:**
- [ ] Cleared cache and cookies
- [ ] Signed out of Microsoft
- [ ] Using consistent port (49719)

---

## **Expected Success Flow:**

1. Click "Log in with Office 365"
2. Microsoft login opens
3. Enter credentials
4. Consent screen appears (may say unverified)
5. Click Accept
6. Redirects to Supabase
7. Supabase creates session
8. Redirects back to localhost:49719
9. App detects session
10. Routes to dashboard

---

## **Still Not Working?**

If still failing after Accept:

1. **Check Supabase Logs:**
   - Dashboard → Authentication → Logs
   - Look for OAuth errors

2. **Test with different browser:**
   - Try Edge or Firefox
   - Try Incognito mode

3. **Share the exact error:**
   - Browser console error
   - Network tab response
   - Supabase logs

We're very close! The consent screen appearing means 90% is working. We just need to fix the final redirect/session creation.

---

**Remember:** The "unverified" warning is NORMAL for development apps. Focus on fixing the error after clicking Accept.
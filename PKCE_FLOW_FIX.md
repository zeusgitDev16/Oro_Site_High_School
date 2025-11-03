# 🔧 **Fix: PKCE Flow Error - login.microsoftonline.com page can't be found**

## **The Problem**

The OAuth flow is using PKCE (Proof Key for Code Exchange) but the URL is malformed. The issue is in how Supabase is configured for Azure AD.

Looking at the URL, I can see:
- `flow_type=pkce` - Using PKCE flow
- `redirect_to=http%3A%2F%2Flocalhost%3A49719%2F` - Trying to redirect to localhost
- But it's going to `login.microsoftonline.com` which gives 404

---

## **Solution: Fix Supabase Azure Provider Configuration**

### **Step 1: Update Azure Provider in Supabase**

1. **Go to [Supabase Dashboard](https://app.supabase.com)**
2. **Navigate to:** Authentication → Providers → Azure
3. **IMPORTANT: Check the Tenant URL format**

The Tenant URL should be:
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

**NOT:**
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181
```

The `/v2.0` at the end is CRITICAL!

4. **Verify ALL fields:**

```yaml
Enable Sign in with Azure: ✅ ON

Azure (AD) OAuth Client ID:
5ef49f61-b51d-4484-85e6-24c127d331ed

Azure (AD) OAuth Client Secret:
[Your client secret value - must be filled]

Azure (AD) Tenant URL:
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
                                                                      ^^^^^^
                                                                   MUST HAVE THIS!
```

5. **Click Save**

---

### **Step 2: Verify Site URL Configuration**

1. **Still in Supabase Dashboard**
2. **Go to:** Authentication → URL Configuration
3. **Set these EXACTLY:**

```yaml
Site URL:
http://localhost:49719

Additional Redirect URLs:
http://localhost:49719
http://localhost:49719/
http://localhost:49719/**
http://localhost:*
http://localhost:*/**
```

4. **Click Save**

---

### **Step 3: Check Azure AD Configuration**

1. **Go to [Azure Portal](https://portal.azure.com)**
2. **Sign in with:** `aezycreative@gmail.com`
3. **Navigate to:** Azure AD → App registrations → Your App
4. **Go to:** Authentication
5. **Verify Redirect URI is EXACTLY:**

```
https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback
```

**Important:**
- NO trailing slash
- HTTPS (not HTTP)
- Must match exactly

6. **Remove any other redirect URIs** (especially localhost ones)
7. **Click Save**

---

### **Step 4: Verify API Permissions**

1. **Still in Azure Portal, go to:** API permissions
2. **Ensure these are present and granted:**
   - ✅ Microsoft Graph → User.Read (Delegated)
   - ✅ Microsoft Graph → email (Delegated)
   - ✅ Microsoft Graph → openid (Delegated)
   - ✅ Microsoft Graph → profile (Delegated)
   - ✅ Microsoft Graph → offline_access (Delegated)

3. **If not granted, click:** "Grant admin consent for [Your Organization]"

---

### **Step 5: Clear Everything**

1. **Clear browser completely:**
   ```
   Ctrl + Shift + Delete
   → Select "All time"
   → Check "Cookies" and "Cached images"
   → Clear data
   ```

2. **Sign out of Microsoft:**
   - Go to https://login.microsoftonline.com
   - Sign out completely

3. **Close ALL browser tabs**

4. **Restart browser**

---

### **Step 6: Test with Fresh Start**

1. **Run app with specific port:**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome --web-port=49719
   ```

2. **Open browser console** (F12) before clicking login

3. **Click "Log in with Office 365"**

4. **Check console output:**
   ```
   🔐 Starting Azure AD authentication...
   🔐 Local redirect URL: http://localhost:49719/
   🔐 OAuth initiated: true
   ```

5. **Expected flow:**
   - Microsoft login opens
   - Enter credentials
   - Accept permissions
   - Redirects to Supabase callback
   - Supabase redirects to localhost:49719
   - You're logged in!

---

## **Alternative: Disable PKCE (If Still Not Working)**

If the above doesn't work, we can try disabling PKCE flow:

### **Update auth_service.dart:**

```dart
final response = await _supabase.auth.signInWithOAuth(
  OAuthProvider.azure,
  scopes: 'email profile openid offline_access',
  redirectTo: appRedirectUrl,
  // Add this to disable PKCE
  authScreenLaunchMode: LaunchMode.externalApplication,
);
```

---

## **Common Issues:**

### **Issue 1: "Tenant URL missing /v2.0"**
**Symptom:** 404 error on login.microsoftonline.com
**Fix:** Add `/v2.0` to end of Tenant URL in Supabase

### **Issue 2: "Client secret expired"**
**Symptom:** Invalid client error
**Fix:** Generate new secret in Azure, update in Supabase

### **Issue 3: "Redirect URI mismatch"**
**Symptom:** AADSTS50011 error
**Fix:** Ensure Azure has ONLY Supabase callback URL

### **Issue 4: "PKCE flow not supported"**
**Symptom:** 404 on Microsoft URL
**Fix:** Ensure Tenant URL has `/v2.0` (v2.0 endpoint supports PKCE)

---

## **Debug Checklist:**

### **Supabase:**
- [ ] Azure provider enabled
- [ ] Client ID: `5ef49f61-b51d-4484-85e6-24c127d331ed`
- [ ] Client Secret filled (not expired)
- [ ] Tenant URL: `https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0`
- [ ] Site URL: `http://localhost:49719`
- [ ] Redirect URLs include localhost patterns

### **Azure:**
- [ ] Redirect URI: `https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback`
- [ ] No localhost in redirect URIs
- [ ] Permissions granted
- [ ] Client secret not expired

### **Browser:**
- [ ] Cache cleared
- [ ] Signed out of Microsoft
- [ ] Console open for debugging

---

## **Expected Success:**

After fixing, you should see:
1. Microsoft login opens cleanly
2. No 404 errors
3. Smooth redirect back to your app
4. Session created
5. Logged in to dashboard

The key fix is ensuring the Tenant URL in Supabase ends with `/v2.0` - this enables the v2.0 endpoint which properly supports PKCE flow.

---

**Most Common Fix:** Add `/v2.0` to the Tenant URL in Supabase!
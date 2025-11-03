# 🎯 Azure Email Issue - Root Cause Identified

## Error Analysis

Based on the console output, the error occurs at this exact moment:

```
supabase.supabase_flutter: INFO: handle deeplink uri
supabase.auth: WARNING: Notifying exception AuthException(message: Error getting user email from external provider, statusCode: unexpected_failure, code: server_error)
```

### What This Means:

1. ✅ Azure AD authentication **succeeds**
2. ✅ User logs in to Microsoft successfully
3. ✅ Azure redirects back to Supabase with a token
4. ✅ Supabase receives the callback (deeplink)
5. ❌ **Supabase cannot extract email from the Azure token**
6. ❌ Authentication fails before reaching our app code

---

## Root Cause

**The Azure AD token does NOT contain the email claim.**

This happens because:
1. Azure App Registration doesn't have proper permissions
2. Admin consent hasn't been granted
3. Email is not configured as an optional claim in the token
4. Supabase expects the email claim but Azure isn't sending it

---

## The Fix: Azure Portal Configuration

### Step 1: Grant API Permissions

1. **Go to:** [Azure Portal](https://portal.azure.com)
2. **Sign in with:** `aezycreative@gmail.com`
3. **Navigate to:** Azure Active Directory → App registrations
4. **Find:** "Oro Site High School ELMS" (or your app name)
5. **Click:** API permissions (left menu)

6. **Verify these permissions exist:**
   - ✅ Microsoft Graph → User.Read (Delegated)
   - ✅ Microsoft Graph → email (Delegated)
   - ✅ Microsoft Graph → openid (Delegated)
   - ✅ Microsoft Graph → profile (Delegated)
   - ✅ Microsoft Graph → offline_access (Delegated)

7. **If any are missing, add them:**
   - Click "Add a permission"
   - Select "Microsoft Graph"
   - Select "Delegated permissions"
   - Search for and add the missing permissions

8. **CRITICAL - Grant Admin Consent:**
   - Click the button: **"Grant admin consent for [Your Organization]"**
   - Click **Yes** to confirm
   - **Wait for green checkmarks** ✅ to appear next to all permissions
   - Status should show: "Granted for [Your Organization]"

---

### Step 2: Add Email as Optional Claim

1. **Still in Azure Portal**
2. **Click:** Token configuration (left menu)
3. **Click:** "Add optional claim"
4. **Select Token type:** ID
5. **Check the box for:** email
6. **Important:** Check "Turn on the Microsoft Graph email permission"
7. **Click:** Add

**Verify:**
- You should see "email" listed under "ID" token type
- It should show as "essential" or "optional"

---

### Step 3: Enable ID Tokens

1. **Click:** Authentication (left menu)
2. **Under "Implicit grant and hybrid flows"**
3. **Check:** ✅ ID tokens (used for implicit and hybrid flows)
4. **Check:** ✅ Access tokens (optional, but recommended)
5. **Click:** Save

---

### Step 4: Verify Manifest (Advanced)

1. **Click:** Manifest (left menu)
2. **Find the `optionalClaims` section**
3. **Ensure it looks like this:**

```json
"optionalClaims": {
    "idToken": [
        {
            "name": "email",
            "source": null,
            "essential": true,
            "additionalProperties": []
        }
    ],
    "accessToken": [],
    "saml2Token": []
}
```

4. **If it's different, update it**
5. **Click:** Save

---

### Step 5: Verify Redirect URI

1. **Click:** Authentication (left menu)
2. **Under "Platform configurations" → Web**
3. **Verify this redirect URI exists:**
   ```
   https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback
   ```
4. **If missing, add it:**
   - Click "Add URI"
   - Paste the URL
   - Click Save

---

### Step 6: Check User Account

1. **Navigate to:** Azure Active Directory → Users
2. **Find:** `admin@aezycreativegmail.onmicrosoft.com`
3. **Click on the user**
4. **Verify:**
   - ✅ Email field is populated
   - ✅ User principal name is set
   - ✅ Account is enabled
   - ✅ No sign-in blocks

5. **If email is missing:**
   - Click "Edit"
   - Fill in the "Mail" field
   - Click "Save"

---

## Supabase Configuration Check

### Step 1: Verify Azure Provider Settings

1. **Go to:** [Supabase Dashboard](https://app.supabase.com)
2. **Select your project:** Oro Site High School ELMS
3. **Navigate to:** Authentication → Providers
4. **Find:** Azure
5. **Click:** to expand settings

### Step 2: Verify Configuration

**Azure Tenant URL:**
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181
```

**IMPORTANT:** Make sure it does **NOT** have `/v2.0` at the end!

❌ **WRONG:**
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

✅ **CORRECT:**
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181
```

**Application (client) ID:**
```
5ef49f61-b51d-4484-85e6-24c127d331ed
```

**Application (client) secret:**
- Should be configured (you won't see the actual value)
- If you're not sure it's correct, generate a new one in Azure Portal

### Step 3: Check URL Configuration

1. **Still in Supabase Dashboard**
2. **Go to:** Authentication → URL Configuration
3. **Verify Site URL:**
   ```
   https://fhqzohvtioosycaafnij.supabase.co
   ```

4. **Verify Redirect URLs include:**
   ```
   http://localhost:*/**
   ```
   (This allows any localhost port)

---

## Testing Procedure

### Step 1: Clear Everything

**Clear Browser Cache:**
```
1. Press Ctrl + Shift + Delete
2. Select "All time"
3. Check: Cookies and other site data
4. Check: Cached images and files
5. Click "Clear data"
```

**Sign Out of Microsoft:**
```
1. Go to: https://login.microsoftonline.com
2. Sign out if logged in
3. Go to: https://myaccount.microsoft.com
4. Sign out there too
```

**Clean Flutter:**
```bash
flutter clean
flutter pub get
```

### Step 2: Run the App

```bash
flutter run -d chrome --web-port=52659
```

### Step 3: Test Login

1. Open browser DevTools (F12) → Console tab
2. Click "Log in with Office 365"
3. Enter credentials: `admin@aezycreativegmail.onmicrosoft.com`
4. **IMPORTANT:** If you see a consent screen, click "Accept"
5. Watch the console output

### Step 4: Expected Success Output

```
🔐 Starting Azure AD authentication...
🔐 OAuth initiated: true

[After Microsoft login and redirect]

supabase.supabase_flutter: INFO: handle deeplink uri
supabase.supabase_flutter: INFO: ***** Supabase init completed *****
✅ Database connection successful
✅ Supabase initialized successfully

🔐 Auth state changed: AuthChangeEvent.signedIn
📧 User Email: admin@aezycreativegmail.onmicrosoft.com
✅ AuthGate: User signed in via OAuth
🎭 AuthGate: User role: admin

[Redirects to Admin Dashboard]
```

---

## Why This Happens

### The Technical Explanation:

1. **Azure AD uses OAuth 2.0 / OpenID Connect**
2. **When a user logs in, Azure issues an ID token**
3. **The ID token contains "claims" (user information)**
4. **By default, Azure does NOT include the email claim**
5. **You must explicitly:**
   - Request the `email` scope
   - Grant permission to read email
   - Add email as an optional claim
   - Get admin consent

6. **Supabase expects the email claim to:**
   - Create the user account
   - Link the identity
   - Populate the user profile

7. **Without the email claim:**
   - Supabase receives a token with just `sub` (subject ID)
   - Cannot create a user without email
   - Throws: "Error getting user email from external provider"

---

## Checklist

### Azure Portal:
- [ ] All 5 permissions added (User.Read, email, openid, profile, offline_access)
- [ ] Admin consent granted (green checkmarks visible)
- [ ] Email added as optional claim in Token configuration
- [ ] ID tokens enabled in Authentication
- [ ] Redirect URI configured: `https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback`
- [ ] User account has email populated

### Supabase Dashboard:
- [ ] Azure provider enabled
- [ ] Tenant URL correct (no `/v2.0` at end)
- [ ] Client ID matches Azure
- [ ] Client secret configured
- [ ] Site URL configured
- [ ] Redirect URLs include `http://localhost:*/**`

### Testing:
- [ ] Browser cache cleared
- [ ] Signed out of Microsoft
- [ ] Flutter cleaned
- [ ] App running on port 52659
- [ ] DevTools console open

---

## Most Common Issue

**99% of the time, the fix is:**

1. **Grant admin consent** in Azure Portal
2. **Add email optional claim**
3. **Clear cache and test**

The admin consent is the most critical step. Even if permissions look correct, clicking "Grant admin consent" again often fixes the issue.

---

## After the Fix

Once configured correctly, the flow will be:

1. User clicks "Log in with Office 365"
2. Redirects to Microsoft login
3. User enters credentials
4. **May see consent screen** (accept it)
5. Redirects to Supabase with token containing email
6. Supabase creates/updates user
7. Redirects to your app
8. User is logged in and routed to dashboard

---

## Still Not Working?

If you've completed all steps and it still fails:

### 1. Check Supabase Logs
```
Supabase Dashboard → Authentication → Logs
Look for detailed error messages
```

### 2. Inspect the Token
```
1. Open browser DevTools → Network tab
2. Attempt login
3. Find the callback request
4. Copy the token from the URL
5. Go to: https://jwt.io
6. Paste the token
7. Check if "email" claim is present in the payload
```

### 3. Verify Azure Token Version
```
In the JWT payload, check:
"ver": "2.0"  ← Should be version 2.0

If it's 1.0, update in Azure Portal → Manifest:
"accessTokenAcceptedVersion": 2
```

### 4. Generate New Client Secret
```
1. Azure Portal → Certificates & secrets
2. Create new client secret
3. Copy the value
4. Update in Supabase Dashboard
5. Test again
```

---

## Expected Timeline

- **Azure Portal changes:** 5-10 minutes
- **Cache clearing:** 2 minutes
- **Testing:** 2 minutes
- **Total:** ~15 minutes

---

## Success Indicators

You'll know it's fixed when:
- ✅ No error in console after login
- ✅ Console shows: `User Email: admin@aezycreativegmail.onmicrosoft.com`
- ✅ App redirects to dashboard
- ✅ User profile is created in Supabase

---

## Contact

If you need help:
1. Copy the complete console output
2. Check Supabase authentication logs
3. Verify the JWT token contains email claim
4. Review this document step by step

The issue is 100% fixable - it's just a configuration matter! 🎯

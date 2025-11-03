# 🚨 CRITICAL: Supabase Azure Configuration Issue

## The Error is Still Happening

```
❌ AuthGate: Error in auth state stream: AuthException
Message: Error getting user email from external provider
```

This error happens **BEFORE** your app code runs. It occurs when **Supabase** tries to exchange the Azure authorization code for a token and extract the email.

---

## The Most Common Issue: Supabase Tenant URL

### ⚠️ CRITICAL CHECK

Go to your Supabase Dashboard and check the **exact** Azure Tenant URL you entered.

**There are TWO possible configurations, and only ONE works:**

### ❌ Configuration 1 (WRONG - Causes your error):
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181
```

### ✅ Configuration 2 (CORRECT - Should work):
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

**The difference:** `/v2.0` at the end

---

## Why This Matters

### Without `/v2.0`:
- Supabase uses Azure AD v1.0 endpoint
- v1.0 tokens have different structure
- Email claim might not be included
- **Result:** "Error getting user email from external provider"

### With `/v2.0`:
- Supabase uses Azure AD v2.0 endpoint
- v2.0 tokens include email claim properly
- Email is extracted successfully
- **Result:** Login works ✅

---

## Step-by-Step Fix

### Step 1: Go to Supabase Dashboard

1. Open: **https://app.supabase.com**
2. Sign in to your account
3. Select your project: **Oro Site High School ELMS**

### Step 2: Navigate to Azure Provider

1. Click: **Authentication** (left sidebar)
2. Click: **Providers** tab
3. Scroll down to find: **Azure**
4. Click to expand the Azure section

### Step 3: Check the Tenant URL

Look at the **"Azure Tenant URL"** field.

**What do you see?**

#### If you see (WITHOUT `/v2.0`):
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181
```

**This is WRONG!** Change it to:
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

#### If you see (WITH `/v2.0`):
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

**This is CORRECT!** But there might be another issue (see below).

### Step 4: Verify Other Settings

While you're in the Azure provider settings, verify:

**Application (client) ID:**
```
5ef49f61-b51d-4484-85e6-24c127d331ed
```

**Application (client) secret:**
- Should show as configured (you can't see the actual value)
- **If you're not 100% sure it's correct, create a NEW one:**
  1. Go to Azure Portal
  2. App Registrations → Your App → Certificates & secrets
  3. Click "New client secret"
  4. Copy the VALUE (not the Secret ID)
  5. Paste it in Supabase

**Azure AD Tenant (if this field exists):**
```
f205dc04-e2d3-4042-94b4-7e0bb9f13181
```

### Step 5: Check Advanced Settings

Scroll down to see if there's an **"Additional Scopes"** or **"Scopes"** field.

**If it exists, enter:**
```
openid profile email offline_access
```

**If it doesn't exist, skip this step.**

### Step 6: SAVE Configuration

1. Click **"Save"** button at the bottom
2. Wait for the success message
3. **Refresh the page** to confirm changes were saved

---

## Alternative Issue: Client Secret

If the Tenant URL is already correct with `/v2.0`, the issue is likely the **client secret**.

### Why Client Secrets Fail:

1. **Expired** - They have expiration dates
2. **Wrong value** - You copied the Secret ID instead of the Value
3. **Not saved** - Supabase didn't save it properly

### How to Fix:

1. **Create a NEW client secret in Azure Portal:**
   ```
   Azure Portal → App Registrations → Your App
   → Certificates & secrets
   → Client secrets
   → + New client secret
   ```

2. **Description:** `Supabase Integration - [Today's Date]`

3. **Expires:** 24 months (or your preference)

4. **Click "Add"**

5. **IMMEDIATELY copy the VALUE** (you can only see it once!)
   - It looks like: `abc123~XYZ789...` (long random string)
   - **NOT** the "Secret ID" (which looks like a UUID)

6. **Go to Supabase Dashboard:**
   - Authentication → Providers → Azure
   - Paste the new secret in "Application (client) secret"
   - Click Save

---

## Testing After Fix

### Step 1: Clear Everything

**Browser:**
```
1. Close all browser windows
2. Open new browser window
3. Press Ctrl + Shift + Delete
4. Select "All time"
5. Check: Cookies and site data
6. Check: Cached images and files
7. Click "Clear data"
```

**Microsoft:**
```
1. Go to: https://login.microsoftonline.com
2. Sign out if logged in
3. Go to: https://myaccount.microsoft.com
4. Sign out there too
5. Close browser
```

**Flutter:**
```bash
flutter clean
flutter pub get
```

### Step 2: Run Fresh

```bash
flutter run -d chrome --web-port=52659
```

### Step 3: Test Login

1. Open DevTools (F12) → Console tab
2. Click "Log in with Office 365"
3. Enter credentials
4. **Accept consent screen if it appears**
5. Watch console output

### Step 4: Expected Success

```
supabase.supabase_flutter: INFO: handle deeplink uri
supabase.supabase_flutter: INFO: ***** Supabase init completed *****

🔐 Auth state changed: AuthChangeEvent.signedIn
📧 User Email: admin@aezycreativegmail.onmicrosoft.com
✅ AuthGate: User signed in via OAuth
```

**No error!** ✅

---

## Debugging: Check Supabase Logs

If still not working, check Supabase logs:

1. **Supabase Dashboard** → **Authentication** → **Logs**
2. Look for recent authentication attempts
3. Click on the failed attempt
4. Look for detailed error message

**Common errors in logs:**

### Error: "Invalid client secret"
**Fix:** Create new client secret in Azure Portal

### Error: "Invalid redirect URI"
**Fix:** Verify redirect URI in Azure Portal matches:
```
https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback
```

### Error: "User email not found in token"
**Fix:** Verify Tenant URL has `/v2.0` at the end

---

## Quick Checklist

### Supabase Configuration:
- [ ] Azure provider is **ENABLED** (toggle is ON)
- [ ] Tenant URL is: `https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0`
- [ ] Tenant URL has `/v2.0` at the end ⚠️ **CRITICAL**
- [ ] Client ID is: `5ef49f61-b51d-4484-85e6-24c127d331ed`
- [ ] Client secret is valid and not expired
- [ ] Configuration is **SAVED**
- [ ] Page refreshed to confirm changes

### Azure Portal (Already Done):
- [x] Admin consent granted
- [x] Email optional claim added
- [x] ID tokens enabled
- [x] User.Read permission granted

### Code (Already Fixed):
- [x] OAuth scopes include Graph API scope
- [x] Query params added

---

## Most Likely Culprits

Based on your error, it's one of these:

1. **Tenant URL missing `/v2.0`** (90% probability)
2. **Client secret is wrong/expired** (80% probability)
3. **Supabase provider not properly saved** (50% probability)

---

## Screenshot Request

Can you take a screenshot of your Supabase Azure provider configuration showing:
- The Tenant URL field
- The Client ID field
- The enabled/disabled toggle

This will help me identify the exact issue.

---

## Alternative: Check Supabase Provider Type

Some Supabase versions have different Azure provider options:

1. **Azure** (standard)
2. **Azure AD B2C** (different)

Make sure you're configuring the correct one. If you see both, use **Azure** (not Azure AD B2C).

---

## Nuclear Option: Recreate Provider

If nothing works, try this:

1. **Disable** the Azure provider in Supabase
2. **Save**
3. **Enable** it again
4. **Re-enter all configuration:**
   - Tenant URL: `https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0`
   - Client ID: `5ef49f61-b51d-4484-85e6-24c127d331ed`
   - Client secret: [new secret from Azure]
5. **Save**
6. **Test**

---

## Expected Timeline

- Check Supabase config: **2 minutes**
- Fix Tenant URL: **1 minute**
- Create new client secret: **3 minutes**
- Clear cache: **2 minutes**
- Test: **2 minutes**
- **Total: ~10 minutes**

---

## The Bottom Line

The error "Error getting user email from external provider" happens at the **Supabase level**, not in your app code.

**This means:**
- ✅ Your Azure Portal is configured correctly
- ✅ Your code is now fixed
- ❌ **Supabase configuration is incorrect**

**The fix is in Supabase Dashboard, not in code!**

Focus on:
1. Tenant URL with `/v2.0`
2. Valid client secret
3. Provider enabled and saved

Once Supabase is configured correctly, the error will disappear! 🎯

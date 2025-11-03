# 🔍 Azure Login Debugging Guide

## Current Issue

**Error Message:**
```
Error getting user email from external provider
error_code: unexpected_failure
code: server_error
```

**What This Means:**
- Azure AD authentication is working ✅
- User successfully logs in to Microsoft ✅
- Azure redirects back to Supabase ✅
- **BUT:** Supabase cannot extract the user's email from the Azure token ❌

---

## Root Cause Analysis

The error occurs because **Azure AD is not sending the email claim** in the ID token to Supabase. This happens when:

1. **API Permissions not granted** - The Azure app doesn't have permission to read user email
2. **Admin consent not given** - Permissions exist but weren't consented by admin
3. **Optional claims not configured** - Email claim not included in token
4. **Token configuration issue** - Wrong token version or audience

---

## Debugging Steps Added

I've added comprehensive debugging to track the authentication flow:

### 1. **Auth Service Debugging** (`lib/services/auth_service.dart`)

**Added logging for:**
- Auth state changes with full user details
- Email extraction from multiple sources (user.email, identity data, metadata)
- Profile creation/update process

**Debug Output:**
```
🔐 Auth state changed: AuthChangeEvent.signedIn
📧 User ID: [user-id]
📧 User Email: [email or "NO EMAIL"]
📧 User Metadata: {...}
📧 App Metadata: {...}
📧 Identity Data: [{provider: azure, identity_data: {...}}]
```

### 2. **AuthGate Debugging** (`lib/screens/auth_gate.dart`)

**Added logging for:**
- Auth state stream events
- Error handling with detailed AuthException info
- User authentication status checks

**Debug Output:**
```
🎯 AuthGate: Received auth state change: signedIn
✅ AuthGate: User signed in via OAuth
👤 AuthGate: Current user ID: [id]
📧 AuthGate: Current user email: [email or "NO EMAIL"]
🎭 AuthGate: User role: [role]
```

### 3. **Email Extraction Fallback**

The code now tries to extract email from multiple sources:
1. `user.email` (primary)
2. `identity.identityData['email']`
3. `identity.identityData['mail']`
4. `identity.identityData['preferred_username']`
5. `identity.identityData['upn']`
6. `user.userMetadata['email']`
7. `user.userMetadata['mail']`
8. `user.userMetadata['preferred_username']`

---

## How to Use the Debugging

### Step 1: Run the Application
```bash
flutter run -d chrome --web-port=52659
```

### Step 2: Open Browser DevTools
- Press **F12** to open DevTools
- Go to **Console** tab
- Keep it open during login

### Step 3: Attempt Azure Login
1. Click "Log in with Office 365"
2. Complete Microsoft authentication
3. Watch the console output

### Step 4: Analyze the Output

**Look for these key debug messages:**

#### A. **OAuth Initiation**
```
🔐 Starting Azure AD authentication...
🔐 Tenant ID: f205dc04-e2d3-4042-94b4-7e0bb9f13181
🔐 Client ID: 5ef49f61-b51d-4484-85e6-24c127d331ed
🔐 Dynamic redirect URL: http://localhost:52659/
```

#### B. **Auth State Change**
```
🔐 Auth state changed: AuthChangeEvent.signedIn
📧 User Email: [CHECK THIS - should show email, not "NO EMAIL"]
📧 Identity Data: [CHECK THIS - should contain email in identity_data]
```

#### C. **Profile Creation**
```
🔍 DEBUG: Creating/updating profile
🔍 User Email: [CHECK THIS]
🔍 User Identities: [CHECK THIS - look for email in identity_data]
```

#### D. **Email Extraction**
```
✅ Using email: [email@domain.com]
OR
⚠️ Email is null, trying to extract from identity data...
❌ ERROR: Could not extract email from any source
```

---

## Expected Debug Output Scenarios

### ✅ **Scenario 1: Success (Email Found)**
```
🔐 Auth state changed: AuthChangeEvent.signedIn
📧 User Email: admin@aezycreativegmail.onmicrosoft.com
🔍 DEBUG: Creating/updating profile
🔍 User Email: admin@aezycreativegmail.onmicrosoft.com
✅ Using email: admin@aezycreativegmail.onmicrosoft.com
✅ AuthGate: User signed in via OAuth
```

### ❌ **Scenario 2: Email Missing (Current Issue)**
```
🔐 Auth state changed: AuthChangeEvent.signedIn
📧 User Email: NO EMAIL
📧 Identity Data: [{provider: azure, identity_data: {sub: xxx, ...}}]
🔍 DEBUG: Creating/updating profile
🔍 User Email: NULL
⚠️ Email is null, trying to extract from identity data...
🔍 Checking identity provider: azure
🔍 Identity data: {sub: xxx, aud: xxx, ...}  [NO EMAIL FIELD!]
❌ ERROR: Could not extract email from any source
```

### ⚠️ **Scenario 3: Email in Identity Data**
```
🔐 Auth state changed: AuthChangeEvent.signedIn
📧 User Email: NO EMAIL
📧 Identity Data: [{provider: azure, identity_data: {email: admin@...}}]
🔍 DEBUG: Creating/updating profile
⚠️ Email is null, trying to extract from identity data...
✅ Found email in identity data: admin@aezycreativegmail.onmicrosoft.com
✅ Using email: admin@aezycreativegmail.onmicrosoft.com
```

---

## What to Check Based on Debug Output

### If `User Email: NO EMAIL` and `Identity Data` has NO email field:

**Problem:** Azure is not sending email claim at all

**Solution:**
1. Go to Azure Portal → App Registrations → Your App
2. **API Permissions:**
   - Ensure `User.Read` is present
   - Ensure `email` permission is present
   - Click **"Grant admin consent"** button
   - Verify all show green checkmarks ✅

3. **Token Configuration:**
   - Go to "Token configuration"
   - Add optional claim: `email` for ID token
   - Mark it as "essential"

4. **Authentication:**
   - Enable "ID tokens" under Implicit grant

5. **Test again** after clearing browser cache

### If `Identity Data` has email but `User Email` is NULL:

**Problem:** Supabase is not extracting email from identity data

**Solution:**
- The fallback code should handle this
- Check Supabase provider configuration
- Verify Azure tenant URL doesn't have double `/v2.0`

### If email is found but login still fails:

**Problem:** Database/profile creation issue

**Solution:**
- Check Supabase logs in dashboard
- Verify `profiles` table exists
- Check RLS policies allow insert

---

## Azure Portal Checklist

### 1. API Permissions (CRITICAL)
- [ ] `User.Read` - Delegated
- [ ] `email` - Delegated
- [ ] `openid` - Delegated
- [ ] `profile` - Delegated
- [ ] `offline_access` - Delegated
- [ ] **Admin consent granted** (green checkmarks)

### 2. Token Configuration
- [ ] Optional claim `email` added to ID token
- [ ] Optional claim marked as "essential"
- [ ] Optional claim `preferred_username` added (optional)

### 3. Authentication
- [ ] ID tokens enabled
- [ ] Access tokens enabled (optional)
- [ ] Redirect URI: `https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback`

### 4. Manifest
```json
{
  "accessTokenAcceptedVersion": 2,
  "optionalClaims": {
    "idToken": [
      {
        "name": "email",
        "essential": true
      }
    ]
  }
}
```

---

## Supabase Configuration Checklist

### 1. Azure Provider Settings
- [ ] Provider enabled
- [ ] Tenant URL: `https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181`
  - **NO `/v2.0` at the end!**
- [ ] Client ID: `5ef49f61-b51d-4484-85e6-24c127d331ed`
- [ ] Client Secret: [configured]

### 2. URL Configuration
- [ ] Site URL matches redirect URI
- [ ] Redirect URLs include: `http://localhost:*/**`

---

## Testing Procedure

### 1. Clear Everything
```bash
# Clear browser data
Ctrl + Shift + Delete → All time → Cookies + Cache

# Sign out of Microsoft
https://login.microsoftonline.com → Sign out
https://myaccount.microsoft.com → Sign out

# Clean Flutter
flutter clean
flutter pub get
```

### 2. Run with Debugging
```bash
flutter run -d chrome --web-port=52659
```

### 3. Monitor Console
- Keep DevTools console open
- Watch for debug messages
- Copy all output if error occurs

### 4. Attempt Login
- Click "Log in with Office 365"
- Complete authentication
- **Accept consent screen if it appears**
- Watch console output

### 5. Analyze Results
- Check if email appears in debug output
- Check if identity data contains email
- Check if profile creation succeeds

---

## Common Fixes

### Fix 1: Grant Admin Consent (Most Common)
1. Azure Portal → App Registrations → Your App
2. API Permissions
3. Click **"Grant admin consent for [Organization]"**
4. Click **Yes**
5. Verify green checkmarks appear
6. Test again

### Fix 2: Add Email Optional Claim
1. Azure Portal → Token configuration
2. Add optional claim
3. Token type: **ID**
4. Select: **email** (mark as essential)
5. Save
6. Test again

### Fix 3: Enable ID Tokens
1. Azure Portal → Authentication
2. Implicit grant and hybrid flows
3. Check: **ID tokens**
4. Save
5. Test again

### Fix 4: Fix Supabase Tenant URL
1. Supabase Dashboard → Authentication → Providers → Azure
2. Ensure Tenant URL is:
   ```
   https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181
   ```
3. **NOT:**
   ```
   https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
   ```
4. Save
5. Test again

---

## Next Steps

1. **Run the app** with debugging enabled
2. **Attempt login** and watch console output
3. **Copy the debug output** and analyze it
4. **Identify which scenario** matches your output
5. **Apply the corresponding fix** from Azure Portal
6. **Test again** after each change

The debug output will tell us exactly where the email is missing and guide us to the right fix!

---

## Additional Resources

- [Azure AD Optional Claims](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-optional-claims)
- [Supabase OAuth Guide](https://supabase.com/docs/guides/auth/social-login/auth-azure)
- [PKCE Flow Documentation](https://oauth.net/2/pkce/)

---

## Contact Points

If debugging shows email in identity data but still failing:
- Check Supabase logs: Dashboard → Authentication → Logs
- Check browser network tab for token response
- Verify JWT token contents at jwt.io

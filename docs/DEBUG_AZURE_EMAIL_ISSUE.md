# Debug Azure AD Email Issue - Step by Step

## Error Message
```
AuthException(message: Error getting user email from external provider, 
statusCode: unexpected_failure, code: server_error)
```

## Root Cause
This error occurs when **Supabase Auth cannot find the email claim** in the Azure AD token during the OAuth callback. This happens BEFORE your Flutter code runs.

## Step-by-Step Debugging

### Step 1: Verify Azure AD Token Configuration

1. **Go to Azure Portal** → **App Registrations** → Your app
2. Click **Token configuration** (left sidebar)
3. **Verify these optional claims are added:**

   **For ID Token:**
   - ✅ `email` (Type: String)
   - ✅ `preferred_username` (Type: String)
   - ✅ `upn` (Type: String)

   **For Access Token:**
   - ✅ `email` (Type: String)
   - ✅ `preferred_username` (Type: String)
   - ✅ `upn` (Type: String)

4. **If any are missing, add them:**
   - Click **+ Add optional claim**
   - Select **Token type: ID** → Check `email`, `preferred_username`, `upn`
   - Click **Add**
   - Accept the Microsoft Graph permission prompt
   - Repeat for **Token type: Access**

### Step 2: Verify API Permissions

1. **Go to Azure Portal** → **App Registrations** → Your app
2. Click **API permissions** (left sidebar)
3. **Verify these permissions exist:**
   - ✅ `email` (Microsoft Graph)
   - ✅ `offline_access` (Microsoft Graph)
   - ✅ `openid` (Microsoft Graph)
   - ✅ `profile` (Microsoft Graph)
   - ✅ `User.Read` (Microsoft Graph)

4. **Verify Admin Consent is granted:**
   - Look for green checkmarks in the "Status" column
   - If not granted, click **Grant admin consent for [Your Org]**

### Step 3: Check User Email in Azure AD

1. **Go to Azure Portal** → **Azure Active Directory** → **Users**
2. **Find the new user** you're trying to login with
3. **Click on the user** → Check these fields:
   - ✅ **User principal name**: Should be filled (e.g., `testuser@yourdomain.com`)
   - ✅ **Mail**: Should be filled (e.g., `testuser@yourdomain.com`)
   - ✅ **Email**: Should be filled

4. **If any are empty:**
   - Click **Edit**
   - Fill in the email fields
   - Click **Save**

### Step 4: Verify Supabase Azure Provider Configuration

1. **Go to Supabase Dashboard** → Your project
2. Click **Authentication** → **Providers**
3. Find **Azure** provider
4. **Verify these settings:**
   - ✅ **Azure Enabled**: ON
   - ✅ **Client ID**: Matches your Azure App Registration Application (client) ID
   - ✅ **Client Secret**: Valid and not expired
   - ✅ **Azure Tenant URL**: `https://login.microsoftonline.com/{TENANT_ID}/v2.0`

5. **Check the Redirect URL:**
   - Copy the redirect URL shown in Supabase (e.g., `https://xxx.supabase.co/auth/v1/callback`)
   - Go to Azure Portal → App Registrations → Your app → **Authentication**
   - Verify this exact URL is in the **Redirect URIs** list

### Step 5: Test with JWT.io

Let's decode the Azure AD token to see what claims are actually being sent:

1. **Create a test login page** to capture the token
2. **Login with your new user**
3. **Copy the access token** from the browser's network tab
4. **Go to https://jwt.io**
5. **Paste the token** in the "Encoded" section
6. **Check the decoded payload** for these claims:
   ```json
   {
     "email": "user@domain.com",        // ← Should exist
     "preferred_username": "user@domain.com",  // ← Should exist
     "upn": "user@domain.com",          // ← Should exist
     "roles": ["student"]               // ← Should exist
   }
   ```

7. **If `email` is missing** → Go back to Step 1 and add optional claims

### Step 6: Check Azure AD User Type

Some Azure AD user types don't have email by default:

1. **Go to Azure Portal** → **Azure Active Directory** → **Users**
2. **Click on the new user**
3. **Check "User type":**
   - ✅ **Member**: Should have email
   - ⚠️ **Guest**: Might not have email claim by default

4. **If Guest user:**
   - You need to configure Azure AD to include email for guest users
   - Or convert to Member user

### Step 7: Clear Browser Cache and Test

Sometimes old tokens are cached:

1. **Open your app in Incognito/Private mode**
2. **Clear all browser data** (Ctrl+Shift+Delete)
3. **Try logging in again**

### Step 8: Check Supabase Logs

1. **Go to Supabase Dashboard** → Your project
2. Click **Logs** → **Auth Logs**
3. **Look for recent failed login attempts**
4. **Check the error details** for more information

### Step 9: Test with a Different User

1. **Create a brand new user in Azure AD**
2. **Fill in ALL fields** (User principal name, Display name, Mail)
3. **Assign a role** in Enterprise Application
4. **Wait 5-10 minutes** for Azure AD to propagate changes
5. **Try logging in with this new user**

### Step 10: Enable Verbose Logging in Flutter

Add this to your `main.dart` to see more detailed logs:

```dart
import 'package:logging/logging.dart';

void main() {
  // Enable verbose logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(MyApp());
}
```

## Common Solutions

### Solution 1: Email Claim Not in Token
**Problem**: Azure AD is not including email in the token
**Fix**: Add `email` as optional claim in Token Configuration (Step 1)

### Solution 2: User Email Not Set
**Problem**: The user account in Azure AD doesn't have an email
**Fix**: Edit the user in Azure AD and fill in the email fields (Step 3)

### Solution 3: API Permissions Not Granted
**Problem**: App doesn't have permission to read user email
**Fix**: Grant admin consent for API permissions (Step 2)

### Solution 4: Wrong Tenant Configuration
**Problem**: Supabase is configured for wrong Azure AD tenant
**Fix**: Verify Azure Tenant URL in Supabase matches your Azure AD tenant (Step 4)

### Solution 5: Redirect URI Mismatch
**Problem**: Azure AD redirect URI doesn't match Supabase callback URL
**Fix**: Add exact Supabase callback URL to Azure AD redirect URIs (Step 4)

## Next Steps

After completing all steps above:

1. **Take screenshots** of:
   - Azure AD Token Configuration page
   - Azure AD API Permissions page
   - Azure AD User details page (the new user)
   - Supabase Azure provider configuration

2. **Try logging in** with the new user in incognito mode

3. **Copy the console logs** and share them

4. **If still failing**, we'll need to:
   - Check the actual Azure AD token claims
   - Verify Supabase Auth configuration
   - Check for any Azure AD conditional access policies blocking the login

## Emergency Workaround

If you need to test immediately and can't fix Azure AD:

1. **Create a test user with email/password** in Supabase Auth
2. **Manually insert records** in profiles and role tables
3. **Test the rest of your app** while debugging Azure AD

This will let you continue development while fixing the Azure AD issue.


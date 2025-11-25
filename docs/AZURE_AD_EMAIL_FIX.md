# Azure AD Authentication - Email Claim Fix

## Problem

When users try to login via Azure AD, they get this error:
```
Error getting user email from external provider
Status Code: unexpected_failure
Code: server_error
```

## Root Cause

Azure AD is not including the `email` claim in the ID token by default. Supabase requires the email claim to create user accounts.

## Solution

### Step 1: Add Email as Optional Claim in Azure AD

1. **Go to Azure Portal**
   - Navigate to: https://portal.azure.com
   - Go to **Azure Active Directory** (or **Microsoft Entra ID**)

2. **Open App Registrations**
   - Click **App registrations** in the left sidebar
   - Select your application (the one used for Supabase authentication)

3. **Configure Token**
   - Click **Token configuration** in the left sidebar
   - Click **+ Add optional claim**

4. **Add Email Claim**
   - Select **Token type: ID**
   - Check the box for **email**
   - Click **Add**
   - If prompted: "Turn on the Microsoft Graph email permission (required for claims to appear in token)"
     - Check the box
     - Click **Add**

### Step 2: Add API Permissions

1. **Go to API Permissions**
   - In your app registration, click **API permissions** in the left sidebar

2. **Add Microsoft Graph Permissions**
   - Click **+ Add a permission**
   - Select **Microsoft Graph**
   - Select **Delegated permissions**

3. **Add These Permissions**:
   - ✅ `email`
   - ✅ `offline_access`
   - ✅ `openid`
   - ✅ `profile`
   - ✅ `User.Read`

4. **Grant Admin Consent**
   - Click **Grant admin consent for [Your Tenant]**
   - Click **Yes** to confirm
   - Wait for all permissions to show "Granted for [Your Tenant]" in green

### Step 3: Verify Redirect URI

1. **Go to Authentication**
   - In your app registration, click **Authentication** in the left sidebar

2. **Check Redirect URIs**
   - Make sure you have these redirect URIs configured:
     - `https://[YOUR-PROJECT-REF].supabase.co/auth/v1/callback`
     - `http://localhost:[PORT]/` (for local development)

3. **Check Supported Account Types**
   - For organizational users only: **Accounts in this organizational directory only**
   - For any Microsoft account: **Accounts in any organizational directory and personal Microsoft accounts**

### Step 4: Verify Supabase Configuration

1. **Go to Supabase Dashboard**
   - Navigate to: https://supabase.com/dashboard
   - Select your project

2. **Enable Azure Provider**
   - Go to **Authentication** → **Providers**
   - Find **Azure** and enable it

3. **Configure Azure Settings**:
   - **Azure Tenant ID**: Your tenant ID from Azure AD
   - **Azure Client ID**: Your application (client) ID
   - **Azure Client Secret**: Your client secret value
   - **Redirect URL**: Copy this and add it to Azure AD redirect URIs

### Step 5: Test the Login

1. **Clear Browser Cache** (important!)
   - Clear cookies and cache for your app
   - Or use an incognito/private window

2. **Try Logging In**
   - Click "Sign in with Microsoft" or "Sign in with Azure"
   - Select your account
   - Grant permissions if prompted
   - You should now be redirected back successfully!

## Verification

After completing these steps, the Azure AD token will include the email claim, and Supabase will be able to:
- ✅ Extract the user's email
- ✅ Create a user account in Supabase Auth
- ✅ Create a profile record in your database
- ✅ Create role-specific records (student, teacher, admin, parent)
- ✅ Route the user to the appropriate dashboard

## Troubleshooting

### Still Getting Email Error?

1. **Wait 5-10 minutes** - Azure AD changes can take time to propagate
2. **Clear browser cache completely**
3. **Check Azure AD logs**:
   - Go to Azure Portal → Azure Active Directory → Sign-in logs
   - Look for your test login attempt
   - Check if the token includes the email claim

### Users Can't See Their Role?

Make sure you've assigned roles in Azure AD:
1. Go to **Enterprise Applications** → Select your app
2. Go to **Users and groups**
3. Click **+ Add user/group**
4. Select the user
5. Click **Select a role**
6. Choose: `student`, `teacher`, `admin`, `parent`, or `grade_coordinator`
7. Click **Assign**

### RLS Policy Errors?

If you see "new row violates row-level security policy", the RLS policies have been updated to allow self-registration. Run:
```sql
-- Check if policies are correct
SELECT tablename, policyname, cmd, with_check 
FROM pg_policies 
WHERE tablename IN ('profiles', 'students', 'teachers', 'admins', 'parents') 
AND cmd = 'INSERT';
```

All INSERT policies should allow `auth.uid() = id OR is_admin()`.

## References

- [Supabase Azure AD Documentation](https://supabase.com/docs/guides/auth/social-login/auth-azure)
- [GitHub Issue #1045](https://github.com/supabase/auth/issues/1045)
- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)


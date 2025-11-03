# 🔧 **Fix: Error getting user email from external provider**

## **Great Progress!**
✅ Microsoft login is working
✅ Authentication is successful
❌ But Supabase can't get the user's email from Azure AD

---

## **The Solution: Fix Azure AD Permissions**

### **Step 1: Grant API Permissions in Azure**

1. **Go to [Azure Portal](https://portal.azure.com)**
2. **Sign in with:** `aezycreative@gmail.com`
3. **Navigate to:** Azure Active Directory → App registrations → Your App
4. **Go to:** API permissions

5. **Add these EXACT permissions if missing:**

   Click **Add a permission** → **Microsoft Graph** → **Delegated permissions**:
   
   - ✅ **User.Read** (Sign in and read user profile)
   - ✅ **email** (View users' email address)
   - ✅ **openid** (Sign users in)
   - ✅ **profile** (View users' basic profile)
   - ✅ **offline_access** (Maintain access to data)

6. **CRITICAL STEP - Grant Admin Consent:**
   - After adding all permissions
   - Click the **"Grant admin consent for [Your Organization]"** button
   - Click **Yes** to confirm
   - You should see green checkmarks ✅ next to all permissions

7. **Verify Status:**
   - All permissions should show "Granted for [Your Organization]"
   - If any show "Not granted", click Grant admin consent again

---

### **Step 2: Update App Registration Settings**

1. **Still in Azure Portal, go to:** Authentication
2. **Under "Implicit grant and hybrid flows", check:**
   - ✅ **Access tokens** (used for implicit flows)
   - ✅ **ID tokens** (used for implicit and hybrid flows)
3. **Click Save**

---

### **Step 3: Verify Token Configuration**

1. **Go to:** Token configuration (in left menu)
2. **Click "Add optional claim"**
3. **Token type:** ID
4. **Select these claims:**
   - ✅ email
   - ✅ family_name
   - ✅ given_name
   - ✅ preferred_username
5. **Click Add**
6. **If prompted about Microsoft Graph permissions, click "Add"**

---

### **Step 4: Check Manifest (Advanced)**

1. **Go to:** Manifest (in left menu)
2. **Find these settings and ensure they're set correctly:**

```json
{
    "accessTokenAcceptedVersion": 2,
    "signInAudience": "AzureADMyOrg",
    "optionalClaims": {
        "idToken": [
            {
                "name": "email",
                "essential": true
            },
            {
                "name": "preferred_username",
                "essential": false
            }
        ],
        "accessToken": [],
        "saml2Token": []
    }
}
```

3. **If you made changes, click Save**

---

### **Step 5: Update Supabase Configuration**

1. **Go to [Supabase Dashboard](https://app.supabase.com)**
2. **Authentication → Providers → Azure**
3. **Verify the configuration:**

```yaml
Azure Tenant URL:
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181

(Make sure it does NOT have /v2.0 at the end since that was causing issues)
```

4. **Advanced: Add Scopes Manually**
   - Some Supabase versions have an "Additional Scopes" field
   - If present, add: `email profile openid offline_access User.Read`

---

### **Step 6: Clear Everything and Test**

1. **Sign out of Microsoft completely:**
   - Go to https://login.microsoftonline.com
   - Sign out
   - Go to https://myaccount.microsoft.com
   - Sign out there too

2. **Clear browser data:**
   ```
   Ctrl + Shift + Delete
   → All time
   → Cookies and cached images
   → Clear data
   ```

3. **Restart your app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome --web-port=49719
   ```

4. **Test login again:**
   - Click "Log in with Office 365"
   - Sign in with `admin@aezycreativegmail.onmicrosoft.com`
   - **IMPORTANT**: You might see a new consent screen asking for email permission
   - Accept all permissions

---

## **Alternative Fix: User Account Settings**

If permissions are correct but still failing:

### **Check the User Account in Azure AD:**

1. **Go to:** Azure Active Directory → Users
2. **Find:** `admin@aezycreativegmail.onmicrosoft.com`
3. **Click on the user**
4. **Verify:**
   - Email field is populated
   - Account is enabled
   - No sign-in blocks

### **Update User Profile:**
1. **Click Edit**
2. **Ensure these fields have values:**
   - User principal name
   - Mail (email address)
   - Display name
3. **Save**

---

## **Debug: Check What's Being Returned**

1. **Open Browser DevTools** (F12)
2. **Go to Network tab**
3. **Try login again**
4. **After redirect back, look for:**
   - URL parameters in the redirect
   - Any error details
   - Check Console for JavaScript errors

5. **Look for the callback URL:**
   ```
   http://localhost:49719/?error=server_error&error_code=unexpected_failure
   ```
   
   This confirms Azure authenticated but didn't return email.

---

## **Quick Checklist:**

### **Azure Portal:**
- [ ] All permissions added (User.Read, email, openid, profile, offline_access)
- [ ] Admin consent granted (green checkmarks)
- [ ] ID tokens enabled in Authentication
- [ ] Optional claims configured for email
- [ ] User account has email populated

### **Supabase:**
- [ ] Tenant URL correct (without double /v2.0)
- [ ] Client ID and Secret correct

### **Browser:**
- [ ] Signed out of all Microsoft accounts
- [ ] Cache cleared
- [ ] Cookies cleared

---

## **Expected Success Flow:**

1. Click "Log in with Office 365"
2. Microsoft login appears
3. Enter credentials
4. **May see consent screen for email permission** (Accept it!)
5. Redirects to Supabase
6. Supabase gets email from token
7. Creates/updates user
8. Redirects to localhost:49719 (WITHOUT error parameters)
9. App detects session
10. Routes to dashboard

---

## **Most Common Fix:**

**Grant admin consent** in Azure Portal! Even if permissions look correct, clicking "Grant admin consent" again often fixes this issue.

The error "Error getting user email from external provider" almost always means Azure AD isn't sending the email claim because permissions weren't properly consented.

---

## **Still Not Working?**

If still getting the error after all steps:

1. **Try creating a new client secret** in Azure
2. **Update it in Supabase**
3. **Test with a different user account**
4. **Check Supabase logs:** Authentication → Logs (look for detailed error)

We're very close! This error means authentication is working - we just need Azure to share the email with Supabase.
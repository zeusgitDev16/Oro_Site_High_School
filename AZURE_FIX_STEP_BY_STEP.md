# 🔧 Azure Email Fix - Step-by-Step Guide

## ⚡ Quick Summary

**Problem:** Azure isn't sending email in the token to Supabase  
**Solution:** Grant admin consent + Add email claim  
**Time:** 5-10 minutes  

---

## 📋 Step-by-Step Instructions

### STEP 1: Open Azure Portal

1. Go to: **https://portal.azure.com**
2. Sign in with: **aezycreative@gmail.com**
3. Wait for portal to load

---

### STEP 2: Navigate to App Registration

1. In the search bar at top, type: **"App registrations"**
2. Click: **App registrations** (under Services)
3. Find your app: **"Oro Site High School ELMS"** (or similar name)
4. Click on it to open

---

### STEP 3: Grant Admin Consent (MOST IMPORTANT!)

1. In the left menu, click: **API permissions**
2. You should see a list of permissions
3. Look for the button: **"Grant admin consent for [Your Organization]"**
4. Click that button
5. A popup appears asking "Do you want to grant consent?"
6. Click: **Yes**
7. Wait a few seconds
8. **Verify:** All permissions now show green checkmarks ✅ in the "Status" column
9. Status should say: **"Granted for [Your Organization]"**

**If you don't see the button:**
- You might not have admin rights
- Contact your Azure admin
- Or use the account that created the Azure subscription

---

### STEP 4: Add Email Optional Claim

1. In the left menu, click: **Token configuration**
2. Click the button: **"+ Add optional claim"**
3. A panel opens on the right
4. Select token type: **ID** (click the radio button)
5. Scroll down and find: **email**
6. Check the box next to **email**
7. A message appears: "Turn on the Microsoft Graph email permission"
8. Check that box too
9. Click: **Add** button at the bottom
10. **Verify:** You should now see "email" listed under "ID" section

---

### STEP 5: Enable ID Tokens

1. In the left menu, click: **Authentication**
2. Scroll down to: **"Implicit grant and hybrid flows"**
3. Check the box: ✅ **ID tokens (used for implicit and hybrid flows)**
4. Check the box: ✅ **Access tokens (used for implicit flows)** (optional but recommended)
5. Click: **Save** button at the top

---

### STEP 6: Verify Redirect URI

1. Still on the **Authentication** page
2. Look for: **"Platform configurations"** section
3. Under **Web**, you should see:
   ```
   https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback
   ```
4. **If it's missing:**
   - Click: **"+ Add URI"**
   - Paste: `https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback`
   - Click: **Save**

---

### STEP 7: Check User Account

1. In the search bar at top, type: **"Azure Active Directory"**
2. Click: **Azure Active Directory**
3. In the left menu, click: **Users**
4. Find: **admin@aezycreativegmail.onmicrosoft.com**
5. Click on the user
6. **Verify these fields have values:**
   - User principal name: ✅ Should be filled
   - Mail: ✅ Should show email address
   - Display name: ✅ Should be filled
7. **If Mail is empty:**
   - Click: **Edit** at the top
   - Fill in the Mail field with: `admin@aezycreativegmail.onmicrosoft.com`
   - Click: **Save**

---

### STEP 8: Verify Supabase Configuration

1. Go to: **https://app.supabase.com**
2. Sign in to your account
3. Select project: **Oro Site High School ELMS**
4. In the left menu, click: **Authentication**
5. Click: **Providers** tab
6. Find: **Azure** in the list
7. Click to expand it
8. **Verify these settings:**

   **Azure Tenant URL:**
   ```
   https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181
   ```
   ⚠️ **Make sure it does NOT end with `/v2.0`**

   **Application (client) ID:**
   ```
   5ef49f61-b51d-4484-85e6-24c127d331ed
   ```

   **Application (client) secret:**
   - Should show as configured (hidden)

9. **If anything is wrong:**
   - Click: **Edit**
   - Fix the values
   - Click: **Save**

---

### STEP 9: Clear Cache

**Clear Browser:**
1. Press: **Ctrl + Shift + Delete**
2. Select: **All time**
3. Check: ✅ Cookies and other site data
4. Check: ✅ Cached images and files
5. Click: **Clear data**

**Sign Out of Microsoft:**
1. Go to: **https://login.microsoftonline.com**
2. If logged in, click sign out
3. Go to: **https://myaccount.microsoft.com**
4. If logged in, click sign out

**Clean Flutter:**
```bash
flutter clean
flutter pub get
```

---

### STEP 10: Test the Fix

1. **Run the app:**
   ```bash
   flutter run -d chrome --web-port=52659
   ```

2. **Open DevTools:**
   - Press: **F12**
   - Click: **Console** tab
   - Keep it open

3. **Attempt login:**
   - Click: **"Log in with Office 365"**
   - Enter: `admin@aezycreativegmail.onmicrosoft.com`
   - Enter password
   - **If consent screen appears:** Click **Accept**

4. **Watch console output:**
   - Should see: `User Email: admin@aezycreativegmail.onmicrosoft.com`
   - Should redirect to dashboard
   - No error messages

---

## ✅ Success Checklist

After completing all steps, verify:

### Azure Portal:
- [ ] Admin consent granted (green checkmarks visible)
- [ ] Email optional claim added to ID token
- [ ] ID tokens enabled in Authentication
- [ ] Redirect URI configured correctly
- [ ] User account has email populated

### Supabase:
- [ ] Azure provider enabled
- [ ] Tenant URL correct (no `/v2.0`)
- [ ] Client ID matches
- [ ] Client secret configured

### Testing:
- [ ] Browser cache cleared
- [ ] Signed out of Microsoft
- [ ] Flutter cleaned
- [ ] App running
- [ ] DevTools open

---

## 🎯 Expected Result

**Console output after successful login:**
```
🔐 Starting Azure AD authentication...
🔐 OAuth initiated: true

[After login]

supabase.supabase_flutter: INFO: handle deeplink uri
supabase.supabase_flutter: INFO: ***** Supabase init completed *****

🔐 Auth state changed: AuthChangeEvent.signedIn
📧 User Email: admin@aezycreativegmail.onmicrosoft.com
✅ AuthGate: User signed in via OAuth
🎭 AuthGate: User role: admin

[Redirects to Admin Dashboard]
```

**No error messages!** ✅

---

## 🆘 Troubleshooting

### If still getting error:

**1. Verify admin consent was granted:**
- Go back to Azure Portal → API permissions
- Check that ALL permissions show green checkmarks
- Status should say "Granted for [Organization]"
- If not, click "Grant admin consent" again

**2. Verify email claim was added:**
- Go to Azure Portal → Token configuration
- Should see "email" listed under ID token
- If not, add it again

**3. Check Supabase logs:**
- Supabase Dashboard → Authentication → Logs
- Look for detailed error messages

**4. Inspect the token:**
- Open DevTools → Network tab
- Attempt login
- Find the callback request
- Copy token from URL
- Go to jwt.io and paste it
- Check if "email" is in the payload

**5. Try a different browser:**
- Sometimes cache issues persist
- Try in incognito/private mode

---

## 💡 Pro Tips

1. **Admin consent is the #1 fix** - Even if permissions look correct, click it again
2. **Wait a few minutes** - Sometimes Azure takes time to propagate changes
3. **Clear cache thoroughly** - Old tokens can cause issues
4. **Check user email** - Make sure the Azure user account has an email set
5. **Use incognito mode** - Helps avoid cache issues during testing

---

## ⏱️ Timeline

- Azure Portal changes: **5 minutes**
- Supabase verification: **2 minutes**
- Cache clearing: **2 minutes**
- Testing: **2 minutes**
- **Total: ~10 minutes**

---

## 🎉 You're Done!

Once you see the success output in the console and get redirected to the dashboard, the Azure login is working correctly!

The email claim is now being sent from Azure to Supabase, and users can log in successfully with their Office 365 accounts.

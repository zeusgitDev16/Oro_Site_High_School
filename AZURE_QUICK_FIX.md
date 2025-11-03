# 🚀 Azure Login Quick Fix

## Error: "Error getting user email from external provider"

### ⚡ Quick Fix (Most Common Solution)

#### 1. Grant Admin Consent in Azure Portal

```
1. Go to: https://portal.azure.com
2. Navigate: Azure Active Directory → App registrations → Oro Site High School ELMS
3. Click: API permissions
4. Click: "Grant admin consent for [Your Organization]"
5. Click: Yes
6. Verify: All permissions show green checkmarks ✅
```

#### 2. Add Email Optional Claim

```
1. Still in Azure Portal
2. Click: Token configuration (left menu)
3. Click: Add optional claim
4. Token type: ID
5. Select: email (check the box)
6. Check: "Turn on the Microsoft Graph email permission"
7. Click: Add
```

#### 3. Enable ID Tokens

```
1. Click: Authentication (left menu)
2. Under "Implicit grant and hybrid flows"
3. Check: ✅ ID tokens
4. Click: Save
```

#### 4. Clear Cache and Test

```bash
# Clear browser
Ctrl + Shift + Delete → All time → Cookies + Cache

# Sign out of Microsoft
https://login.microsoftonline.com → Sign out

# Run app
flutter clean
flutter pub get
flutter run -d chrome --web-port=52659
```

---

## 🔍 How to Debug

### Run with Console Open

```bash
# 1. Run app
flutter run -d chrome --web-port=52659

# 2. Press F12 in browser
# 3. Go to Console tab
# 4. Attempt login
# 5. Watch for these messages:
```

### ✅ Success Output
```
📧 User Email: admin@aezycreativegmail.onmicrosoft.com
✅ Using email: admin@aezycreativegmail.onmicrosoft.com
✅ AuthGate: User signed in via OAuth
```

### ❌ Failure Output
```
📧 User Email: NO EMAIL
❌ ERROR: Could not extract email from any source
```

---

## 📋 Azure Permissions Checklist

Required permissions (all Delegated):
- [ ] User.Read
- [ ] email
- [ ] openid
- [ ] profile
- [ ] offline_access
- [ ] **Admin consent granted** (green checkmarks)

---

## 🔗 Quick Links

- **Azure Portal:** https://portal.azure.com
- **Supabase Dashboard:** https://app.supabase.com
- **Full Debug Guide:** See `AZURE_LOGIN_DEBUG_GUIDE.md`

---

## 💡 Why This Happens

Azure AD doesn't send the email claim by default. You must:
1. Request the `email` permission
2. Grant admin consent
3. Add email as an optional claim in the token

Without these, Supabase receives a token without the email field and cannot create the user profile.

---

## ⏱️ Expected Time

- Azure Portal changes: 2-3 minutes
- Cache clearing: 1 minute
- Testing: 1 minute
- **Total: ~5 minutes**

---

## ✨ After Fix

You should see:
```
🔐 Starting Azure AD authentication...
🔐 OAuth initiated: true

[After login]

📧 User Email: admin@aezycreativegmail.onmicrosoft.com
✅ Using email: admin@aezycreativegmail.onmicrosoft.com
✅ AuthGate: User signed in via OAuth
🎭 AuthGate: User role: admin

[Redirects to Admin Dashboard]
```

---

## 🆘 Still Not Working?

1. Check console output for detailed error
2. Verify all Azure permissions have green checkmarks
3. Ensure Supabase Tenant URL doesn't have `/v2.0` at end
4. Check Supabase logs: Dashboard → Authentication → Logs
5. See full guide: `AZURE_LOGIN_DEBUG_GUIDE.md`

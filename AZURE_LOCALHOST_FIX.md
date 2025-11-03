# 🔧 **Fix: Localhost Connection Refused After Azure Login**

## **Understanding the OAuth Flow**

The correct flow should be:
```
Your App (localhost) → Microsoft Login → Supabase Callback → Your App (localhost)
```

But you're getting:
```
Your App → Microsoft Login → ❌ Localhost (connection refused)
```

---

## **The Problem**

Azure AD is trying to redirect directly to your localhost instead of going through Supabase first. This happens when the Azure AD app registration has localhost in its redirect URIs.

---

## **Solution: Fix Azure AD Redirect URIs**

### **Step 1: Remove Localhost from Azure AD**

1. **Go to [Azure Portal](https://portal.azure.com)**
2. **Sign in with:** `aezycreative@gmail.com`
3. **Navigate to:** Azure Active Directory → App registrations → Your App
4. **Go to:** Authentication
5. **Under Redirect URIs, REMOVE all localhost entries:**
   - ❌ Remove: `http://localhost:49719/`
   - ❌ Remove: `http://localhost:49719/#/`
   - ❌ Remove: Any other localhost URLs

6. **KEEP ONLY the Supabase callback URL:**
   ```
   ✅ https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback
   ```

7. **Click Save**

### **Step 2: Verify Supabase Configuration**

1. **Go to [Supabase Dashboard](https://app.supabase.com)**
2. **Navigate to:** Authentication → Providers → Azure
3. **Verify these settings:**

```yaml
Enable Sign in with Azure: ON

Azure (AD) OAuth Client ID:
5ef49f61-b51d-4484-85e6-24c127d331ed

Azure (AD) OAuth Client Secret:
[Your client secret]

Azure (AD) Tenant URL:
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

4. **Check the Site URL setting:**
   - Go to: Authentication → URL Configuration
   - **Site URL** should be your app URL:
     - For local dev: `http://localhost:49719` (or your port)
     - For production: Your production URL

5. **Add Redirect URLs:**
   - Still in URL Configuration
   - **Redirect URLs** - Add:
     ```
     http://localhost:49719/**
     http://localhost:*/**
     ```

---

## **Step 3: Clear Browser Cache**

This is IMPORTANT because browsers cache OAuth redirects:

1. **Open Chrome DevTools** (F12)
2. **Right-click the Refresh button**
3. **Select "Empty Cache and Hard Reload"**
4. **Or use:** Ctrl + Shift + Delete → Clear browsing data

---

## **Step 4: Test Again**

1. **Run your app:**
   ```bash
   flutter run -d chrome --web-port=49719
   ```
   (Use a specific port so it's consistent)

2. **Open browser console** (F12) to see debug output

3. **Click "Log in with Office 365"**

4. **Check console for:**
   ```
   🔐 Starting Azure AD authentication...
   🔐 Local redirect URL: http://localhost:49719/
   🔐 OAuth initiated: true
   🔐 Supabase will redirect back to: http://localhost:49719/
   ```

5. **Expected flow:**
   - Microsoft login opens
   - You enter credentials
   - Microsoft redirects to: `https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback`
   - Supabase processes and redirects to: `http://localhost:49719/`
   - App detects session and logs you in

---

## **Alternative Solution: Use Supabase CLI (If Above Doesn't Work)**

If you still have issues, you can use Supabase CLI for local development:

1. **Install Supabase CLI:**
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase:**
   ```bash
   supabase login
   ```

3. **Link your project:**
   ```bash
   supabase link --project-ref fhqzohvtioosycaafnij
   ```

4. **Start local Supabase:**
   ```bash
   supabase start
   ```

5. **Update your app to use local Supabase:**
   ```dart
   // For local development
   SUPABASE_URL=http://localhost:54321
   ```

---

## **Quick Fix: Use Email/Password Instead**

While troubleshooting Azure, you can use email/password login:

1. **Create a test user in Supabase:**
   - Go to Authentication → Users → Add user
   - Email: `admin@orosite.edu.ph`
   - Password: `Admin123!`

2. **Use "Log in with Email"** button instead

---

## **Debugging Checklist**

### **In Azure Portal:**
- [ ] Only Supabase callback URL in redirect URIs (no localhost)
- [ ] ID tokens enabled
- [ ] Permissions granted (User.Read, email, openid, profile)

### **In Supabase:**
- [ ] Azure provider enabled
- [ ] Client ID and Secret correct
- [ ] Tenant URL ends with `/v2.0`
- [ ] Site URL set to your localhost
- [ ] Redirect URLs include localhost pattern

### **In Browser:**
- [ ] Cache cleared
- [ ] Popups allowed
- [ ] Console open to see errors

### **In Code:**
- [ ] Using specific port: `flutter run -d chrome --web-port=49719`
- [ ] Environment has `ENABLE_AZURE_AUTH=true`

---

## **Common Errors and Solutions**

### **Error: "AADSTS50011: Reply URL mismatch"**
**Solution:** Azure redirect URI must be exactly: `https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback`

### **Error: "This site can't be reached - localhost refused to connect"**
**Solution:** Remove localhost from Azure redirect URIs, keep only Supabase callback

### **Error: "Invalid request, some parameters are missing"**
**Solution:** Clear browser cache and cookies

### **Error: "User does not have an existing session"**
**Solution:** Check Supabase Site URL configuration

---

## **Still Not Working?**

If you're still having issues:

1. **Share the exact error** you see in browser console
2. **Check Network tab** in DevTools for the redirect chain
3. **Verify Supabase logs** for any OAuth errors
4. **Try incognito mode** to rule out cache issues

The key is that Azure should NEVER redirect directly to localhost. It should always go through Supabase first.

---

**Remember:** The flow must be:
```
Localhost → Microsoft → Supabase → Localhost
```

NOT:
```
Localhost → Microsoft → ❌ Localhost (direct)
```
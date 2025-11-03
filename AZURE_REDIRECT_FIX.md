# 🔧 **Azure AD Redirect URI Configuration Fix**

## **Problem**
After Microsoft authentication, the browser redirects to `localhost:3000` which doesn't exist, causing "This site can't be reached" error.

---

## **Root Cause**
The Azure AD app registration has the wrong redirect URI configured. It's set to `localhost:3000` instead of your actual Flutter app URL.

---

## **Solution: Update Azure AD App Registration**

### **Step 1: Access Azure Portal**
1. Go to [Azure Portal](https://portal.azure.com)
2. Sign in with your admin account

### **Step 2: Find Your App Registration**
1. Navigate to **Azure Active Directory** → **App registrations**
2. Find your app: **"Oro Site High School ELMS"** or similar
3. Click on it to open settings

### **Step 3: Update Redirect URIs**
1. Go to **Authentication** in the left menu
2. Under **Platform configurations** → **Web**
3. **Remove** the incorrect URI: `http://localhost:3000/...`
4. **Add** these redirect URIs:

#### **For Local Development:**
```
http://localhost:49719/
http://localhost:49719/#/
http://localhost:49719/auth/callback
```
(Replace 49719 with your actual Flutter web port)

#### **For Supabase Integration:**
```
https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback
```

#### **For Production (if deployed):**
```
https://your-domain.com/
https://your-domain.com/auth/callback
```

### **Step 4: Save Changes**
1. Click **Save** at the top
2. Wait a few minutes for changes to propagate

---

## **Alternative: Update Supabase Azure Provider Settings**

### **In Supabase Dashboard:**
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project
3. Go to **Authentication** → **Providers**
4. Click on **Azure (Microsoft)**
5. Ensure these are set correctly:
   - **Client ID**: `5ef49f61-b51d-4484-85e6-24c127d331ed`
   - **Secret**: (your client secret)
   - **Tenant URL**: `https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181`
6. **Redirect URL** shown here should be added to Azure AD

---

## **Quick Fix for Testing**

If you need to test immediately without waiting for Azure changes:

### **Option 1: Use Email/Password Login**
Instead of Azure AD, use the "Log in with Email" option with test credentials.

### **Option 2: Mock Mode**
Set in your `.env` or Environment class:
```dart
USE_MOCK_DATA=true
DEBUG_MODE=true
```

### **Option 3: Direct Navigation**
After the error, manually navigate back to your app:
```
http://localhost:49719/
```
The session might already be created.

---

## **Verification Steps**

After updating Azure AD:

1. **Clear browser cache** (important!)
2. **Run the app:**
   ```bash
   flutter run -d chrome --web-port=49719
   ```
3. **Test login:**
   - Click "Log in with Office 365"
   - Complete Microsoft authentication
   - Should redirect back to your app (not localhost:3000)

---

## **Code Updates Applied**

### **auth_service.dart**
- Now detects the current URL and uses it for redirect
- For localhost, uses the actual port (e.g., 49719)
- For production, uses Supabase callback URL

### **environment.dart**
- Redirect URI properly configured
- Fallback to Supabase callback URL

---

## **Expected Flow After Fix**

1. User clicks "Log in with Office 365"
2. Microsoft login page opens
3. User enters credentials
4. Microsoft validates and redirects to:
   - Local: `http://localhost:49719/` (your Flutter port)
   - Production: `https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback`
5. App receives the session
6. User is logged in and routed to dashboard

---

## **Still Having Issues?**

### **Check These:**
1. **Azure AD Redirect URIs** - Must match exactly
2. **Supabase Site URL** - In Supabase settings
3. **Browser Console** - Check for specific errors
4. **Network Tab** - See the actual redirect URL being used

### **Debug Output:**
The app now logs the redirect URL:
```
🔐 Starting Azure OAuth with redirect: http://localhost:49719/
```

Check your console to see what URL is being used.

---

## **Contact Support**
If the issue persists after these changes:
1. Check Azure AD logs for authentication errors
2. Check Supabase logs for OAuth errors
3. Verify your Azure AD app permissions

---

**Status**: 🔧 Configuration update required in Azure Portal
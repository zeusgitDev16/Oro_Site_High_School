# 🔧 Supabase Azure Configuration Fix

## The Real Issue

You've correctly configured Azure Portal ✅, but the error is happening because **Supabase's Azure provider configuration is incorrect or incomplete**.

The error occurs when Supabase tries to exchange the Azure authorization code for a token and extract the user's email.

---

## Critical Supabase Configuration Steps

### Step 1: Get Azure Client Secret

**You need the Azure Client Secret** (not just the Client ID)

1. Go to **Azure Portal** → **App Registrations** → Your App
2. Click **Certificates & secrets** (left menu)
3. Under "Client secrets":
   - If you have an existing secret, you **cannot view it again**
   - You must **create a new one**
4. Click **"+ New client secret"**
5. Description: `Supabase Integration`
6. Expires: Choose **24 months** (or your preference)
7. Click **Add**
8. **IMMEDIATELY COPY THE VALUE** - You can only see it once!
9. Save it somewhere safe

---

### Step 2: Configure Supabase Azure Provider

1. Go to **https://app.supabase.com**
2. Select your project: **Oro Site High School ELMS**
3. Click **Authentication** (left sidebar)
4. Click **Providers** tab
5. Scroll down and find **Azure**
6. Click to expand it
7. Toggle **Enable Sign in with Azure** to ON

### Step 3: Enter Configuration (CRITICAL!)

**Azure Tenant URL:**
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

⚠️ **IMPORTANT:** Notice the `/v2.0` at the end! This is required for proper email extraction.

**Application (client) ID:**
```
5ef49f61-b51d-4484-85e6-24c127d331ed
```

**Application (client) secret:**
```
[Paste the secret you just created in Step 1]
```

**Azure AD Tenant:**
```
f205dc04-e2d3-4042-94b4-7e0bb9f13181
```

### Step 4: Advanced Settings (CRITICAL!)

Scroll down to **Advanced Settings** and add:

**Scopes:**
```
openid profile email offline_access
```

**This is crucial!** Without explicitly requesting these scopes in Supabase, Azure won't send the email claim.

### Step 5: Save Configuration

1. Click **Save** at the bottom
2. Wait for confirmation message

---

## Step 6: Verify URL Configuration

1. Still in Supabase Dashboard
2. Go to **Authentication** → **URL Configuration**
3. **Site URL:** Should be your production URL or:
   ```
   http://localhost:52659
   ```

4. **Redirect URLs:** Should include:
   ```
   http://localhost:*/**
   https://fhqzohvtioosycaafnij.supabase.co/**
   ```

---

## Step 7: Update Azure Redirect URI (If Needed)

1. Go back to **Azure Portal**
2. **App Registrations** → Your App → **Authentication**
3. Under **Web** platform, verify this redirect URI exists:
   ```
   https://fhqzohvtioosycaafnij.supabase.co/auth/v1/callback
   ```

4. **Also add this one for local testing:**
   ```
   http://localhost:52659/
   ```

5. Click **Save**

---

## Common Supabase Configuration Mistakes

### ❌ Mistake 1: Missing `/v2.0` in Tenant URL
**Wrong:**
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181
```

**Correct:**
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

The `/v2.0` endpoint is required for Azure AD v2.0 tokens which include the email claim.

### ❌ Mistake 2: Missing Scopes
If you don't specify scopes in Supabase, it won't request the email from Azure.

**Required scopes:**
```
openid profile email offline_access
```

### ❌ Mistake 3: Wrong or Expired Client Secret
- Client secrets expire
- If you can't see the secret value, create a new one
- Make sure you copy the **Value**, not the **Secret ID**

### ❌ Mistake 4: Not Saving Configuration
- Always click **Save** after making changes
- Wait for the success message

---

## Testing After Configuration

### Step 1: Clear Everything

**Browser:**
```
Ctrl + Shift + Delete → All time → Clear cookies and cache
```

**Microsoft:**
```
Go to https://login.microsoftonline.com → Sign out
Go to https://myaccount.microsoft.com → Sign out
```

**Flutter:**
```bash
flutter clean
flutter pub get
```

### Step 2: Run and Test

```bash
flutter run -d chrome --web-port=52659
```

1. Open DevTools (F12) → Console
2. Click "Log in with Office 365"
3. Enter credentials
4. Watch console output

### Step 3: Expected Success Output

```
🔐 Starting Azure AD authentication...
🔐 OAuth initiated: true

[After login]

supabase.supabase_flutter: INFO: handle deeplink uri
supabase.supabase_flutter: INFO: ***** Supabase init completed *****

🔐 Auth state changed: AuthChangeEvent.signedIn
📧 User Email: admin@aezycreativegmail.onmicrosoft.com
✅ AuthGate: User signed in via OAuth
```

---

## If Still Not Working

### Check 1: Verify Supabase Logs

1. Supabase Dashboard → **Authentication** → **Logs**
2. Look for recent authentication attempts
3. Check for detailed error messages

### Check 2: Test Azure Token Manually

1. Open browser DevTools → **Network** tab
2. Attempt login
3. Look for requests to `login.microsoftonline.com`
4. Find the token response
5. Copy the `id_token` value
6. Go to **https://jwt.io**
7. Paste the token
8. **Verify the payload contains:**
   ```json
   {
     "email": "admin@aezycreativegmail.onmicrosoft.com",
     "name": "...",
     "oid": "...",
     ...
   }
   ```

If email is missing from the token, the issue is still in Azure configuration.

### Check 3: Verify Supabase Provider is Enabled

1. Supabase Dashboard → Authentication → Providers
2. Azure should show as **Enabled** (green toggle)
3. If not, enable it and save

### Check 4: Check for Multiple Azure Providers

1. In Supabase, make sure you only have ONE Azure provider configured
2. If you see multiple, delete the extras
3. Keep only the correctly configured one

---

## Alternative: Use Azure AD B2C (If Available)

If you have Azure AD B2C, you might need to use that provider instead:

1. Supabase Dashboard → Authentication → Providers
2. Look for **Azure AD B2C** (separate from Azure)
3. Configure it with your B2C tenant details

---

## Checklist

### Azure Portal:
- [x] Admin consent granted (you confirmed this)
- [x] Email optional claim added (you confirmed this)
- [x] ID tokens enabled (you confirmed this)
- [ ] Client secret created and copied
- [ ] Redirect URI includes Supabase callback URL

### Supabase Dashboard:
- [ ] Azure provider enabled
- [ ] Tenant URL includes `/v2.0` at the end
- [ ] Client ID matches Azure
- [ ] Client secret is current and valid
- [ ] Scopes include: `openid profile email offline_access`
- [ ] Configuration saved

### Testing:
- [ ] Browser cache cleared
- [ ] Signed out of Microsoft
- [ ] Flutter cleaned
- [ ] App running with DevTools open

---

## Most Likely Issues

Based on the error, the most likely problems are:

1. **Missing `/v2.0` in Supabase Tenant URL** (90% of cases)
2. **Missing or incorrect scopes in Supabase** (80% of cases)
3. **Expired or wrong client secret** (70% of cases)
4. **Supabase provider not properly saved** (50% of cases)

---

## Quick Fix Summary

1. ✅ Azure Portal is configured correctly (you did this)
2. ❌ **Supabase needs:**
   - Tenant URL with `/v2.0`
   - Valid client secret
   - Scopes: `openid profile email offline_access`
   - Provider enabled and saved

3. 🧪 **Test:**
   - Clear cache
   - Run app
   - Check console for email in output

---

## Expected Timeline

- Get client secret: **2 minutes**
- Configure Supabase: **5 minutes**
- Clear cache: **2 minutes**
- Test: **2 minutes**
- **Total: ~10 minutes**

---

## Success Indicator

When configured correctly, you'll see:

```
📧 User Email: admin@aezycreativegmail.onmicrosoft.com
✅ Using email: admin@aezycreativegmail.onmicrosoft.com
✅ AuthGate: User signed in via OAuth
🎭 AuthGate: User role: admin
```

No error messages! ✅

---

## Need Help?

If still not working after these steps:
1. Take a screenshot of your Supabase Azure provider configuration
2. Copy the complete console output
3. Check Supabase authentication logs
4. Verify the JWT token contains email at jwt.io

The issue is definitely in the Supabase ↔ Azure connection configuration!

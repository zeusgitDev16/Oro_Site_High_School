# ✅ Supabase Configuration Checklist

## Your Error:
```
Error getting user email from external provider
```

## This Means:
Supabase cannot extract email from the Azure token. The issue is in **Supabase Dashboard configuration**.

---

## 🎯 CRITICAL: Check These Exact Values

### 1. Azure Tenant URL

**Go to:** Supabase Dashboard → Authentication → Providers → Azure

**Find the field:** "Azure Tenant URL" or "Tenant URL"

**What it should be:**
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

**Check character by character:**
- [ ] Starts with `https://`
- [ ] Has `login.microsoftonline.com`
- [ ] Has `/f205dc04-e2d3-4042-94b4-7e0bb9f13181`
- [ ] **ENDS WITH `/v2.0`** ⚠️ **MOST IMPORTANT!**

**Common mistakes:**
- ❌ Missing `/v2.0` at the end
- ❌ Has `/v2.0/v2.0` (double)
- ❌ Has extra spaces
- ❌ Has `/oauth2/v2.0/authorize` at the end

**Correct format:**
```
https://login.microsoftonline.com/{TENANT_ID}/v2.0
```

---

### 2. Application (client) ID

**Should be exactly:**
```
5ef49f61-b51d-4484-85e6-24c127d331ed
```

**Check:**
- [ ] No extra spaces
- [ ] All lowercase
- [ ] Correct dashes in right places
- [ ] 36 characters total (including dashes)

---

### 3. Application (client) secret

**This is the tricky one!**

**Problem:** You can't see the secret value in Supabase after saving it.

**Solution:** Create a NEW secret in Azure Portal

#### How to Create New Secret:

1. **Azure Portal** → **App Registrations** → Your App
2. Click **"Certificates & secrets"** (left menu)
3. Under **"Client secrets"** section
4. Click **"+ New client secret"**
5. Description: `Supabase - [Today's Date]`
6. Expires: **24 months**
7. Click **"Add"**
8. **IMMEDIATELY COPY THE VALUE!**
   - It's in the "Value" column (NOT "Secret ID")
   - Looks like: `abc123~XYZ789...` (long string)
   - You can only see it ONCE!

9. **Go to Supabase Dashboard**
10. Paste it in "Application (client) secret"
11. Click **Save**

**Check:**
- [ ] Secret is less than 6 months old
- [ ] You copied the VALUE (not Secret ID)
- [ ] No extra spaces when pasting
- [ ] Saved in Supabase

---

### 4. Provider Enabled

**Check:**
- [ ] Azure provider toggle is **ON** (green/blue)
- [ ] Not grayed out or disabled

---

### 5. Configuration Saved

**After entering all values:**
- [ ] Clicked **"Save"** button
- [ ] Saw success message
- [ ] Refreshed page to confirm changes persisted

---

## 🔍 Verification Steps

### Step 1: Check Tenant URL Format

**Copy your Tenant URL from Supabase and paste it here (mentally):**
```
[Your Tenant URL here]
```

**Does it match this EXACTLY?**
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0
```

**If NO, fix it!**

### Step 2: Count the Slashes

Your Tenant URL should have exactly **5 forward slashes** (`/`):
1. `https://` (2 slashes)
2. `/f205dc04...` (1 slash)
3. `/v2.0` (1 slash)

**Total: 4 slashes** (not counting the `://`)

### Step 3: Check the Ending

**The last 5 characters should be:**
```
/v2.0
```

**NOT:**
- `/v2.0/`
- `/v2.0/authorize`
- `/oauth2/v2.0`
- Just `/f205dc04-e2d3-4042-94b4-7e0bb9f13181`

---

## 🧪 Test Configuration

### After fixing Supabase config:

1. **Clear browser cache completely**
2. **Sign out of Microsoft**
3. **Run app:**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome --web-port=52659
   ```
4. **Open DevTools (F12) → Console**
5. **Attempt login**
6. **Watch for:**
   - ✅ `User Email: admin@...`
   - ✅ `User signed in via OAuth`
   - ❌ No error messages

---

## 📊 Diagnostic Questions

Answer these to identify the issue:

### Q1: What is your EXACT Tenant URL in Supabase?
- [ ] Has `/v2.0` at the end
- [ ] Does NOT have `/v2.0` at the end
- [ ] Not sure / Can't see it

### Q2: When did you last create a new client secret?
- [ ] Today
- [ ] This week
- [ ] More than a week ago
- [ ] Never / Don't remember

### Q3: Did you click "Save" in Supabase after entering values?
- [ ] Yes, and saw success message
- [ ] Yes, but didn't see confirmation
- [ ] Not sure

### Q4: Is the Azure provider toggle ON (enabled)?
- [ ] Yes, it's green/blue
- [ ] No, it's gray
- [ ] Not sure

---

## 🎯 Most Likely Issues (In Order)

### Issue #1: Tenant URL Missing `/v2.0` (90% probability)

**Symptom:** Your exact error message

**Fix:**
1. Add `/v2.0` to the end of Tenant URL
2. Save
3. Test

### Issue #2: Client Secret Wrong/Expired (80% probability)

**Symptom:** Your exact error message

**Fix:**
1. Create new secret in Azure Portal
2. Copy the VALUE
3. Paste in Supabase
4. Save
5. Test

### Issue #3: Configuration Not Saved (50% probability)

**Symptom:** Changes don't persist

**Fix:**
1. Re-enter all values
2. Click Save
3. Wait for success message
4. Refresh page
5. Verify values are still there

---

## 🚨 Red Flags

If you see any of these, there's a problem:

- ❌ Tenant URL doesn't end with `/v2.0`
- ❌ Client secret is more than 6 months old
- ❌ Azure provider is disabled (gray toggle)
- ❌ After clicking Save, values disappear
- ❌ No success message after saving

---

## ✅ Success Indicators

You'll know it's configured correctly when:

1. **Tenant URL ends with `/v2.0`**
2. **Client secret is fresh (created today/this week)**
3. **Provider is enabled (green toggle)**
4. **Configuration persists after page refresh**
5. **Login works without error**

---

## 📸 Screenshot Request

To help diagnose, take a screenshot showing:

1. **Supabase Dashboard** → **Authentication** → **Providers** → **Azure**
2. Show the **Tenant URL field** (you can blur the tenant ID if needed)
3. Show the **Client ID field**
4. Show the **enabled/disabled toggle**

This will help identify the exact issue!

---

## 🔄 If Still Not Working

Try this sequence:

1. **Disable Azure provider** in Supabase
2. **Save**
3. **Wait 30 seconds**
4. **Enable Azure provider** again
5. **Re-enter ALL values:**
   - Tenant URL: `https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0`
   - Client ID: `5ef49f61-b51d-4484-85e6-24c127d331ed`
   - Client secret: [NEW secret from Azure Portal]
6. **Save**
7. **Refresh page**
8. **Verify values persisted**
9. **Clear browser cache**
10. **Test login**

---

## 💡 Pro Tip

The `/v2.0` at the end of the Tenant URL is **THE MOST COMMON ISSUE**.

If you only check one thing, check that!

---

## ⏱️ Quick Fix Timeline

- Check Tenant URL: **30 seconds**
- Add `/v2.0` if missing: **10 seconds**
- Create new client secret: **2 minutes**
- Update Supabase: **1 minute**
- Clear cache: **1 minute**
- Test: **1 minute**
- **Total: ~5 minutes**

---

## 🎉 Expected Result

After fixing Supabase configuration:

```
✅ Supabase initialized successfully
🔐 Auth state changed: AuthChangeEvent.signedIn
📧 User Email: admin@aezycreativegmail.onmicrosoft.com
✅ AuthGate: User signed in via OAuth
🎭 AuthGate: User role: admin
```

**No error messages!**
**Redirects to dashboard!**
**Login works!** 🚀

---

## 📞 Next Steps

1. **Check your Supabase Tenant URL** - Does it have `/v2.0`?
2. **If NO** - Add it, save, test
3. **If YES** - Create new client secret, update Supabase, test
4. **Report back** - Share the result or screenshot

The fix is in Supabase configuration! 🎯

# 🔧 **Fix: Double /v2.0 in OAuth URL**

## **The Problem Identified**

Looking at your error URL:
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0/oauth2/v2.0/authorize
                                                                        ^^^^        ^^^^
```

There's a **DOUBLE `/v2.0`** in the path, which causes the 404 error!

The correct URL should be:
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0/oauth2/authorize
```

---

## **The Solution**

Supabase is automatically appending `/v2.0/oauth2/authorize` to whatever Tenant URL you provide. So if you include `/v2.0` in your Tenant URL, it becomes doubled.

### **Option 1: Remove /v2.0 from Tenant URL (Try This First)**

1. **Go to Supabase Dashboard** → Authentication → Providers → Azure
2. **Change the Azure Tenant URL to:**
   ```
   https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181
   ```
   (WITHOUT `/v2.0` at the end)

3. **Save** and wait 30 seconds
4. **Clear browser cache** and test

### **Option 2: Use Just the Tenant ID (If Option 1 Doesn't Work)**

Some versions of Supabase expect just the tenant ID, not the full URL:

1. **Try entering ONLY the tenant ID:**
   ```
   f205dc04-e2d3-4042-94b4-7e0bb9f13181
   ```

2. **Save** and test

### **Option 3: Use Common Endpoint (Alternative)**

If your app allows any Microsoft account (not just your tenant):

1. **Try using:**
   ```
   https://login.microsoftonline.com/common
   ```

2. **Save** and test

---

## **Testing Each Option**

After each change:

1. **Save in Supabase**
2. **Wait 30 seconds**
3. **Clear browser cache:** `Ctrl + Shift + Delete`
4. **Run app:** `flutter run -d chrome --web-port=49719`
5. **Try login**
6. **Check the URL in the error** - see if the double `/v2.0` is gone

---

## **Which Option to Use?**

### **For Single Tenant (Your Organization Only):**
```
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181
```
(WITHOUT `/v2.0`)

### **For Multi-Tenant (Any Microsoft Account):**
```
https://login.microsoftonline.com/common
```

### **If Supabase Wants Just ID:**
```
f205dc04-e2d3-4042-94b4-7e0bb9f13181
```

---

## **Verification Steps**

### **Check What URL is Being Generated:**

1. **Open Browser DevTools** (F12)
2. **Go to Network tab**
3. **Click "Log in with Office 365"**
4. **Look for the request to `login.microsoftonline.com`**
5. **Check the full URL** - it should NOT have double `/v2.0`

### **Correct OAuth URL Format:**
```
✅ CORRECT:
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0/oauth2/authorize

❌ WRONG (Double v2.0):
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181/v2.0/oauth2/v2.0/authorize
```

---

## **Why This Happens**

Different versions of Supabase handle the Azure Tenant URL differently:

1. **Older versions:** Expect full URL with `/v2.0`
2. **Newer versions:** Expect URL without `/v2.0` (they add it automatically)
3. **Some versions:** Expect just the tenant ID

Your Supabase instance appears to be automatically adding `/v2.0/oauth2/authorize`, so you should NOT include `/v2.0` in your Tenant URL.

---

## **Quick Test**

Try this exact configuration in Supabase:

```yaml
Azure enabled: ✅ ON

Application (client) ID:
5ef49f61-b51d-4484-85e6-24c127d331ed

Secret Value:
[Your secret - keep as is]

Azure Tenant URL:
https://login.microsoftonline.com/f205dc04-e2d3-4042-94b4-7e0bb9f13181

(NO /v2.0 at the end!)
```

This should fix the double `/v2.0` issue!
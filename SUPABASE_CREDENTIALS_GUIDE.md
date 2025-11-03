# 🔐 SUPABASE CREDENTIALS SETUP GUIDE
## How to Get Your Supabase Credentials

This guide will walk you through getting the required credentials to connect your app to Supabase.

---

## 📋 STEP-BY-STEP INSTRUCTIONS

### **STEP 1: Get Your Supabase Project URL and Anon Key**

1. **Go to Supabase Dashboard**
   - Open your browser and go to: https://supabase.com/dashboard
   - Sign in with your account

2. **Select Your Project**
   - Click on your project: **"Oro Site High School ELMS"** (or whatever you named it)

3. **Navigate to Project Settings**
   - On the left sidebar, click the **⚙️ Settings** icon (gear icon at the bottom)
   - Click on **"API"** in the settings menu

4. **Copy Your Credentials**
   
   You'll see a section called **"Project API keys"**. You need TWO values:

   **A. Project URL:**
   ```
   Look for: "Project URL"
   Example: https://abcdefghijklmnop.supabase.co
   ```
   
   **B. Anon/Public Key:**
   ```
   Look for: "anon" or "public" key
   Example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYxNjE2MTYxNiwiZXhwIjoxOTMxNzM3NjE2fQ.abcdefghijklmnopqrstuvwxyz123456789
   ```
   
   ⚠️ **IMPORTANT:** 
   - Copy the **ENTIRE** anon key (it's very long, usually 200+ characters)
   - Do NOT copy the "service_role" key - that's for server-side only!

5. **Update Your `.env` File**
   
   Open the `.env` file in your project root and replace:
   ```env
   SUPABASE_URL=YOUR_SUPABASE_PROJECT_URL_HERE
   SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY_HERE
   ```
   
   With your actual values:
   ```env
   SUPABASE_URL=https://abcdefghijklmnop.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYxNjE2MTYxNiwiZXhwIjoxOTMxNzM3NjE2fQ.abcdefghijklmnopqrstuvwxyz123456789
   ```

---

### **STEP 2: Get Your Azure AD Client ID**

1. **Go to Azure Portal**
   - Open: https://portal.azure.com
   - Sign in with your Azure account

2. **Navigate to App Registrations**
   - In the search bar at the top, type: **"App registrations"**
   - Click on **"App registrations"** in the results

3. **Find Your App**
   - Look for: **"Oro Site High School ELMS"**
   - Click on it

4. **Copy the Application (client) ID**
   - On the Overview page, you'll see:
     ```
     Application (client) ID: 12345678-1234-1234-1234-123456789abc
     ```
   - Copy this entire ID (it's a UUID format)

5. **Update Your `.env` File**
   
   Replace:
   ```env
   AZURE_CLIENT_ID=YOUR_AZURE_CLIENT_ID_HERE
   ```
   
   With your actual value:
   ```env
   AZURE_CLIENT_ID=12345678-1234-1234-1234-123456789abc
   ```

---

### **STEP 3: Configure Azure AD in Supabase**

You need to link Azure AD with Supabase for authentication to work.

1. **Go to Supabase Dashboard**
   - Navigate to your project
   - Click **"Authentication"** in the left sidebar
   - Click **"Providers"**

2. **Enable Azure Provider**
   - Scroll down to find **"Azure"**
   - Toggle it **ON**

3. **Configure Azure Settings**
   
   You'll need to enter:
   
   **A. Azure Tenant ID:**
   ```
   aezycreativegmail.onmicrosoft.com
   ```
   
   **B. Azure Client ID:**
   ```
   (The same Client ID you copied in Step 2)
   ```
   
   **C. Azure Client Secret:**
   - Go back to Azure Portal > Your App Registration
   - Click **"Certificates & secrets"** in the left menu
   - Click **"+ New client secret"**
   - Add a description: "Supabase Integration"
   - Choose expiration: "24 months" (or your preference)
   - Click **"Add"**
   - **IMMEDIATELY COPY THE VALUE** (you can only see it once!)
   - Paste this value in Supabase Azure settings

4. **Set Redirect URL in Azure**
   
   - In Azure Portal, go to your App Registration
   - Click **"Authentication"** in the left menu
   - Under **"Platform configurations"**, click **"+ Add a platform"**
   - Choose **"Web"**
   - Add this Redirect URI:
     ```
     https://YOUR_SUPABASE_PROJECT_REF.supabase.co/auth/v1/callback
     ```
     (Replace YOUR_SUPABASE_PROJECT_REF with your actual project reference from the Supabase URL)
   
   - Click **"Configure"**

5. **Save Everything**
   - Click **"Save"** in Supabase
   - Click **"Save"** in Azure Portal

---

## ✅ VERIFICATION CHECKLIST

After completing all steps, your `.env` file should look like this:

```env
# ============================================
# SUPABASE CONFIGURATION
# ============================================
SUPABASE_URL=https://abcdefghijklmnop.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9....(very long key)

# ============================================
# AZURE AD CONFIGURATION
# ============================================
AZURE_TENANT_ID=aezycreativegmail.onmicrosoft.com
AZURE_CLIENT_ID=12345678-1234-1234-1234-123456789abc
AZURE_REDIRECT_URI=io.supabase.orosite://login-callback/

# ============================================
# FEATURE FLAGS
# ============================================
USE_MOCK_DATA=false  # ← Change to 'false' to use real backend
ENABLE_OFFLINE=true
ENABLE_REALTIME=true
ENABLE_AZURE_AUTH=true

# ... rest of the configuration
```

**Checklist:**
- [ ] SUPABASE_URL is filled with your actual Supabase project URL
- [ ] SUPABASE_ANON_KEY is filled with your actual anon key (200+ characters)
- [ ] AZURE_CLIENT_ID is filled with your Azure App Registration Client ID
- [ ] Azure provider is enabled in Supabase dashboard
- [ ] Azure Client Secret is configured in Supabase
- [ ] Redirect URL is added in Azure Portal
- [ ] USE_MOCK_DATA is set to `false` (to use real backend)

---

## 🧪 TESTING YOUR CONNECTION

After setting up your credentials:

1. **Test the Connection**
   ```bash
   flutter run
   ```

2. **Check the Console Output**
   
   You should see:
   ```
   🚀 Initializing Supabase...
   ═══════════════════════════════════════════════════════
              ORO SITE HIGH SCHOOL ELMS
              Environment Configuration
   ═══════════════════════════════════════════════════════
   Environment Type: PRODUCTION
   ───��───────────────────────────────────────────────────
   Supabase:
     ✓ URL: https://abcdefghijklmnop...
     ✓ Key: Configured
   ───────────────────────────────────────────────────────
   ✅ Database connection successful
   ✅ Supabase initialized successfully
   ```

3. **If You See Errors:**
   
   **Error: "SUPABASE_URL not found in .env file"**
   - Make sure the `.env` file is in the project root
   - Check that the file is named exactly `.env` (not `.env.txt`)
   
   **Error: "Database connection failed"**
   - Verify your SUPABASE_URL is correct
   - Verify your SUPABASE_ANON_KEY is correct and complete
   - Check your internet connection
   - Verify your Supabase project is active
   
   **Error: "Azure AD authentication failed"**
   - Verify AZURE_CLIENT_ID is correct
   - Check that Azure provider is enabled in Supabase
   - Verify the redirect URL is configured in Azure Portal

---

## 🔒 SECURITY NOTES

⚠️ **IMPORTANT SECURITY REMINDERS:**

1. **Never commit `.env` to Git**
   - The `.env` file is already in `.gitignore`
   - Double-check before pushing to GitHub

2. **Keep Your Keys Secret**
   - Never share your SUPABASE_ANON_KEY publicly
   - Never share your AZURE_CLIENT_SECRET
   - Don't post them in Discord, Slack, or forums

3. **Use Environment Variables in Production**
   - For production deployment, use environment variables
   - Don't deploy the `.env` file to production servers

4. **Rotate Keys Regularly**
   - Change your Azure Client Secret every 6-12 months
   - Supabase keys can be rotated in the dashboard if compromised

---

## 📞 NEED HELP?

If you're stuck:

1. **Check Supabase Documentation:**
   - https://supabase.com/docs/guides/auth

2. **Check Azure AD Documentation:**
   - https://learn.microsoft.com/en-us/azure/active-directory/

3. **Common Issues:**
   - Make sure all 28 tables are created in Supabase
   - Verify Row Level Security (RLS) policies are set up
   - Check that your Azure users are created

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Status:** Ready for Setup

---

## 🎯 QUICK REFERENCE

### Where to Find Each Credential:

| Credential | Location | Format |
|------------|----------|--------|
| SUPABASE_URL | Supabase Dashboard → Settings → API | `https://xxx.supabase.co` |
| SUPABASE_ANON_KEY | Supabase Dashboard → Settings → API | Long JWT token (200+ chars) |
| AZURE_CLIENT_ID | Azure Portal → App Registrations → Overview | UUID format |
| AZURE_CLIENT_SECRET | Azure Portal → App Registrations → Certificates & secrets | Random string |

### Test Users (Already Created):

| Email | Password | Role |
|-------|----------|------|
| admin@aezycreativegmail.onmicrosoft.com | OroSystem123#2025 | Admin |
| ICT_Coordinator@aezycreativegmail.onmicrosoft.com | OroSystem123#2025 | Coordinator |
| Teacher@aezycreativegmail.onmicrosoft.com | OroSystem123#2025 | Teacher |
| student@aezycreativegmail.onmicrosoft.com | OroSystem123#2025 | Student |

---

**Ready to proceed? Follow the steps above and you'll be connected in no time! 🚀**

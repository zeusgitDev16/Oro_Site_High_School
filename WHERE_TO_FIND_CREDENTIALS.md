# 🔍 WHERE TO FIND YOUR CREDENTIALS

## Visual Guide with Screenshots Instructions

---

## 📍 LOCATION 1: Supabase Dashboard

### Getting SUPABASE_URL and SUPABASE_ANON_KEY

```
1. Open Browser → https://supabase.com/dashboard
2. Sign in to your account
3. Click on your project: "Oro Site High School ELMS"

You'll see this screen:
┌─────────────────────────────────────────────────────┐
│  🏠 Home    📊 Table Editor    🔐 Authentication    │
│  ⚙️ Settings                                        │
└─────────────────────────────────────────────────────┘

4. Click the ⚙️ Settings icon (bottom left)
5. Click "API" in the settings menu

You'll see:
┌─────────────────────────────────────────────────────┐
│  Configuration                                       │
│  ─────────────────────────────────────────────────  │
│  Project URL                                         │
│  https://abcdefghijklmnop.supabase.co              │
│  [Copy]                                             │
│                                                      │
│  Project API keys                                    │
│  ─────────────────────────────────────────────────  │
│  anon public                                         │
│  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3M...  │
│  [Copy]                                             │
│                                                      │
│  service_role secret                                 │
│  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3M...  │
│  [Copy]  ⚠️ DO NOT USE THIS ONE!                    │
└────────────────────────────────────────────���────────┘

6. Click [Copy] next to "Project URL"
   → Paste in .env as SUPABASE_URL

7. Click [Copy] next to "anon public"
   → Paste in .env as SUPABASE_ANON_KEY
```

**⚠️ IMPORTANT:**
- Copy the **anon public** key (NOT the service_role key!)
- The anon key is very long (200+ characters) - make sure you copy ALL of it
- Don't add quotes around the values in .env

---

## 📍 LOCATION 2: Azure Portal

### Getting AZURE_CLIENT_ID

```
1. Open Browser → https://portal.azure.com
2. Sign in with your Azure account
3. In the search bar at top, type: "App registrations"

You'll see:
┌─────────────────────────────────────────────────────┐
│  🔍 Search: App registrations                       │
│  ─────────────────────────────────────────────────  │
│  Services                                            │
│  📱 App registrations                               │
└─────────────────────────────────────────────────────┘

4. Click "App registrations"
5. Find and click: "Oro Site High School ELMS"

You'll see the Overview page:
┌─────────────────────────────────────────────────────┐
│  Oro Site High School ELMS                          │
│  ─────────────────────────────────────────────────  │
│  Essentials                                          │
│                                                      │
│  Display name: Oro Site High School ELMS            │
│  Application (client) ID:                            │
│  12345678-1234-1234-1234-123456789abc              │
│  [Copy to clipboard]                                │
│                                                      │
│  Directory (tenant) ID:                              │
│  87654321-4321-4321-4321-cba987654321              │
│  [Copy to clipboard]                                │
└─────────────────────────────────────────────────────┘

6. Click [Copy to clipboard] next to "Application (client) ID"
   → Paste in .env as AZURE_CLIENT_ID
```

---

## 📍 LOCATION 3: Your .env File

### Where to Paste the Credentials

```
Open this file in your code editor:
📁 c:\Users\User1\F_Dev\oro_site_high_school\.env

You'll see:
┌─────────────────────────────────────────────────────┐
│  # SUPABASE CONFIGURATION                           │
│  SUPABASE_URL=YOUR_SUPABASE_PROJECT_URL_HERE       │
│  SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY_HERE     │
│                                                      │
│  # AZURE AD CONFIGURATION                           │
│  AZURE_TENANT_ID=aezycreativegmail.onmicrosoft.com │
│  AZURE_CLIENT_ID=YOUR_AZURE_CLIENT_ID_HERE         │
└─────────────────────────────────────────────────────┘

Replace the placeholder text with your actual values:
┌─────────────────────────────────────────────────────┐
│  # SUPABASE CONFIGURATION                           │
│  SUPABASE_URL=https://abcdefg.supabase.co          │
│  SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI... │
│                                                      │
│  # AZURE AD CONFIGURATION                           │
│  AZURE_TENANT_ID=aezycreativegmail.onmicrosoft.com │
│  AZURE_CLIENT_ID=12345678-1234-1234-1234-123456... │
└─────────────────────────────────────────────────────┘

Then scroll down and change:
┌─────────────────────────────────────────────────────┐
│  # FEATURE FLAGS                                     │
│  USE_MOCK_DATA=true   ← Change this to false       │
└─────────────────────────────────────────────────────┘

To:
┌─────────────────────────────────────────────────────┐
│  # FEATURE FLAGS                                     │
│  USE_MOCK_DATA=false  ← Now using real backend     │
└─────────────────────────────────────────────────────┘

Save the file (Ctrl+S)
```

---

## ✅ VERIFICATION

### How to Know You Did It Right

After pasting your credentials, your `.env` file should look like this:

```env
# ============================================
# SUPABASE CONFIGURATION
# ============================================
SUPABASE_URL=https://abcdefghijklmnop.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYxNjE2MTYxNiwiZXhwIjoxOTMxNzM3NjE2fQ.abcdefghijklmnopqrstuvwxyz123456789

# ============================================
# AZURE AD CONFIGURATION
# ============================================
AZURE_TENANT_ID=aezycreativegmail.onmicrosoft.com
AZURE_CLIENT_ID=12345678-1234-1234-1234-123456789abc
AZURE_REDIRECT_URI=io.supabase.orosite://login-callback/

# ============================================
# FEATURE FLAGS
# ============================================
USE_MOCK_DATA=false
ENABLE_OFFLINE=true
ENABLE_REALTIME=true
ENABLE_AZURE_AUTH=true
```

**Check these:**
- ✅ No placeholder text like "YOUR_SUPABASE_PROJECT_URL_HERE"
- ✅ SUPABASE_URL starts with `https://`
- ✅ SUPABASE_ANON_KEY is very long (200+ characters)
- ✅ AZURE_CLIENT_ID is in UUID format (8-4-4-4-12 characters)
- ✅ USE_MOCK_DATA is set to `false`
- ✅ No quotes around the values
- ✅ No spaces before or after the `=` sign

---

## 🎯 QUICK COPY-PASTE FORMAT

For easy reference, here's the format:

```env
SUPABASE_URL=https://[YOUR-PROJECT-REF].supabase.co
SUPABASE_ANON_KEY=eyJ[VERY-LONG-KEY-HERE]
AZURE_CLIENT_ID=[UUID-FORMAT-HERE]
USE_MOCK_DATA=false
```

---

## 🔗 DIRECT LINKS

**Supabase Dashboard:**
https://supabase.com/dashboard

**Azure Portal:**
https://portal.azure.com

**App Registrations (Direct):**
https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade

---

## 📱 MOBILE FRIENDLY

If you're setting this up on mobile:

1. **Supabase:** Use the Supabase mobile app or browser
2. **Azure:** Use Azure mobile app or browser
3. **Editing .env:** Use a code editor app like:
   - VS Code (mobile)
   - Termux + nano
   - Any text editor

---

## 🆘 STILL STUCK?

### Can't find Supabase project?
- Make sure you're signed in to the correct account
- Check if project was created successfully
- Look in "All projects" dropdown

### Can't find Azure app registration?
- Make sure you're in the correct Azure tenant
- Check "All applications" view
- Search by name: "Oro Site High School ELMS"

### .env file not working?
- Make sure file is named exactly `.env` (not `.env.txt`)
- Make sure file is in project root folder
- Restart your IDE/editor after saving
- Run `flutter clean` then `flutter pub get`

---

**Need more help? Check:**
- `SUPABASE_CREDENTIALS_GUIDE.md` - Detailed step-by-step guide
- `QUICK_START_BACKEND.md` - 5-minute quick start
- `BACKEND_SETUP_CHECKLIST.md` - Complete checklist

---

**Happy Coding! 🚀**

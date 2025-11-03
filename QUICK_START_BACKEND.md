# 🚀 QUICK START: Backend Setup

## ⚡ 5-Minute Setup Guide

### Step 1: Get Supabase Credentials (2 minutes)

1. Go to: https://supabase.com/dashboard
2. Select your project
3. Click **Settings** (⚙️) → **API**
4. Copy these two values:
   - **Project URL** → Example: `https://abcdefg.supabase.co`
   - **anon public key** → Example: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (very long)

### Step 2: Get Azure Client ID (1 minute)

1. Go to: https://portal.azure.com
2. Search for **"App registrations"**
3. Click **"Oro Site High School ELMS"**
4. Copy the **Application (client) ID** → Example: `12345678-1234-1234-1234-123456789abc`

### Step 3: Update .env File (1 minute)

Open the `.env` file in your project root and replace these lines:

```env
SUPABASE_URL=YOUR_SUPABASE_PROJECT_URL_HERE
SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY_HERE
AZURE_CLIENT_ID=YOUR_AZURE_CLIENT_ID_HERE
```

With your actual values:

```env
SUPABASE_URL=https://abcdefg.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
AZURE_CLIENT_ID=12345678-1234-1234-1234-123456789abc
```

### Step 4: Enable Real Backend (30 seconds)

In the same `.env` file, change:

```env
USE_MOCK_DATA=true
```

To:

```env
USE_MOCK_DATA=false
```

### Step 5: Test Connection (30 seconds)

Run your app:

```bash
flutter run
```

Look for this in the console:

```
✅ Database connection successful
✅ Supabase initialized successfully
```

---

## 🎯 That's It!

Your backend is now connected! 

### What You Can Do Now:

✅ **Login with Azure AD users:**
- admin@aezycreativegmail.onmicrosoft.com
- ICT_Coordinator@aezycreativegmail.onmicrosoft.com
- Teacher@aezycreativegmail.onmicrosoft.com
- student@aezycreativegmail.onmicrosoft.com

Password for all: `OroSystem123#2025`

✅ **Real-time data sync** - Changes appear instantly
✅ **Offline support** - Works without internet
✅ **28 database tables** - All ready to use

---

## 🆘 Troubleshooting

**Problem:** "SUPABASE_URL not found"
- **Solution:** Make sure `.env` file is in project root (not in a subfolder)

**Problem:** "Database connection failed"
- **Solution:** Double-check your SUPABASE_URL and SUPABASE_ANON_KEY are correct

**Problem:** "Azure login not working"
- **Solution:** See full guide in `SUPABASE_CREDENTIALS_GUIDE.md`

---

## 📚 Need More Details?

Read the complete guide: **`SUPABASE_CREDENTIALS_GUIDE.md`**

---

**Happy Coding! 🎉**

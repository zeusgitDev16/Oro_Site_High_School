# Subject Resources Migration Guide

## Overview
This migration creates the infrastructure for quarter-based subject resources (modules, assignment resources, and assignments).

## Files
1. `20250124_create_subject_resources.sql` - Creates the main table and RLS policies
2. `20250124_create_subject_resources_storage.sql` - Creates storage bucket and policies

## Running the Migration

### Option 1: Using Supabase CLI (Recommended)
```bash
# Make sure you're in the project root
cd c:/Users/User1/F_Dev/oro_site_high_school

# Run the migrations
supabase db push
```

### Option 2: Manual Execution via Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select your project
3. Navigate to SQL Editor
4. Copy and paste the contents of each migration file
5. Execute them in order:
   - First: `20250124_create_subject_resources.sql`
   - Second: `20250124_create_subject_resources_storage.sql`

### Option 3: Using the Supabase Tool (via Agent)
The agent can execute these migrations for you using the `supabase` tool.

## Database Schema

### Table: `subject_resources`
Stores all resource metadata with the following structure:

**Columns:**
- `id` (UUID) - Primary key
- `subject_id` (UUID) - Foreign key to classroom_subjects
- `resource_name` (TEXT) - Name of the resource
- `resource_type` (TEXT) - 'module', 'assignment_resource', or 'assignment'
- `quarter` (INTEGER) - 1, 2, 3, or 4
- `file_url` (TEXT) - URL to the file in storage
- `file_name` (TEXT) - Original file name
- `file_size` (BIGINT) - File size in bytes
- `file_type` (TEXT) - File extension (pdf, docx, pptx, xlsx, png, jpeg, mp4)
- `version` (INTEGER) - Version number (default: 1)
- `is_latest_version` (BOOLEAN) - Flag for latest version
- `previous_version_id` (UUID) - Reference to previous version
- `display_order` (INTEGER) - Order for display
- `description` (TEXT) - Optional description
- `is_active` (BOOLEAN) - Active status
- `created_at` (TIMESTAMPTZ) - Creation timestamp
- `updated_at` (TIMESTAMPTZ) - Last update timestamp
- `created_by` (UUID) - User who created the resource
- `uploaded_by` (UUID) - User who uploaded the file

### Storage Bucket: `subject-resources`
- **Max file size:** 100 MB
- **Allowed types:** PDF, DOCX, PPTX, XLSX, PNG, JPEG, MP4
- **Public:** No (requires authentication)

### Folder Structure
```
subject-resources/
├── modules/
│   └── {classroom_id}/
│       └── {subject_id}/
│           ├── q1/
│           ├── q2/
│           ├── q3/
│           └── q4/
├── assignment_resources/
│   └── (same structure)
└── assignments/
    └── (same structure)
```

## Access Control (RLS Policies)

### Admins
- ✅ Full CRUD on all resources
- ✅ Upload modules, assignment resources
- ✅ View assignments (created by teachers)
- ✅ Delete any file

### Teachers
- ✅ View modules and assignment resources
- ✅ Full CRUD on assignments
- ✅ Upload assignment files only
- ❌ Cannot upload modules or assignment resources

### Students
- ✅ View modules
- ✅ View assignments
- ❌ Cannot view assignment resources
- ❌ Cannot upload anything

## Verification

After running the migration, verify with these queries:

```sql
-- Check if table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'subject_resources'
);

-- Check if storage bucket exists
SELECT * FROM storage.buckets WHERE id = 'subject-resources';

-- Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'subject_resources';

-- Check storage policies
SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';
```

## Rollback (if needed)

```sql
-- Drop table and related objects
DROP TABLE IF EXISTS subject_resources CASCADE;

-- Remove storage bucket
DELETE FROM storage.buckets WHERE id = 'subject-resources';

-- Drop policies (automatically dropped with table)
```

## Next Steps

After successful migration:
1. ✅ Create Flutter models (`SubjectResource`, `ResourceType`)
2. ✅ Create service class (`SubjectResourceService`)
3. ✅ Implement file upload logic
4. ✅ Update UI to display resources
5. ✅ Add temporary storage logic for CREATE mode


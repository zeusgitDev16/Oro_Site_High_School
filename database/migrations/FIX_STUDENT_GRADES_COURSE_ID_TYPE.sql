-- Fix student_grades.course_id type to match courses.id (idempotent)
-- Safely aligns the data type and foreign key so inserts/updates from the Teacher Grade Entry screen stop failing with
--   ERROR: invalid input syntax for type uuid: "11" (code 22P02)
--
-- What this does:
-- 1) Detects the actual type of public.courses.id (uuid vs integer)
-- 2) Ensures public.student_grades.course_id has the same type
-- 3) Re-creates/ensures the foreign key from student_grades.course_id -> courses(id)
-- 4) Adds a helpful composite index used by the app (student_id, classroom_id, course_id, quarter)
--
-- Notes:
-- - If student_grades.course_id currently contains non-castable values, ALTER TYPE may fail.
--   In most cases this table was empty because writes were failing. If you already have rows,
--   run a quick SELECT to inspect distinct course_id values before executing this script.
-- - This script is idempotent: running it multiple times will no-op after the first successful run.

begin;

-- 0) Ensure the table exists (do nothing if it does not)
--    We won't create the table here to avoid guessing full schema.
--    If the table is missing, the app would show a different error.

-- 1) Detect types
DO $$
DECLARE
  courses_id_udt text;
  sg_course_id_udt text;
  fk_name text;
  idx_name text;
  pol_name text;
  pol_rec record;
  sql text;
  cmd_clause text;
  err text;
  needs_fk boolean := false;
BEGIN
  SELECT c.udt_name
    INTO courses_id_udt
    FROM information_schema.columns c
   WHERE c.table_schema = 'public' AND c.table_name = 'courses' AND c.column_name = 'id'
   LIMIT 1;

  IF courses_id_udt IS NULL THEN
    RAISE NOTICE 'No courses.id column found; skipping type alignment.';
    RETURN;
  END IF;

  SELECT c.udt_name
    INTO sg_course_id_udt
    FROM information_schema.columns c
   WHERE c.table_schema = 'public' AND c.table_name = 'student_grades' AND c.column_name = 'course_id'
   LIMIT 1;

  IF sg_course_id_udt IS NULL THEN
    RAISE NOTICE 'No student_grades.course_id column found; skipping type alignment.';
    RETURN;
  END IF;

  -- 2) Align type: courses.id -> uuid
  IF courses_id_udt = 'uuid' THEN
    IF sg_course_id_udt <> 'uuid' THEN
      RAISE NOTICE 'Altering student_grades.course_id to UUID to match courses.id';
      -- Drop any FK that may block type change
      FOR fk_name IN
        SELECT conname
          FROM pg_constraint
         WHERE conrelid = 'public.student_grades'::regclass
           AND confrelid = 'public.courses'::regclass
      LOOP
        EXECUTE format('ALTER TABLE public.student_grades DROP CONSTRAINT %I', fk_name);
      END LOOP;

      -- Capture and drop RLS policies on public.student_grades (required to alter column type)
      CREATE TEMP TABLE IF NOT EXISTS _sg_policies (
        polname text,
        polcmd text,
        permissive boolean,
        roles_clause text,
        using_expr text,
        with_check_expr text
      ) ON COMMIT DROP;

      -- Save current policies for later recreation
      DELETE FROM _sg_policies;
      INSERT INTO _sg_policies (polname, polcmd, permissive, roles_clause, using_expr, with_check_expr)
      SELECT
        polname,
        polcmd::text,
        polpermissive,
        CASE
          WHEN polroles IS NULL OR array_length(polroles,1)=0 THEN 'TO PUBLIC'
          ELSE 'TO ' || array_to_string(ARRAY(SELECT quote_ident(rolname) FROM pg_roles WHERE oid = ANY(polroles)), ', ')
        END AS roles_clause,
        COALESCE(pg_get_expr(polqual, polrelid), '') AS using_expr,
        COALESCE(pg_get_expr(polwithcheck, polrelid), '') AS with_check_expr
      FROM pg_policy
      WHERE polrelid = 'public.student_grades'::regclass;

      -- Drop existing policies so the column type can be changed
      FOR pol_name IN
        SELECT polname FROM pg_policy
        WHERE polrelid = 'public.student_grades'::regclass
      LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.student_grades', pol_name);
      END LOOP;

      -- Drop indexes on course_id to avoid opclass/type conflicts during ALTER TYPE
      FOR idx_name IN
        SELECT indexname FROM pg_indexes
        WHERE schemaname = 'public' AND tablename = 'student_grades'
          AND indexdef ILIKE '%(course_id%'
      LOOP
        EXECUTE format('DROP INDEX IF EXISTS %I', idx_name);
      END LOOP;

      -- Attempt type change with safe fallback: non-UUID values become NULL instead of failing
      BEGIN
        -- Inform how many rows will become NULL due to non-UUID values
        PERFORM 1;
        RAISE NOTICE 'Non-UUID course_id rows (set to NULL): %', (
          SELECT count(*) FROM public.student_grades
          WHERE course_id IS NOT NULL AND NOT (
            course_id::text ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
          )
        );
        EXECUTE 'ALTER TABLE public.student_grades ALTER COLUMN course_id DROP NOT NULL';
        EXECUTE $uuid$
          ALTER TABLE public.student_grades
          ALTER COLUMN course_id TYPE uuid
          USING (
            CASE
              WHEN course_id IS NULL THEN NULL
              WHEN course_id::text ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' THEN (course_id::text)::uuid
              ELSE NULL
            END
          )
        $uuid$;
      EXCEPTION WHEN others THEN
        GET STACKED DIAGNOSTICS err = MESSAGE_TEXT;
        RAISE EXCEPTION 'Failed converting student_grades.course_id to UUID: %', err;
      END;
      needs_fk := true;
    END IF;

  -- 3) Align type: courses.id -> integer/bigint family
  ELSIF courses_id_udt IN ('int8','int4','int2') THEN
    IF sg_course_id_udt NOT IN ('int8','int4','int2') THEN
      RAISE NOTICE 'Altering student_grades.course_id to BIGINT to match courses.id';
      -- Drop any FK that may block type change
      FOR fk_name IN
        SELECT conname
          FROM pg_constraint
         WHERE conrelid = 'public.student_grades'::regclass
           AND confrelid = 'public.courses'::regclass
      LOOP
        EXECUTE format('ALTER TABLE public.student_grades DROP CONSTRAINT %I', fk_name);
      END LOOP;

      -- Capture and drop RLS policies on public.student_grades (required to alter column type)
      CREATE TEMP TABLE IF NOT EXISTS _sg_policies (
        polname text,
        polcmd text,
        permissive boolean,
        roles_clause text,
        using_expr text,
        with_check_expr text
      ) ON COMMIT DROP;

      -- Save current policies for later recreation
      DELETE FROM _sg_policies;
      INSERT INTO _sg_policies (polname, polcmd, permissive, roles_clause, using_expr, with_check_expr)
      SELECT
        polname,
        polcmd::text,
        polpermissive,
        CASE
          WHEN polroles IS NULL OR array_length(polroles,1)=0 THEN 'TO PUBLIC'
          ELSE 'TO ' || array_to_string(ARRAY(SELECT quote_ident(rolname) FROM pg_roles WHERE oid = ANY(polroles)), ', ')
        END AS roles_clause,
        COALESCE(pg_get_expr(polqual, polrelid), '') AS using_expr,
        COALESCE(pg_get_expr(polwithcheck, polrelid), '') AS with_check_expr
      FROM pg_policy
      WHERE polrelid = 'public.student_grades'::regclass;

      -- Drop existing policies so the column type can be changed
      FOR pol_name IN
        SELECT polname FROM pg_policy
        WHERE polrelid = 'public.student_grades'::regclass
      LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.student_grades', pol_name);
      END LOOP;

      -- Drop indexes on course_id to avoid opclass/type conflicts during ALTER TYPE
      FOR idx_name IN
        SELECT indexname FROM pg_indexes
        WHERE schemaname = 'public' AND tablename = 'student_grades'
          AND indexdef ILIKE '%(course_id%'
      LOOP
        EXECUTE format('DROP INDEX IF EXISTS %I', idx_name);
      END LOOP;

      -- Convert to BIGINT using safe fallback: non-numeric values become NULL instead of failing
      BEGIN
        -- Inform how many rows will become NULL due to non-numeric values
        PERFORM 1;
        RAISE NOTICE 'Non-numeric course_id rows (set to NULL): %', (
          SELECT count(*) FROM public.student_grades
          WHERE course_id IS NOT NULL AND NOT (course_id::text ~ '^[0-9]+$')
        );
        EXECUTE 'ALTER TABLE public.student_grades ALTER COLUMN course_id DROP NOT NULL';
        EXECUTE $bigint$
          ALTER TABLE public.student_grades
          ALTER COLUMN course_id TYPE bigint
          USING (
            CASE
              WHEN course_id IS NULL THEN NULL
              WHEN course_id::text ~ '^[0-9]+$' THEN (course_id::text)::bigint
              ELSE NULL
            END


          )
        $bigint$;
      EXCEPTION WHEN others THEN
        GET STACKED DIAGNOSTICS err = MESSAGE_TEXT;
        RAISE EXCEPTION 'Failed converting student_grades.course_id to BIGINT: %', err;
      END;
      needs_fk := true;
    END IF;
  ELSE
    RAISE NOTICE 'Unsupported courses.id type (udt=%). No changes applied.', courses_id_udt;
  END IF;

  -- 4) Recreate the FK if missing (cannot use IF NOT EXISTS on constraints)
  IF needs_fk OR NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conrelid = 'public.student_grades'::regclass
       AND confrelid = 'public.courses'::regclass
  ) THEN
    -- Drop any pre-existing similarly named FK to avoid duplicates
    FOR fk_name IN
      SELECT conname
        FROM pg_constraint
       WHERE conrelid = 'public.student_grades'::regclass
         AND contype = 'f'
    LOOP
      EXECUTE format('ALTER TABLE public.student_grades DROP CONSTRAINT %I', fk_name);
    END LOOP;

    -- Add the new FK pointing to courses(id). Use NOT VALID so existing bad rows don't block creation; new writes must comply.
    EXECUTE 'ALTER TABLE public.student_grades
              ADD CONSTRAINT student_grades_course_id_fkey
              FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE NOT VALID';
  END IF;

  -- 5) Recreate any RLS policies we dropped earlier
  IF EXISTS (
    SELECT 1
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE c.relname = '_sg_policies' AND n.nspname LIKE 'pg_temp%'
  ) THEN
    FOR pol_rec IN
      SELECT polname, polcmd, permissive, roles_clause, using_expr, with_check_expr
      FROM _sg_policies
    LOOP
      cmd_clause := CASE pol_rec.polcmd
        WHEN 'r' THEN 'FOR SELECT'
        WHEN 'a' THEN 'FOR INSERT'
        WHEN 'w' THEN 'FOR UPDATE'
        WHEN 'd' THEN 'FOR DELETE'
        ELSE ''
      END;

      sql := 'CREATE POLICY ' || quote_ident(pol_rec.polname) ||
             ' ON public.student_grades ' ||
             (CASE WHEN pol_rec.permissive THEN '' ELSE 'AS RESTRICTIVE ' END) ||
             cmd_clause || ' ' || pol_rec.roles_clause ||
             (CASE WHEN NULLIF(btrim(pol_rec.using_expr),'') IS NULL THEN '' ELSE ' USING (' || pol_rec.using_expr || ')' END) ||
             (CASE WHEN NULLIF(btrim(pol_rec.with_check_expr),'') IS NULL THEN '' ELSE ' WITH CHECK (' || pol_rec.with_check_expr || ')' END);
      EXECUTE sql;
    END LOOP;
  END IF;

END $$;

-- 5) Helpful composite index for the upsert/select paths used by the app
CREATE INDEX IF NOT EXISTS idx_student_grades_lookup
  ON public.student_grades (student_id, classroom_id, course_id, quarter);

commit;


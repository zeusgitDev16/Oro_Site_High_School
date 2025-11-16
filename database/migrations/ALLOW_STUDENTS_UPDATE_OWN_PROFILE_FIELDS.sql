-- Migration: Allow students to update a limited set of their own profile fields
-- NOTE: This is additive and does not change existing admin-only policies.
-- Existing policy `students_update_admin` remains in place for admins.

-- Row Level Security must already be enabled on public.students.
-- This policy allows authenticated users to UPDATE the row where id = auth.uid().
-- Frontend and services MUST only send updates for allowed fields:
--   lrn, birth_date, gender, address, guardian_name, guardian_contact,
--   school_level, track, strand, and other non-admin-controlled metadata.
--   Admin-controlled fields such as id, is_active, grade_level, section, and
--   school_year must not be modified by student-facing code.

CREATE POLICY "students_update_own_profile_fields"
  ON public.students
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());


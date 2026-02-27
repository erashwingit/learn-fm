-- ============================================================
-- Migration 002: Full courses schema + admin access
-- Learn FM — Admin Panel
-- Run this against your Supabase project SQL editor or CLI
-- ============================================================

-- ── 1. Add is_admin column to profiles ─────────────────────────────────────
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- ── 2. Courses table ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS courses (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT NOT NULL,
  description     TEXT,
  domain          TEXT,                     -- FM domain (one of 14)
  difficulty      TEXT
    CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced'))
    DEFAULT 'Beginner',
  duration_hours  NUMERIC DEFAULT 0,
  thumbnail_url   TEXT,
  is_published    BOOLEAN DEFAULT TRUE,
  created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- RLS on courses
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'courses' AND policyname = 'Anyone can read published courses'
  ) THEN
    CREATE POLICY "Anyone can read published courses" ON courses
      FOR SELECT USING (is_published = true OR
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'courses' AND policyname = 'Admins can insert courses'
  ) THEN
    CREATE POLICY "Admins can insert courses" ON courses
      FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'courses' AND policyname = 'Admins can update courses'
  ) THEN
    CREATE POLICY "Admins can update courses" ON courses
      FOR UPDATE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'courses' AND policyname = 'Admins can delete courses'
  ) THEN
    CREATE POLICY "Admins can delete courses" ON courses
      FOR DELETE USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
      );
  END IF;
END $$;

-- ── 3. Lessons table ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lessons (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id        UUID REFERENCES courses(id) ON DELETE CASCADE,
  domain_title     TEXT,          -- alias kept for course_detail_screen queries
  title            TEXT NOT NULL,
  content_type     TEXT CHECK (content_type IN ('video', 'pdf', 'text')),
  content_url      TEXT,
  file_url         TEXT,          -- alias: same as content_url
  content_text     TEXT,
  file_path        TEXT,          -- Supabase Storage path (for deletion)
  description      TEXT,
  order_index      INTEGER DEFAULT 0,
  duration_minutes INTEGER DEFAULT 0,
  duration_mins    INTEGER DEFAULT 0,   -- alias used by older queries
  is_published     BOOLEAN DEFAULT TRUE,
  uploaded_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Add course_id to existing lessons table if missing
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS course_id UUID REFERENCES courses(id) ON DELETE CASCADE;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS domain_title TEXT;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS file_url TEXT;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS file_path TEXT;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS duration_minutes INTEGER DEFAULT 0;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS duration_mins INTEGER DEFAULT 0;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT TRUE;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- RLS on lessons
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'lessons' AND policyname = 'Anyone can read lessons'
  ) THEN
    CREATE POLICY "Anyone can read lessons" ON lessons FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'lessons' AND policyname = 'Admins can insert lessons'
  ) THEN
    CREATE POLICY "Admins can insert lessons" ON lessons FOR INSERT WITH CHECK (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
    );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'lessons' AND policyname = 'Admins can update lessons'
  ) THEN
    CREATE POLICY "Admins can update lessons" ON lessons FOR UPDATE USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
    );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'lessons' AND policyname = 'Admins can delete lessons'
  ) THEN
    CREATE POLICY "Admins can delete lessons" ON lessons FOR DELETE USING (
      EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
    );
  END IF;
END $$;

-- ── 4. Lesson progress table ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lesson_progress (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id    UUID REFERENCES lessons(id) ON DELETE CASCADE,
  completed    BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  UNIQUE(user_id, lesson_id)
);

ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'lesson_progress' AND policyname = 'Users manage own progress'
  ) THEN
    CREATE POLICY "Users manage own progress" ON lesson_progress
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- ── 5. Enrollments table ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS enrollments (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  domain_title TEXT,
  course_id    UUID REFERENCES courses(id) ON DELETE SET NULL,
  progress     NUMERIC DEFAULT 0,    -- 0–100
  enrolled_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, domain_title)
);

ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'enrollments' AND policyname = 'Users manage own enrollments'
  ) THEN
    CREATE POLICY "Users manage own enrollments" ON enrollments
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'enrollments' AND policyname = 'Admins can read all enrollments'
  ) THEN
    CREATE POLICY "Admins can read all enrollments" ON enrollments
      FOR SELECT USING (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
      );
  END IF;
END $$;

-- ── 6. Supabase Storage buckets ──────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
  VALUES ('lesson-content', 'lesson-content', true)
  ON CONFLICT DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
  VALUES ('course-videos', 'course-videos', true)
  ON CONFLICT DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
  VALUES ('course-pdfs', 'course-pdfs', true)
  ON CONFLICT DO NOTHING;

-- Storage policies: allow authenticated uploads; public read
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Admins can upload lesson content'
  ) THEN
    CREATE POLICY "Admins can upload lesson content"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id IN ('lesson-content', 'course-videos', 'course-pdfs')
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'objects' AND policyname = 'Public can read lesson content'
  ) THEN
    CREATE POLICY "Public can read lesson content"
      ON storage.objects FOR SELECT
      USING (bucket_id IN ('lesson-content', 'course-videos', 'course-pdfs'));
  END IF;
END $$;

-- ── 7. Grant admin to test user ──────────────────────────────────────────────
-- Set imptemplate@gmail.com as admin
UPDATE profiles
SET is_admin = true
WHERE id = (
  SELECT id FROM auth.users WHERE email = 'imptemplate@gmail.com'
);

-- ── Done ──────────────────────────────────────────────────────────────────────
-- After running this migration:
-- 1. imptemplate@gmail.com will see "Admin Panel" in their profile
-- 2. They can upload courses, lessons, and manage content
-- 3. Run: SELECT id, email, is_admin FROM profiles JOIN auth.users ...
--    to verify the admin flag was set.

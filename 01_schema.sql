-- ============================================================
--  TIMETABLE MANAGEMENT SYSTEM — DATABASE SCHEMA
--  MySQL 8.0+
-- ============================================================

CREATE DATABASE IF NOT EXISTS timetable_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE timetable_db;

-- ──────────────────────────────────────────────
-- 1. DEPARTMENTS
-- ──────────────────────────────────────────────
CREATE TABLE departments (
    dept_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dept_code    VARCHAR(10)  NOT NULL UNIQUE,
    dept_name    VARCHAR(100) NOT NULL,
    hod_name     VARCHAR(100),
    created_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ──────────────────────────────────────────────
-- 2. ACADEMIC YEARS / SEMESTERS
-- ──────────────────────────────────────────────
CREATE TABLE academic_years (
    year_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    year_label   VARCHAR(20)  NOT NULL UNIQUE,   -- e.g. "2024-25"
    start_date   DATE         NOT NULL,
    end_date     DATE         NOT NULL,
    is_current   TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT chk_year_dates CHECK (end_date > start_date)
);

CREATE TABLE semesters (
    semester_id  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    year_id      INT UNSIGNED NOT NULL,
    sem_number   TINYINT      NOT NULL,           -- 1 or 2
    sem_label    VARCHAR(30)  NOT NULL,            -- "Odd 2024", "Even 2025"
    start_date   DATE         NOT NULL,
    end_date     DATE         NOT NULL,
    is_current   TINYINT(1)   NOT NULL DEFAULT 0,
    FOREIGN KEY (year_id) REFERENCES academic_years(year_id) ON DELETE CASCADE,
    UNIQUE KEY uq_year_sem (year_id, sem_number),
    CONSTRAINT chk_sem_dates CHECK (end_date > start_date)
);

-- ──────────────────────────────────────────────
-- 3. CLASSROOMS / LABS
-- ──────────────────────────────────────────────
CREATE TABLE rooms (
    room_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_code    VARCHAR(15)  NOT NULL UNIQUE,
    room_name    VARCHAR(80)  NOT NULL,
    capacity     SMALLINT     NOT NULL DEFAULT 60,
    room_type    ENUM('LECTURE','LAB','SEMINAR','AUDITORIUM') NOT NULL DEFAULT 'LECTURE',
    building     VARCHAR(50),
    floor_no     TINYINT,
    is_active    TINYINT(1)   NOT NULL DEFAULT 1
);

-- ──────────────────────────────────────────────
-- 4. FACULTY
-- ──────────────────────────────────────────────
CREATE TABLE faculty (
    faculty_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dept_id      INT UNSIGNED NOT NULL,
    emp_code     VARCHAR(15)  NOT NULL UNIQUE,
    first_name   VARCHAR(50)  NOT NULL,
    last_name    VARCHAR(50)  NOT NULL,
    email        VARCHAR(100) NOT NULL UNIQUE,
    phone        VARCHAR(15),
    designation  VARCHAR(60),
    max_hours_per_week TINYINT NOT NULL DEFAULT 18,
    is_active    TINYINT(1)   NOT NULL DEFAULT 1,
    created_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- ──────────────────────────────────────────────
-- 5. COURSES / SUBJECTS
-- ──────────────────────────────────────────────
CREATE TABLE courses (
    course_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dept_id      INT UNSIGNED NOT NULL,
    course_code  VARCHAR(15)  NOT NULL UNIQUE,
    course_name  VARCHAR(120) NOT NULL,
    credits      TINYINT      NOT NULL DEFAULT 3,
    hours_per_week TINYINT    NOT NULL DEFAULT 3,
    course_type  ENUM('THEORY','LAB','TUTORIAL','PROJECT') NOT NULL DEFAULT 'THEORY',
    semester_no  TINYINT      NOT NULL,            -- which sem it belongs to
    is_active    TINYINT(1)   NOT NULL DEFAULT 1,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- ──────────────────────────────────────────────
-- 6. STUDENT BATCHES / SECTIONS
-- ──────────────────────────────────────────────
CREATE TABLE batches (
    batch_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    dept_id      INT UNSIGNED NOT NULL,
    batch_name   VARCHAR(30)  NOT NULL,            -- "CSE-A", "ECE-B"
    strength     SMALLINT     NOT NULL DEFAULT 60,
    semester_no  TINYINT      NOT NULL,
    year_id      INT UNSIGNED NOT NULL,
    created_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dept_id)  REFERENCES departments(dept_id),
    FOREIGN KEY (year_id)  REFERENCES academic_years(year_id),
    UNIQUE KEY uq_batch (dept_id, batch_name, semester_no, year_id)
);

-- ──────────────────────────────────────────────
-- 7. TIME SLOTS
-- ──────────────────────────────────────────────
CREATE TABLE time_slots (
    slot_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    slot_label   VARCHAR(20)  NOT NULL UNIQUE,     -- "P1", "P2", … "P7"
    start_time   TIME         NOT NULL,
    end_time     TIME         NOT NULL,
    slot_type    ENUM('REGULAR','BREAK','LUNCH')  NOT NULL DEFAULT 'REGULAR',
    CONSTRAINT chk_slot_time CHECK (end_time > start_time)
);

-- ──────────────────────────────────────────────
-- 8. TIMETABLE ENTRIES  (core table)
-- ──────────────────────────────────────────────
CREATE TABLE timetable (
    entry_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    semester_id  INT UNSIGNED NOT NULL,
    batch_id     INT UNSIGNED NOT NULL,
    course_id    INT UNSIGNED NOT NULL,
    faculty_id   INT UNSIGNED NOT NULL,
    room_id      INT UNSIGNED NOT NULL,
    slot_id      INT UNSIGNED NOT NULL,
    day_of_week  ENUM('MON','TUE','WED','THU','FRI','SAT') NOT NULL,
    is_active    TINYINT(1)   NOT NULL DEFAULT 1,
    created_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id),
    FOREIGN KEY (batch_id)    REFERENCES batches(batch_id),
    FOREIGN KEY (course_id)   REFERENCES courses(course_id),
    FOREIGN KEY (faculty_id)  REFERENCES faculty(faculty_id),
    FOREIGN KEY (room_id)     REFERENCES rooms(room_id),
    FOREIGN KEY (slot_id)     REFERENCES time_slots(slot_id),

    -- No two batches in the same room at the same time
    UNIQUE KEY uq_room_slot_day      (room_id,    slot_id, day_of_week, semester_id),
    -- No faculty teaching two places at once
    UNIQUE KEY uq_faculty_slot_day   (faculty_id, slot_id, day_of_week, semester_id),
    -- No batch with two subjects at once
    UNIQUE KEY uq_batch_slot_day     (batch_id,   slot_id, day_of_week, semester_id)
);

-- ──────────────────────────────────────────────
-- 9. COURSE–FACULTY ASSIGNMENTS  (who can teach what)
-- ──────────────────────────────────────────────
CREATE TABLE course_faculty (
    cf_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    course_id    INT UNSIGNED NOT NULL,
    faculty_id   INT UNSIGNED NOT NULL,
    semester_id  INT UNSIGNED NOT NULL,
    assigned_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id)   REFERENCES courses(course_id),
    FOREIGN KEY (faculty_id)  REFERENCES faculty(faculty_id),
    FOREIGN KEY (semester_id) REFERENCES semesters(semester_id),
    UNIQUE KEY uq_cf (course_id, faculty_id, semester_id)
);

-- ──────────────────────────────────────────────
-- 10. SUBSTITUTIONS / REPLACEMENTS
-- ──────────────────────────────────────────────
CREATE TABLE substitutions (
    sub_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    original_entry  INT UNSIGNED NOT NULL,
    sub_date        DATE         NOT NULL,
    substitute_fac  INT UNSIGNED NOT NULL,
    reason          VARCHAR(200),
    approved_by     VARCHAR(100),
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (original_entry) REFERENCES timetable(entry_id),
    FOREIGN KEY (substitute_fac) REFERENCES faculty(faculty_id)
);

-- ──────────────────────────────────────────────
-- 11. AUDIT LOG
-- ──────────────────────────────────────────────
CREATE TABLE audit_log (
    log_id       BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_name   VARCHAR(50)  NOT NULL,
    operation    ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    record_id    INT UNSIGNED NOT NULL,
    changed_by   VARCHAR(80)  NOT NULL DEFAULT USER(),
    changed_at   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    old_data     JSON,
    new_data     JSON
);

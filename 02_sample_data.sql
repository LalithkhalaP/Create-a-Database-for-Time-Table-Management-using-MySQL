-- ============================================================
--  TIMETABLE MANAGEMENT SYSTEM — SAMPLE DATA
-- ============================================================

USE timetable_db;

-- ── DEPARTMENTS ──────────────────────────────────────────────
INSERT INTO departments (dept_code, dept_name, hod_name) VALUES
  ('CSE',  'Computer Science & Engineering',     'Dr. R. Krishnamurthy'),
  ('ECE',  'Electronics & Communication Engg.',  'Dr. S. Lakshmi'),
  ('MECH', 'Mechanical Engineering',             'Dr. P. Venkatesh'),
  ('CIVIL','Civil Engineering',                  'Dr. A. Rajan');

-- ── ACADEMIC YEAR ────────────────────────────────────────────
INSERT INTO academic_years (year_label, start_date, end_date, is_current) VALUES
  ('2023-24', '2023-06-01', '2024-05-31', 0),
  ('2024-25', '2024-06-01', '2025-05-31', 1);

-- ── SEMESTERS ────────────────────────────────────────────────
INSERT INTO semesters (year_id, sem_number, sem_label, start_date, end_date, is_current) VALUES
  (2, 1, 'Odd Semester 2024',  '2024-06-01', '2024-11-30', 1),
  (2, 2, 'Even Semester 2025', '2025-01-01', '2025-05-31', 0);

-- ── ROOMS ────────────────────────────────────────────────────
INSERT INTO rooms (room_code, room_name, capacity, room_type, building, floor_no) VALUES
  ('A101', 'Classroom A-101',   60, 'LECTURE', 'Block A', 1),
  ('A102', 'Classroom A-102',   60, 'LECTURE', 'Block A', 1),
  ('A201', 'Classroom A-201',   60, 'LECTURE', 'Block A', 2),
  ('A202', 'Seminar Hall A',    80, 'SEMINAR', 'Block A', 2),
  ('B101', 'CS Lab 1',          40, 'LAB',     'Block B', 1),
  ('B102', 'CS Lab 2',          40, 'LAB',     'Block B', 1),
  ('B201', 'Electronics Lab',   35, 'LAB',     'Block B', 2),
  ('C101', 'Mech Workshop',     45, 'LAB',     'Block C', 1);

-- ── FACULTY ──────────────────────────────────────────────────
INSERT INTO faculty (dept_id, emp_code, first_name, last_name, email, phone, designation, max_hours_per_week) VALUES
  (1, 'EMP001', 'Arjun',    'Sharma',     'arjun.sharma@college.edu',    '9876543210', 'Associate Professor', 18),
  (1, 'EMP002', 'Priya',    'Nair',       'priya.nair@college.edu',      '9876543211', 'Assistant Professor', 16),
  (1, 'EMP003', 'Karthik',  'Suresh',     'karthik.suresh@college.edu',  '9876543212', 'Assistant Professor', 16),
  (2, 'EMP004', 'Divya',    'Menon',      'divya.menon@college.edu',     '9876543213', 'Associate Professor', 18),
  (2, 'EMP005', 'Rahul',    'Iyer',       'rahul.iyer@college.edu',      '9876543214', 'Assistant Professor', 16),
  (3, 'EMP006', 'Sundar',   'Rajan',      'sundar.rajan@college.edu',    '9876543215', 'Professor',           18),
  (4, 'EMP007', 'Meena',    'Balasubramaniam', 'meena.b@college.edu',    '9876543216', 'Assistant Professor', 16);

-- ── COURSES ──────────────────────────────────────────────────
INSERT INTO courses (dept_id, course_code, course_name, credits, hours_per_week, course_type, semester_no) VALUES
  (1, 'CS301', 'Data Structures & Algorithms',   4, 4, 'THEORY',   3),
  (1, 'CS302', 'Database Management Systems',    4, 4, 'THEORY',   3),
  (1, 'CS303', 'Operating Systems',              3, 3, 'THEORY',   3),
  (1, 'CS304', 'Data Structures Lab',            2, 3, 'LAB',      3),
  (1, 'CS305', 'DBMS Lab',                       2, 3, 'LAB',      3),
  (1, 'CS401', 'Computer Networks',              4, 4, 'THEORY',   4),
  (1, 'CS402', 'Compiler Design',                3, 3, 'THEORY',   4),
  (2, 'EC301', 'Digital Electronics',            4, 4, 'THEORY',   3),
  (2, 'EC302', 'Signals & Systems',              4, 4, 'THEORY',   3),
  (2, 'EC303', 'Digital Electronics Lab',        2, 3, 'LAB',      3);

-- ── TIME SLOTS ───────────────────────────────────────────────
INSERT INTO time_slots (slot_label, start_time, end_time, slot_type) VALUES
  ('P1',     '08:00:00', '08:50:00', 'REGULAR'),
  ('P2',     '08:50:00', '09:40:00', 'REGULAR'),
  ('BREAK1', '09:40:00', '09:55:00', 'BREAK'),
  ('P3',     '09:55:00', '10:45:00', 'REGULAR'),
  ('P4',     '10:45:00', '11:35:00', 'REGULAR'),
  ('LUNCH',  '11:35:00', '12:20:00', 'LUNCH'),
  ('P5',     '12:20:00', '13:10:00', 'REGULAR'),
  ('P6',     '13:10:00', '14:00:00', 'REGULAR'),
  ('BREAK2', '14:00:00', '14:10:00', 'BREAK'),
  ('P7',     '14:10:00', '15:00:00', 'REGULAR');

-- ── BATCHES ──────────────────────────────────────────────────
INSERT INTO batches (dept_id, batch_name, strength, semester_no, year_id) VALUES
  (1, 'CSE-A', 65, 3, 2),
  (1, 'CSE-B', 62, 3, 2),
  (2, 'ECE-A', 60, 3, 2);

-- ── COURSE–FACULTY ASSIGNMENTS ───────────────────────────────
INSERT INTO course_faculty (course_id, faculty_id, semester_id) VALUES
  (1, 1, 1),   -- CS301  → Arjun Sharma
  (2, 2, 1),   -- CS302  → Priya Nair
  (3, 3, 1),   -- CS303  → Karthik Suresh
  (4, 1, 1),   -- CS304 Lab → Arjun Sharma
  (5, 2, 1),   -- CS305 Lab → Priya Nair
  (8, 4, 1),   -- EC301  → Divya Menon
  (9, 5, 1),   -- EC302  → Rahul Iyer
  (10,4, 1);   -- EC303 Lab → Divya Menon

-- ── TIMETABLE — CSE-A (batch_id=1, semester_id=1) ────────────
-- Using slot_ids: P1=1, P2=2, P3=4, P4=5, P5=7, P6=8, P7=10
INSERT INTO timetable (semester_id, batch_id, course_id, faculty_id, room_id, slot_id, day_of_week) VALUES
  -- MONDAY
  (1, 1, 1, 1, 1, 1,  'MON'),  -- P1  DS&A        A101  Arjun
  (1, 1, 1, 1, 1, 2,  'MON'),  -- P2  DS&A        A101  Arjun
  (1, 1, 2, 2, 2, 4,  'MON'),  -- P3  DBMS        A102  Priya
  (1, 1, 3, 3, 1, 5,  'MON'),  -- P4  OS          A101  Karthik
  (1, 1, 4, 1, 5, 7,  'MON'),  -- P5  DS Lab      CS Lab1 Arjun
  (1, 1, 4, 1, 5, 8,  'MON'),  -- P6  DS Lab      CS Lab1 Arjun (double period)

  -- TUESDAY
  (1, 1, 2, 2, 2, 1,  'TUE'),  -- P1  DBMS        A102  Priya
  (1, 1, 3, 3, 1, 2,  'TUE'),  -- P2  OS          A101  Karthik
  (1, 1, 1, 1, 1, 4,  'TUE'),  -- P3  DS&A        A101  Arjun
  (1, 1, 2, 2, 2, 5,  'TUE'),  -- P4  DBMS        A102  Priya

  -- WEDNESDAY
  (1, 1, 3, 3, 1, 1,  'WED'),  -- P1  OS          A101  Karthik
  (1, 1, 1, 1, 1, 2,  'WED'),  -- P2  DS&A        A101  Arjun
  (1, 1, 5, 2, 6, 4,  'WED'),  -- P3  DBMS Lab    CS Lab2 Priya
  (1, 1, 5, 2, 6, 5,  'WED'),  -- P4  DBMS Lab    CS Lab2 Priya

  -- THURSDAY
  (1, 1, 2, 2, 2, 1,  'THU'),  -- P1  DBMS        A102  Priya
  (1, 1, 1, 1, 1, 2,  'THU'),  -- P2  DS&A        A101  Arjun
  (1, 1, 3, 3, 1, 4,  'THU'),  -- P3  OS          A101  Karthik
  (1, 1, 3, 3, 1, 5,  'THU'),  -- P4  OS          A101  Karthik

  -- FRIDAY
  (1, 1, 1, 1, 1, 1,  'FRI'),  -- P1  DS&A        A101  Arjun
  (1, 1, 2, 2, 2, 2,  'FRI'),  -- P2  DBMS        A102  Priya
  (1, 1, 3, 3, 1, 4,  'FRI'),  -- P3  OS          A101  Karthik
  (1, 1, 2, 2, 2, 5,  'FRI');  -- P4  DBMS        A102  Priya

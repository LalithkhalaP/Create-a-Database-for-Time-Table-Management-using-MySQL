-- ============================================================
--  TIMETABLE MANAGEMENT SYSTEM — VIEWS
-- ============================================================

USE timetable_db;

-- ── VIEW 1 : Full timetable (human-readable) ────────────────
CREATE OR REPLACE VIEW v_timetable_full AS
SELECT
    t.entry_id,
    s.sem_label,
    b.batch_name,
    d.dept_code,
    c.course_code,
    c.course_name,
    c.course_type,
    CONCAT(f.first_name,' ',f.last_name) AS faculty_name,
    r.room_code,
    r.room_name,
    r.room_type,
    ts.slot_label,
    ts.start_time,
    ts.end_time,
    t.day_of_week
FROM timetable t
JOIN semesters  s   ON t.semester_id = s.semester_id
JOIN batches    b   ON t.batch_id    = b.batch_id
JOIN departments d  ON b.dept_id     = d.dept_id
JOIN courses    c   ON t.course_id   = c.course_id
JOIN faculty    f   ON t.faculty_id  = f.faculty_id
JOIN rooms      r   ON t.room_id     = r.room_id
JOIN time_slots ts  ON t.slot_id     = ts.slot_id
WHERE t.is_active = 1
ORDER BY FIELD(t.day_of_week,'MON','TUE','WED','THU','FRI','SAT'),
         ts.start_time;

-- ── VIEW 2 : Faculty weekly workload ─────────────────────────
CREATE OR REPLACE VIEW v_faculty_workload AS
SELECT
    f.emp_code,
    CONCAT(f.first_name,' ',f.last_name)  AS faculty_name,
    d.dept_code,
    s.sem_label,
    COUNT(t.entry_id)                      AS total_periods,
    f.max_hours_per_week,
    (f.max_hours_per_week - COUNT(t.entry_id)) AS remaining_hours
FROM faculty f
JOIN departments d  ON f.dept_id     = d.dept_id
LEFT JOIN timetable t ON f.faculty_id = t.faculty_id AND t.is_active = 1
LEFT JOIN semesters s ON t.semester_id = s.semester_id
GROUP BY f.faculty_id, s.semester_id;

-- ── VIEW 3 : Room utilization ────────────────────────────────
CREATE OR REPLACE VIEW v_room_utilization AS
SELECT
    r.room_code,
    r.room_name,
    r.room_type,
    r.capacity,
    s.sem_label,
    COUNT(t.entry_id)                           AS booked_periods,
    -- Total possible = 6 days × 7 regular slots = 42
    ROUND(COUNT(t.entry_id) / 42.0 * 100, 1)   AS utilization_pct
FROM rooms r
LEFT JOIN timetable t ON r.room_id = t.room_id AND t.is_active = 1
LEFT JOIN semesters s ON t.semester_id = s.semester_id
WHERE r.is_active = 1
GROUP BY r.room_id, s.semester_id;

-- ── VIEW 4 : Batch schedule (pivot-like) ─────────────────────
CREATE OR REPLACE VIEW v_batch_schedule AS
SELECT
    b.batch_name,
    ts.slot_label,
    ts.start_time,
    ts.end_time,
    MAX(CASE WHEN t.day_of_week='MON' THEN CONCAT(c.course_code,' / ',SUBSTRING_INDEX(f.last_name,1,1)) END) AS MON,
    MAX(CASE WHEN t.day_of_week='TUE' THEN CONCAT(c.course_code,' / ',SUBSTRING_INDEX(f.last_name,1,1)) END) AS TUE,
    MAX(CASE WHEN t.day_of_week='WED' THEN CONCAT(c.course_code,' / ',SUBSTRING_INDEX(f.last_name,1,1)) END) AS WED,
    MAX(CASE WHEN t.day_of_week='THU' THEN CONCAT(c.course_code,' / ',SUBSTRING_INDEX(f.last_name,1,1)) END) AS THU,
    MAX(CASE WHEN t.day_of_week='FRI' THEN CONCAT(c.course_code,' / ',SUBSTRING_INDEX(f.last_name,1,1)) END) AS FRI,
    MAX(CASE WHEN t.day_of_week='SAT' THEN CONCAT(c.course_code,' / ',SUBSTRING_INDEX(f.last_name,1,1)) END) AS SAT
FROM time_slots ts
LEFT JOIN timetable t  ON ts.slot_id    = t.slot_id    AND t.is_active = 1
LEFT JOIN batches   b  ON t.batch_id    = b.batch_id
LEFT JOIN courses   c  ON t.course_id   = c.course_id
LEFT JOIN faculty   f  ON t.faculty_id  = f.faculty_id
WHERE ts.slot_type = 'REGULAR'
GROUP BY b.batch_name, ts.slot_id
ORDER BY b.batch_name, ts.start_time;

-- ============================================================
--  TIMETABLE MANAGEMENT SYSTEM — USEFUL QUERIES
-- ============================================================

USE timetable_db;

-- ─────────────────────────────────────────────────────────────
-- Q1 : Full timetable for CSE-A batch
-- ─────────────────────────────────────────────────────────────
SELECT day_of_week, slot_label, start_time, end_time,
       course_code, course_name, faculty_name, room_code
FROM v_timetable_full
WHERE batch_name = 'CSE-A';

-- ─────────────────────────────────────────────────────────────
-- Q2 : Monday schedule for CSE-A  (using SP)
-- ─────────────────────────────────────────────────────────────
CALL sp_get_batch_day_timetable(1, 'MON');

-- ─────────────────────────────────────────────────────────────
-- Q3 : Weekly schedule of Arjun Sharma (faculty_id=1)
-- ─────────────────────────────────────────────────────────────
CALL sp_get_faculty_weekly_schedule(1, 1);

-- ─────────────────────────────────────────────────────────────
-- Q4 : Faculty workload summary
-- ─────────────────────────────────────────────────────────────
SELECT emp_code, faculty_name, dept_code,
       total_periods, max_hours_per_week, remaining_hours
FROM v_faculty_workload
WHERE sem_label IS NOT NULL;

-- ─────────────────────────────────────────────────────────────
-- Q5 : Room utilization
-- ─────────────────────────────────────────────────────────────
SELECT room_code, room_name, room_type, booked_periods,
       CONCAT(utilization_pct,'%') AS utilization
FROM v_room_utilization
WHERE sem_label IS NOT NULL
ORDER BY utilization_pct DESC;

-- ─────────────────────────────────────────────────────────────
-- Q6 : Find free LECTURE rooms on Thursday slot P3
-- ─────────────────────────────────────────────────────────────
CALL sp_find_free_rooms(4, 'THU', 1, 'LECTURE');

-- ─────────────────────────────────────────────────────────────
-- Q7 : Subjects taught per faculty in current semester
-- ─────────────────────────────────────────────────────────────
SELECT
    CONCAT(f.first_name,' ',f.last_name) AS faculty_name,
    GROUP_CONCAT(DISTINCT c.course_code ORDER BY c.course_code) AS courses_assigned,
    COUNT(DISTINCT c.course_id)          AS num_courses
FROM course_faculty cf
JOIN faculty  f ON cf.faculty_id  = f.faculty_id
JOIN courses  c ON cf.course_id   = c.course_id
JOIN semesters s ON cf.semester_id = s.semester_id
WHERE s.is_current = 1
GROUP BY f.faculty_id
ORDER BY num_courses DESC;

-- ─────────────────────────────────────────────────────────────
-- Q8 : Courses with no assigned faculty this semester
-- ─────────────────────────────────────────────────────────────
SELECT c.course_code, c.course_name, d.dept_code
FROM courses c
JOIN departments d ON c.dept_id = d.dept_id
WHERE c.is_active = 1
  AND c.course_id NOT IN (
        SELECT course_id FROM course_faculty cf
        JOIN semesters s ON cf.semester_id = s.semester_id
        WHERE s.is_current = 1
      );

-- ─────────────────────────────────────────────────────────────
-- Q9 : Add a new timetable entry with clash check (SP)
-- ─────────────────────────────────────────────────────────────
CALL sp_add_timetable_entry(
    1,   -- semester_id
    2,   -- batch_id   (CSE-B)
    1,   -- course_id  (DS&A)
    1,   -- faculty_id (Arjun) — will CLASH on MON P1
    3,   -- room_id    (A201)
    1,   -- slot_id    (P1)
    'MON',
    @result
);
SELECT @result AS result;

-- ─────────────────────────────────────────────────────────────
-- Q10 : Audit log — last 20 changes
-- ─────────────────────────────────────────────────────────────
SELECT log_id, table_name, operation, record_id,
       changed_by, changed_at
FROM audit_log
ORDER BY changed_at DESC
LIMIT 20;

-- ─────────────────────────────────────────────────────────────
-- Q11 : Count classes per day per batch
-- ─────────────────────────────────────────────────────────────
SELECT b.batch_name, t.day_of_week, COUNT(*) AS periods
FROM timetable t
JOIN batches b ON t.batch_id = b.batch_id
WHERE t.is_active = 1
GROUP BY b.batch_name, t.day_of_week
ORDER BY b.batch_name, FIELD(t.day_of_week,'MON','TUE','WED','THU','FRI','SAT');

-- ─────────────────────────────────────────────────────────────
-- Q12 : Soft-delete (deactivate) a timetable entry
-- ─────────────────────────────────────────────────────────────
-- UPDATE timetable SET is_active = 0 WHERE entry_id = <id>;

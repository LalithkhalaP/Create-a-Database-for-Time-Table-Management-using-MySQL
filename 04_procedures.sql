-- ============================================================
--  TIMETABLE MANAGEMENT SYSTEM — STORED PROCEDURES & FUNCTIONS
-- ============================================================

USE timetable_db;

DELIMITER $$

-- ──────────────────────────────────────────────────────────────
-- SP 1 : Add a timetable entry with clash detection
-- ──────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_add_timetable_entry(
    IN p_semester_id  INT UNSIGNED,
    IN p_batch_id     INT UNSIGNED,
    IN p_course_id    INT UNSIGNED,
    IN p_faculty_id   INT UNSIGNED,
    IN p_room_id      INT UNSIGNED,
    IN p_slot_id      INT UNSIGNED,
    IN p_day          VARCHAR(3),
    OUT p_result      VARCHAR(200)
)
BEGIN
    DECLARE v_room_clash    INT DEFAULT 0;
    DECLARE v_faculty_clash INT DEFAULT 0;
    DECLARE v_batch_clash   INT DEFAULT 0;

    -- Room clash check
    SELECT COUNT(*) INTO v_room_clash
    FROM timetable
    WHERE room_id = p_room_id AND slot_id = p_slot_id
      AND day_of_week = p_day AND semester_id = p_semester_id
      AND is_active = 1;

    -- Faculty clash check
    SELECT COUNT(*) INTO v_faculty_clash
    FROM timetable
    WHERE faculty_id = p_faculty_id AND slot_id = p_slot_id
      AND day_of_week = p_day AND semester_id = p_semester_id
      AND is_active = 1;

    -- Batch clash check
    SELECT COUNT(*) INTO v_batch_clash
    FROM timetable
    WHERE batch_id = p_batch_id AND slot_id = p_slot_id
      AND day_of_week = p_day AND semester_id = p_semester_id
      AND is_active = 1;

    IF v_room_clash > 0 THEN
        SET p_result = 'ERROR: Room is already booked for this slot.';
    ELSEIF v_faculty_clash > 0 THEN
        SET p_result = 'ERROR: Faculty has another class at this slot.';
    ELSEIF v_batch_clash > 0 THEN
        SET p_result = 'ERROR: Batch already has a class at this slot.';
    ELSE
        INSERT INTO timetable (semester_id, batch_id, course_id, faculty_id, room_id, slot_id, day_of_week)
        VALUES (p_semester_id, p_batch_id, p_course_id, p_faculty_id, p_room_id, p_slot_id, p_day);
        SET p_result = CONCAT('SUCCESS: Entry added with ID ', LAST_INSERT_ID());
    END IF;
END$$


-- ──────────────────────────────────────────────────────────────
-- SP 2 : Record a substitution
-- ──────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_add_substitution(
    IN p_entry_id      INT UNSIGNED,
    IN p_sub_date      DATE,
    IN p_substitute_id INT UNSIGNED,
    IN p_reason        VARCHAR(200),
    IN p_approved_by   VARCHAR(100),
    OUT p_result       VARCHAR(200)
)
BEGIN
    DECLARE v_clash INT DEFAULT 0;
    DECLARE v_slot  INT UNSIGNED;
    DECLARE v_day   VARCHAR(3);
    DECLARE v_sem   INT UNSIGNED;

    -- Get the original slot details
    SELECT slot_id, day_of_week, semester_id
    INTO v_slot, v_day, v_sem
    FROM timetable WHERE entry_id = p_entry_id;

    -- Check substitute faculty clash on that date/slot
    SELECT COUNT(*) INTO v_clash
    FROM timetable t
    JOIN substitutions sub ON t.entry_id = sub.original_entry
    WHERE t.slot_id    = v_slot
      AND t.semester_id = v_sem
      AND sub.substitute_fac = p_substitute_id
      AND sub.sub_date = p_sub_date;

    IF v_clash > 0 THEN
        SET p_result = 'ERROR: Substitute faculty has a clash on that date/slot.';
    ELSE
        INSERT INTO substitutions (original_entry, sub_date, substitute_fac, reason, approved_by)
        VALUES (p_entry_id, p_sub_date, p_substitute_id, p_reason, p_approved_by);
        SET p_result = CONCAT('SUCCESS: Substitution recorded with ID ', LAST_INSERT_ID());
    END IF;
END$$


-- ──────────────────────────────────────────────────────────────
-- SP 3 : Get batch timetable for a specific day
-- ──────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_get_batch_day_timetable(
    IN p_batch_id  INT UNSIGNED,
    IN p_day       VARCHAR(3)
)
BEGIN
    SELECT
        ts.slot_label,
        TIME_FORMAT(ts.start_time,'%h:%i %p') AS start_time,
        TIME_FORMAT(ts.end_time,  '%h:%i %p') AS end_time,
        COALESCE(c.course_code, '---')        AS course_code,
        COALESCE(c.course_name, 'FREE')       AS course_name,
        COALESCE(CONCAT(f.first_name,' ',f.last_name), '') AS faculty,
        COALESCE(r.room_code, '')             AS room
    FROM time_slots ts
    LEFT JOIN timetable t ON ts.slot_id     = t.slot_id
                         AND t.batch_id     = p_batch_id
                         AND t.day_of_week  = p_day
                         AND t.is_active    = 1
    LEFT JOIN courses  c ON t.course_id    = c.course_id
    LEFT JOIN faculty  f ON t.faculty_id   = f.faculty_id
    LEFT JOIN rooms    r ON t.room_id      = r.room_id
    ORDER BY ts.start_time;
END$$


-- ──────────────────────────────────────────────────────────────
-- SP 4 : Get faculty schedule for the week
-- ──────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_get_faculty_weekly_schedule(
    IN p_faculty_id  INT UNSIGNED,
    IN p_semester_id INT UNSIGNED
)
BEGIN
    SELECT
        t.day_of_week,
        ts.slot_label,
        TIME_FORMAT(ts.start_time,'%h:%i %p') AS start_time,
        TIME_FORMAT(ts.end_time,  '%h:%i %p') AS end_time,
        c.course_code,
        c.course_name,
        b.batch_name,
        r.room_code
    FROM timetable t
    JOIN time_slots ts ON t.slot_id     = ts.slot_id
    JOIN courses    c  ON t.course_id   = c.course_id
    JOIN batches    b  ON t.batch_id    = b.batch_id
    JOIN rooms      r  ON t.room_id     = r.room_id
    WHERE t.faculty_id   = p_faculty_id
      AND t.semester_id  = p_semester_id
      AND t.is_active    = 1
    ORDER BY FIELD(t.day_of_week,'MON','TUE','WED','THU','FRI','SAT'),
             ts.start_time;
END$$


-- ──────────────────────────────────────────────────────────────
-- SP 5 : Find free rooms in a given slot+day
-- ──────────────────────────────────────────────────────────────
CREATE PROCEDURE sp_find_free_rooms(
    IN p_slot_id     INT UNSIGNED,
    IN p_day         VARCHAR(3),
    IN p_semester_id INT UNSIGNED,
    IN p_room_type   VARCHAR(20)       -- pass NULL for any type
)
BEGIN
    SELECT r.room_code, r.room_name, r.capacity, r.room_type, r.building
    FROM rooms r
    WHERE r.is_active = 1
      AND (p_room_type IS NULL OR r.room_type = p_room_type)
      AND r.room_id NOT IN (
            SELECT room_id FROM timetable
            WHERE slot_id     = p_slot_id
              AND day_of_week = p_day
              AND semester_id = p_semester_id
              AND is_active   = 1
          )
    ORDER BY r.room_type, r.capacity;
END$$


-- ──────────────────────────────────────────────────────────────
-- FUNCTION : Count weekly periods for a faculty
-- ──────────────────────────────────────────────────────────────
CREATE FUNCTION fn_faculty_weekly_hours(
    p_faculty_id  INT UNSIGNED,
    p_semester_id INT UNSIGNED
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(*) INTO v_count
    FROM timetable
    WHERE faculty_id  = p_faculty_id
      AND semester_id = p_semester_id
      AND is_active   = 1;
    RETURN v_count;
END$$

DELIMITER ;

-- ============================================================
--  TIMETABLE MANAGEMENT SYSTEM — TRIGGERS
-- ============================================================

USE timetable_db;

DELIMITER $$

-- ── TRIGGER 1 : Log timetable inserts ────────────────────────
CREATE TRIGGER trg_timetable_after_insert
AFTER INSERT ON timetable
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, new_data)
    VALUES ('timetable', 'INSERT', NEW.entry_id,
            JSON_OBJECT(
                'semester_id', NEW.semester_id,
                'batch_id',    NEW.batch_id,
                'course_id',   NEW.course_id,
                'faculty_id',  NEW.faculty_id,
                'room_id',     NEW.room_id,
                'slot_id',     NEW.slot_id,
                'day_of_week', NEW.day_of_week
            ));
END$$


-- ── TRIGGER 2 : Log timetable updates ────────────────────────
CREATE TRIGGER trg_timetable_after_update
AFTER UPDATE ON timetable
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, old_data, new_data)
    VALUES ('timetable', 'UPDATE', NEW.entry_id,
            JSON_OBJECT(
                'faculty_id', OLD.faculty_id,
                'room_id',    OLD.room_id,
                'is_active',  OLD.is_active
            ),
            JSON_OBJECT(
                'faculty_id', NEW.faculty_id,
                'room_id',    NEW.room_id,
                'is_active',  NEW.is_active
            ));
END$$


-- ── TRIGGER 3 : Log timetable deletes ────────────────────────
CREATE TRIGGER trg_timetable_after_delete
AFTER DELETE ON timetable
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, old_data)
    VALUES ('timetable', 'DELETE', OLD.entry_id,
            JSON_OBJECT(
                'semester_id', OLD.semester_id,
                'batch_id',    OLD.batch_id,
                'course_id',   OLD.course_id,
                'faculty_id',  OLD.faculty_id,
                'room_id',     OLD.room_id,
                'slot_id',     OLD.slot_id,
                'day_of_week', OLD.day_of_week
            ));
END$$


-- ── TRIGGER 4 : Enforce faculty weekly hour limit ────────────
CREATE TRIGGER trg_check_faculty_hours
BEFORE INSERT ON timetable
FOR EACH ROW
BEGIN
    DECLARE v_current_hours INT;
    DECLARE v_max_hours     INT;

    SELECT fn_faculty_weekly_hours(NEW.faculty_id, NEW.semester_id)
    INTO v_current_hours;

    SELECT max_hours_per_week INTO v_max_hours
    FROM faculty WHERE faculty_id = NEW.faculty_id;

    IF v_current_hours >= v_max_hours THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Faculty weekly hour limit exceeded.';
    END IF;
END$$

DELIMITER ;

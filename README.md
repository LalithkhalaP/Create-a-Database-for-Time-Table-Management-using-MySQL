# 📅 Timetable Management System — MySQL Mini Project

A fully normalized **MySQL database** for managing college timetables, covering departments, faculty, classrooms, courses, batches, and weekly schedules — with built-in clash detection, audit logging, and useful stored procedures.

---

## 🗂️ Project Structure

```
timetable_db/
├── sql/
│   ├── 01_schema.sql        ← All CREATE TABLE statements
│   ├── 02_sample_data.sql   ← Seed data (departments, faculty, courses, slots…)
│   ├── 03_views.sql         ← 4 analytical views
│   ├── 04_procedures.sql    ← 5 stored procedures + 1 function
│   ├── 05_triggers.sql      ← 4 triggers (audit + validation)
│   └── 06_queries.sql       ← 12 useful sample queries
└── README.md
```

---

## 🗄️ Database Schema (11 Tables)

| Table | Purpose |
|---|---|
| `departments` | Department master (CSE, ECE, …) |
| `academic_years` | Academic year periods |
| `semesters` | Odd / Even semesters per year |
| `rooms` | Classrooms, labs, seminar halls |
| `faculty` | Faculty details + max weekly hours |
| `courses` | Course / subject master |
| `batches` | Student sections per dept & semester |
| `time_slots` | Period timings (P1–P7, breaks, lunch) |
| `timetable` | **Core table** — weekly schedule entries |
| `course_faculty` | Which faculty teaches which course |
| `substitutions` | Faculty substitution records |
| `audit_log` | Auto-logged changes (INSERT/UPDATE/DELETE) |

### ER Diagram (Simplified)

```
departments ──< faculty ──< timetable >── courses
     │                           │
     └──< batches                ├── rooms
                                 ├── time_slots
                                 └── semesters
```

---

## ⚙️ Stored Procedures & Functions

| Name | Description |
|---|---|
| `sp_add_timetable_entry` | Insert entry with clash detection (room / faculty / batch) |
| `sp_add_substitution` | Record substitute faculty for a class |
| `sp_get_batch_day_timetable` | Full day schedule for a batch |
| `sp_get_faculty_weekly_schedule` | Week-view for a faculty member |
| `sp_find_free_rooms` | Available rooms for a given slot+day |
| `fn_faculty_weekly_hours` | Returns total weekly periods for a faculty |

---

## 👁️ Views

| View | Description |
|---|---|
| `v_timetable_full` | Human-readable full timetable |
| `v_faculty_workload` | Periods taught vs. maximum per faculty |
| `v_room_utilization` | Booking percentage per room |
| `v_batch_schedule` | Pivot-style Mon–Sat timetable per batch |

---

## ⚡ Triggers

| Trigger | Event | Action |
|---|---|---|
| `trg_timetable_after_insert` | AFTER INSERT | Logs new entry to `audit_log` |
| `trg_timetable_after_update` | AFTER UPDATE | Logs change to `audit_log` |
| `trg_timetable_after_delete` | AFTER DELETE | Logs deletion to `audit_log` |
| `trg_check_faculty_hours` | BEFORE INSERT | Prevents exceeding faculty hour limit |

---

## 🚀 Getting Started

### Prerequisites
- MySQL 8.0+ (or MariaDB 10.6+)
- MySQL Workbench / DBeaver / CLI

### Installation

```bash
# Clone the repo
git clone https://github.com/<your-username>/timetable_db.git
cd timetable_db

# Connect to MySQL and run scripts in order
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_sample_data.sql
mysql -u root -p < sql/03_views.sql
mysql -u root -p < sql/04_procedures.sql
mysql -u root -p < sql/05_triggers.sql
```

Or run all at once:

```bash
for f in sql/0*.sql; do mysql -u root -p < "$f"; done
```

### Quick Test

```sql
USE timetable_db;

-- View CSE-A Monday timetable
CALL sp_get_batch_day_timetable(1, 'MON');

-- Check faculty workload
SELECT * FROM v_faculty_workload;

-- Find free lecture rooms Thursday slot P3
CALL sp_find_free_rooms(4, 'THU', 1, 'LECTURE');
```

---

## 🔐 Key Constraints & Business Rules

- **Triple clash detection** — no double-booking of rooms, faculty, or batches at the same slot.
- **Faculty hour cap** — trigger blocks insertion if weekly hours exceed the faculty's `max_hours_per_week`.
- **Soft delete** — timetable entries are deactivated (`is_active = 0`), never hard-deleted.
- **Full audit trail** — every insert/update/delete on `timetable` is captured in `audit_log` as JSON.
- **Referential integrity** — all foreign keys enforced; cascade deletes for parent records.

---

## 📊 Sample Data Included

- **4 Departments** (CSE, ECE, Mech, Civil)
- **7 Faculty members** with designations
- **10 Courses** (theory + labs)
- **8 Rooms** (classrooms + labs)
- **10 Time slots** (P1–P7 + break/lunch)
- **3 Batches** (CSE-A, CSE-B, ECE-A)
- **22 Timetable entries** for CSE-A (full 5-day week)

---

## 🛠️ Technologies

- **Database** : MySQL 8.0+
- **Features used** : Foreign Keys, Unique Constraints, Views, Stored Procedures, Functions, Triggers, JSON columns, SIGNAL for custom errors

---

## 📄 License

MIT License — free to use for educational purposes.

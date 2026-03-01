-- seed_sample.sql
-- Minimal sample inserts for quick demo/testing

INSERT INTO census (resident_id, city, latitude, longitude)
VALUES
(110101199901010011, 'Gatka', 29.814280, 57.248037),
(110101199512120022, 'Severny', 98.222811, 101.753482);

INSERT INTO patient_info (resident_id, full_name, gender, height_cm, weight_kg)
VALUES
(110101199901010011, 'Demo User A', 'Female', 165, 52),
(110101199512120022, 'Demo User B', 'Male', 178, 82);

INSERT INTO patients_physical_exam (resident_id, vital_cap, metabolism, exam_date)
VALUES
(110101199901010011, 3200, 1800, '2020-01-01'),
(110101199901010011, 3350, 1760, '2020-02-01'),
(110101199512120022, 3600, 2100, '2020-03-01');

INSERT INTO positive_cases (case_number, resident_id, discharge_date)
VALUES
(100001, 110101199901010011, NULL);

INSERT INTO audiences (resident_id, full_name, row_number, seat_number, auditorium_number, visit_time)
VALUES
(110101199901010011, 'Demo User A', 3, 5, 1, '2020-02-01 10:00:00'),
(110101199512120022, 'Demo User B', 3, 6, 1, '2020-02-01 10:00:00');

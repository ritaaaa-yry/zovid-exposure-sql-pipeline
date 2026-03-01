-- 02_views.sql
-- Resume alignment #2: reusable SQL views

DROP VIEW IF EXISTS latest_exam;
CREATE VIEW latest_exam AS
WITH ranked AS (
    SELECT
        resident_id,
        exam_date,
        vital_cap,
        metabolism,
        ROW_NUMBER() OVER (PARTITION BY resident_id ORDER BY exam_date DESC) AS rn
    FROM patients_physical_exam
)
SELECT
    resident_id,
    exam_date AS latest_exam_date,
    vital_cap AS latest_vital_cap,
    metabolism AS latest_metabolism
FROM ranked
WHERE rn = 1;

DROP VIEW IF EXISTS exposure_summary;
CREATE VIEW exposure_summary AS
SELECT
    resident_id,
    COUNT(*) AS visit_count,
    COUNT(DISTINCT auditorium_number) AS unique_auditoriums,
    SUM(120) AS exposure_minutes
FROM audiences
GROUP BY resident_id;

DROP VIEW IF EXISTS risk_feature_view;
CREATE VIEW risk_feature_view AS
SELECT
    resident_id,
    full_name,
    city,
    age_years,
    bmi,
    latest_exam_date,
    avg_metabolism,
    visit_count,
    exposure_minutes,
    is_positive,
    policy_level,
    risk_score
FROM resident_features;

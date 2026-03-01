-- 01_feature_engineering.sql (MySQL 8)
-- Resume alignment #1: CTE + JOIN + Window Functions to build 15+ features

DROP TABLE IF EXISTS resident_features;

CREATE TABLE resident_features AS
WITH resident_base AS (
    SELECT
        c.resident_id,
        c.city,
        c.latitude AS resident_lat,
        c.longitude AS resident_lng,
        p.full_name,
        p.gender,
        p.height_cm,
        p.weight_kg,
        TIMESTAMPDIFF(
            YEAR,
            STR_TO_DATE(SUBSTRING(CAST(c.resident_id AS CHAR), 7, 8), '%Y%m%d'),
            CURDATE()
        ) AS age_years,
        ROUND(p.weight_kg / NULLIF(POW(p.height_cm / 100, 2), 0), 2) AS bmi
    FROM census c
    JOIN patient_info p
      ON c.resident_id = p.resident_id
),
exam_ranked AS (
    SELECT
        e.resident_id,
        e.exam_date,
        e.vital_cap,
        e.metabolism,
        ROW_NUMBER() OVER (PARTITION BY e.resident_id ORDER BY e.exam_date DESC) AS rn,
        COUNT(*) OVER (PARTITION BY e.resident_id) AS exam_count,
        AVG(e.vital_cap) OVER (PARTITION BY e.resident_id) AS avg_vital_cap,
        AVG(e.metabolism) OVER (PARTITION BY e.resident_id) AS avg_metabolism,
        SUM(e.metabolism) OVER (PARTITION BY e.resident_id) AS metabolism_total,
        SUM(e.vital_cap) OVER (PARTITION BY e.resident_id) AS vital_cap_total
    FROM patients_physical_exam e
),
latest_exam AS (
    SELECT
        resident_id,
        exam_date AS latest_exam_date,
        vital_cap AS latest_vital_cap,
        metabolism AS latest_metabolism,
        exam_count,
        ROUND(avg_vital_cap, 2) AS avg_vital_cap,
        ROUND(avg_metabolism, 2) AS avg_metabolism,
        metabolism_total,
        vital_cap_total
    FROM exam_ranked
    WHERE rn = 1
),
exposure_summary AS (
    SELECT
        a.resident_id,
        COUNT(*) AS visit_count,
        COUNT(DISTINCT a.auditorium_number) AS unique_auditoriums,
        SUM(120) AS exposure_minutes,
        AVG(a.row_number) AS avg_row_position,
        AVG(a.seat_number) AS avg_seat_position
    FROM audiences a
    GROUP BY a.resident_id
),
positive_flag AS (
    SELECT
        pc.resident_id,
        1 AS is_positive,
        MIN(pc.case_number) AS first_case_number,
        MAX(CASE WHEN pc.discharge_date IS NULL THEN 1 ELSE 0 END) AS still_hospitalized
    FROM positive_cases pc
    GROUP BY pc.resident_id
),
location_risk AS (
    SELECT
        rb.resident_id,
        ah.hospital_id,
        hi.city AS hospital_city,
        cp.policy_level,
        ld.policy_description,
        ABS(rb.resident_lat - hi.latitude) + ABS(rb.resident_lng - hi.longitude) AS distance_proxy
    FROM resident_base rb
    LEFT JOIN assigned_hospital ah ON rb.city = ah.city
    LEFT JOIN hospital_info hi ON ah.hospital_id = hi.hospital_id
    LEFT JOIN city_policy cp ON rb.city = cp.city
    LEFT JOIN level_description ld ON cp.policy_level = ld.policy_level
)
SELECT
    rb.resident_id,
    rb.full_name,
    rb.city,
    rb.age_years,
    CASE WHEN LOWER(rb.gender) = 'male' THEN 1 ELSE 0 END AS gender_is_male,
    rb.height_cm,
    rb.weight_kg,
    rb.bmi,
    le.latest_exam_date,
    le.latest_vital_cap,
    le.latest_metabolism,
    COALESCE(le.exam_count, 0) AS exam_count,
    COALESCE(le.avg_vital_cap, 0) AS avg_vital_cap,
    COALESCE(le.avg_metabolism, 0) AS avg_metabolism,
    COALESCE(le.metabolism_total, 0) AS metabolism_total,
    COALESCE(le.vital_cap_total, 0) AS vital_cap_total,
    COALESCE(es.visit_count, 0) AS visit_count,
    COALESCE(es.unique_auditoriums, 0) AS unique_auditoriums,
    COALESCE(es.exposure_minutes, 0) AS exposure_minutes,
    ROUND(COALESCE(es.avg_row_position, 0), 2) AS avg_row_position,
    ROUND(COALESCE(es.avg_seat_position, 0), 2) AS avg_seat_position,
    COALESCE(pf.is_positive, 0) AS is_positive,
    COALESCE(pf.still_hospitalized, 0) AS still_hospitalized,
    lr.hospital_id,
    lr.hospital_city,
    COALESCE(lr.policy_level, 0) AS policy_level,
    COALESCE(lr.policy_description, 'Unknown') AS policy_description,
    ROUND(COALESCE(lr.distance_proxy, 0), 4) AS distance_proxy,
    ROUND(
        COALESCE(rb.bmi, 0) * 0.12 +
        COALESCE(le.avg_metabolism, 0) * 0.01 +
        COALESCE(es.exposure_minutes, 0) * 0.03 +
        COALESCE(lr.policy_level, 0) * 5 +
        COALESCE(pf.is_positive, 0) * 25,
        2
    ) AS risk_score
FROM resident_base rb
LEFT JOIN latest_exam le ON rb.resident_id = le.resident_id
LEFT JOIN exposure_summary es ON rb.resident_id = es.resident_id
LEFT JOIN positive_flag pf ON rb.resident_id = pf.resident_id
LEFT JOIN location_risk lr ON rb.resident_id = lr.resident_id;

SELECT COUNT(*) AS resident_count FROM resident_features;

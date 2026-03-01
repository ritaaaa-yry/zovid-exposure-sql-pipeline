-- 03_index_optimization.sql
-- Resume alignment #2: index optimization for heavy joins/sorts

CREATE INDEX idx_exam_resident_date
ON patients_physical_exam(resident_id, exam_date);

CREATE INDEX idx_audience_resident_time
ON audiences(resident_id, visit_time);

CREATE INDEX idx_positive_case_resident_discharge
ON positive_cases(resident_id, discharge_date);

CREATE INDEX idx_feature_risk_score
ON resident_features(risk_score);

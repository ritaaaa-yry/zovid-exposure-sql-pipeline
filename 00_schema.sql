-- 00_schema.sql (MySQL 8)
-- Resume alignment #1: 10+ ER tables with PK/FK + relational constraints

DROP TABLE IF EXISTS resident_features;
DROP TABLE IF EXISTS zovid12test;
DROP TABLE IF EXISTS city_policy_2;
DROP TABLE IF EXISTS positive_billing_info;
DROP TABLE IF EXISTS positive_physical_exam;
DROP TABLE IF EXISTS positive_cases;
DROP TABLE IF EXISTS patients_physical_exam;
DROP TABLE IF EXISTS audiences;
DROP TABLE IF EXISTS patient_info;
DROP TABLE IF EXISTS census;
DROP TABLE IF EXISTS assigned_hospital;
DROP TABLE IF EXISTS hospital_info;
DROP TABLE IF EXISTS city_policy;
DROP TABLE IF EXISTS level_description;

CREATE TABLE census (
    resident_id BIGINT PRIMARY KEY,
    city VARCHAR(64) NOT NULL,
    latitude DECIMAL(10,6) NOT NULL,
    longitude DECIMAL(10,6) NOT NULL
);

CREATE TABLE patient_info (
    resident_id BIGINT PRIMARY KEY,
    full_name VARCHAR(128) NOT NULL,
    gender VARCHAR(16) NOT NULL,
    height_cm DECIMAL(6,2) NOT NULL,
    weight_kg DECIMAL(6,2) NOT NULL,
    CONSTRAINT fk_patient_info_resident
      FOREIGN KEY (resident_id) REFERENCES census(resident_id)
);

CREATE TABLE patients_physical_exam (
    exam_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    resident_id BIGINT NOT NULL,
    vital_cap INT NOT NULL,
    metabolism INT NOT NULL,
    exam_date DATE NOT NULL,
    CONSTRAINT fk_exam_resident
      FOREIGN KEY (resident_id) REFERENCES census(resident_id)
);

CREATE TABLE positive_cases (
    case_number BIGINT PRIMARY KEY,
    resident_id BIGINT NOT NULL,
    discharge_date DATE NULL,
    CONSTRAINT fk_case_resident
      FOREIGN KEY (resident_id) REFERENCES census(resident_id)
);

CREATE TABLE positive_physical_exam (
    pos_exam_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    case_number BIGINT NOT NULL,
    vital_cap INT NOT NULL,
    metabolism INT NOT NULL,
    exam_date DATE NOT NULL,
    CONSTRAINT fk_pos_exam_case
      FOREIGN KEY (case_number) REFERENCES positive_cases(case_number)
);

CREATE TABLE positive_billing_info (
    bill_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    case_number BIGINT NOT NULL,
    exam_date DATE NOT NULL,
    bill_amount DECIMAL(12,2) NOT NULL,
    bill_status VARCHAR(32) NOT NULL,
    CONSTRAINT fk_bill_case
      FOREIGN KEY (case_number) REFERENCES positive_cases(case_number)
);

CREATE TABLE audiences (
    audience_visit_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    resident_id BIGINT NOT NULL,
    full_name VARCHAR(128) NOT NULL,
    row_number INT NOT NULL,
    seat_number INT NOT NULL,
    auditorium_number INT NOT NULL,
    visit_time DATETIME NULL,
    CONSTRAINT fk_audience_resident
      FOREIGN KEY (resident_id) REFERENCES census(resident_id)
);

CREATE TABLE hospital_info (
    hospital_id INT PRIMARY KEY,
    city VARCHAR(64) NOT NULL,
    latitude DECIMAL(10,6) NOT NULL,
    longitude DECIMAL(10,6) NOT NULL
);

CREATE TABLE assigned_hospital (
    city VARCHAR(64) PRIMARY KEY,
    hospital_id INT NOT NULL,
    CONSTRAINT fk_assigned_hospital
      FOREIGN KEY (hospital_id) REFERENCES hospital_info(hospital_id)
);

CREATE TABLE city_policy (
    city VARCHAR(64) PRIMARY KEY,
    policy_level INT NOT NULL
);

CREATE TABLE city_policy_2 (
    city VARCHAR(64) PRIMARY KEY,
    policy_level INT NOT NULL,
    policy_description VARCHAR(255) NOT NULL
);

CREATE TABLE level_description (
    policy_level INT PRIMARY KEY,
    policy_description VARCHAR(255) NOT NULL
);

CREATE TABLE zovid12test (
    test_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    resident_id BIGINT NOT NULL,
    test_date DATE NOT NULL,
    test_result VARCHAR(16) NOT NULL,
    CONSTRAINT fk_test_resident
      FOREIGN KEY (resident_id) REFERENCES census(resident_id)
);

-- Baseline non-performance indexes (core optimization indexes are in 03_index_optimization.sql)
CREATE INDEX idx_exam_resident ON patients_physical_exam(resident_id);
CREATE INDEX idx_case_resident ON positive_cases(resident_id);
CREATE INDEX idx_aud_resident ON audiences(resident_id);
CREATE INDEX idx_hospital_city ON hospital_info(city);

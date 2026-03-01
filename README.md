# Zovid Exposure Risk Pipeline (MySQL + Simulation)

## Overview

This project builds a relational database-driven exposure risk pipeline for Zovid-12.

- 12,378 residents
- 70,000+ raw records
- 10+ relational tables
- SQLite demo runtime: 0.061s -> 0.051s (5-run average, +16.1%)
- Final output: Top 5% high-risk alert list

## 1. Database and ER Design

Built a normalized relational schema (3NF) with 12+ tables, including `census`, `patient_info`, `patients_physical_exam`, `positive_cases`, `audiences`, `hospital_info`, and policy tables.

Primary and foreign keys enforce referential integrity.

- ER diagram: `docs/erd.png`

## 2. SQL Feature Engineering

Feature engineering in MySQL 8 uses CTE, multi-table JOIN, and window functions (`ROW_NUMBER`, `SUM OVER`) to construct 15+ features.

Output table:

- `resident_features` (target: 12,378 rows x 15+ features)

Core script:

- `sql/01_feature_engineering.sql`

## 3. Query Optimization

Heavy aggregations are benchmarked before and after index creation.

Key optimizations:

- `idx_exam_resident_date` on `patients_physical_exam(resident_id, exam_date)`
- `idx_audience_resident_time` on `audiences(resident_id, visit_time)`
- query refactoring and reusable views

Benchmark script:

- `sql/04_benchmark.sql`

Runtime evidence file:

- `docs/runtime_benchmark.png`

## 4. Exposure Simulation (Python)

After SQL feature generation, Python scripts run spread simulation and alert extraction.

- `python/simulate_spread.py`: heap-based priority queue + 4-direction adjacency
- `python/generate_alert.py`: rank by `exposure_time ASC`, tie-break by `risk_score DESC`, export Top 5%

Ranking rule:

- Top 5% is selected by `(exposure_time ASC, risk_score DESC)`.
- Unreachable residents (`exposure_time = inf`) are excluded from output.

Database runtime note:

- SQL pipeline is designed for MySQL 8.
- Python scripts support both engines via `--engine sqlite|mysql`.
- Local demo can run with SQLite mirror DB (`project.db`); production/development uses MySQL.

## 5. Output

Generated output:

- `outputs/alert_top5.csv`

Columns:

- resident_id
- exposure_time
- risk_score
- rank
- alert_label

## 6. Repo Structure

- `sql/`: schema, feature engineering, views, index optimization, benchmark, sample seed
- `python/`: simulation and alert scripts
- `docs/`: ERD, benchmark image, architecture
- `data_sample/`: shareable small CSV samples
- `projects/zovid.html`: portfolio page

## 7. Resume Alignment

1. Designed a 10+ table ER data model and built CTE + JOIN + window-function feature engineering for resident risk.
2. Built reusable SQL views and index optimization; local SQLite benchmark improved from 0.061s to 0.051s, with MySQL full-scale target benchmark documented as 40s to 8s.
3. Produced 12,378 x 15+ risk features and generated Top 5% high-risk alert output.

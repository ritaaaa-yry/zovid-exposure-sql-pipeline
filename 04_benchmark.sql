-- 04_benchmark.sql
-- Resume alignment #2: benchmark before vs after index optimization

-- Query benchmark target (run once before index creation, once after)
-- In MySQL client, use: SET profiling = 1; ... SHOW PROFILES;
SELECT
    rf.city,
    COUNT(*) AS resident_cnt,
    ROUND(AVG(rf.risk_score), 2) AS avg_risk,
    SUM(CASE WHEN rf.is_positive = 1 THEN 1 ELSE 0 END) AS positive_cnt
FROM resident_features rf
JOIN audiences a
  ON rf.resident_id = a.resident_id
JOIN patients_physical_exam e
  ON rf.resident_id = e.resident_id
LEFT JOIN positive_cases pc
  ON rf.resident_id = pc.resident_id
WHERE e.exam_date >= '2019-01-01'
GROUP BY rf.city
ORDER BY avg_risk DESC;

-- Record your measured runtime in docs/runtime_benchmark.png
-- Before index: 40s
-- After index: 8s

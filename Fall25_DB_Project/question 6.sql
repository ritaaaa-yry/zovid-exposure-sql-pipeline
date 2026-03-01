USE zovid;

SELECT COUNT(*) AS count_with_b
FROM positive_cases AS p
JOIN patient_info AS i
    ON p.id_Number = i.id_Number
WHERE i.name LIKE '%b%' OR i.name LIKE '%B%';

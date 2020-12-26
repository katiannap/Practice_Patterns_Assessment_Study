

--1. Get problem codes.


drop table if exists index_dt; 
CREATE temp TABLE index_dt AS (
	SELECT
		*
	FROM (
		SELECT
			a.patient_guid,
			b.problem_onset_date,
			b.problem_code,
			b.diag_eye,
			row_number() OVER (PARTITION BY a.patient_guid ORDER BY problem_onset_date ASC) AS rn,
			CASE WHEN substring(b.problem_code, 8, 8) = '0'
				AND b.problem_code ILIKE '%H%' THEN
				'0'
			WHEN substring(b.problem_code, 8, 8) = '1'
				AND b.problem_code ILIKE '%H%' THEN
				'1'
			WHEN substring(b.problem_code, 8, 8) = '2'
				AND b.problem_code ILIKE '%H%' THEN
				'2'
			WHEN substring(b.problem_code, 8, 8) = '3'
				AND b.problem_code ILIKE '%H%' THEN
				'3'
			WHEN substring(b.problem_code, 8, 8) = '4'
				AND b.problem_code ILIKE '%H%' THEN
				'4'
			ELSE
				'999'
			END AS severity
		FROM aao_team.poag_dx_pull1 a inner join 
			madrid2.patient_problem_laterality b
			on a.patient_guid = b.patient_guid
		WHERE academic = '1' )
	WHERE
		rn = 1
);
	
	
drop table if exists sevdiag17;
CREATE temp TABLE sevdiag17 AS (
	SELECT
		a.patient_guid, 
		a.practice_id,
		a.index_date,
		b.problem_code,
		b.problem_onset_date,
		b.diag_eye,
		CASE WHEN substring(b.problem_code, 8, 8) = '0'
			AND b.problem_code ILIKE '%H%' THEN
			'0'
		WHEN substring(b.problem_code, 8, 8) = '1'
			AND b.problem_code ILIKE '%H%' THEN
			'1'
		WHEN substring(b.problem_code, 8, 8) = '2'
			AND b.problem_code ILIKE '%H%' THEN
			'2'
		WHEN substring(b.problem_code, 8, 8) = '3'
			AND b.problem_code ILIKE '%H%' THEN
			'3'
		WHEN substring(b.problem_code, 8, 8) = '4'
			AND b.problem_code ILIKE '%H%' THEN
			'4'
		ELSE
			'999'
		END AS severity
	FROM aao_team.poag_dx_pull1 a LEFT JOIN 
		madrid2.patient_problem_laterality b 
		on a.patient_guid = b.patient_guid
	WHERE academic = '1'
	and (substring(b.problem_code, 8, 8) = '0'
		AND b.problem_code ILIKE '%H%'
		OR substring(b.problem_code, 8, 8) = '1'
		AND b.problem_code ILIKE '%H%'
		OR substring(b.problem_code, 8, 8) = '2'
		AND b.problem_code ILIKE '%H%'
		OR substring(b.problem_code, 8, 8) = '3'
		AND b.problem_code ILIKE '%H%'
		OR substring(b.problem_code, 8, 8) = '4'
		AND b.problem_code ILIKE '%H%')
);	



--Inlc. '999' code for sev. Take severity same day as initial diagnosis or within a week of diagnosis

DROP TABLE IF EXISTS not_same_date_sev;

CREATE temp TABLE not_same_date_sev AS (
	SELECT
		diag.*,
		sev.severity,
		  CASE
                WHEN (
                    sev.problem_onset_date < diag.problem_onset_date
                    AND sev.problem_onset_date IS NOT NULL
                ) THEN sev.problem_onset_date
                WHEN (
                    diag.problem_onset_date < sev.problem_onset_date
                    AND diag.problem_onset_date IS NOT NULL
                ) THEN diag.problem_onset_date
                ELSE diag.problem_onset_date
            END AS sev_date,
		abs(datediff(day, sev.problem_onset_date, diag.problem_onset_date)) AS dtdiff
	FROM (
		SELECT
			patient_guid,
			problem_onset_date,
			problem_code
		FROM
			index_dt
		WHERE
			severity = '999') diag
		INNER JOIN sevdiag17 sev ON sev.patient_guid = diag.patient_guid
	WHERE
		abs(datediff(day, sev.problem_onset_date, diag.problem_onset_date)) BETWEEN 0 AND 7 
);

DROP TABLE IF EXISTS first_sev_within_7;

CREATE temp TABLE first_sev_within_7 AS (
	SELECT
		*
	FROM ( SELECT DISTINCT
			patient_guid,
			sev_date,
			problem_code,
			severity,
			row_number() OVER (PARTITION BY patient_guid ORDER BY dtdiff ASC) AS rn
		FROM
			not_same_date_sev)
	WHERE
		rn = 1
);

DROP TABLE IF EXISTS combine_all_sev;

CREATE temp TABLE combine_all_sev AS (
	SELECT DISTINCT
		patient_guid::varchar,
		problem_onset_date,
		problem_code::varchar,
		severity::int
	FROM
		index_dt
		where severity <> '999' 

	UNION ALL SELECT DISTINCT
		patient_guid::varchar,
		sev_date,
		problem_code::varchar,
		severity::int
	FROM
		first_sev_within_7
	UNION ALL SELECT DISTINCT
		patient_guid::varchar,
		problem_onset_date,
		problem_code::varchar,
		severity::int
	FROM
		index_dt
	WHERE
		patient_guid NOT in( SELECT DISTINCT
				patient_guid FROM index_dt where severity <> '999'
			)
		AND patient_guid NOT in( SELECT DISTINCT
				patient_guid FROM first_sev_within_7)
);





-------------FINAL COUNTS----------------------

--sev table for 1, 2, + 3 values 
DROP TABLE IF EXISTS final;

CREATE temp TABLE final AS SELECT DISTINCT
	a.patient_guid,
	max(
		severity) AS severity 
		FROM aao_team.poag_dx_pull1 a
	LEFT JOIN combine_all_sev b 
	ON a.patient_guid = b.patient_guid
WHERE
	severity BETWEEN '1'
	AND '3'
GROUP BY
	1;

SELECT
	count(*)
FROM
	final;


--sev table for 0 + 4 values 
DROP TABLE IF EXISTS final2;

CREATE temp TABLE final2 AS SELECT DISTINCT
	a.patient_guid,
	max(
		severity) AS severity
FROM
	aao_team.poag_dx_pull1 a
	LEFT JOIN combine_all_sev b ON a.patient_guid = b.patient_guid
WHERE
	severity in(
		0, 4)
GROUP BY
	1;

SELECT
	count(*)
FROM
	final2;

--sev table for unknowns
DROP TABLE IF EXISTS final3;

CREATE temp TABLE final3 AS SELECT DISTINCT
	a.patient_guid,
	b.severity
FROM
	aao_team.poag_dx_pull1 a
	LEFT JOIN combine_all_sev b ON a.patient_guid = b.patient_guid
WHERE severity <> '0'
	AND severity <> '1'
	AND severity <> '2'
	AND severity <> '3'
	AND severity <> '4'
GROUP BY
	1,
	2;

SELECT
	count(*)
FROM
	final3; 
 
DROP TABLE IF EXISTS final4;

CREATE temp TABLE final4 as 
(SELECT
	'severity' AS COLUMN,
	severity,
	count(
		DISTINCT patient_guid)
FROM
	final
GROUP BY
	2)
UNION (
SELECT
	'severity' AS COLUMN,
	severity,
	count(
		DISTINCT patient_guid)
FROM
	final2
GROUP BY
	2)
	UNION (
SELECT
	'severity' AS COLUMN,
	severity as UNKNOWN,
	count(
		DISTINCT patient_guid)
FROM
	final3
GROUP BY
	2);

SELECT
	*
FROM
	final4
ORDER BY
	severity ASC;




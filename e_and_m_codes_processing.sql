DROP TABLE IF EXISTS aao_team.skuta_emcodes;
CREATE TABLE aao_team.skuta_emcodes AS SELECT DISTINCT a.patient_guid,
	procedure_date AS effective_date, academic,
	CASE WHEN procedure_code ILIKE '%99201%' THEN
		'New patient office or other outpatient visits'
	WHEN procedure_code ILIKE '%99202%' THEN
		'New patient office or other outpatient visits'
	WHEN procedure_code ILIKE '%99203%' THEN
		'New patient office or other outpatient visits'
	WHEN procedure_code ILIKE '%99204%' THEN
		'New patient office or other outpatient visits'
	WHEN procedure_code ILIKE '%99205%' THEN
		'New patient office or other outpatient visits'
	WHEN procedure_code ILIKE '%99211%' THEN
		'Established patient office or other outpatient visits'
	WHEN procedure_code ILIKE '%99212%' THEN
		'Established patient office or other outpatient visits'
	WHEN procedure_code ILIKE '%99213%' THEN
		'Established patient office or other outpatient visits'
	WHEN procedure_code ILIKE '%99214%' THEN
		'Established patient office or other outpatient visits'
	WHEN procedure_code ILIKE '%99215%' THEN
		'Established patient office or other outpatient visits'
	WHEN procedure_code ILIKE '%99221%' THEN
		'Initial hospital care for new or established patient'
	WHEN procedure_code ILIKE '%99222%' THEN
		'Initial hospital care for new or established patient'
	WHEN procedure_code ILIKE '%99223%' THEN
		'Initial hospital care for new or established patient'
	WHEN procedure_code ILIKE '%99231%' THEN
		'Subsequent hospital care'
	WHEN procedure_code ILIKE '%99232%' THEN
		'Subsequent hospital care'
	WHEN procedure_code ILIKE '%99233%' THEN
		'Subsequent hospital care'
	WHEN procedure_code ILIKE '%99281%' THEN
		'Emergency department services'
	WHEN procedure_code ILIKE '%99282%' THEN
		'Emergency department services'
	WHEN procedure_code ILIKE '%99283%' THEN
		'Emergency department services'
	WHEN procedure_code ILIKE '%99284%' THEN
		'Emergency department services'
	WHEN procedure_code ILIKE '%99285%' THEN
		'Emergency department services'
	WHEN procedure_code ILIKE '%99304%' THEN
		'Nursing facility services'
	WHEN procedure_code ILIKE '%99305%' THEN
		'Nursing facility services'
	WHEN procedure_code ILIKE '%99306%' THEN
		'Nursing facility services'
	WHEN procedure_code ILIKE '%99307%' THEN
		'Nursing facility services'
	WHEN procedure_code ILIKE '%99308%' THEN
		'Nursing facility services'
	WHEN procedure_code ILIKE '%99309%' THEN
		'Nursing facility services'
	WHEN procedure_code ILIKE '%99310%' THEN
		'Nursing facility services'
	END AS category,
	CASE WHEN procedure_code ILIKE '%99201%' THEN
		'99201'
	WHEN procedure_code ILIKE '%99202%' THEN
		'99202'
	WHEN procedure_code ILIKE '%99203%' THEN
		'99203'
	WHEN procedure_code ILIKE '%99204%' THEN
		'99204'
	WHEN procedure_code ILIKE '%99211%' THEN
		'99211'
	WHEN procedure_code ILIKE '%99212%' THEN
		'99212'
	WHEN procedure_code ILIKE '%99213%' THEN
		'99213'
	WHEN procedure_code ILIKE '%99214%' THEN
		'99214'
	WHEN procedure_code ILIKE '%99215%' THEN
		'99215'
	WHEN procedure_code ILIKE '%99222%' THEN
		'99222'
	WHEN procedure_code ILIKE '%99223%' THEN
		'99223'
	WHEN procedure_code ILIKE '%99231%' THEN
		'99231'
	WHEN procedure_code ILIKE '%99232%' THEN
		'99232'
	WHEN procedure_code ILIKE '%99233%' THEN
		'99233'
	WHEN procedure_code ILIKE '%99281%' THEN
		'99281'
	WHEN procedure_code ILIKE '%99282%' THEN
		'99282'
	WHEN procedure_code ILIKE '%99283%' THEN
		'99283'
	WHEN procedure_code ILIKE '%99284%' THEN
		'99284'
	WHEN procedure_code ILIKE '%99285%' THEN
		'99285'
	WHEN procedure_code ILIKE '%99304%' THEN
		'99304'
	WHEN procedure_code ILIKE '%99305%' THEN
		'99305'
	WHEN procedure_code ILIKE '%99306%' THEN
		'99306'
	WHEN procedure_code ILIKE '%99307%' THEN
		'99307'
	WHEN procedure_code ILIKE '%99308%' THEN
		'99308'
	WHEN procedure_code ILIKE '%99309%' THEN
		'99309'
	WHEN procedure_code ILIKE '%99310%' THEN
		'99310'
	ELSE
		procedure_code
	END AS practice_code
FROM
	aao_team.poag_dx_pull1 a
	LEFT JOIN madrid2.patient_procedure b ON a.patient_guid = b.patient_guid
		AND datediff(
			days, a.index_date, b.procedure_date) BETWEEN 0 AND 365 = TRUE
WHERE
	procedure_code ILIKE '%99201%'
	OR procedure_code ILIKE '%99202%'
	OR procedure_code ILIKE '%99203%'
	OR procedure_code ILIKE '%99204%'
	OR procedure_code ILIKE '%99205%'
	OR procedure_code ILIKE '%99211%'
	OR procedure_code ILIKE '%99212%'
	OR procedure_code ILIKE '%99213%'
	OR procedure_code ILIKE '%99214%'
	OR procedure_code ILIKE '%99215%'
	OR procedure_code ILIKE '%99221%'
	OR procedure_code ILIKE '%99222%'
	OR procedure_code ILIKE '%99223%'
	OR procedure_code ILIKE '%99231%'
	OR procedure_code ILIKE '%99232%'
	OR procedure_code ILIKE '%99233%'
	OR procedure_code ILIKE '%99281%'
	OR procedure_code ILIKE '%99282%'
	OR procedure_code ILIKE '%99283%'
	OR procedure_code ILIKE '%99284%'
	OR procedure_code ILIKE '%99285%'
	OR procedure_code ILIKE '%99304%'
	OR procedure_code ILIKE '%99305%'
	OR procedure_code ILIKE '%99306%'
	OR procedure_code ILIKE '%99307%'
	OR procedure_code ILIKE '%99308%'
	OR procedure_code ILIKE '%99309%'
	OR procedure_code ILIKE '%99310%'
	AND(
		procedure_date BETWEEN '2013-01-01'
		AND '2019-12-31'
);
--Get code counts
SELECT
	SUBSTRING(practice_code, 1, 5) AS practice_code,
	academic,
	count(patient_guid)
FROM
	aao_team.skuta_emcodes
GROUP BY
	2, 1
ORDER BY
	2,1;

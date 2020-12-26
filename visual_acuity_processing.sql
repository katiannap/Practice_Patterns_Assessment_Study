 
-------------VA RESULTS---------------- 
DROP TABLE IF EXISTS skuta_va;
CREATE temp TABLE skuta_va AS (
	SELECT
		va.patient_guid,
		va.result_date,
		cast(va.logmar as DECIMAL(10,1)) as logmar,
		va.modified_snellen,
		va.result_code,
		va.eye,
		u.index_date,
		datediff(YEAR, u.index_date, va.result_date) AS dd,
		datediff(month, u.index_date, va.result_date) AS mm
	FROM
		aao_team.poag_dx_pull1 u
		INNER JOIN madrid2.patient_result_va va ON u.patient_guid = va.patient_guid
		AND u.index_date <= va.result_date
			AND va.result_date BETWEEN '2013-01-01'
			AND '2019-12-31'
	WHERE
		logmar <> 999
		AND academic = '0'
		AND logmar IS NOT NULL
		AND result_date IS NOT NULL
	GROUP BY
		va.patient_guid,
		va.result_date,
		va.logmar,
		va.modified_snellen,
		va.result_code,
		va.eye,
		u.index_date
);

/*
SELECT * from skuta_va limit 50;
SELECT count(patient_guid), COUNT(DISTINCT patient_guid) from skuta_va;*/


--1 yr window
drop table if exists skuta_va_oneyear; 
CREATE temp TABLE skuta_va_oneyear AS (
SELECT
		patient_guid,
		result_date,
		logmar,
		CASE WHEN cnt_incorrect > 12 THEN
			'12' ELSE
			cnt_incorrect
		END AS cnt
from 
	(
	SELECT
		count(patient_guid) AS cnt_incorrect,
		patient_guid,
		result_date,
		avg(logmar) AS logmar 
	FROM
		skuta_va
	WHERE
		mm BETWEEN 0 AND 12
		and logmar between '-0.3' and '2.0'
	GROUP BY
		patient_guid,
		result_date
));



------------1 YEAR COUNTS + SUMMARY STATS----------------
SELECT * from (
select
            'VA' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt
        from
            skuta_va_oneyear
        union
        select
            'VA' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_va_oneyear
        union
        select
            'VA' as category,
            'median (.25 - .75)' as value,
            percentile_cont(0.5) within group (
                order by
                    cnt :: float
            ) || ' (' || percentile_cont(0.25) within group (
                order by
                    cnt :: float
            ) || ' -- ' || percentile_cont(0.75) within group (
                order by
                    cnt :: float
            ) || ')' as cnt
        from
            skuta_va_oneyear
        union
        select
            'VA' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_va_oneyear
        union
        select
            'VA' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_va
        where
            patient_guid not in (
                select
                    distinct patient_guid
                from
                    skuta_va_oneyear));

------------1 YEAR MEASUREMENT SUMMARY STATS----------------
select
            'VA' as category,
            'min - max' as value,
            min(logmar) || ' -- ' || max(logmar) as cnt
        from
            skuta_va_oneyear
        union
        select
            'VA' as category,
            'mean (SD)' as value,
            substring(round(avg(logmar :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(logmar :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_va_oneyear
        union
        select
            'VA' as category,
            'median (.25 - .75)' as value,
            percentile_cont(0.5) within group (
                order by
                    logmar :: float
            ) || ' (' || percentile_cont(0.25) within group (
                order by
                    logmar :: float
            ) || ' -- ' || percentile_cont(0.75) within group (
                order by
                    logmar :: float
            ) || ')' as cnt
        from
            skuta_va_oneyear;
            
            

-------------BASELINE PROCESSING-----------------------------------

drop table if exists skuta_va_baseline; 
CREATE temp TABLE skuta_va_baseline AS
SELECT
	patient_guid,
	result_date,
	logmar,
	CASE WHEN cnt_incorrect > 12 THEN
		12
	ELSE
		cnt_incorrect
	END AS cnt
FROM (
	SELECT
		count(patient_guid) AS cnt_incorrect,
		patient_guid,
		result_date,
		avg(logmar) AS logmar
	FROM
		skuta_va
	WHERE
		mm = 0
		AND logmar BETWEEN '-0.3'
		AND '2.0'
	GROUP BY
		patient_guid,
		result_date
);


------------BASELINE COUNTS + SUMMARY STATS----------------
SELECT * from (
select
            'VA' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt
        from
            skuta_va_baseline
        union
        select
            'VA' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_va_baseline
        union
        select
            'VA' as category,
            'median (.25 - .75)' as value,
            percentile_cont(0.5) within group (
                order by
                    cnt :: float
            ) || ' (' || percentile_cont(0.25) within group (
                order by
                    cnt :: float
            ) || ' -- ' || percentile_cont(0.75) within group (
                order by
                    cnt :: float
            ) || ')' as cnt
        from
            skuta_va_baseline
        union
        select
            'VA' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_va_baseline
        union
        select
            'VA' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_va
        where
            patient_guid not in (
                select
                    distinct patient_guid
                from
                    skuta_va_baseline));

------------BASELINE MEASUREMENT SUMMARY STATS----------------
select
            'VA' as category,
            'min - max' as value,
            min(logmar) || ' -- ' || max(logmar) as cnt
        from
            skuta_va_baseline
        union
        select
            'VA' as category,
            'mean (SD)' as value,
            substring(round(avg(logmar :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(logmar :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_va_baseline
        union
        select
            'VA' as category,
            'median (.25 - .75)' as value,
            percentile_cont(0.5) within group (
                order by
                    logmar :: float
            ) || ' (' || percentile_cont(0.25) within group (
                order by
                    logmar :: float
            ) || ' -- ' || percentile_cont(0.75) within group (
                order by
                    logmar :: float
            ) || ')' as cnt
        from
            skuta_va_baseline;

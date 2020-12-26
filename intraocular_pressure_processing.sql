
--1. Get mean IOP (0-80) measurements (not visits) closest to index and then 1 year 

--2. 1 ac visits table and 1 for non ac tbl--actual measurements: summary stats 
--Result date and measurement that was taken on same date 

--3. Check having cap

--fix demo and results + add eye visit codes 

--WORK ON VA CTD AND IOP PROCESSING CODES 

--academic = 1
--nonacademic = 0
-------------IOP RESULTS---------------- 
DROP TABLE IF EXISTS skuta_iop;

CREATE temp TABLE skuta_iop AS (
	SELECT 
		iop.patient_guid,
		iop.result_date,
		iop.iop,
		iop.eye,
		u.index_date,
		datediff(days, u.index_date, iop.result_date) AS dd,
		datediff(month, u.index_date, iop.result_date) AS mm
	FROM
		aao_team.poag_dx_pull1 u
		INNER JOIN madrid2.patient_result_iop iop ON u.patient_guid = iop.patient_guid
			AND iop.result_date BETWEEN '2013-01-01'
			AND '2019-12-31'
	WHERE
		iop <> 999
		AND iop IS NOT NULL
		AND RESULT_date is not NULL
		AND u.index_date <= iop.result_date
		and iop BETWEEN '0' and '80'
		and academic = '0'
);

SELECT * from madrid2.patient_result_iop;

/*SELECT count(patient_guid), count(distinct patient_guid) from skuta_iop;
SELECT * from skuta_iop limit 500;*/

--1 yr window 
DROP TABLE IF EXISTS skuta_iop_oneyear;

CREATE temp TABLE skuta_iop_oneyear AS (
	SELECT
		patient_guid,
		result_date,
		iop,
		CASE WHEN cnt_incorrect > 12 THEN
			12
		ELSE
			cnt_incorrect
		END AS cnt
	FROM (
		SELECT
			patient_guid,
			result_date,
			count(result_date) AS cnt_incorrect,
			avg(iop) AS iop
		FROM
			skuta_iop
		WHERE
			mm BETWEEN 0 AND 12
		GROUP BY
			patient_guid,
			result_date)
);

SELECT * from skuta_iop_oneyear limit 500;


------------1 YEAR COUNTS  + SUMMARY STATS----------------

SELECT * from (
select
            'IOP' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt
        from
            skuta_iop_oneyear
        union
        select
            'IOP' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_iop_oneyear
        union
        select
            'IOP' as category,
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
            skuta_iop_oneyear
        union
        select
            'IOP' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_iop_oneyear
        union
        select
            'IOP' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_iop
        where
            patient_guid not in (
                select
                    distinct patient_guid
                from
                    skuta_iop_oneyear));

------------1 YEAR MEASUREMENT SUMMARY STATS----------------


SELECT * from (
select
            'IOP' as category,
            'min - max' as value,
            min(iop) || ' -- ' || max(iop) as cnt
        from
            skuta_iop_oneyear
        union
        select
            'IOP' as category,
            'mean (SD)' as value,
            substring(round(avg(iop :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(iop :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_iop_oneyear
        union
        select
            'IOP' as category,
            'median (.25 - .75)' as value,
            percentile_cont(0.5) within group (
                order by
                    iop :: float
            ) || ' (' || percentile_cont(0.25) within group (
                order by
                    iop :: float
            ) || ' -- ' || percentile_cont(0.75) within group (
                order by
                    iop :: float
            ) || ')' as cnt
        from
            skuta_iop_oneyear);


-------------BASELINE PROCESSING-----------------------------------
DROP TABLE IF EXISTS skuta_iop_baseline;

CREATE temp TABLE skuta_iop_baseline AS (
	SELECT
		patient_guid,
		result_date,
		iop,
		CASE WHEN cnt_incorrect > 12 THEN
			12
		ELSE
			cnt_incorrect
		END AS cnt
from (
	SELECT
		patient_guid,
		result_date,
		count(result_date) AS cnt_incorrect,
		avg(iop) AS iop
		
	FROM
		skuta_iop
	WHERE
		mm = 0
	GROUP BY
		patient_guid,
		result_date
));

SELECT * from skuta_iop_baseline limit 500;


------------BASELINE COUNTS  + SUMMARY STATS----------------

SELECT * from (
select
            'IOP' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt
        from
            skuta_iop_baseline
        union
        select
            'IOP' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_iop_baseline
        union
        select
            'IOP' as category,
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
            skuta_iop_baseline
        union
        select
            'IOP' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_iop_baseline
        union
        select
            'IOP' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_iop
        where
            patient_guid not in (
                select
                    distinct patient_guid
                from
                    skuta_iop_baseline)
                    order by 2);

------------BASELINE MEASUREMENT SUMMARY STATS----------------

select
            'IOP' as category,
            'min - max' as value,
            min(iop) || ' -- ' || max(iop) as cnt
        from
            skuta_iop_baseline
        union
        select
            'IOP' as category,
            'mean (SD)' as value,
            substring(round(avg(iop :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(iop :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_iop_baseline
        union
        select
            'IOP' as category,
            'median (.25 - .75)' as value,
            percentile_cont(0.5) within group (
                order by
                    iop :: float
            ) || ' (' || percentile_cont(0.25) within group (
                order by
                    iop :: float
            ) || ' -- ' || percentile_cont(0.75) within group (
                order by
                    iop :: float
            ) || ')' as cnt
        from
            skuta_iop_baseline
     


--academic = 1
--nonacademic = 0
-------------CTD RESULTS---------------- 
drop table if exists skuta_ctd; 
CREATE temp TABLE skuta_ctd AS (
	SELECT
		ctd.patient_guid,
		ctd.result_date,
		ctd.ctd,
		ctd.eye,
		u.index_date,
		datediff(days, u.index_date, ctd.result_date) AS dd,
		datediff(month, u.index_date, ctd.result_date) AS mm
	FROM
		aao_team.poag_dx_pull1 u
		INNER JOIN madrid2.patient_result_ctd ctd ON u.patient_guid = ctd.patient_guid
			AND u.index_date <= ctd.result_date     --result date has to be after or on index date 
			AND ctd.result_date BETWEEN '2013-01-01'
			AND '2019-12-31'
			and academic = '1'
			and ctd BETWEEN '0' and '1'
			
);


--1 yr window
drop table if exists skuta_ctd_oneyear; 
CREATE temp TABLE skuta_ctd_oneyear AS (
SELECT
		patient_guid,
		result_date,
		CTD,
		CASE WHEN cnt_incorrect > 12 THEN
			'12' ELSE
			cnt_incorrect
		END AS cnt
from 
	(SELECT
		patient_guid,
		result_date,
		count(patient_guid) AS cnt_incorrect,
		avg(ctd) AS ctd --avg multiple ctd values on the same day
	FROM
		skuta_ctd
	WHERE
		mm BETWEEN 0 AND 12
	GROUP BY
		patient_guid,
		result_date
));


------------1 YEAR COUNTS  + SUMMARY STATS----------------

SELECT * from (
select
            'CTD' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt
        from
            skuta_ctd_oneyear
        union
        select
            'CTD' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_ctd_oneyear
        union
        select
            'CTD' as category,
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
            skuta_ctd_oneyear
        union
        select
            'CTD' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_ctd_oneyear
        union
        --no follow up visits -- patients cannot be in skuta_ctd_oneyear
        select
            'CTD' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_ctd
        where
            patient_guid not in (
                select
                    distinct patient_guid
                from
                    skuta_ctd_oneyear));

------------1 YEAR MEASUREMENT SUMMARY STATS----------------

select
            'CTD' as category,
            'min - max' as value,
            min(ctd) || ' -- ' || max(ctd) as cnt
        from
            skuta_ctd_oneyear
        union
        select
            'CTD' as category,
            'mean (SD)' as value,
            substring(round(avg(ctd :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(ctd :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_ctd_oneyear
        union
        select
            'CTD' as category,
            'median (.25 - .75)' as value,
            percentile_cont(0.5) within group (
                order by
                    ctd :: float
            ) || ' (' || percentile_cont(0.25) within group (
                order by
                    ctd :: float
            ) || ' -- ' || percentile_cont(0.75) within group (
                order by
                    ctd :: float
            ) || ')' as cnt
        from
            skuta_ctd_oneyear;
            
            

-------------BASELINE PROCESSING-----------------------------------

drop table if exists skuta_ctd_baseline; 
CREATE temp TABLE skuta_ctd_baseline AS (
	SELECT
		patient_guid,
		result_date,
		ctd,
		CASE WHEN cnt_incorrect > 12 THEN
			12
		ELSE
			cnt_incorrect
		END AS cnt
from (SELECT
		patient_guid,
		result_date,
		count(patient_guid) AS cnt_incorrect,
		avg(ctd) AS ctd --avg multiple ctd values on the same day
	FROM
		skuta_ctd
	WHERE
		mm = 0
	GROUP BY
		patient_guid,
		result_date)
);


------------BASELINE COUNTS  + SUMMARY STATS----------------
SELECT * from (
select
            'CTD' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt
        from
            skuta_ctd_baseline
        union
        select
            'CTD' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_ctd_baseline
        union
        select
            'CTD' as category,
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
            skuta_ctd_baseline
        union
        select
            'CTD' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_ctd_baseline
        union
        select
            'CTD' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar
        from
            skuta_ctd
        where
            patient_guid not in (
                select
                    distinct patient_guid
                from
                    skuta_ctd_baseline));


------------BASELINE MEASUREMENT SUMMARY STATS----------------


select
            'CTD' as category,
            'min - max' as value,
            min(ctd) || ' -- ' || max(ctd) as cnt
        from
            skuta_ctd_baseline
        union
        select
            'CTD' as category,
            'mean (SD)' as value,
            substring(round(avg(ctd :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(ctd :: float), 4) :: varchar, 1, 6) || ')' as cnt
        from
            skuta_ctd_baseline
        union
        select
            'CTD' as category,
            'median (.25 - .75)' as value,
            percentile_cont(0.5) within group (
                order by
                    ctd :: float
            ) || ' (' || percentile_cont(0.25) within group (
                order by
                    ctd :: float
            ) || ' -- ' || percentile_cont(0.75) within group (
                order by
                    ctd :: float
            ) || ')' as cnt
        from
            skuta_ctd_baseline;

------------------------------------------------
--ACADEMIC AND NON ACADEMIC PROCEDURES
--when academic = '1' then academic
--when academic = '0' then non academic
------------------------------------------------
--------------NEW PROCEDURE TABLE---------------
--Get patient_guids, procedure codes, procedure dates and categories between 2013 and 2019

DROP TABLE IF EXISTS aao_team.skuta_procedures_new;

CREATE TABLE aao_team.skuta_procedures_new AS SELECT DISTINCT
	a.patient_guid,
	procedure_date AS effective_date,
	CASE WHEN procedure_code ILIKE '%66180%' THEN
		'66180'
	WHEN procedure_code ILIKE '%66185%' THEN
		'66185'
	WHEN procedure_code ILIKE '%66175%' THEN
		'66175'
	WHEN procedure_code ILIKE '%66174%' THEN
		'66174'
	WHEN procedure_code ILIKE '%66982%' THEN
		'66982'
	WHEN procedure_code ILIKE '%66711%' THEN
		'66711'
	WHEN procedure_code ILIKE '%66183%' THEN
		'66183'
	WHEN procedure_code ILIKE '%65820%' THEN
		'65820'
	WHEN procedure_code ILIKE '%65855%' THEN
		'65855'
	WHEN procedure_code ILIKE '%99024%' THEN
		'99024'
	WHEN procedure_code ILIKE '%65920%' THEN
		'65920'
	WHEN procedure_code ILIKE '%0474T%' THEN
		'0474T'
	WHEN procedure_code ILIKE '%0191T%' THEN
		'0191T'
	WHEN procedure_code ILIKE '%66710%' THEN
		'66710' 
	WHEN procedure_code ILIKE '%92133%' THEN
		'92133'
	WHEN procedure_code ILIKE '%92081%' THEN
		'92081'
	WHEN procedure_code ILIKE '%92082%' THEN
		'92082'
	WHEN procedure_code ILIKE '%92083%' THEN
		'92083'
	WHEN procedure_code ILIKE '%66250%' THEN
		'66250'
	WHEN procedure_code ILIKE '%66172%' THEN
		'66172'
	END AS practice_code,
	CASE WHEN procedure_code ILIKE '%66180%' THEN
		'Aqueous Shunt'
	WHEN procedure_code ILIKE '%66185%' THEN
		'Aqueous Shunt, Revision'
	WHEN procedure_code ILIKE '%66175%' THEN
		'Canaloplasty with Stent'
	WHEN procedure_code ILIKE '%66174%' THEN
		'Canaloplasty without Stent'
	WHEN procedure_code ILIKE '%66982%' THEN
		'Cataract Surgery'
	WHEN procedure_code ILIKE '%66711%' THEN
		'Endoscopic Cyclophotocoagulation'
	WHEN procedure_code ILIKE '%66183%' THEN
		'ExPress Shunt'
	WHEN procedure_code ILIKE '%65820%' THEN
		'Goniotomy'
	WHEN procedure_code ILIKE '%65855%' THEN
		'Laser Trabeculoplasty'
	WHEN procedure_code ILIKE '%99024%' THEN
		'Postoperative Revisions'
	WHEN procedure_code ILIKE '%65920%' THEN
		'Removal of Device'
	WHEN procedure_code ILIKE '%0474T%' THEN
		'Suprachoroidal Bypass, Cypass'
	WHEN procedure_code ILIKE '%0191T%' THEN
		'Trabecular Bypass, iStent/Hydrus'
	WHEN procedure_code ILIKE '%66172%' THEN
		'Trabeculectomy'
	WHEN procedure_code ILIKE '%66250%' THEN
		'Trabeculectomy, Revision'
	WHEN procedure_code ILIKE '%66710%' THEN
		'Transscleral Cyclophotocoagulation'
	WHEN procedure_code ILIKE '%92133%' THEN
		'Optic Nerve/Nerve Fiber Layer Imaging'
	WHEN procedure_code ILIKE '%92081%'
		OR procedure_code ILIKE '%92082%'
		OR procedure_code ILIKE '%92083%' THEN
		'Visual Field Testing'
	ELSE
		procedure_description
	END AS category,
	academic 
FROM
	aao_team.poag_dx_pull1 a
	LEFT JOIN madrid2.patient_procedure b ON a.patient_guid = b.patient_guid
		AND datediff(
			days, a.index_date, b.procedure_date) BETWEEN 0 AND 365 = TRUE
WHERE
	(
		practice_code ILIKE '%66180%'
		OR practice_code ILIKE '%66185%'
		OR practice_code ILIKE '%66175%'
		OR practice_code ILIKE '%66174%'
		OR practice_code ILIKE '%66982%'
		OR practice_code ILIKE '%66711%'
		OR practice_code ILIKE '%66183%'
		OR practice_code ILIKE '%65820%'
		OR practice_code ILIKE '%65855%'
		OR practice_code ILIKE '%99024%'
		OR practice_code ILIKE '%65920%'
		OR practice_code ILIKE '%0474T%'
		OR practice_code ILIKE '%0191T%'
		OR practice_code ILIKE '%66710%'
		OR practice_code ILIKE '%66172%'
		OR practice_code ILIKE '%66250%'
		OR practice_code ILIKE '%92133%'
		OR practice_code ILIKE '%92081%'
		OR practice_code ILIKE '%92082%'
		OR practice_code ILIKE '%92083%' 
		AND practice_code IS NOT NULL)
	AND(
		procedure_date BETWEEN '2013-01-01'
		AND '2019-12-31'
);

	
--Get frequency of each CPT code

SELECT academic, 
	category,
	SUBSTRING(practice_code, 1, 5) AS practice_code,
	count(*)
FROM
	aao_team.skuta_procedures_new
GROUP BY
	1,
	2
ORDER BY
	1;

/*SELECT
	count(*)
FROM
	aao_team.skuta_procedures_new;*/



--Combine visits + results dates + procedure dates
DROP TABLE IF EXISTS aao_team.skuta_visits;
CREATE TABLE aao_team.skuta_visits AS
SELECT
	patient_guid,
	dt,
	academic
FROM (
	--visits
	SELECT distinct
		u.patient_guid,
		visit_start_date AS dt,
		academic
	FROM
		aao_team.poag_dx_pull1 u
	inner JOIN madrid2.patient_visit visits ON u.patient_guid = visits.patient_guid
		AND datediff(day, u.index_date, visit_start_date) BETWEEN 0 AND 365 = TRUE
WHERE visit_start_date BETWEEN index_date
	AND last_dt
UNION
--results
SELECT distinct
	u.patient_guid,
	result_date AS dt,
	academic
FROM
	aao_team.poag_dx_pull1 u
	inner JOIN madrid2.patient_result_observation a ON u.patient_guid = a.patient_guid
		AND datediff(day, u.index_date, result_date) BETWEEN 0 AND 365 = TRUE
WHERE
	result_date BETWEEN '2013-01-01'
	AND '2019-12-31'
UNION
--procedures
SELECT distinct
	u.patient_guid,
	procedure_date AS dt,
	academic
FROM
	aao_team.poag_dx_pull1 u
	inner JOIN madrid2.patient_procedure a ON u.patient_guid = a.patient_guid
		AND datediff(day, u.index_date, procedure_date) BETWEEN 0 AND 365 = TRUE
WHERE
	procedure_date BETWEEN '2013-01-01'
	AND '2019-12-31');

--and then i took the first effective date per category for each patient
-- take first patient effective date per category since all visits will follow this code
--aka determine the earliest date of each procedure after which there will be follow-up visits

drop table if exists first_date_per_category;
create temp table first_date_per_category as
select * from
(select *,
row_number() OVER (PARTITION BY patient_guid, category ORDER BY effective_date ASC)
			AS rk
from aao_team.skuta_procedures_new)
where rk=1;

--all visits will follow this date

--this is joining visits to the min procedure date table

drop table if exists proc_test;
create temp table proc_test as
SELECT DISTINCT
			a.patient_guid,
			a.category,
			a.practice_code,
			a.effective_date,
			b.dt,
			a.academic
		FROM
			first_date_per_category a
		INNER JOIN aao_team.skuta_visits b ON a.patient_guid = b.patient_guid
		and dt > effective_date;

--this is creating the count variable:

drop table if exists proc_visit_ct;
create temp table proc_visit_ct as
select patient_guid, category, practice_code, academic,
case when cnt_incorrect > 12 then 12
else cnt_incorrect end as cnt
from
(SELECT
		COUNT(dt) AS cnt,
		patient_guid,
		category,
		practice_code,
		academic
	FROM proc_test
	GROUP BY
		academic,
		patient_guid,
		category,
		practice_code
	order by
		academic,
		patient_guid,
		category,
	practice_code);

------------------------------------------------
--COUNTS
DROP TABLE IF EXISTS skuta_counts;
CREATE temp TABLE skuta_counts AS
select
    category,
    value,
    cnt 
from
    (
        select
            'Laser Trabeculoplasty' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
           proc_visit_ct
        where
            category = 'Laser Trabeculoplasty'
            group by academic
           
        union
        select
            'Laser Trabeculoplasty' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Laser Trabeculoplasty'
            group by academic
         
        union
        select
            'Laser Trabeculoplasty' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Laser Trabeculoplasty'
            group by academic
         
        union
        select
            'Laser Trabeculoplasty' as category,
            '1+ postvisits',
            count(DISTINCT patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Laser Trabeculoplasty'
            and post_op = '1'
            group by academic
       
        union
        select
            'Laser Trabeculoplasty' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Laser Trabeculoplasty'
            and post_op = '0'
            group by academic
        
        union
        select
            'Transscleral Cyclophotocoagulation' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Transscleral Cyclophotocoagulation'
            group by academic
         
        union
        select
            'Transscleral Cyclophotocoagulation' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Transscleral Cyclophotocoagulation'
            group by academic
           
        union
        select
            'Transscleral Cyclophotocoagulation' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Transscleral Cyclophotocoagulation'
            group by academic
      
        union
        select
            'Transscleral Cyclophotocoagulation' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Transscleral Cyclophotocoagulation'
            and post_op = '1'
            group by academic
         
        union
        select
            'Transscleral Cyclophotocoagulation' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Transscleral Cyclophotocoagulation'
            and post_op = '0'
            group by academic
          
        union
        select
            'Removal of Device' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Removal of Device'
            group by academic
          
        union
        select
            'Removal of Device' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Removal of Device'
            group by academic
           
        union
        select
            'Removal of Device' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Removal of Device'
            group by academic
        
        union
        select
            'Removal of Device' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Removal of Device'
            and post_op = '1'
            group by academic
          
        union
          select
            'Removal of Device' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Removal of Device'
            and post_op = '0'
            group by academic
        
        union
        select
            'Visual Field Testing' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Visual Field Testing'
            group by academic
          
        union
        select
            'Visual Field Testing' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Visual Field Testing'
            group by academic
     
        union
        select
            'Visual Field Testing' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Visual Field Testing'
            group by academic
        
        union
      SELECT
	'Visual Field Testing' AS category,
	'1+ postvisits',
	count(DISTINCT patient_guid)::varchar,
	academic
FROM
	proc_visit_ct
WHERE
	category = 'Visual Field Testing'
	AND post_op = '1'
	group by academic
	
        union
     select
            'Visual Field Testing' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
            WHERE category = 'Visual Field Testing'
            and post_op = '0'
            group by academic
          
        union
        select
            'Trabeculectomy, Revision' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabeculectomy, Revision'
            group by academic
    
        union
        select
            'Trabeculectomy, Revision' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabeculectomy, Revision'
            group by academic
        
        union
        select
            'Trabeculectomy, Revision' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabeculectomy, Revision'
            group by academic
        
        union
        select
            'Trabeculectomy, Revision' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabeculectomy, Revision'
            and post_op = '1'
            group by academic
       
        union
        select
            'Trabeculectomy, Revision' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabeculectomy, Revision'
            and post_op = '0'
            group by academic
        
        union
        select
            'Goniotomy' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Goniotomy'
            group by academic
         
        union
        select
            'Goniotomy' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Goniotomy'
            group by academic
      
        union
        select
            'Goniotomy' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Goniotomy'
            group by academic
        
        union
        select
            'Goniotomy' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
           proc_visit_ct
        where
            category = 'Goniotomy'
            and post_op = '1'
            group by academic
     
        union
          select
            'Goniotomy' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Goniotomy'
            and post_op = '0'
            group by academic
 
        union
        select
            'Trabeculectomy' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabeculectomy'
            group by academic
 
        union
        select
            'Trabeculectomy' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabeculectomy'
            group by academic

        union
        select
            'Trabeculectomy' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabeculectomy'
            group by academic
         
        union
        select
            'Trabeculectomy' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabeculectomy'
            and post_op = '1'
            group by academic
    
        union
        select
            'Trabeculectomy' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabeculectomy'
            and post_op = '0'
            group by academic
        
        union
        select
            'Optic Nerve/Nerve Fiber Layer Imaging' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Optic Nerve/Nerve Fiber Layer Imaging'
            group by academic
       
        union
        select
            'Optic Nerve/Nerve Fiber Layer Imaging' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Optic Nerve/Nerve Fiber Layer Imaging'
            group by academic
        
        union
        select
            'Optic Nerve/Nerve Fiber Layer Imaging' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Optic Nerve/Nerve Fiber Layer Imaging'
            group by academic
     
        union
        select
            'Optic Nerve/Nerve Fiber Layer Imaging' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Optic Nerve/Nerve Fiber Layer Imaging'
            and post_op = '1'
            group by academic
        
        union
       select
            'Optic Nerve/Nerve Fiber Layer Imaging' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Optic Nerve/Nerve Fiber Layer Imaging'
            and post_op = '0'
            group by academic
    
        union
        select
            'Canaloplasty without Stent' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Canaloplasty without Stent'
            group by academic
         
        union
        select
            'Canaloplasty without Stent' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Canaloplasty without Stent'
            group by academic
          
        union
        select
            'Canaloplasty without Stent' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Canaloplasty without Stent'
            group by academic
         
        union
         select
            'Canaloplasty without Stent' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Canaloplasty without Stent'
            and post_op = '1'
            group by academic
           
        union
      select
            'Canaloplasty without Stent' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Canaloplasty without Stent'
            and post_op = '0'
            group by academic
           
      union 
        select
            'Canaloplasty with Stent' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Canaloplasty with Stent'
            group by academic
       
        union
        select
            'Canaloplasty with Stent' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Canaloplasty with Stent'
            group by academic
            
        union
        select
            'Canaloplasty with Stent' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Canaloplasty with Stent'
            group by academic
         
        union
        select
            'Canaloplasty with Stent' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Canaloplasty with Stent'
            and post_op = '1'
            group by academic
      
        union
         select
            'Canaloplasty with Stent' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        WHERE 
            category = 'Canaloplasty with Stent'
           and post_op = '0'
            group by academic
            
           union
        select
            'Cataract Surgery' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Cataract Surgery'
            group by academic
           
        union
        select
            'Cataract Surgery' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Cataract Surgery'
            group by academic
         
        union
        select
            'Cataract Surgery' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Cataract Surgery'
            group by academic
           
        union
        select
            'Cataract Surgery' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Cataract Surgery'
            and post_op = '1'
            group by academic
            
        union
          select
            'Cataract Surgery' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Cataract Surgery'
            and post_op = '0'
            group by academic
       
        union
        select
            'Aqueous Shunt' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Aqueous Shunt'
            group by academic
        
        union
        select
            'Aqueous Shunt' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Aqueous Shunt'
            group by academic
          
        union
        select
            'Aqueous Shunt' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Aqueous Shunt'
            group by academic
         
        union
        select
            'Aqueous Shunt' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Aqueous Shunt'
            and post_op = '1'
            group by academic
 
        union
        select
            'Aqueous Shunt' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Aqueous Shunt'
            and post_op = '0'
            group by academic
    
        union
        select
            'Postoperative Revisions' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Postoperative Revisions'
            group by academic
      
        union
        select
            'Postoperative Revisions' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Postoperative Revisions'
            group by academic
        
        union
        select
            'Postoperative Revisions' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Postoperative Revisions'
            group by academic

        union
        select
            'Postoperative Revisions' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Postoperative Revisions'
            and post_op = '1'
            group by academic
     
        union
          select
            'Postoperative Revisions' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Postoperative Revisions'
            and post_op = '0'
            group by academic
        
        union
        select
           'Suprachoroidal Bypass, Cypass' as category,
           'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Suprachoroidal Bypass, Cypass'
            group by academic
      
        union
        select
            'Suprachoroidal Bypass, Cypass' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Suprachoroidal Bypass, Cypass'
            group by academic
           
        union
        select
            'Suprachoroidal Bypass, Cypass' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Suprachoroidal Bypass, Cypass'
            group by academic
   
        union
        select
            'Suprachoroidal Bypass, Cypass' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Suprachoroidal Bypass, Cypass'
            and post_op = '1'
            group by academic
          
        union
        
        select
            'Suprachoroidal Bypass, Cypass' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Suprachoroidal Bypass, Cypass'
            and post_op = '0'
            group by academic
        
          union
                select
            'Trabecular Bypass, iStent/Hydrus' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabecular Bypass, iStent/Hydrus'
            group by academic
            
        union
        select
            'Trabecular Bypass, iStent/Hydrus' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabecular Bypass, iStent/Hydrus'
            group by academic
       
        union
        select
            'Trabecular Bypass, iStent/Hydrus' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabecular Bypass, iStent/Hydrus'
            group by academic
 
        union
        select
            'Trabecular Bypass, iStent/Hydrus' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabecular Bypass, iStent/Hydrus'
            and post_op = '1'
            group by academic
           
        union
           select
            'Trabecular Bypass, iStent/Hydrus' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Trabecular Bypass, iStent/Hydrus'
            and post_op = '0'
            group by academic
            
        union
        select
            'Endoscopic Cyclophotocoagulation' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Endoscopic Cyclophotocoagulation'
            group by academic
      
        union
        select
            'Endoscopic Cyclophotocoagulation' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Endoscopic Cyclophotocoagulation'
            group by academic
           
        union
        select
            'Endoscopic Cyclophotocoagulation' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Endoscopic Cyclophotocoagulation'
            group by academic
           
        union
        select
            'Endoscopic Cyclophotocoagulation' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Endoscopic Cyclophotocoagulation'
            and post_op = '1'
            group by academic
           
        union
       select
            'Endoscopic Cyclophotocoagulation' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Endoscopic Cyclophotocoagulation'
            and post_op = '0'
            group by academic
           
        union
        select
            'ExPress Shunt' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'ExPress Shunt'
            group by academic
            
        union
        select
            'ExPress Shunt' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'ExPress Shunt'
            group by academic
            
        union
        select
            'ExPress Shunt' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'ExPress Shunt'
            group by academic
          
        union
        select
            'ExPress Shunt' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'ExPress Shunt'
            and post_op = '1'
            group by academic
           
        union
        select
            'ExPress Shunt' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'ExPress Shunt'
            and post_op = '0'
            group by academic
          
        union
        select
            'Aqueous Shunt, Revision' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Aqueous Shunt, Revision'
            group by academic
         
        union
        select
            'Aqueous Shunt, Revision' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Aqueous Shunt, Revision'
            group by academic
          
        union
        select
            'Aqueous Shunt, Revision' as category,
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
            ) || ')' as cnt,
            academic
        from
            proc_visit_ct
        where
            category = 'Aqueous Shunt, Revision'
            group by academic
            
        union
        select
            'Aqueous Shunt, Revision' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Aqueous Shunt, Revision'
            and post_op = '1'
            group by academic
            
        union
        select
            'Aqueous Shunt, Revision' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            proc_visit_ct
        where
            category = 'Aqueous Shunt, Revision'
            and post_op = '0'
            group by academic
            
    )
    where academic = '1'
ORDER BY 2;

SELECT * from skuta_counts ORDER BY 1, 2;
------------------------------------------------------------------------
/*Flora: For the gonioscopy, he wondered if we could look at gonioscopy procedures done on 
the same date as a new patient visit code:  92002, 92204, 99202, 99203, 99204, 99205; 
and the same for central corneal thickness?*/

---Gather visit and procedure codes with same criteria of original procedure tbl (above)
---Gonioscopy Processing 
DROP TABLE IF EXISTS skuta_gonio_processing;

CREATE TABLE skuta_gonio_processing AS SELECT DISTINCT
	a.patient_guid,
	CASE WHEN procedure_code ILIKE '%92020%' THEN
		'Gonioscopy'
	ELSE
		procedure_description
	END AS category,
	procedure_date AS effective_date,
	procedure_code,
	visit_start_date,
	visit_type_code
FROM
	aao_team.poag_dx_pull1 a
	LEFT JOIN madrid2.patient_procedure b ON a.patient_guid = b.patient_guid
	LEFT JOIN madrid2.patient_visit c ON b.patient_guid = c.patient_guid
		AND datediff(
			days, a.index_date, b.procedure_date) BETWEEN 0 AND 365 = TRUE
WHERE (
	visit_type_code ILIKE '%92002%'
	OR visit_type_code ILIKE '%92004%'
	OR visit_type_code ILIKE '%92202%'
	OR visit_type_code ILIKE '%92203%'
	OR visit_type_code ILIKE '%92204%'
	OR visit_type_code ILIKE '%92205%')
AND(
	procedure_code ILIKE '%92020%'
	AND visit_start_date = procedure_date
	AND procedure_date BETWEEN '2013-01-01'
	AND '2019-12-31'
);

---Join to visits tbl + do casing for post procedure dates 
DROP TABLE IF EXISTS skuta_postop_gonio;

CREATE temp TABLE skuta_postop_gonio AS
select patient_guid, category, practice_code, academic,
case when cnt_incorrect > 12 then 12
else cnt_incorrect end as cnt
from
(SELECT
		COUNT(dt) AS cnt_incorrect,
		patient_guid,
		category,
		procedure_code,
		academic
	FROM skuta_gonio_processing
	GROUP BY
		academic,
		patient_guid,
		category,
		procedure_code
	order by
		academic,
		patient_guid,
		category,
	procedure_code);

SELECT
	*
FROM
	skuta_postop_gonio
LIMIT 5000;

-----Gonioscopy Counts 
DROP TABLE IF EXISTS skuta_gonio_counts;

CREATE temp TABLE skuta_gonio_counts AS
select 
	category,
	VALUE,
	cnt 
	
 from (


select
            'Gonioscopy' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic 
        from
            skuta_postop_gonio
        where
            category = 'Gonioscopy'
            GROUP by academic
           
        union
        
        
        select
            'Gonioscopy' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic 
        from
            skuta_postop_gonio
        where
            category = 'Gonioscopy'
            GROUP by academic
        
           
           
        union
        
        
        select
            'Gonioscopy' as category,
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
            ) || ')' as cnt,
            academic 
        from
           skuta_postop_gonio
        where
            category = 'Gonioscopy'
            GROUP by academic
            
            
            
        union
        
        
        select
            'Gonioscopy' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic 
        from
            skuta_postop_gonio
        where
            category = 'Gonioscopy'
            and post_op = '1'
            GROUP by academic
           
        union
        
        
         select
            'Gonioscopy' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic 
        from
            skuta_postop_gonio
        where
            category = 'Gonioscopy'
            and post_op = '0'
            GROUP by academic
            )
            WHERE academic = '1';

SELECT * from skuta_gonio_counts ORDER BY 2;


---central corneal thickness AKA Pachymetry processing 
---Gather visit and procedure codes with same criteria of original procedure tbl (above)
DROP TABLE IF EXISTS skuta_pachy_processing;

CREATE TABLE skuta_pachy_processing AS SELECT DISTINCT
	ROW_NUMBER(
) OVER ( PARTITION BY a.patient_guid,
		procedure_code,
		visit_type_code ORDER BY procedure_date) AS rn,
	a.patient_guid,
	procedure_date AS effective_date,
	CASE WHEN procedure_code ILIKE '%76514%' THEN
		'Pachymetry'
	ELSE
		procedure_description
	END AS category,
	procedure_code,
	visit_start_date,
	visit_type_code
FROM
	aao_team.poag_dx_pull1 a
	LEFT JOIN madrid2.patient_procedure b ON a.patient_guid = b.patient_guid
	LEFT JOIN madrid2.patient_visit c ON b.patient_guid = c.patient_guid
		AND datediff(
			days, a.index_date, b.procedure_date) BETWEEN 0 AND 365 = TRUE
WHERE (
	visit_type_code ILIKE '%92002%'
	OR visit_type_code ILIKE '%92004%'
	OR visit_type_code ILIKE '%92202%'
	OR visit_type_code ILIKE '%92203%'
	OR visit_type_code ILIKE '%92204%'
	OR visit_type_code ILIKE '%92205%')
AND(
	procedure_code ILIKE '%76514%'
	AND visit_start_date = procedure_date
	AND procedure_date BETWEEN '2013-01-01'
	AND '2019-12-31'
);

---Join to visits tbl + do casing for post procedure dates 
DROP TABLE IF EXISTS skuta_postop_pachy;

CREATE temp TABLE skuta_postop_pachy AS
select patient_guid, category, practice_code, academic,
case when cnt_incorrect > 12 then 12
else cnt_incorrect end as cnt
from
(SELECT
		COUNT(dt) AS cnt_incorrect,
		patient_guid,
		category,
		procedure_code,
		academic
	FROM skuta_pachy_processing
	GROUP BY
		academic,
		patient_guid,
		category,
		procedure_code
	order by
		academic,
		patient_guid,
		category,
	procedure_code);

SELECT * from skuta_postop_pachy;

-----Pachymetry Counts 
DROP TABLE IF EXISTS skuta_pachy_counts;

CREATE temp TABLE skuta_pachy_counts AS
select category, value, cnt
 from (
select DISTINCT
            'Pachymetry' as category,
            'min - max' as value,
            min(cnt) || ' -- ' || max(cnt) as cnt,
            academic
        from
            skuta_postop_pachy
        where
            category = 'Pachymetry'
              and post_op = '1'
              group by academic
              
        union
        select
            'Pachymetry' as category,
            'mean (SD)' as value,
            substring(round(avg(cnt :: float), 4) :: varchar, 1, 6) || ' (' || substring(round(stddev(cnt :: float), 4) :: varchar, 1, 6) || ')' as cnt,
            academic
        from
            skuta_postop_pachy
        where
            category = 'Pachymetry'
            and post_op = '1'
              group by academic
            
        union
        select
            'Pachymetry' as category,
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
            ) || ')' as cnt,
            academic
        from
            skuta_postop_pachy
        where
            category = 'Pachymetry'
            and post_op = '1'
              group by academic
           
        union
        select
            'Pachymetry' as category,
            '1+ postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
           skuta_postop_pachy
        where
            category = 'Pachymetry'
            and post_op ='1'
              group by academic
            
        union
        select
            'Pachymetry' as category,
            '0 postvisits',
            count(distinct patient_guid) :: varchar,
            academic
        from
            skuta_postop_pachy
        where
            category = 'Pachymetry'
            and post_op = '0'
            group by academic
            )
            WHERE academic = '0'
            ORDER BY 2;
SELECT
	*
FROM
	skuta_pachy_counts
ORDER BY
	2;

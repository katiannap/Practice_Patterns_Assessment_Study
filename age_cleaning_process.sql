
--QC step to see how many patients have ages that we cannot utilize for our analyses
drop table if exists age;
CREATE TABLE age AS  (
        SELECT
            u.patient_guid,
            datepart (year, index_date) - year_of_birth AS age
        FROM
            aao_team.poag_dx_pull1 u
            LEFT JOIN madrid2.patient b ON u.patient_guid = b.patient_guid
        WHERE
            academic = '0'
    );
  
SELECT
    count(distinct patient_guid)
from
    age
where
    age is NULL;

 
select
    count(*)
from
    (
        SELECT
            u.patient_guid,
            datepart (year, index_date) - year_of_birth AS age
        FROM
            aao_team.poag_dx_pull1 u
            LEFT JOIN madrid2.patient b ON u.patient_guid = b.patient_guid
        WHERE
            academic = '0'
    )
where
    age < 0;

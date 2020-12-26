 -- region
    -- start by obtaining npi from documentation date
    -- Get just patient_guids and documentation_dates in a single table
    

    DROP TABLE IF EXISTS region;
CREATE TEMPORARY TABLE region AS
SELECT
    DISTINCT patient_guid,
    index_date
FROM
    aao_team.poag_dx_pull1;


-- Join to visits, get closest visit date to each diagnosis
    drop table if exists region2;
CREATE TEMPORARY TABLE region2 AS
SELECT
    patient_guid,
    index_date,
    npi
FROM
    (
        SELECT
            patient_guid,
            npi,
            index_date,
            visit_start_date,
            row_number() OVER (
                PARTITION BY patient_guid,
                index_date
                ORDER BY
                    days_between ASC
            ) AS "row"
        FROM
            (
                SELECT
                    d.patient_guid,
                    v.npi,
                    d.index_date,
                    v.visit_start_date,
                    abs(d.index_date - v.visit_start_date) AS days_between
                FROM
                    region d
                    LEFT JOIN (
                        SELECT
                            patient_guid,
                            visit_start_date,
                            npi
                        FROM
                            madrid2.patient_visit
                        WHERE
                            npi IS NOT NULL
                    ) v ON d.patient_guid = v.patient_guid
            ) r1
        WHERE
            days_between <= 365 -- 1 yr restriction
    ) r2
WHERE
    "row" = 1;
SELECT
    count(DISTINCT patient_guid)
FROM
    region2;
-- Of diagnoses that still don't have a provider, attempt to get from procedures
    drop table if exists region3;
create temporary table region3 as
select
    patient_guid,
    index_date,
    npi
from
    (
        select
            patient_guid,
            npi,
            index_date,
            procedure_date,
            row_number() over(
                partition by patient_guid,
                index_date
                order by
                    days_between asc
            ) as "row"
        from
            (
                select
                    d.patient_guid,
                    p.npi,
                    d.index_date,
                    p.procedure_date,
                    abs(d.index_date - p.procedure_date) as days_between
                from
                    region2 d
                    left join (
                        select
                            patient_guid,
                            procedure_date,
                            npi
                        from
                            madrid2.patient_procedure
                        where
                            npi is not null
                    ) p on d.patient_guid = p.patient_guid
            ) r1
        where
            days_between <= 365 -- 1 yr restriction
    ) r2
where
    "row" = 1;
-- Append npis to region3 from the previous two tables if NULL
    drop table if exists region4;
CREATE TEMPORARY TABLE region4 AS
SELECT
    DISTINCT u.patient_guid,
    u.index_date,
    coalesce(pv.npi, pp.npi) AS npi
FROM
    region u
    LEFT JOIN region2 pv ON (
        u.patient_guid = pv.patient_guid
        AND u.index_date = pv.index_date
    )
    LEFT JOIN region3 pp ON (
        u.patient_guid = pp.patient_guid
        AND u.index_date = pp.index_date
    );
-- Of diagnoses that still don't have a provider, attempt to get from patient_provider
    drop table if exists region5;
CREATE TEMPORARY TABLE region5 AS
SELECT
    r1.patient_guid,
    r1.index_date,
    p.npi
FROM
    (
        SELECT
            DISTINCT patient_guid,
            index_date
        FROM
            region4
        WHERE
            npi IS NULL
    ) r1
    LEFT JOIN madrid2.patient_provider p ON (
        r1.patient_guid = p.patient_guid
        AND r1.index_date BETWEEN p.first_time_provider_seen
        AND p.last_time_provider_seen
    );
-- Take mode of provider_id for each patient_guid-index_date combination
    drop table if exists region6;
create temporary table region6 as
select
    patient_guid,
    index_date,
    npi
from
    (
        select
            patient_guid,
            index_date,
            npi,
            row_number() over (
                partition by patient_guid,
                index_date
                order by
                    count(*) desc
            ) as "row"
        from
            region5
        group by
            patient_guid,
            index_date,
            npi
    ) as r1
where
    "row" = 1;
-- Coalesce npi for all sources
    drop table if exists region7;
create table region7 as
select
    c.patient_guid,
    c.index_date,
    coalesce(p.npi, pm.npi) as npi
from
    region c
    left join region4 p on (
        c.patient_guid = p.patient_guid
        and c.index_date = p.index_date
    )
    left join region6 pm on (
        c.patient_guid = pm.patient_guid
        and c.index_date = pm.index_date
    );
drop table if exists skuta_location_process;
CREATE temp TABLE skuta_location_process AS
SELECT
    DISTINCT npi,
    state,
    CASE
        WHEN state = 'AK' THEN 'West'
        WHEN state = 'CA' THEN 'West'
        WHEN state = 'HI' THEN 'West'
        WHEN state = 'OR' THEN 'West'
        WHEN state = 'WA' THEN 'West'
        WHEN state = 'AZ' THEN 'West'
        WHEN state = 'CO' THEN 'West'
        WHEN state = 'ID' THEN 'West'
        WHEN state = 'NM' THEN 'West'
        WHEN state = 'MT' THEN 'West'
        WHEN state = 'UT' THEN 'West'
        WHEN state = 'NV' THEN 'West'
        WHEN state = 'WY' THEN 'West'
        WHEN state = 'DE' THEN 'South'
        WHEN state = 'DC' THEN 'South'
        WHEN state = 'FL' THEN 'South'
        WHEN state = 'GA' THEN 'South'
        WHEN state = 'MD' THEN 'South'
        WHEN state = 'NC' THEN 'South'
        WHEN state = 'SC' THEN 'South'
        WHEN state = 'VA' THEN 'South'
        WHEN state = 'WV' THEN 'South'
        WHEN state = 'AL' THEN 'South'
        WHEN state = 'KY' THEN 'South'
        WHEN state = 'MS' THEN 'South'
        WHEN state = 'TN' THEN 'South'
        WHEN state = 'AR' THEN 'South'
        WHEN state = 'LA' THEN 'South'
        WHEN state = 'OK' THEN 'South'
        WHEN state = 'TX' THEN 'South'
        WHEN state = 'IN' THEN 'Midwest'
        WHEN state = 'IL' THEN 'Midwest'
        WHEN state = 'MI' THEN 'Midwest'
        WHEN state = 'OH' THEN 'Midwest'
        WHEN state = 'WI' THEN 'Midwest'
        WHEN state = 'IA' THEN 'Midwest'
        WHEN state = 'KS' THEN 'Midwest'
        WHEN state = 'MN' THEN 'Midwest'
        WHEN state = 'MO' THEN 'Midwest'
        WHEN state = 'NE' THEN 'Midwest'
        WHEN state = 'ND' THEN 'Midwest'
        WHEN state = 'SD' THEN 'Midwest'
        WHEN state = 'CT' THEN 'Northeast'
        WHEN state = 'ME' THEN 'Northeast'
        WHEN state = 'MA' THEN 'Northeast'
        WHEN state = 'NH' THEN 'Northeast'
        WHEN state = 'RI' THEN 'Northeast'
        WHEN state = 'VT' THEN 'Northeast'
        WHEN state = 'NJ' THEN 'Northeast'
        WHEN state = 'NY' THEN 'Northeast'
        WHEN state = 'PA' THEN 'Northeast'
        ELSE NULL
    END AS region
FROM
    madrid2.provider_directory
WHERE
    npi in (
        SELECT
            DISTINCT npi
        FROM
            region7
    )
    AND state IS NOT NULL;
SELECT
    state
from
    madrid2.provider_directory
LIMIT
    5000;
SELECT
    count(DISTINCT npi)
FROM
    skuta_location_process;
-- some npis have equally as frequent regions, pick one
    DROP TABLE if exists skuta_location_process2;
CREATE temp TABLE skuta_location_process2 as WITH skuta_reg_summary AS (
        SELECT
            p.*,
            ROW_NUMBER() OVER(
                PARTITION BY p.npi
                ORDER BY
                    p.npi,
                    p.region ASC
            ) AS rk
        FROM
            skuta_location_process p
    )
SELECT
    s.*,
    a.index_date,
    a.patient_guid
FROM
    skuta_reg_summary s
    INNER join region7 as a on a.npi = s.npi
WHERE
    s.rk = 1;
SELECT
    *
from
    skuta_location_process2
limit
    500;
DROP TABLE if exists skuta_location_process_final;
CREATE temp TABLE skuta_location_process_final as
SELECT
    a.patient_guid,
    a.practice_id,
    a.academic,
    a.last_dt,
    a.rn,
    a.prac_code,
    a.index_date,
    b.npi,
    b.state,
    b.region
FROM
    aao_team.poag_dx_pull1 a
    LEFT JOIN skuta_location_process2 b on a.patient_guid = b.patient_guid
WHERE
    academic = '1';
SELECT
    count(DISTINCT patient_guid)
from
    skuta_location_process_final;
SELECT
    *
FROM
    aao_team.poag_dx_pull1
limit
    500;
SELECT
    *
FROM
    skuta_location_process2
limit
    500;

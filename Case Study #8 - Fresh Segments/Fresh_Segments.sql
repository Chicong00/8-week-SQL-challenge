/* Data Exploration and Cleansing */
-- Change the datatype of interest_id to integer
ALTER TABLE fresh_segments.interest_metrics
aLTER COLUMN interest_id TYPE INTEGER USING interest_id::integer;

-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
SELECT 
    to_date(month_year,'MM-YYYY') AS month_year_date
FROM fresh_segments.interest_metrics;

ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN month_year TYPE DATE
USING TO_DATE(month_year, 'MM-YYYY');

SELECT 
    month_year
FROM fresh_segments.interest_metrics
GROUP BY month_year
ORDER BY 1 DESC;

-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT
    month_year,
    count(*) AS record_count
FROM fresh_segments.interest_metrics
GROUP BY 1
ORDER BY 1 ASC NULLS FIRST;

-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
-- we should remove them as they are not valid records and will not be useful for our analysis.
DELETE FROM fresh_segments.interest_metrics
WHERE month_year IS NULL;

-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
SELECT
    count(DISTINCT interest_id) AS interest_id_not_in_map
FROM fresh_segments.interest_metrics me
LEFT JOIN fresh_segments.interest_map ma ON me.interest_id::integer = ma.id
WHERE ma.id IS NULL;

SELECT interest_id::integer AS interest_id_not_in_metrics
FROM fresh_segments.interest_metrics me
EXCEPT DISTINCT
SELECT id
FROM fresh_segments.interest_map ma

-- 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table

-- 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

SELECT
    me.*,
    ma.interest_name,
    ma.interest_summary,
    ma.created_at,
    ma.last_modified
FROM fresh_segments.interest_metrics me
JOIN fresh_segments.interest_map ma ON me.interest_id = ma.id
WHERE me.interest_id = 21246;

SELECT *
FROM fresh_segments.interest_map ma
WHERE ma.id = 21246;

SELECT *
FROM fresh_segments.interest_metrics me
WHERE me.interest_id = 21246;

-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?
with cte as (
SELECT
    me.*,
    ma.interest_name,
    ma.interest_summary,
    ma.created_at,
    ma.last_modified
FROM fresh_segments.interest_metrics me
JOIN fresh_segments.interest_map ma ON me.interest_id = ma.id
WHERE me.interest_id = 21246
)
SELECT * 
FROM cte
WHERE month_year < created_at;
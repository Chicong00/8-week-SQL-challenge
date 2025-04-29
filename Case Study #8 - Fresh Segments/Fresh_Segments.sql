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

/* B. Interest Analysis */
-- 1. Which interests have been present in all month_year dates in our dataset?
SELECT
    interest_id,
    ma.interest_name
FROM fresh_segments.interest_metrics me
LEFT JOIN fresh_segments.interest_map ma ON me.interest_id = ma.id
GROUP BY 1,2
HAVING count(DISTINCT month_year) 
    = (SELECT count(distinct month_year) FROM fresh_segments.interest_metrics);

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
-- Count the total number of months for each interest_id
WITH months_count AS (
SELECT
  interest_id,
  count(DISTINCT month_year) AS total_months
FROM fresh_segments.interest_metrics
WHERE interest_id IS NOT NULL
GROUP BY interest_id
)
-- Count the number of interest_ids for each total_months value
, interests_count AS (
  SELECT
    total_months,
    COUNT(DISTINCT interest_id) AS interest_count
  FROM months_count
  GROUP BY total_months
)

SELECT
  total_months,
  interest_count,
 -- Create running total field using cumulative values of interest count
  ROUND(100 * SUM(interest_count) OVER (ORDER BY total_months DESC) / 
      (SUM(INTEREST_COUNT) OVER ()),2) AS cumulative_percentage
FROM interests_count;

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
with cte as (
WITH months_count AS (
SELECT
  interest_id,
  count(DISTINCT month_year) AS total_months
FROM fresh_segments.interest_metrics
WHERE interest_id IS NOT NULL
GROUP BY interest_id
)
-- Count the number of interest_ids for each total_months value
, interests_count AS (
  SELECT
    total_months,
    COUNT(DISTINCT interest_id) AS interest_count
  FROM months_count
  GROUP BY total_months
)

SELECT
  total_months,
  interest_count,
 -- Create running total field using cumulative values of interest count
  ROUND(100 * SUM(interest_count) OVER (ORDER BY total_months DESC) / 
      (SUM(INTEREST_COUNT) OVER ()),2) AS cumulative_percentage
FROM interests_count
)
SELECT
    sum(interest_count) AS total_data_points_removed
FROM cte
WHERE total_months < 6;

-- Step 1: Calculate total_months for each interest_id
WITH months_count AS (
  SELECT
    interest_id,
    COUNT(DISTINCT month_year) AS total_months
  FROM fresh_segments.interest_metrics
  WHERE interest_id IS NOT NULL
  GROUP BY interest_id
)

-- Step 2: Filter out interest_ids with total_months < 6 and count them
SELECT
  COUNT(*) AS removed_interest_ids
FROM months_count
WHERE total_months < 6;

-- 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
WITH interest_months AS (
  SELECT
    interest_id,
    COUNT(DISTINCT month_year) AS total_months,
    MAX(month_year) AS last_seen_month
  FROM fresh_segments.interest_metrics
  WHERE interest_id IS NOT NULL
  GROUP BY interest_id
),

latest_month AS (
  SELECT MAX(month_year) AS max_month FROM fresh_segments.interest_metrics
)

SELECT
  i.interest_id,
  i.total_months,
  i.last_seen_month,
  CASE 
    WHEN i.total_months < 6 
         AND i.last_seen_month < (l.max_month - INTERVAL '6 months')
    THEN 'remove'
    ELSE 'keep'
  END AS removal_flag
FROM interest_months i
CROSS JOIN latest_month l
ORDER BY removal_flag DESC, total_months ASC;


-- 5. After removing these interests - how many unique interests are there for each month?
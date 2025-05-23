﻿/*1.Data Cleansing */

select * from data_mart.weekly_sales limit 10;

DROP TABLE IF EXISTS data_mart.clean_weekly_sales;
--create a new table to store the cleaned data
CREATE TABLE data_mart.clean_weekly_sales AS (
SELECT
  TO_DATE(week_date, 'DD/MM/YY') AS week_date, -- convert week_date to date format
  DATE_PART('week', TO_DATE(week_date, 'DD/MM/YY')) AS week_number, -- add week_number column
  DATE_PART('month', TO_DATE(week_date, 'DD/MM/YY')) AS month_number, -- add month_number column
  DATE_PART('year', TO_DATE(week_date, 'DD/MM/YY')) AS calendar_year, -- add calendar_year column
  region, 
  platform,
  customer_type, 
  segment,
  CASE 
    WHEN RIGHT(segment,1) = '1' THEN 'Young Adults'
    WHEN RIGHT(segment,1) = '2' THEN 'Middle Aged'
    WHEN RIGHT(segment,1) in ('3','4') THEN 'Retirees'
    ELSE 'unknown' END AS age_band, -- add age_band column
  CASE 
    WHEN LEFT(segment,1) = 'C' THEN 'Couples'
    WHEN LEFT(segment,1) = 'F' THEN 'Families'
    ELSE 'unknown' END AS demographic, -- add demographic column
  transactions,
  ROUND((sales/transactions),2) AS avg_transaction, -- add avg_transaction column
  sales
FROM data_mart.weekly_sales
);

select * from data_mart.clean_weekly_sales limit 10;

/*2. Data Exploration*/

--1. What day of the week is used for each week_date value?
-- Day name of the week
SELECT DISTINCT(TO_CHAR(week_date, 'day')) AS week_day 
FROM data_mart.clean_weekly_sales;

--2. What range of week numbers are missing from the dataset?
-- Create a table with the number of 1 to 52 corresponding to 52 weeks in the year

-- Option 1: Using a recursive CTE to generate week numbers from 1 to 52
WITH RECURSIVE allweeks AS (
  SELECT 1 AS weeknum
  UNION ALL
  SELECT weeknum + 1
  FROM allweeks
  WHERE weeknum + 1 <= 52
)

SELECT DISTINCT a.weeknum, c.week_number
FROM allweeks a
LEFT JOIN data_mart.clean_weekly_sales c
  ON a.weeknum = c.week_number
WHERE c.week_number IS NULL
ORDER BY a.weeknum;

-- Option 2: Using generate_series function to create a series of week numbers
with allweeks as
(
  SELECT generate_series(1, 52) AS weeknum
)
SELECT DISTINCT a.weeknum, c.week_number
FROM allweeks a
LEFT JOIN data_mart.clean_weekly_sales c
  ON a.weeknum = c.week_number
WHERE c.week_number IS NULL
ORDER BY a.weeknum;


--3. How many total transactions were there for each year in the dataset?
select 
	calendar_year,
	sum(transactions) total_transactions
from data_mart.clean_weekly_sales
group by calendar_year
order by 1 DESC, 2 DESC;

--4. What is the total sales for each region for each month?
select
	region,
	month_number,
	sum(sales) total_sales
from data_mart.clean_weekly_sales
group by region, month_number
order by region, month_number;

--5. What is the total count of transactions for each platform
select 
	platform,
	sum(transactions) total_transactions
from data_mart.clean_weekly_sales
group by platform;

--6. What is the percentage of sales for Retail vs Shopify for each month?
-- Option 1: No pivot
with sale as
(
select 
	calendar_year,
	month_number,
	platform,
	sum(sales) sales,
	sum(sum(sales)) over (partition by calendar_year, month_number) total_sales
from data_mart.clean_weekly_sales
group by calendar_year,month_number, platform
)
select 
	calendar_year,
	month_number,
	platform, 
	round(100.0*sum(sales)/sum(total_sales),2) Percentage_sales
from sale
group by calendar_year, month_number, platform
order by calendar_year, month_number; 

-- Option 2: Pivot
with sale as
(
select 
	calendar_year,
	month_number,
	platform,
	sum(sales) sales,
	sum(sum(sales)) over (partition by calendar_year, month_number) total_sales
from data_mart.clean_weekly_sales
group by calendar_year,month_number, platform
)
select 
	calendar_year,
	month_number,
	round(100*sum(case WHEN platform = 'Retail' THEN sales else 0 end)/max(total_sales),2) as retail_sales_pct,
	round(100*sum(case WHEN platform = 'Shopify' THEN sales else 0 end)/max(total_sales),2) as shopify_sales_pct
from sale
group by calendar_year, month_number
order by calendar_year, month_number; 

--7. What is the percentage of sales by demographic for each year in the dataset?
with demo as 
(
select 
	calendar_year,
	demographic,
	sum(sales) year_sales
from data_mart.clean_weekly_sales
group by calendar_year, demographic
)
select 
	calendar_year,
	sum(year_sales) total_sales,
	cast(100.0*sum(case when demographic = 'Families' then year_sales end)/sum(year_sales) as decimal(5,2)) as pct_fam,
	cast(100.0*sum(case when demographic = 'Couples' then year_sales end)/sum(year_sales) as decimal(5,2))as pct_coup,
	cast(100.0*sum(case when demographic = 'unknown' then year_sales end)/sum(year_sales) as decimal(5,2))as pct_unkn
from demo
group by calendar_year
order by calendar_year desc;

--8. Which age_band and demographic values contribute the most to Retail sales?

select 
	age_band,
	demographic,
	sum(sales) sales,
	cast(100.0*sum(sales)/(select sum(sales) from data_mart.clean_weekly_sales where platform = 'Retail') as decimal(5,2)) contribution_pct
from data_mart.clean_weekly_sales	
group by age_band, demographic
order by contribution_pct desc;

--9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
-- Option 1: without pivot
SELECT 
  calendar_year, 
  platform, 
  SUM(sales) / sum(transactions) AS avg_transaction_group
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;

-- Option 2: with pivot
SELECT
 calendar_year,
 round(sum(case when platform = 'Retail' then sales else 0 end)
 / sum(case when platform = 'Retail' then transactions else 0 end)) avg_retail_transaction,
 round(sum(case when platform = 'Shopify' then sales else 0 end)
 / sum(case when platform = 'Shopify' then transactions else 0 end)) avg_shopify_transaction
FROM data_mart.clean_weekly_sales
GROUP BY 1
ORDER BY 1 DESC;


/*3. Before & After Analysis*/

/*Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before*/

--1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
with cte as (
SELECT
	CASE 
		WHEN week_date < date '2020-06-15' THEN '4 weeks before 2020-06-15'
		WHEN week_date = date '2020-06-15' THEN '2020-06-15'
		WHEN week_date > date '2020-06-15' THEN '4 weeks after 2020-06-15'
	END AS period,
	sum(sales) as total_sales
FROM data_mart.clean_weekly_sales
where week_date BETWEEN date '2020-06-15' - interval '4 weeks' 
					and date '2020-06-15' + interval '4 weeks'
GROUP BY 1
)
SELECT * FROM cte
ORDER BY 
	CASE WHEN period = '4 weeks before 2020-06-15' THEN 1
		WHEN period = '2020-06-15' THEN 2
		WHEN period = '4 weeks after 2020-06-15' THEN 3 END;

--2. What about the entire 12 weeks before and after?
with cte as (
SELECT
	CASE 
		WHEN week_date < date '2020-06-15' THEN '12 weeks before 2020-06-15'
		WHEN week_date = date '2020-06-15' THEN '2020-06-15'
		WHEN week_date > date '2020-06-15' THEN '12 weeks after 2020-06-15'
	END AS period,
	sum(sales) as total_sales
FROM data_mart.clean_weekly_sales
where week_date BETWEEN date '2020-06-15' - interval '12 weeks' 
					and date '2020-06-15' + interval '12 weeks'
GROUP BY 1
)
SELECT * FROM cte
ORDER BY 
	CASE WHEN period = '12 weeks before 2020-06-15' THEN 1
		WHEN period = '2020-06-15' THEN 2
		WHEN period = '12 weeks after 2020-06-15' THEN 3 END;

--3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
------ Compare the periods in 2020 with the same periods in 2018 and 2019 sales metrics
WITH periods AS (
    SELECT 
        '12 weeks before 15-06' AS period, 
        date '2020-06-15' - interval '12 weeks' AS start_date, 
        date '2020-06-15' - interval '1 day' AS end_date
    UNION ALL
    SELECT 
        '12 weeks after 15-06', 
        date '2020-06-15' + interval '1 day', 
        date '2020-06-15' + interval '12 weeks'
    UNION ALL
    SELECT 
        '4 weeks before 15-06', 
        date '2020-06-15' - interval '4 weeks', 
        date '2020-06-15' - interval '1 day'
    UNION ALL
    SELECT 
        '4 weeks after 15-06', 
        date '2020-06-15' + interval '1 day', 
        date '2020-06-15' + interval '4 weeks'
)
, sales_by_year AS (
SELECT 
        p.period,
        EXTRACT(YEAR FROM ws.week_date)::int AS year,
        SUM(ws.sales) AS total_sales
    FROM periods p
    JOIN data_mart.clean_weekly_sales ws 
        ON ws.week_date BETWEEN p.start_date AND p.end_date
        OR ws.week_date BETWEEN (p.start_date - interval '1 year') AND (p.end_date - interval '1 year')
        OR ws.week_date BETWEEN (p.start_date - interval '2 years') AND (p.end_date - interval '2 years')
    WHERE EXTRACT(YEAR FROM ws.week_date)::int IN (2018, 2019, 2020)
    GROUP BY p.period, year
),
final AS (
    SELECT 
        period,
        MAX(CASE WHEN year = 2020 THEN total_sales END) AS sales_2020,
        MAX(CASE WHEN year = 2019 THEN total_sales END) AS sales_2019,
        MAX(CASE WHEN year = 2018 THEN total_sales END) AS sales_2018
    FROM sales_by_year
    GROUP BY period
)
SELECT 
    period as period_in_2020, 
    ROUND(sales_2020::numeric / NULLIF(sales_2018, 0), 2) AS compare_with_2018,
    ROUND(sales_2020::numeric / NULLIF(sales_2019, 0), 2) AS compare_with_2019
FROM final
ORDER BY 
    CASE 
        WHEN period = '12 weeks before 2020-06-15' THEN 1
        WHEN period = '
        ' THEN 2
        WHEN period = '4 weeks before 2020-06-15' THEN 3
        WHEN period = '4 weeks after 2020-06-15' THEN 4
    END;

------ Compare the periods in 2020 with the full year 2018 and 2019 sales metrics
-- Step 1: Define the target periods in 2020
WITH periods_2020 AS (
    SELECT 
        '12 weeks before 2020-06-15' AS period, 
        date '2020-06-15' - interval '12 weeks' AS start_date, 
        date '2020-06-15' - interval '1 day' AS end_date
    UNION ALL
    SELECT 
        '12 weeks after 2020-06-15', 
        date '2020-06-15' + interval '1 day', 
        date '2020-06-15' + interval '12 weeks'
    UNION ALL
    SELECT 
        '4 weeks before 2020-06-15', 
        date '2020-06-15' - interval '4 weeks', 
        date '2020-06-15' - interval '1 day'
    UNION ALL
    SELECT 
        '4 weeks after 2020-06-15', 
        date '2020-06-15' + interval '1 day', 
        date '2020-06-15' + interval '4 weeks'
),

-- Step 2: Get total sales for each 2020 period
sales_2020_periods AS (
    SELECT 
        p.period,
        SUM(ws.sales) AS sales_2020
    FROM periods_2020 p
    JOIN data_mart.clean_weekly_sales ws
        ON ws.week_date BETWEEN p.start_date AND p.end_date
    WHERE EXTRACT(YEAR FROM ws.week_date) = 2020
    GROUP BY p.period
),

-- Step 3: Get total sales for full year 2018 and 2019
total_sales_by_year AS (
    SELECT 
        EXTRACT(YEAR FROM week_date)::int AS year,
        SUM(sales) AS total_sales
    FROM data_mart.clean_weekly_sales
    WHERE EXTRACT(YEAR FROM week_date)::int IN (2018, 2019)
    GROUP BY year
),

-- Step 4: Join and calculate ratio
final AS (
    SELECT 
        s.period,
        s.sales_2020,
        MAX(CASE WHEN y.year = 2018 THEN y.total_sales END) AS full_year_2018,
        MAX(CASE WHEN y.year = 2019 THEN y.total_sales END) AS full_year_2019
    FROM sales_2020_periods s
    CROSS JOIN total_sales_by_year y
    GROUP BY s.period, s.sales_2020
)

-- Step 5: Output final ratio table
SELECT 
    period,
    ROUND(sales_2020::numeric *100/ NULLIF(full_year_2018, 0), 2) AS compare_with_2018,
    ROUND(sales_2020::numeric *100/ NULLIF(full_year_2019, 0), 2) AS compare_with_2019
FROM final
ORDER BY 
    CASE 
        WHEN period = '12 weeks before 06-15' THEN 1
        WHEN period = '12 weeks after 06-15' THEN 2
        WHEN period = '4 weeks before 06-15' THEN 3
        WHEN period = '4 weeks after 06-15' THEN 4
    END;


/*D. Bonus Question*/
/*Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
region
platform
age_band
demographic
customer_type*/;

-- Region
WITH region_cte AS (
  SELECT
    'Region' AS business_areas,
    region AS segment,
    SUM(CASE
      WHEN week_date BETWEEN DATE '2020-06-15' - INTERVAL '12 weeks'
                        AND DATE '2020-06-15' - INTERVAL '1 day'
      THEN sales END) AS sales_12_weeks_before,
    SUM(CASE
      WHEN week_date BETWEEN DATE '2020-06-15' + INTERVAL '1 day'
                        AND DATE '2020-06-15' + INTERVAL '12 weeks'
      THEN sales END) AS sales_12_weeks_after
  FROM data_mart.clean_weekly_sales
  GROUP BY region
),

-- Platform
platform_cte AS (
  SELECT
    'Platform' AS business_areas,
    platform AS segment,
    SUM(CASE
      WHEN week_date BETWEEN DATE '2020-06-15' - INTERVAL '12 weeks'
                        AND DATE '2020-06-15' - INTERVAL '1 day'
      THEN sales END) AS sales_12_weeks_before,
    SUM(CASE
      WHEN week_date BETWEEN DATE '2020-06-15' + INTERVAL '1 day'
                        AND DATE '2020-06-15' + INTERVAL '12 weeks'
      THEN sales END) AS sales_12_weeks_after
  FROM data_mart.clean_weekly_sales
  GROUP BY platform
),

-- Age Band
age_band_cte AS (
  SELECT
    'Age Band' AS business_areas,
    age_band AS segment,
    SUM(CASE
      WHEN week_date BETWEEN DATE '2020-06-15' - INTERVAL '12 weeks'
                        AND DATE '2020-06-15' - INTERVAL '1 day'
      THEN sales END) AS sales_12_weeks_before,
    SUM(CASE
      WHEN week_date BETWEEN DATE '2020-06-15' + INTERVAL '1 day'
                        AND DATE '2020-06-15' + INTERVAL '12 weeks'
      THEN sales END) AS sales_12_weeks_after
  FROM data_mart.clean_weekly_sales
  GROUP BY age_band
),

-- Demographic
demo_cte AS (
  SELECT
    'Demographic' AS business_areas,
    demographic AS segment,
    SUM(CASE
      WHEN week_date BETWEEN DATE '2020-06-15' - INTERVAL '12 weeks'
                        AND DATE '2020-06-15' - INTERVAL '1 day'
      THEN sales END) AS sales_12_weeks_before,
    SUM(CASE
      WHEN week_date BETWEEN DATE '2020-06-15' + INTERVAL '1 day'
                        AND DATE '2020-06-15' + INTERVAL '12 weeks'
      THEN sales END) AS sales_12_weeks_after
  FROM data_mart.clean_weekly_sales
  GROUP BY demographic
),

-- Customer Type
cust_type_cte AS (
  SELECT
    'Customer Type' AS business_areas,
    customer_type AS segment,
    SUM(CASE
      WHEN week_date BETWEEN DATE '2020-06-15' - INTERVAL '12 weeks'
                        AND DATE '2020-06-15' - INTERVAL '1 day'
      THEN sales END) AS sales_12_weeks_before,
    SUM(CASE
      WHEN week_date BETWEEN DATE '2020-06-15' + INTERVAL '1 day'
                        AND DATE '2020-06-15' + INTERVAL '12 weeks'
      THEN sales END) AS sales_12_weeks_after
  FROM data_mart.clean_weekly_sales
  GROUP BY customer_type
),

-- Combine all
combined AS (
  SELECT * FROM region_cte
  UNION ALL
  SELECT * FROM platform_cte
  UNION ALL
  SELECT * FROM age_band_cte
  UNION ALL
  SELECT * FROM demo_cte
  UNION ALL
  SELECT * FROM cust_type_cte
)
-- Final select with pct_change and rank
, rank_cte as ( 
SELECT
  *,
  ROUND(100.0 * (sales_12_weeks_after - sales_12_weeks_before) / sales_12_weeks_before::NUMERIC, 2) AS pct_change,
  RANK() OVER (PARTITION BY business_areas ORDER BY 
    (sales_12_weeks_after - sales_12_weeks_before) / sales_12_weeks_before::NUMERIC ASC
  ) AS pct_rank
FROM combined
)
SELECT 
    business_areas,
    segment,
    sales_12_weeks_before,
    sales_12_weeks_after,
    pct_change
FROM rank_cte
WHERE pct_rank = 1
ORDER BY pct_change DESC;


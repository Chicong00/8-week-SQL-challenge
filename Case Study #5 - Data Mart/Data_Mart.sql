/*A.Data Cleansing */

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

/*B. Data Exploration*/

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


/*Before & After Analysis*/

/*Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before*/

--1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
declare @baselineweek int =
(select 
	distinct week_number
from data_mart.clean_weekly_sales
where week_date = '2020-06-15');
with cte as
(
select 
	sum(case when week_number between @baselineweek-4 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+3 then sales end) after_sales
from data_mart.clean_weekly_sales
where calendar_year = 2020
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from cte 

--2. What about the entire 12 weeks before and after?
declare @baselineweek int =
(select 
	distinct week_number
from data_mart.clean_weekly_sales
where week_date = '2020-06-15');
with cte as
(
select 
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from data_mart.clean_weekly_sales
where calendar_year = 2020
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from cte 

--3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
--4 weeks before and after
declare @baselineweek int =
(select 
	distinct week_number
from data_mart.clean_weekly_sales
where week_date = '2020-06-15');
with cte as
(
select 
	calendar_year,
	sum(case when week_number between @baselineweek-4 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+3 then sales end) after_sales
from data_mart.clean_weekly_sales
group by calendar_year
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from cte  
order by calendar_year

--12 weeks before and after
declare @baselineweek int =
(select 
	distinct week_number
from data_mart.clean_weekly_sales
where week_date = '2020-06-15');
with cte as
(
select 
	calendar_year,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from data_mart.clean_weekly_sales
group by calendar_year
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from cte 
order by calendar_year

/*D. Bonus Question*/
/*Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

region
platform
age_band
demographic
customer_type*/

--Find the week_number of '2020-06-15' (@weekNum=25)
declare @baselineweek int 
set @baselineweek
=(select 
	distinct week_number
from data_mart.clean_weekly_sales
where week_date = '2020-06-15');

-- region
with region as
(
select 
	region,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from data_mart.clean_weekly_sales
group by region
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from region 
order by pct_change 

-- platform
declare @baselineweek int 
set @baselineweek
=(select 
	distinct week_number
from data_mart.clean_weekly_sales
where week_date = '2020-06-15');

with platform as
(
select 
	platform,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from data_mart.clean_weekly_sales
group by platform
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from platform 
order by pct_change 

-- age_band
declare @baselineweek int 
set @baselineweek
=(select 
	distinct week_number
from data_mart.clean_weekly_sales
where week_date = '2020-06-15');

with age_band as
(
select 
	age_band,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from data_mart.clean_weekly_sales
group by age_band
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from age_band 
order by pct_change 

-- demographic
declare @baselineweek int 
set @baselineweek
=(select 
	distinct week_number
from data_mart.clean_weekly_sales
where week_date = '2020-06-15');

with demographic as
(
select 
	demographic,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from data_mart.clean_weekly_sales
group by demographic
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from demographic 
order by pct_change 

-- customer_type
declare @baselineweek int 
set @baselineweek
=(select 
	distinct week_number
from data_mart.clean_weekly_sales
where week_date = '2020-06-15');

with customer as
(
select 
	customer_type,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from data_mart.clean_weekly_sales
group by customer_type
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from customer 
order by pct_change 

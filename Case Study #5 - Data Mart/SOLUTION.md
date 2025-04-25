# 🛒 Data Mart: Solution

[SQL Syntax](https://github.com/Chicong00/8-week-SQL-challenge/blob/main/Case%20Study%20%235%20-%20Data%20Mart/Data_Mart.sql)

## 1. Data Cleaning
```sql
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
```
**Sample table**

First 10 rows

| week_date | week_number | month_number | calendar_year | region | platform | segment | age_band     | demographic | transactions | avg_transaction | sales    |
|-----------|-------------|--------------|---------------|--------|----------|---------|--------------|-------------|--------------|-----------------|----------|
| 8/31/2020 | 36          | 8            | 2020          | ASIA   | Retail   | C3      | Retirees     | Couples     | 120631       | 30.31           | 3656163  |
| 8/31/2020 | 36          | 8            | 2020          | ASIA   | Retail   | F1      | Young Adults | Families    | 31574        | 31.56           | 996575   |
| 8/31/2020 | 36          | 8            | 2020          | USA    | Retail   | null    | unknown      | unknown     | 529151       | 31.2            | 16509610 |
| 8/31/2020 | 36          | 8            | 2020          | EUROPE | Retail   | C1      | Young Adults | Couples     | 4517         | 31.42           | 141942   |
| 8/31/2020 | 36          | 8            | 2020          | AFRICA | Retail   | C2      | Middle Aged  | Couples     | 58046        | 30.29           | 1758388  |
| 8/31/2020 | 36          | 8            | 2020          | CANADA | Shopify  | F2      | Middle Aged  | Families    | 1336         | 182.54          | 243878   |
| 8/31/2020 | 36          | 8            | 2020          | AFRICA | Shopify  | F3      | Retirees     | Families    | 2514         | 206.64          | 519502   |
| 8/31/2020 | 36          | 8            | 2020          | ASIA   | Shopify  | F1      | Young Adults | Families    | 2158         | 172.11          | 371417   |
| 8/31/2020 | 36          | 8            | 2020          | AFRICA | Shopify  | F2      | Middle Aged  | Families    | 318          | 155.84          | 49557    |
| 8/31/2020 | 36          | 8            | 2020          | AFRICA | Retail   | C3      | Retirees     | Couples     | 111032       | 35.02           | 3888162  |


## 2. Data Exploration

### 1. What day of the week is used for each `week_date` value?

```sql
SELECT DISTINCT(TO_CHAR(week_date, 'day')) AS week_day 
FROM data_mart.clean_weekly_sales;
```
|week_day|
|---|
|monday|

### 2. What range of week numbers are missing from the dataset?

- Step 1: Using generate_series() function to create a series of week numbers
- Step 2: Using left join with clean_weekly_sales to retrieve missing weeks with the filter is week_number is null

```sql
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
```
Missing weeks range: [1-12], [37-52]


### 3. How many total transactions were there for each year in the dataset?

```sql
select 
	calendar_year,
	sum(transactions) total_transactions
from data_mart.clean_weekly_sales
group by calendar_year
order by 1 DESC, 2 DESC;
```
| calendar_year | total_transactions |
|---------------|--------------------|
| 2020          | 375813651          |
| 2019          | 365639285          |
| 2018          | 346406460          |

### 4. What is the total sales for each region for each month?

```sql
select
	region,
	month_number,
	sum(sales) total_sales
from data_mart.clean_weekly_sales
group by region, month_number
order by region, month_number;
```
**Sample result**

First 5 rows / 50 rows
| region | month_number | total_sales |
|--------|--------------|-------------|
| AFRICA | 3            | 567767480   |
| AFRICA | 4            | 1911783504  |
| AFRICA | 5            | 1647244738  |
| AFRICA | 6            | 1767559760  |
| AFRICA | 7            | 1960219710  |

### 5. What is the total count of transactions for each platform

```sql
select 
	platform,
	sum(transactions) total_transactions
from data_mart.clean_weekly_sales
group by platform;
```
| platform | total_transactions |
|----------|--------------------|
| Shopify  | 5925169            |
| Retail   | 1081934227         |


### 6. What is the percentage of sales for Retail vs Shopify for each month?

```sql
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
```
**Sample result**

Sample results with calendar_year = 2018. The full results consist of 20 rows.

| calendar_year | month_number | retail_sales_pct | shopify_sales_pct |
|---------------|--------------|------------------|-------------------|
| 2018          | 3            | 97.92            | 2.08              |
| 2018          | 4            | 97.93            | 2.07              |
| 2018          | 5            | 97.73            | 2.27              |
| 2018          | 6            | 97.76            | 2.24              |
| 2018          | 7            | 97.75            | 2.25              |
| 2018          | 8            | 97.71            | 2.29              |
| 2018          | 9            | 97.68            | 2.32              |

### 7. What is the percentage of sales by demographic for each year in the dataset?

```sql
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
```

| calendar_year | total_sales | pct_fam | pct_coup | pct_unkn |
|---------------|-------------|---------|----------|----------|
| 2020          | 14100220900 | 32.73   | 28.72    | 38.55    |
| 2019          | 13746032500 | 32.47   | 27.28    | 40.25    |
| 2018          | 12897380827 | 31.99   | 26.38    | 41.63    |


### 8. Which `age_band` and `demographic` values contribute the most to Retail sales?
```sql
select 
	age_band,
	demographic,
	sum(sales) sales,
	cast(100.0*sum(sales)/(select sum(sales) from data_mart.clean_weekly_sales where platform = 'Retail') as decimal(5,2)) contribution_pct
from data_mart.clean_weekly_sales	
group by age_band, demographic
order by contribution_pct desc;
```
| age_band     | demographic | sales       | contribution_pct |
|--------------|-------------|-------------|------------------|
| unknown      | unknown     | 16338612234 | 41.2             |
| Retirees     | Families    | 6750457132  | 17.02            |
| Retirees     | Couples     | 6531115070  | 16.47            |
| Middle Aged  | Families    | 4556141618  | 11.49            |
| Young Adults | Couples     | 2679593130  | 6.76             |
| Middle Aged  | Couples     | 1990499351  | 5.02             |
| Young Adults | Families    | 1897215692  | 4.78             |

The highest contribution ratio is 41.2% from unknown `age_band` and `demographic`, followed by retired families at 16.73% and retired couples at 16.07%.

### 9. Can we use the `avg_transaction` column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

- The `avg_transaction` column is the average **by row** -> sales/transaction in that row 
- The avg_transaction that we want to achieve in this question is the avg_transaction by group of the platform each year -> total sales/total transaction group by platform,year

```sql
SELECT
 calendar_year,
 round(sum(case when platform = 'Retail' then sales else 0 end)
 / sum(case when platform = 'Retail' then transactions else 0 end)) avg_retail_transaction,
 round(sum(case when platform = 'Shopify' then sales else 0 end)
 / sum(case when platform = 'Shopify' then transactions else 0 end)) avg_shopify_transaction
FROM data_mart.clean_weekly_sales
GROUP BY 1
ORDER BY 1 DESC;
```
| calendar_year | avg_retail_transaction | avg_shopify_transaction |
|---------------|------------------------|------------------------|
| 2020          | 36                     | 179                    |
| 2019          | 36                     | 183                    |
| 2018          | 36                     | 192                    |

## 3. Before & After Analysis
Taking the `week_date` value of `2020-06-15` as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all `week_date` values for `2020-06-15` as the start of the period **after** the change and the previous `week_date` values would be **before**.

### 1. What is the total sales for the 4 weeks before and after `2020-06-15`? What is the growth or reduction rate in actual values and percentage of sales?

Use **interval** to enhance the precision of time calculations and results. 

```sql
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
```

| period                    | total_sales |
|---------------------------|-------------|
| 4 weeks before 2020-06-15 | 2345878357  |
| 2020-06-15                | 570025348   |
| 4 weeks after 2020-06-15  | 2334905223  |


### 2. What about the entire 12 weeks before and after?

```sql
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
```
| period                     | total_sales |
|----------------------------|-------------|
| 12 weeks before 2020-06-15 | 7126273147  |
| 2020-06-15                 | 570025348   |
| 12 weeks after 2020-06-15  | 6403922405  |


### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

**Compare the periods in 2020 with the same periods in 2018 and 2019 sales metrics**

```sql
-- Define target date periods around 15-06
WITH periods AS (
-- 12 weeks before 2020-06-15
    SELECT 
        '12 weeks before 15-06' AS period, 
        date '2020-06-15' - interval '12 weeks' AS start_date, 
        date '2020-06-15' - interval '1 day' AS end_date
    UNION ALL
-- 12 weeks after 2020-06-15
    SELECT 
        '12 weeks after 15-06', 
        date '2020-06-15' + interval '1 day', 
        date '2020-06-15' + interval '12 weeks'
    UNION ALL
-- 4 weeks before 2020-06-15
    SELECT 
        '4 weeks before 15-06', 
        date '2020-06-15' - interval '4 weeks', 
        date '2020-06-15' - interval '1 day'
    UNION ALL
-- 4 weeks after 2020-06-15
    SELECT 
        '4 weeks after 15-06', 
        date '2020-06-15' + interval '1 day', 
        date '2020-06-15' + interval '4 weeks'
)
--Get sales for each year and period
, sales_by_year AS (
SELECT 
        p.period,
        EXTRACT(YEAR FROM ws.week_date)::int AS year,
        SUM(ws.sales) AS total_sales
    FROM periods p
    JOIN data_mart.clean_weekly_sales ws 
        ON ws.week_date BETWEEN p.start_date AND p.end_date
	-- same period in 2019
        OR ws.week_date BETWEEN (p.start_date - interval '1 year') AND (p.end_date - interval '1 year')
	-- same period in 2018
        OR ws.week_date BETWEEN (p.start_date - interval '2 years') AND (p.end_date - interval '2 years')
    WHERE EXTRACT(YEAR FROM ws.week_date)::int IN (2018, 2019, 2020)
    GROUP BY p.period, year
),
--Pivot sales by year
final AS (
    SELECT 
        period,
        MAX(CASE WHEN year = 2020 THEN total_sales END) AS sales_2020,
        MAX(CASE WHEN year = 2019 THEN total_sales END) AS sales_2019,
        MAX(CASE WHEN year = 2018 THEN total_sales END) AS sales_2018
    FROM sales_by_year
    GROUP BY period
)
--Calculate ratios
SELECT 
    period as period_in_2020, 
    ROUND(sales_2020::numeric *100/ NULLIF(sales_2018, 0), 2) AS compare_with_2018,
    ROUND(sales_2020::numeric *100/ NULLIF(sales_2019, 0), 2) AS compare_with_2019
FROM final
ORDER BY 
    CASE 
        WHEN period = '12 weeks before 2020-06-15' THEN 1
        WHEN period = '12 weeks after 2020-06-15' THEN 2
        WHEN period = '4 weeks before 2020-06-15' THEN 3
        WHEN period = '4 weeks after 2020-06-15' THEN 4
    END;
```
| period_in_2020        | compare_with_2018 | compare_with_2019 |
|-----------------------|-------------------|-------------------|
| 4 weeks before 15-06  | 1.10              | 1.04              |
| 4 weeks after 15-06   | 1.10              | 1.04              |
| 12 weeks before 15-06 | 1.11              | 1.04              |
| 12 weeks after 15-06  | 0.99              | 0.93              |

---
**Compare the periods in 2020 with the full year 2018 and 2019 sales metrics**
```sql
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
```
| period                     | compare_with_2018 | compare_with_2019 |
|----------------------------|-------------------|-------------------|
| 4 weeks before 2020-06-15  | 18.19             | 17.07             |
| 4 weeks after 2020-06-15   | 18.1              | 16.99             |
| 12 weeks before 2020-06-15 | 55.25             | 51.84             |
| 12 weeks after 2020-06-15  | 49.65             | 46.59             |

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


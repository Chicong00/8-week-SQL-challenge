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
  DATE_PART('year', TO_DATE(week_date, 'DD/MM/YY')) AS calendar_year, -- add year_calendar column
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

### 2. What range of week numbers are missing from the dataset?

### 3. How many total transactions were there for each year in the dataset?

### 4. What is the total sales for each region for each month?

### 5. What is the total count of transactions for each platform

### 6. What is the percentage of sales for Retail vs Shopify for each month?

### 7. What is the percentage of sales by demographic for each year in the dataset?

### 8. Which `age_band` and `demographic` values contribute the most to Retail sales?

### 9. Can we use the `avg_transaction` column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

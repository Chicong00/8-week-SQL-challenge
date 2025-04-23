# 🏦 Data Bank: Solution

[SQL Syntax](https://github.com/Chicong00/8-week-SQL-challenge/blob/adb92f99774c36d5c6eba7a5f88745372e8253a0/Case%20Study%20%234%20-%20Data%20Bank/Data_bank.sql)

## A. Customer Nodes Exploration
### 1. How many unique nodes are there on the Data Bank system?
````sql
SELECT count(distinct node_id) unique_node_count
from data_bank.customer_nodes;
````
|unique_node_count|
|---|
|5|
  
### 2. What is the number of nodes per region?
````sql
SELECT 
    region_name,
    COUNT( node_id) number_of_nodes
from data_bank.customer_nodes n 
join data_bank.regions r 
on n.region_id = r.region_id 
group by region_name
order by number_of_nodes desc ; 
````
|region_name|	number_of_nodes|
|---|---|
|Australia|	770|
|America|	735|
|Africa|	714|
|Asia|	665|
|Europe|	616|

### 3. How many customers are allocated to each region?
````sql
SELECT 
    region_name,
    COUNT(distinct customer_id) customer_count
from data_bank.customer_nodes n 
join data_bank.regions r 
on n.region_id = r.region_id
group by region_name
order by customer_count desc; 
````
|region_name|	customer_count|
|---|---|  
|Australia|	110|
|America|	105|
|Africa|	102|
|Asia|	95|
|Europe|	88|
  
### 4. How many days on average are customers reallocated to a different node?
````sql
WITH node_diff AS (
  SELECT 
    customer_id, node_id, start_date, end_date,
    end_date - start_date AS diff
  FROM customer_nodes
  WHERE end_date != '9999-12-31'
  GROUP BY customer_id, node_id, start_date, end_date
  ORDER BY customer_id, node_id
  ),
sum_diff_cte AS (
  SELECT 
    customer_id, node_id, SUM(diff) AS sum_diff
  FROM node_diff
  GROUP BY customer_id, node_id)

SELECT 
  ROUND(AVG(sum_diff),2) AS avg_reallocation_days
FROM sum_diff_cte;  
````  
|avg_reallocation_days|
|---|
|24|  
  
### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?  
  

## B. Customer Transactions
  
### 1. What is the unique count and total amount for each transaction type?
````sql
select 
	txn_type,
	count(*) customer_count,
	sum(txn_amount) total_amount
from data_bank.customer_transactions
group by txn_type  
````
|txn_type|	customer_count|	total_amount|
|---|---|---|
|purchase|	1617|	806537|
|withdrawal|	1580|	793003|
|deposit|	2671|	1359168|
  
### 2. What is the average total historical deposit counts and amounts for all customers?
````sql
with deposit_type as 
(
select
	customer_id,
	count(1) trans_count,
	avg(txn_amount) avg_amount
from data_bank.customer_transactions
where txn_type = 'deposit'
group by customer_id
)
select 
	round(AVG(trans_count)) avg_trans_count,
	round(avg(avg_amount)) avg_amount
from deposit_type;
````
|avg_trans_count|	avg_amount|
|---|---|
|5|	509  |
  
### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
````sql
with cte as (
select 
	customer_id,
	extract(month from txn_date) as month_no,
	SUM(case when txn_type = 'deposit' then 1 else 0 end) as deposit_flg,
	SUM(case when txn_type = 'purchase' then 1 else 0 end) as purchase_flg,
	SUM(case when txn_type = 'withdrawal' then 1 else 0 end) as withdrawal_flg
from data_bank.customer_transactions
GROUP BY 1,2
HAVING SUM(case when txn_type = 'deposit' then 1 else 0 end) > 1 
	and (SUM(case when txn_type = 'purchase' then 1 else 0 end) = 1
	or SUM(case when txn_type = 'withdrawal' then 1 else 0 end) = 1)
)
SELECT
	month_no,
	count(distinct customer_id) customer_count
FROM cte
GROUP BY month_no
ORDER BY month_no;
````
|month_no|	customer_count|
|---|---|  
|1|	115|
|2|	108|
|3|	113|
|4|	50|
  
### 4. What is the closing balance for each customer at the end of the month?
Closing balance = opening balance + deposits - withdrawals - purchases

```sql
with cte as (
SELECT
	customer_id,
	extract('month' from txn_date) as month_no,
	txn_date,
	sum(case when txn_type = 'deposit' then txn_amount else 0 end) - sum(case when txn_type != 'deposit' then txn_amount else 0 end) as balance
FROM data_bank.customer_transactions t
GROUP BY month_no, txn_date, customer_id
)
, balance as (
SELECT 
	*,
	SUM(balance) OVER (PARTITION BY customer_id ORDER BY txn_date) cumulative_balance, -- cumulative balance
	row_number() over (PARTITION BY customer_id, month_no ORDER BY txn_date DESC) as row_num -- row number for each month to get the last balance of the month
FROM cte
ORDER BY txn_date
)
SELECT
	customer_id,
	month_no,
	(date_trunc('month',txn_date) + INTERVAL '1 month - 1 day')::date as end_of_month,
	cumulative_balance as closing_balance
FROM balance
WHERE row_num = 1
	and customer_id < 6
ORDER BY customer_id, month_no DESC, end_of_month DESC
; 
```
**Sample result**

First 5 customers

| customer_id | month_no | end_of_month | closing_balance |
|-------------|----------|--------------|-----------------|
| 1           | 3        | 3/31/2020    | -640            |
| 1           | 1        | 1/31/2020    | 312             |
| 2           | 3        | 3/31/2020    | 610             |
| 2           | 1        | 1/31/2020    | 549             |
| 3           | 4        | 4/30/2020    | -729            |
| 3           | 3        | 3/31/2020    | -1222           |
| 3           | 2        | 2/29/2020    | -821            |
| 3           | 1        | 1/31/2020    | 144             |
| 4           | 3        | 3/31/2020    | 655             |
| 4           | 1        | 1/31/2020    | 848             |
| 5           | 4        | 4/30/2020    | -2413           |
| 5           | 3        | 3/31/2020    | -1923           |
| 5           | 1        | 1/31/2020    | 954             |


### 5. What is the percentage of customers who increase their closing balance by more than 5%? 

- Step 1: Use the query in #4 to calculate the closing balance 
- Step 2: Add the previous closing balance column by using the LAG() function
- Step 3: Calculate the percent change between the current and previous closing balance and flag for the one with the value > 5
- Step 4: Sum the number of customers with the flag and divide by the total number of customers

```sql
-- step 1: calculate closing balance
with cte as (
SELECT
	customer_id,
	extract('month' from txn_date) as month_no,
	txn_date,
	sum(case when txn_type = 'deposit' then txn_amount else 0 end) - sum(case when txn_type != 'deposit' then txn_amount else 0 end) as balance
FROM data_bank.customer_transactions t
GROUP BY month_no, txn_date, customer_id
)
, balance as (
SELECT 
	*,
	SUM(balance) OVER (PARTITION BY customer_id ORDER BY txn_date) cumulative_balance, -- cumulative balance
	row_number() over (PARTITION BY customer_id, month_no ORDER BY txn_date DESC) as row_num -- row number for each month to get the last balance of the month
FROM cte
ORDER BY txn_date
)
-- step 2: add previous closing balance column to compare row by row
, pre_clo_balance as (
SELECT
	customer_id,
	month_no,
	(date_trunc('month',txn_date) + INTERVAL '1 month - 1 day')::date as end_of_month,
	cumulative_balance as closing_balance,
	 lag(cumulative_balance) over (PARTITION BY customer_id ORDER BY month_no) as prev_closing_balance
FROM balance
WHERE row_num = 1
ORDER BY customer_id, end_of_month
)
-- step 3: closing balance change month by month of each customer
, closing_balance_change as (
SELECT
*,
	round((closing_balance - prev_closing_balance) / nullif(prev_closing_balance,0) * 100, 2) as closing_balance_change_percentage,
	case 
		when closing_balance > prev_closing_balance and round((closing_balance - prev_closing_balance) / nullif(prev_closing_balance,0) * 100, 2) > 5 then 1
		else 0 end as closing_balance_increase_5_percent_flg
FROM pre_clo_balance
WHERE prev_closing_balance is not null
)
-- step 4: the percentage of customers who increase their closing balance by more than 5%
select 
	round(sum(closing_balance_increase_5_percent_flg) * 100.0 / count(closing_balance_increase_5_percent_flg), 2) as closing_balance_increase_5_percent_percentage
from closing_balance_change;
```
|closing_balance_increase_5_percent_percentage|
|---|
|21.31|
  
## C. Data Allocation Challenge

## D. Extra Challenge

## E. Extension Request


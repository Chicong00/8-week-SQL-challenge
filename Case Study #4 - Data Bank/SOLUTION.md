# 🏦 Data Bank: Solution

💻 Work performed on MS SQL Server 💻

[SQL Syntax](https://github.com/Chicong00/8-week-SQL-challenge/blob/adb92f99774c36d5c6eba7a5f88745372e8253a0/Case%20Study%20%234%20-%20Data%20Bank/Data_bank.sql)

<details>
<summary>
A. Customer Nodes Exploration
</summary> 

1. How many unique nodes are there on the Data Bank system?
````sql
SELECT count(distinct node_id) unique_node_count
from dbo.customer_nodes
````
|unique_node_count|
|---|
|5|
  
2. What is the number of nodes per region?
````sql
SELECT 
    region_name,
    COUNT( node_id) number_of_nodes
from dbo.customer_nodes n 
join dbo.regions r 
on n.region_id = r.region_id 
group by region_name
order by number_of_nodes desc   
````
|region_name|	number_of_nodes|
|---|---|
|Australia|	770|
|America|	735|
|Africa|	714|
|Asia|	665|
|Europe|	616|

3. How many customers are allocated to each region?
````sql
SELECT 
    region_name,
    COUNT(distinct customer_id) customer_count
from dbo.customer_nodes n 
join dbo.regions r 
on n.region_id = r.region_id
group by region_name
order by customer_count desc 
````
|region_name|	customer_count|
|---|---|  
|Australia|	110|
|America|	105|
|Africa|	102|
|Asia|	95|
|Europe|	88|
  
4. How many days on average are customers reallocated to a different node?
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
  
5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?  
  
</details>
    
<details>
<summary>
B. Customer Transactions
</summary> 
  
1. What is the unique count and total amount for each transaction type?
````sql
select 
	txn_type,
	count(*) customer_count,
	sum(txn_amount) total_amount
from customer_transactions
group by txn_type  
````
|txn_type|	customer_count|	total_amount|
|---|---|---|
|purchase|	1617|	806537|
|withdrawal|	1580|	793003|
|deposit|	2671|	1359168|
  
2. What is the average total historical deposit counts and amounts for all customers?
````sql
with deposit_type as 
(
select
	customer_id,
	count(1) trans_count,
	avg(txn_amount) avg_amount
from customer_transactions
where txn_type = 'deposit'
group by customer_id
)
select 
	AVG(trans_count) avg_deposit,
	avg(avg_amount) avg_amount
from deposit_type  
````
|avg_deposit|	avg_amount|
|---|---|
|5|	508  |
  
3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
````sql
with txn_type as 
(
select 
	customer_id,
	txn_date,
	txn_type,
	sum(case when txn_type = 'deposit' then 1 end) as txn_deposit,
	sum(case when txn_type = 'purchase' then 1 end) as txn_purchase,
	sum(case when txn_type = 'withdrawal' then 1 end) as txn_withdrawal
from customer_transactions
group by customer_id, txn_date, txn_type
)
,customer as 
(
select customer_id,
	datepart(month,txn_date) month,
	sum(txn_deposit) deposit_count,
	sum(txn_purchase) purchase_count,
	sum(txn_withdrawal) withdrawal_count
from txn_type
group by customer_id, datepart(month,txn_date)
)
select 
	month, 
	count(customer_id) customer_count
from customer
where deposit_count > 1 and( purchase_count = 1 or withdrawal_count = 1 )
group by month 
````
|month|	customer_count|
|---|---|  
|1|	115|
|2|	108|
|3|	113|
|4|	50|
  
4. What is the closing balance for each customer at the end of the month?
  
5. What is the percentage of customers who increase their closing balance by more than 5%? 
  
</details>
  
<details>
<summary>
C. Data Allocation Challenge
</summary> 
  
</details>
  
<details>
<summary>
D. Extra Challenge
</summary> 
  
</details>
  
<details>
<summary>
Extension Request
</summary> 
  
</details>

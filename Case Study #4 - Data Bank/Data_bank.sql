----- A. Customer Nodes Exploration -----
--1. How many unique nodes are there on the Data Bank system?
SELECT count(distinct node_id) unique_node_count
from data_bank.customer_nodes;

--2. What is the number of nodes per region?
SELECT 
    region_name,
    COUNT( node_id) number_of_nodes
from data_bank.customer_nodes n 
join data_bank.regions r 
on n.region_id = r.region_id 
group by region_name
order by number_of_nodes desc ;

--3. How many customers are allocated to each region?
SELECT 
    region_name,
    COUNT(distinct customer_id) customer_count
from data_bank.customer_nodes n 
join data_bank.regions r 
on n.region_id = r.region_id
group by region_name
order by customer_count desc; 

--4. How many days on average are customers reallocated to a different node?
with date_diff as 
(
    SELECT 
        customer_id,
        node_id,
        sum(end_date - start_date) datediff_
    from data_bank.customer_nodes
    WHERE end_date != '9999-12-31'
    GROUP BY customer_id, node_id
)
SELECT
    round(avg(datediff_)) avg_reallocated_days_by_customer
from date_diff;

--5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?


----- B. Customer Transactions -----
--1. What is the unique count and total amount for each transaction type?

select 
	txn_type,
	count(*) customer_count,
	sum(txn_amount) total_amount
from data_bank.customer_transactions
group by txn_type;

--2. What is the average total historical deposit counts and amounts for all customers?
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

--3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

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


--4. What is the closing balance for each customer at the end of the month?
-- closing balance = opening balance + deposits - withdrawals - purchases
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

--5. What is the percentage of customers who increase their closing balance by more than 5%?
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

 
----- C. Data Allocation Challenge ----- 
----- D. Extra Challenge -----
----- Extension Request -----

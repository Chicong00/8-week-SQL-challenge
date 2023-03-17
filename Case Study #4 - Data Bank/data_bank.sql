SELECT * from dbo.customer_nodes
SELECT * from dbo.customer_transactions
select * from dbo.regions

----- A. Customer Nodes Exploration -----
--1. How many unique nodes are there on the Data Bank system?
SELECT count(distinct node_id) unique_node_count
from dbo.customer_nodes

--2. What is the number of nodes per region?
SELECT 
    region_name,
    COUNT( node_id) number_of_nodes
from dbo.customer_nodes n 
join dbo.regions r 
on n.region_id = r.region_id 
group by region_name
order by number_of_nodes desc 

--3. How many customers are allocated to each region?
SELECT 
    region_name,
    COUNT(distinct customer_id) customer_count
from dbo.customer_nodes n 
join dbo.regions r 
on n.region_id = r.region_id
group by region_name
order by customer_count desc 

--4. How many days on average are customers reallocated to a different node?
SELECT * from dbo.customer_nodes
-- Bài làm -> ĐÚNG
with date_diff as 
(
    SELECT 
        customer_id,
        node_id,
        start_date,
        end_date,
        DATEDIFF(DAY,start_date,end_date) datediff_
    from dbo.customer_nodes
    WHERE end_date != '9999-12-31'
    GROUP by customer_id,node_id,start_date,end_date
),
sum_diff as 
(
    SELECT  
        customer_id,
        node_id,
        SUM(datediff_) sum_
    from date_diff 
    GROUP by customer_id,node_id
)
select  
    customer_id,
    AVG(sum_) avg_reallocated_days_by_customer,
    avg(AVG(sum_)) over () avg_reallocated_days_all_customer
from sum_diff
GROUP by customer_id


-- Bài sửa (Cách khác)
WITH node_diff AS (
  SELECT 
    customer_id, node_id, start_date, end_date,
    DATEDIFF(DAY,start_date,end_date) AS diff
  FROM dbo.customer_nodes
  WHERE end_date != '9999-12-31'
  GROUP BY customer_id, node_id, start_date, end_date
  ),
sum_diff_cte AS (
  SELECT 
    customer_id, node_id, SUM(diff) AS sum_diff
  FROM node_diff
  GROUP BY customer_id, node_id)

SELECT 
    customer_id,
    SUM(sum_diff) total_reallocation_days,
    ROUND(AVG(sum_diff),2) AS avg_reallocation_days
FROM sum_diff_cte
GROUP by customer_id 

--5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

--Kiểm tra các trường hợp node trùng nhau khi reallocate
select 
	customer_id,
	region_id,
	node_id,
	lag(node_id) over(partition by customer_id order by node_id) Prev_node,
	start_date,
	end_date
from customer_nodes
where year(end_date) != '9999'
order by customer_id

-- Bài làm (chưa đúng)
with percentile as
(
select 
	customer_id,
	region_name,
	node_id,
	LAG(node_id) over (partition by customer_id order by node_id) Prev_node,
	start_date,
	end_date,
	(DATEDIFF(DAY,start_date,end_date)) AS date_diff
from regions r 
join customer_nodes n
on r.region_id = n.region_id
where year(end_date) != '9999'
group by region_name, customer_id, node_id, start_date, end_date
)
select 
	distinct region_name,
	PERCENTILE_CONT(0.50) within group(order by date_diff) over (partition by region_name) as median,
	PERCENTILE_CONT(0.80) within group(order by date_diff) over (partition by region_name) as "80th_percentile",
	PERCENTILE_CONT(0.95) within group(order by date_diff) over (partition by region_name) as "95th_percentile"
from percentile
where Prev_node != node_id


-- Bài tham khảo
WITH get_all_days AS (
	SELECT
			r.region_name,
			cn.customer_id,
			cn.node_id,
			cn.start_date,
			cn.end_date,
			DATEDIFF(DAY,start_date,end_date) date_diff,
			LAG(cn.node_id) OVER (PARTITION BY cn.customer_id ORDER BY cn.start_date) AS prev_node
	FROM
			customer_nodes AS cn
	JOIN regions AS r
		ON
		r.region_id = cn.region_id
	WHERE 
			year(cn.end_date) != '9999'
	group by region_name, customer_id, node_id, start_date, end_date
	/*ORDER BY
			cn.customer_id,
			cn.start_date*/
),
perc_reallocation AS (
SELECT
		region_name,
		PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY date_diff) over(partition by region_name) AS "50th_perc",
		PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY date_diff) over(partition by region_name) AS "80th_perc",
		PERCENTILE_CONT(0.95) WITHIN GROUP(ORDER BY date_diff) over(partition by region_name) AS "95th_perc"
FROM
		get_all_days
WHERE
		prev_node != node_id
--GROUP BY region_name
)
SELECT
	distinct region_name,
	ceiling("50th_perc") AS median,
	ceiling("80th_perc") AS "80th_percentile",
	ceiling("95th_perc") AS "95th_percentile"
FROM
	perc_reallocation;



----- B. Customer Transactions -----
--1. What is the unique count and total amount for each transaction type?

select 
	txn_type,
	count(*) customer_count,
	sum(txn_amount) total_amount
from customer_transactions
group by txn_type

--2. What is the average total historical deposit counts and amounts for all customers?

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
	AVG(trans_count),
	avg(avg_amount)
from deposit_type

-- Bài tham khảo
WITH deposits AS (
  SELECT 
    customer_id, 
    txn_type, 
    COUNT(*) AS txn_count, 
    AVG(txn_amount) AS avg_amount
  FROM customer_transactions
  GROUP BY customer_id, txn_type)

SELECT 
  ROUND(AVG(txn_count),0) AS avg_deposit, 
  ROUND(AVG(avg_amount),2) AS avg_amount
FROM deposits
WHERE txn_type = 'deposit';

--3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
--Bài làm
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

-- Bài tham khảo
WITH monthly_transactions AS (
  SELECT 
    customer_id, 
    DATEPART(month, txn_date) AS month,
    SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
    SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
    SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
  FROM customer_transactions
  GROUP BY customer_id, DATEPART(month, txn_date)
 )

SELECT
  month,
  COUNT(DISTINCT customer_id) AS customer_count
FROM monthly_transactions
WHERE deposit_count >= 2 
  AND (purchase_count = 1 OR withdrawal_count = 1)
GROUP BY month
ORDER BY month;


--4. What is the closing balance for each customer at the end of the month? (số dư cuối tháng của khách hàng)
-- Bài làm (chưa xong)
/*Tạo bảng transaction amount*/
with trans as 
(
select 
	customer_id,
	datepart(month,txn_date) month,
	(case when txn_type = 'deposit' then +txn_amount else -txn_amount end) as trans_amount
from customer_transactions
group by customer_id, datepart(month,txn_date), txn_amount, txn_type
),
closing_balance as
(
select
	customer_id,
	month,
	trans_amount,
	sum(trans_amount) over (partition by customer_id,month order by month rows between unbounded preceding and current row) closing_balance,
	ROW_NUMBER() over (partition by customer_id,month order by month desc) rn
from trans 
)
select customer_id, month, trans_amount, closing_balance
from closing_balance
where rn = 1 

-- Bài tham khảo (1)
with closing_balance AS (
	SELECT
		customer_id,
		txn_amount,
		datepart(Month, txn_date) AS txn_month,
		SUM(
			CASE
	        	WHEN txn_type = 'deposit' THEN txn_amount
	        	ELSE -txn_amount  -- Subtract transaction if not a deposit
	              
			END
		) AS transaction_amount
	FROM
		customer_transactions
	GROUP BY
		customer_id,
		datepart(Month, txn_date),
		txn_amount
	--ORDER BY customer_id
),
get_all_transactions_per_month AS (
	SELECT customer_id,
	       txn_month,
	       transaction_amount,
	       sum(transaction_amount) over(PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance,
	       row_number() OVER (PARTITION BY customer_id, txn_month ORDER BY txn_month desc) AS rn
	FROM closing_balance
	--ORDER BY customer_id, txn_month
)
SELECT 
	customer_id,
	txn_month,
	transaction_amount,
	closing_balance
from
	get_all_transactions_per_month
WHERE rn = 1

-- Bài tham khảo (2)
--End date in the month of the max date of our dataset
DECLARE @maxDate DATE --Khai báo biến maxDate
SET @maxDate = (SELECT EOMONTH(MAX(txn_date)) FROM customer_transactions);

--CTE 1: Monthly transactions of each customer
WITH monthly_transactions AS (
  SELECT
    customer_id,
    EOMONTH(txn_date) AS end_date,
    SUM(CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount
             ELSE txn_amount END) AS transactions
  FROM customer_transactions
  GROUP BY customer_id, EOMONTH(txn_date)
),

--CTE 2: Increment last days of each month till they are equal to @maxDate 
recursive_dates AS (
  SELECT
    DISTINCT customer_id,
    CAST('2020-01-31' AS DATE) AS end_date
  FROM customer_transactions
  UNION ALL
  SELECT 
    customer_id,
    EOMONTH(DATEADD(MONTH, 1, end_date)) AS end_date
  FROM recursive_dates
  WHERE EOMONTH(DATEADD(MONTH, 1, end_date)) <= @maxDate
)

SELECT 
  r.customer_id,
  r.end_date,
  COALESCE(m.transactions, 0) AS transactions,
  SUM(m.transactions) OVER (PARTITION BY r.customer_id ORDER BY r.end_date 
      ROWS UNBOUNDED PRECEDING) AS closing_balance
FROM recursive_dates r
LEFT JOIN  monthly_transactions m
  ON r.customer_id = m.customer_id
  AND r.end_date = m.end_date;


--5. What is the percentage of customers who increase their closing balance by more than 5%?


----- C. Data Allocation Challenge ----- 
----- D. Extra Challenge -----
----- Extension Request -----
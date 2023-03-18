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

--5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?


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

--3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

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


--4. What is the closing balance for each customer at the end of the month? (số dư cuối tháng của khách hàng)


--5. What is the percentage of customers who increase their closing balance by more than 5%?

----- C. Data Allocation Challenge ----- 
----- D. Extra Challenge -----
----- Extension Request -----

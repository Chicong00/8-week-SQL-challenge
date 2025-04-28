/* A. High Level Sales Analysis*/

-- 1.What was the total quantity sold for all products?
SELECT SUM(qty) AS total_quantity_sold
FROM balanced_tree.sales;

-- 2.What is the total generated revenue for all products before discounts?
SELECT SUM(price * qty) AS total_revenue_before_discounts
FROM balanced_tree.sales;

-- 3.What was the total discount amount for all products?
SELECT SUM(price * qty * discount)/100 AS total_discount_amount
FROM balanced_tree.sales;

/* B. Transaction Analysis*/
-- 1. How many unique transactions were there?
SELECT
    COUNT(DISTINCT txn_id) AS unique_transactions
FROM balanced_tree.sales;

-- 2. What is the average unique products purchased in each transaction?
SELECT
    SUM(qty)/ COUNT(DISTINCT txn_id) AS avg_unique_products_per_transaction
FROM balanced_tree.sales;

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price * qty) AS p25_revenue,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price * qty) AS p50_revenue,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price * qty) AS p75_revenue
FROM balanced_tree.sales;

-- 4. What is the average discount value per transaction?
SELECT
    round(AVG(price * qty * discount)/100,2) AS avg_discount_value_per_transaction
FROM balanced_tree.sales;

-- 5. What is the percentage split of all transactions for members vs non-members?
SELECT
    round(SUM(CASE WHEN member = 't' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS member_percentage,
    round(SUM(CASE WHEN member = 'f' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS non_member_percentage
FROM balanced_tree.sales;

-- 6. What is the average revenue for member transactions and non-member transactions?
SELECT
    round(AVG(CASE WHEN member = 't' THEN price * qty END),2) AS avg_member_revenue,
    round(AVG(CASE WHEN member = 'f' THEN price * qty END),2) AS avg_non_member_revenue
FROM balanced_tree.sales;

/* C. Product Analysis*/
-- 1. What are the top 3 products by total revenue before discount?

with cte as (
SELECT
    p.product_name,
    SUM(s.price * qty) AS total_revenue_before_discount,
    rank() OVER (ORDER BY SUM(s.price * qty) DESC) AS revenue_rank
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
GROUP BY 1
)
SELECT
    product_name,
    total_revenue_before_discount
FROM cte
WHERE revenue_rank <= 3;

-- 2. What is the total quantity, revenue and discount for each segment?
SELECT
    p.segment_name,
    SUM(s.qty) AS total_quantity,
    SUM((s.price * s.qty) - ((s.price * s.qty * s.discount/100))) AS total_revenue,     
    SUM(s.price * s.qty * s.discount/100) AS total_discount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
GROUP BY 1;

-- 3. What is the top selling product for each segment?
with cte as (
SELECT
    p.segment_name,
    p.product_name,
    SUM(s.qty) AS total_quantity_sold,
    rank() OVER (PARTITION BY p.segment_name ORDER BY SUM(s.qty) DESC) AS product_rank
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
GROUP BY 1,2
ORDER BY 1,3 DESC
)
SELECT
    segment_name,
    product_name,
    total_quantity_sold
FROM cte
WHERE product_rank = 1
;

-- 4. What is the total quantity, revenue and discount for each category?

SELECT
    p.category_name,
    SUM(s.qty) AS total_quantity,
    SUM((s.price * s.qty) - (s.price * s.qty * s.discount/100)) AS total_revenue,     
    SUM(s.price * s.qty * s.discount/100) AS total_discount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
GROUP BY 1;

-- 5. What is the top selling product for each category?
with cte as (
SELECT
    p.category_name,
    p.product_name,
    SUM(s.qty) AS total_quantity_sold,
    rank() OVER (PARTITION BY p.category_name ORDER BY SUM(s.qty) DESC) AS product_rank
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
GROUP BY 1,2
)
SELECT
    category_name,
    product_name,
    total_quantity_sold
FROM cte
WHERE product_rank = 1;

-- 6. What is the percentage split of revenue by product for each segment?
SELECT
    p.segment_name,
    p.product_name,
    round(SUM((s.price * s.qty) - (s.price * s.qty * s.discount/100)) * 100.0 
        / SUM(SUM((s.price * s.qty) - (s.price * s.qty * s.discount/100))) 
            OVER (PARTITION BY p.segment_name),2) AS percentage_split_revenue
FROM balanced_tree.product_details p
JOIN balanced_tree.sales s ON p.product_id = s.prod_id
GROUP BY 1,2
ORDER BY 1,3 DESC;

-- 7. What is the percentage split of revenue by segment for each category?
SELECT
    p.category_name,
    p.segment_name,
    round(SUM((s.price * s.qty) - (s.price * s.qty * s.discount/100)) * 100.0 
        / SUM(SUM((s.price * s.qty) - (s.price * s.qty * s.discount/100))) 
            OVER (PARTITION BY p.category_name),2) AS percentage_split_revenue
FROM balanced_tree.product_details p
JOIN balanced_tree.sales s ON p.product_id = s.prod_id
GROUP BY 1,2
ORDER BY 1,3 DESC;

-- 8. What is the percentage split of total revenue by category?
SELECT
    p.category_name,
    round(SUM((s.price * s.qty) - (s.price * s.qty * s.discount/100)) * 100.0 
        / SUM(SUM((s.price * s.qty) - (s.price * s.qty * s.discount/100))) 
            OVER (),2) AS percentage_split_revenue
FROM balanced_tree.product_details p
JOIN balanced_tree.sales s ON p.product_id = s.prod_id
GROUP BY 1
ORDER BY 1,2 DESC;

-- 9. What is the total transaction “penetration” for each product? 
-- (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
WITH prod_txn as (
SELECT
    p.product_id,
    p.product_name,
    count(DISTINCT s.txn_id) AS prod_txn_count
FROM balanced_tree.product_details p
JOIN balanced_tree.sales s ON p.product_id = s.prod_id
WHERE qty > 0
GROUP BY 1,2
)
, total_txn as (
SELECT
    COUNT(DISTINCT s.txn_id) AS total_txn_count  
FROM balanced_tree.sales s
)
SELECT
    p.product_name,
    p.prod_txn_count,
    t.total_txn_count,
    ROUND(prod_txn_count * 100.0 / t.total_txn_count,2) AS penetration_percentage
FROM prod_txn p
CROSS JOIN total_txn t
ORDER BY 4 DESC;

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
WITH transaction_products AS (
    SELECT
        txn_id,
        prod_id
    FROM balanced_tree.sales
),
triplet_combinations AS (
    SELECT
        tp1.txn_id,
        LEAST(tp1.prod_id, tp2.prod_id, tp3.prod_id) AS prod1,
        --To avoid duplicate sets like (A,B,C) and (B,A,C).
        CASE
            WHEN (tp1.prod_id > tp2.prod_id AND tp1.prod_id < tp3.prod_id) OR (tp1.prod_id < tp2.prod_id AND tp1.prod_id > tp3.prod_id) THEN tp1.prod_id
            WHEN (tp2.prod_id > tp1.prod_id AND tp2.prod_id < tp3.prod_id) OR (tp2.prod_id < tp1.prod_id AND tp2.prod_id > tp3.prod_id) THEN tp2.prod_id
            ELSE tp3.prod_id
        END AS prod2,
        GREATEST(tp1.prod_id, tp2.prod_id, tp3.prod_id) AS prod3
    FROM transaction_products tp1
    JOIN transaction_products tp2
        ON tp1.txn_id = tp2.txn_id AND tp1.prod_id < tp2.prod_id
    JOIN transaction_products tp3
        ON tp1.txn_id = tp3.txn_id AND tp2.prod_id < tp3.prod_id
)
, combo_counts AS (
    SELECT
        prod1,
        prod2,
        prod3,
        COUNT(*) AS combo_count,
        rank() OVER (ORDER BY COUNT(*) DESC) AS combo_rank
    FROM triplet_combinations
    GROUP BY prod1, prod2, prod3
    ORDER BY combo_count DESC
)
SELECT
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    p3.product_name AS product_3,
    combo_count
FROM combo_counts
JOIN balanced_tree.product_details p1 ON combo_counts.prod1 = p1.product_id
JOIN balanced_tree.product_details p2 ON combo_counts.prod2 = p2.product_id
JOIN balanced_tree.product_details p3 ON combo_counts.prod3 = p3.product_id
WHERE combo_rank = 1;

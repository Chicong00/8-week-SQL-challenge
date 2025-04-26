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
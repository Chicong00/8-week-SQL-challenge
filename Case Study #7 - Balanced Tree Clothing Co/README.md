# 👕 Case study 7: Balanced  Tree Clothing Co

## Table of Contents
- [Introduction](#introduction)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question and Solution](#question-and-solution)

***
## Introduction
Balanced Tree Clothing Company prides themselves on providing an optimised range of clothing and lifestyle wear for the modern adventurer!

Danny, the CEO of this trendy fashion company has asked you to assist the team’s merchandising teams analyse their sales performance and generate a basic financial report to share with the wider business.

## Entity Relationship Diagram
<img width="560" alt="image" src="https://github.com/user-attachments/assets/94cd5ca9-dec3-4714-bc4a-1e5dfcbb51ae">

**Table: `Product Details`**
| product_id | price | product_name                     | category_id | segment_id | style_id | category_name | segment_name | style_name          |
|------------|-------|----------------------------------|-------------|------------|----------|---------------|--------------|---------------------|
| c4a632     | 13    | Navy Oversized Jeans - Womens    | 1           | 3          | 7        | Womens        | Jeans        | Navy Oversized      |
| e83aa3     | 32    | Black Straight Jeans - Womens    | 1           | 3          | 8        | Womens        | Jeans        | Black Straight      |
| e31d39     | 10    | Cream Relaxed Jeans - Womens     | 1           | 3          | 9        | Womens        | Jeans        | Cream Relaxed       |
| d5e9a6     | 23    | Khaki Suit Jacket - Womens       | 1           | 4          | 10       | Womens        | Jacket       | Khaki Suit          |
| 72f5d4     | 19    | Indigo Rain Jacket - Womens      | 1           | 4          | 11       | Womens        | Jacket       | Indigo Rain         |
| 9ec847     | 54    | Grey Fashion Jacket - Womens     | 1           | 4          | 12       | Womens        | Jacket       | Grey Fashion        |
| 5d267b     | 40    | White Tee Shirt - Mens           | 2           | 5          | 13       | Mens          | Shirt        | White Tee           |
| c8d436     | 10    | Teal Button Up Shirt - Mens      | 2           | 5          | 14       | Mens          | Shirt        | Teal Button Up      |
| 2a2353     | 57    | Blue Polo Shirt - Mens           | 2           | 5          | 15       | Mens          | Shirt        | Blue Polo           |
| f084eb     | 36    | Navy Solid Socks - Mens          | 2           | 6          | 16       | Mens          | Socks        | Navy Solid          |
| b9a74d     | 17    | White Striped Socks - Mens       | 2           | 6          | 17       | Mens          | Socks        | White Striped       |
| 2feb6b     | 29    | Pink Fluro Polkadot Socks - Mens | 2           | 6          | 18       | Mens          | Socks        | Pink Fluro Polkadot |

**Table: `Product Sales`**
| prod_id | qty | price | discount | member | txn_id | start_txn_time           |
|---------|-----|-------|----------|--------|--------|--------------------------|
| c4a632  | 4   | 13    | 17       | t      | 54f307 | 2021-02-13 01:59:43.296  |
| 5d267b  | 4   | 40    | 17       | t      | 54f307 | 2021-02-13 01:59:43.296  |
| b9a74d  | 4   | 17    | 17       | t      | 54f307 | 2021-02-13 01:59:43.296  |
| 2feb6b  | 2   | 29    | 17       | t      | 54f307 | 2021-02-13 01:59:43.296  |
| c4a632  | 5   | 13    | 21       | t      | 26cc98 | 2021-01-19 01:39:00.3456 |
| e31d39  | 2   | 10    | 21       | t      | 26cc98 | 2021-01-19 01:39:00.3456 |
| 72f5d4  | 3   | 19    | 21       | t      | 26cc98 | 2021-01-19 01:39:00.3456 |
| 2a2353  | 3   | 57    | 21       | t      | 26cc98 | 2021-01-19 01:39:00.3456 |
| f084eb  | 3   | 36    | 21       | t      | 26cc98 | 2021-01-19 01:39:00.3456 |
| c4a632  | 1   | 13    | 21       | f      | ef648d | 2021-01-27 02:18:17.1648 |

**Table: `Product Hierarcy`**
| id | parent_id | level_text          | level_name |
|----|-----------|---------------------|------------|
| 1  | Womens    | Category            |            |
| 2  | Mens      | Category            |            |
| 3  | 1         | Jeans               | Segment    |
| 4  | 1         | Jacket              | Segment    |
| 5  | 2         | Shirt               | Segment    |
| 6  | 2         | Socks               | Segment    |
| 7  | 3         | Navy Oversized      | Style      |
| 8  | 3         | Black Straight      | Style      |
| 9  | 3         | Cream Relaxed       | Style      |
| 10 | 4         | Khaki Suit          | Style      |
| 11 | 4         | Indigo Rain         | Style      |
| 12 | 4         | Grey Fashion        | Style      |
| 13 | 5         | White Tee           | Style      |
| 14 | 5         | Teal Button Up      | Style      |
| 15 | 5         | Blue Polo           | Style      |
| 16 | 6         | Navy Solid          | Style      |
| 17 | 6         | White Striped       | Style      |
| 18 | 6         | Pink Fluro Polkadot | Style      |

**Table: `Product Price`**
| id | product_id | price |
|----|------------|-------|
| 7  | c4a632     | 13    |
| 8  | e83aa3     | 32    |
| 9  | e31d39     | 10    |
| 10 | d5e9a6     | 23    |
| 11 | 72f5d4     | 19    |
| 12 | 9ec847     | 54    |
| 13 | 5d267b     | 40    |
| 14 | c8d436     | 10    |
| 15 | 2a2353     | 57    |
| 16 | f084eb     | 36    |
| 17 | b9a74d     | 17    |
| 18 | 2feb6b     | 29    |

## Question and Solution
### A. High Level Sales Analysis
#### 1. What was the total quantity sold for all products?
```sql
SELECT SUM(qty) AS total_quantity_sold
FROM balanced_tree.sales;
```
|total_quantity_sold|
|---|
|45216|

#### 2. What is the total generated revenue for all products before discounts?
```sql
SELECT SUM(price * qty) AS total_revenue_before_discounts
FROM balanced_tree.sales;
```
|total_revenue_before_discounts|
|---|
|1289453|

#### 3. What was the total discount amount for all products?
```sql
SELECT SUM(price * qty * discount)/100 AS total_discount_amount
FROM balanced_tree.sales;
```
|total_discount_amount|
|---|
|156229|

### B. Transaction Analysis
#### 1. How many unique transactions were there?
```sql
SELECT
    COUNT(DISTINCT txn_id) AS unique_transactions
FROM balanced_tree.sales;
```
|unique_transactions|
|---|
|2500|

#### 2. What is the average unique products purchased in each transaction?
```sql
SELECT
    SUM(qty)/ COUNT(DISTINCT txn_id) AS avg_unique_products_per_transaction
FROM balanced_tree.sales;
```
|avg_unique_products_per_transaction|
|---|
|18|

#### 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
```sql
SELECT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price * qty) AS p25_revenue,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price * qty) AS p50_revenue,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price * qty) AS p75_revenue
FROM balanced_tree.sales;
```
| p25_revenue | p50_revenue | p75_revenue |
|-------------|-------------|-------------|
| 38          | 65          | 116         |

#### 4. What is the average discount value per transaction?
```sql
SELECT
    round(AVG(price * qty * discount)/100,2) AS avg_discount_value_per_transaction
FROM balanced_tree.sales;
```
|avg_discount_value_per_transaction/|
|---|
|10.35|

#### 5. What is the percentage split of all transactions for members vs non-members?
```sql
SELECT
    round(SUM(CASE WHEN member = 't' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS member_percentage,
    round(SUM(CASE WHEN member = 'f' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS non_member_percentage
FROM balanced_tree.sales;
```
| member_percentage | non_member_percentage |
|-------------------|-----------------------|
| 60.03             | 39.97                 |

#### 6. What is the average revenue for member transactions and non-member transactions?
```sql
SELECT
    round(AVG(CASE WHEN member = 't' THEN price * qty END),2) AS avg_member_revenue,
    round(AVG(CASE WHEN member = 'f' THEN price * qty END),2) AS avg_non_member_revenue
FROM balanced_tree.sales;
```
| avg_member_revenue | avg_non_member_revenue |
|--------------------|------------------------|
| 85.75              | 84.93                  |

### C. Product Analysis
#### 1. What are the top 3 products by total revenue before discount?
```sql
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
```
| product_name                 | total_revenue_before_discount |
|------------------------------|-------------------------------|
| Blue Polo Shirt - Mens       | 217683                        |
| Grey Fashion Jacket - Womens | 209304                        |
| White Tee Shirt - Mens       | 152000                        |

#### 2. What is the total quantity, revenue and discount for each segment?
```sql
SELECT
    p.segment_name,
    SUM(s.qty) AS total_quantity,
    SUM((s.price * s.qty) - ((s.price * s.qty * s.discount/100))) AS total_revenue,     
    SUM(s.price * s.qty * s.discount/100) AS total_discount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
GROUP BY 1;
```
| segment_name | total_quantity | total_revenue | total_discount |
|--------------|----------------|---------------|----------------|
| Shirt        | 11265          | 358061        | 48082          |
| Jeans        | 11349          | 184677        | 23673          |
| Jacket       | 11385          | 324532        | 42451          |
| Socks        | 11217          | 272697        | 35280          |


#### 3. What is the top selling product for each segment?
```sql
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
```
| segment_name | product_name                  | total_quantity_sold |
|--------------|-------------------------------|---------------------|
| Jacket       | Grey Fashion Jacket - Womens  | 3876                |
| Jeans        | Navy Oversized Jeans - Womens | 3856                |
| Shirt        | Blue Polo Shirt - Mens        | 3819                |
| Socks        | Navy Solid Socks - Mens       | 3792                |


#### 4. What is the total quantity, revenue and discount for each category?
```sql
SELECT
    p.category_name,
    SUM(s.qty) AS total_quantity,
    SUM((s.price * s.qty) - (s.price * s.qty * s.discount/100)) AS total_revenue,     
    SUM(s.price * s.qty * s.discount/100) AS total_discount
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
GROUP BY 1;
```
| category_name | total_quantity | total_revenue | total_discount |
|---------------|----------------|---------------|----------------|
| Mens          | 22482          | 630758        | 83362          |
| Womens        | 22734          | 509209        | 66124          |

#### 5. What is the top selling product for each category?
```SQL
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
```
| category_name | product_name                 | total_quantity_sold |
|---------------|------------------------------|---------------------|
| Mens          | Blue Polo Shirt - Mens       | 3819                |
| Womens        | Grey Fashion Jacket - Womens | 3876                |

#### 6. What is the percentage split of revenue by product for each segment?
```sql
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
```
| segment_name | product_name                     | percentage_split_revenue |
|--------------|----------------------------------|--------------------------|
| Jacket       | Grey Fashion Jacket - Womens     | 56.86                    |
| Jacket       | Khaki Suit Jacket - Womens       | 23.61                    |
| Jacket       | Indigo Rain Jacket - Womens      | 19.53                    |
| Jeans        | Black Straight Jeans - Womens    | 57.94                    |
| Jeans        | Navy Oversized Jeans - Womens    | 24.14                    |
| Jeans        | Cream Relaxed Jeans - Womens     | 17.92                    |
| Shirt        | Blue Polo Shirt - Mens           | 53.48                    |
| Shirt        | White Tee Shirt - Mens           | 37.43                    |
| Shirt        | Teal Button Up Shirt - Mens      | 9.09                     |
| Socks        | Navy Solid Socks - Mens          | 44.17                    |
| Socks        | Pink Fluro Polkadot Socks - Mens | 35.57                    |
| Socks        | White Striped Socks - Mens       | 20.26                    |

#### 7. What is the percentage split of revenue by segment for each category?
```sql
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
```
| category_name | segment_name | percentage_split_revenue |
|---------------|--------------|--------------------------|
| Mens          | Shirt        | 56.77                    |
| Mens          | Socks        | 43.23                    |
| Womens        | Jacket       | 63.73                    |
| Womens        | Jeans        | 36.27                    |

#### 8. What is the percentage split of total revenue by category?
```SQL
SELECT
    p.category_name,
    round(SUM((s.price * s.qty) - (s.price * s.qty * s.discount/100)) * 100.0 
        / SUM(SUM((s.price * s.qty) - (s.price * s.qty * s.discount/100))) 
            OVER (),2) AS percentage_split_revenue
FROM balanced_tree.product_details p
JOIN balanced_tree.sales s ON p.product_id = s.prod_id
GROUP BY 1
ORDER BY 1,2 DESC;
```
| category_name | percentage_split_revenue |
|---------------|--------------------------|
| Mens          | 55.33                    |
| Womens        | 44.67                    |

#### 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
```SQL
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
```
| product_name                     | prod_txn_count | total_txn_count | penetration_percentage |
|----------------------------------|----------------|-----------------|------------------------|
| Navy Solid Socks - Mens          | 1281           | 2500            | 51.24                  |
| Grey Fashion Jacket - Womens     | 1275           | 2500            | 51                     |
| Navy Oversized Jeans - Womens    | 1274           | 2500            | 50.96                  |
| Blue Polo Shirt - Mens           | 1268           | 2500            | 50.72                  |
| White Tee Shirt - Mens           | 1268           | 2500            | 50.72                  |
| Pink Fluro Polkadot Socks - Mens | 1258           | 2500            | 50.32                  |
| Indigo Rain Jacket - Womens      | 1250           | 2500            | 50                     |
| Khaki Suit Jacket - Womens       | 1247           | 2500            | 49.88                  |
| Black Straight Jeans - Womens    | 1246           | 2500            | 49.84                  |
| Cream Relaxed Jeans - Womens     | 1243           | 2500            | 49.72                  |
| White Striped Socks - Mens       | 1243           | 2500            | 49.72                  |
| Teal Button Up Shirt - Mens      | 1242           | 2500            | 49.68                  |

#### 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
```sql
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
),
combo_counts AS (
    SELECT
        prod1,
        prod2,
        prod3,
        COUNT(*) AS combo_count
    FROM triplet_combinations
    GROUP BY prod1, prod2, prod3
    ORDER BY combo_count DESC
    LIMIT 1
)
SELECT
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    p3.product_name AS product_3,
    combo_count
FROM combo_counts
JOIN balanced_tree.product_details p1 ON combo_counts.prod1 = p1.product_id
JOIN balanced_tree.product_details p2 ON combo_counts.prod2 = p2.product_id
JOIN balanced_tree.product_details p3 ON combo_counts.prod3 = p3.product_id;
```
| product_1              | product_2                    | product_3                   | combo_count |
|------------------------|------------------------------|-----------------------------|-------------|
| White Tee Shirt - Mens | Grey Fashion Jacket - Womens | Teal Button Up Shirt - Mens | 352         |

### D. Reporting Challenge

### E. Bonus Challenge

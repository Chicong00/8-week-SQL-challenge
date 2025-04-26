
# 🖱️ Case study 6: Clique Bait

## Table of Contents
- [Introduction](#introduction)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question and Solution](#question-and-solution)

***
## Introduction

Clique Bait is not like your regular online seafood store - the founder and CEO Danny, was also a part of a digital data analytics team and wanted to expand his knowledge into the seafood industry!

In this case study - you are required to support Danny’s vision and analyse his dataset and come up with creative solutions to calculate funnel fallout rates for the Clique Bait online store.

## Entity Relationship Diagram
<img width="825" alt="image" src="https://user-images.githubusercontent.com/81607668/134619326-f560a7b0-23b2-42ba-964b-95b3c8d55c76.png">

**Table: `users`**

<img width="366" alt="image" src="https://user-images.githubusercontent.com/81607668/134623074-7c51d63a-c0a4-41e0-a6fc-257e4ca3997d.png">

**Table: `events`**

<img width="849" alt="image" src="https://user-images.githubusercontent.com/81607668/134623132-dfa2acd3-60c9-4305-9bea-6b39a9403c14.png">

**Table: `event_identifier`**

<img width="273" alt="image" src="https://user-images.githubusercontent.com/81607668/134623311-1ad16fe7-36e3-45b6-9dc6-8114333cf473.png">

**Table: `page_hierarchy`**

<img width="576" alt="image" src="https://user-images.githubusercontent.com/81607668/134623202-3158ca06-6f04-4b67-91f1-e184761e885c.png">

**Table: `campaign_identifier`**

<img width="792" alt="image" src="https://user-images.githubusercontent.com/81607668/134623354-0977d67c-fc61-4e61-90ee-f24a29682a9b.png">

## Question and Solution
[SQL syntax](https://github.com/Chicong00/8-week-SQL-challenge/blob/main/Case%20Study%20%236%20-%20Clique%20Bait/Clique_Bait.sql)

### A. Digital Analysis
#### 1. How many users are there?
```sql
select count(distinct user_id) total_users
from clique_bait.users;
```
|total_users|
|---|
|500|

#### 2.How many cookies does each user have on average?
```sql
select 
	round(COUNT(cookie_id)/count(distinct user_id)::numeric,2) avg_cookies_per_user
from clique_bait.users;
```
|avg_cookies_per_user|
|---|
|3.56|

#### 3. What is the unique number of visits by all users per month?
```sql
select
	DATE_PART('month',event_time) as month_number,
	count(distinct visit_id) visit_count
from clique_bait.events e 
group by DATE_PART('month',event_time)
order by 1;
```
| month_number | visit_count |
|--------------|-------------|
| 1            | 876         |
| 2            | 1488        |
| 3            | 916         |
| 4            | 248         |
| 5            | 36          |


#### 4. What is the number of events for each event type?
```sql
select 
	event_name,
	count(*) event_count
from clique_bait.events e 
join clique_bait.event_identifier ei
on e.event_type = ei.event_type
group by event_name
order by event_count desc;
```
| event_name    | event_count |
|---------------|-------------|
| Page View     | 20928       |
| Add to Cart   | 8451        |
| Purchase      | 1777        |
| Ad Impression | 876         |
| Ad Click      | 702         |

#### 5. What is the percentage of visits which have a purchase event?
```sql
select	
	event_name,
	cast(100.0*count(distinct visit_id)/(select count(distinct visit_id) from clique_bait.events) as decimal(5,2)) pct_visit_count
from clique_bait.events e
join clique_bait.event_identifier ei
on e.event_type = ei.event_type
where event_name = 'Purchase'
group by event_name;
```
|event_name	|pct_visit_count|
|---|---|
|Purchase|	49.86|

#### 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
- Count the number of visits with event_name = 'Page View' and page_name = 'Checkout'
- Then filter out the number of visits with event_name = 'purchase' in the first condition 
=> Number of visits which view the checkout page but do not have a purchase event

```sql
with checkout_view as 
(
select 
	count(distinct visit_id) visit_count
from clique_bait.events e
left join clique_bait.page_hierarchy p on e.page_id = p.page_id
left join clique_bait.event_identifier ei on e.event_type = ei.event_type
where ei.event_name = 'Page View' and p.page_name = 'Checkout'
)
select 
	cast(100-100.0*count(distinct visit_id)/(select visit_count from checkout_view) as decimal(5,2)) pct_view_checkout_not_purchase
from clique_bait.events e 
join clique_bait.event_identifier ei
on e.event_type = ei.event_type
where event_name = 'Purchase';
```
|pct_view_checkout_not_purchase|
|---|
|15.50|

#### 7. What are the top 3 pages by number of views?
```sql
with cte as (
select 
	p.page_name,
	count(visit_id) visit_count,
	rank() over (order by count(visit_id) desc) as ranking
from clique_bait.events e
join clique_bait.page_hierarchy p on e.page_id = p.page_id
join clique_bait.event_identifier ei on e.event_type = ei.event_type
where event_name = 'Page View'
group by page_name
order by visit_count desc
)
SELECT
	page_name,
	visit_count
FROM cte 
WHERE ranking  < 4;
```
Top 3 pages by number of views

| page_name    | visit_count |
|--------------|-------------|
| All Products | 3174        |
| Checkout     | 2103        |
| Home Page    | 1782        |


#### 8. What is the number of views and cart adds for each product category?
```sql
SELECT 
  ph.product_category, 
  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_views_count,
  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds_count
from clique_bait.events AS e
JOIN clique_bait.page_hierarchy AS ph ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category
ORDER BY 2 DESC;
```
| product_category | page_views_count | cart_adds_count |
|------------------|------------------|-----------------|
| Shellfish        | 6204             | 3792            |
| Fish             | 4633             | 2789            |
| Luxury           | 3032             | 1870            |


#### 9. What are the top 3 products by purchases?
```sql
with cte as (
select 
	ph.page_name,
	ph.product_category,
	count(*) purchase_count,
	rank() over (order by count(*) desc) ranking
from clique_bait.events e 
join clique_bait.event_identifier ei on e.event_type = ei.event_type
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
-- Step1 : Products are added to cart 
where event_name = 'Add to Cart'
-- Step 2: Add-to-cart products are purchased
and e.visit_id in 
	(select e.visit_id from clique_bait.events e
	join clique_bait.event_identifier ei on e.event_type = ei.event_type
	where event_name = 'Purchase')
group by ph.page_name, ph.product_category 
order by 3 desc
)
SELECT
	page_name,
	product_category,
	purchase_count
FROM cte 
WHERE ranking  < 4;
```
| page_name | product_category | purchase_count |
|-----------|------------------|----------------|
| Lobster   | Shellfish        | 754            |
| Oyster    | Shellfish        | 726            |
| Crab      | Shellfish        | 719            |

---

### B. Product Funnel Analysis

#### Create a new output table which has the following details:
- How many times was each product viewed?
- How many times was each product added to cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased?
```sql
drop table if exists clique_bait.product_info;
create table clique_bait.product_info as
(
with product_view_add as
(
select 
	ph.product_id,ph.page_name, ph.product_category, 
	sum(case when event_name = 'Page View' then 1 end) as viewed,
	sum(case when event_name = 'Add to Cart' then 1 end) as added_to_cart
from clique_bait.events e 
join clique_bait.event_identifier ei on e.event_type = ei.event_type
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
where ph.product_category is not null
group by ph.product_id, ph.page_name, ph.product_category
),
product_abandoned as
(
select ph.product_id, ph.page_name, ph.product_category, count(*) abandoned
from clique_bait.events e 
join clique_bait.event_identifier ei on e.event_type = ei.event_type
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
where ei.event_name = 'Add to Cart' 
	and e.visit_id not in (select e1.visit_id 
							from clique_bait.events e1 
							join clique_bait.event_identifier ei1 on e1.event_type = ei1.event_type
							where event_name = 'Purchase')
group by ph.product_id, ph.page_name, ph.product_category
),
product_purchased as 
(
select ph.product_id, ph.page_name, ph.product_category, count(*) purchased
from clique_bait.events e 
join clique_bait.event_identifier ei on e.event_type = ei.event_type
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
where ei.event_name = 'Add to Cart' 
	and e.visit_id in (select e1.visit_id 
							from clique_bait.events e1 
							join clique_bait.event_identifier ei1 on e1.event_type = ei1.event_type
							where event_name = 'Purchase')
group by ph.product_id, ph.page_name, ph.product_category
)
select 
	pva.product_id,pva.page_name,pva.product_category,pva.viewed, pva.added_to_cart,
	pa.abandoned,
	pp.purchased
from product_view_add pva
join product_abandoned pa on pva.product_id = pa.product_id
join product_purchased pp on pva.product_id = pp.product_id
order by pva.product_id asc
);
SELECT * FROM clique_bait.product_info;
```
| product_id | page_name      | product_category | viewed | added_to_cart | abandoned | purchased |
|------------|----------------|------------------|--------|---------------|-----------|-----------|
| 1          | Salmon         | Fish             | 1559   | 938           | 227       | 711       |
| 2          | Kingfish       | Fish             | 1559   | 920           | 213       | 707       |
| 3          | Tuna           | Fish             | 1515   | 931           | 234       | 697       |
| 4          | Russian Caviar | Luxury           | 1563   | 946           | 249       | 697       |
| 5          | Black Truffle  | Luxury           | 1469   | 924           | 217       | 707       |
| 6          | Abalone        | Shellfish        | 1525   | 932           | 233       | 699       |
| 7          | Lobster        | Shellfish        | 1547   | 968           | 214       | 754       |
| 8          | Crab           | Shellfish        | 1564   | 949           | 230       | 719       |
| 9          | Oyster         | Shellfish        | 1568   | 943           | 217       | 726       |


#### Create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

```sql
DROP table IF EXISTS clique_bait.category_info;
CREATE TABLE clique_bait.category_info AS
(
with product_info as
(
select 
	ph.product_category, 
	sum(case when event_name = 'Page View' then 1 end) as viewd,
	sum(case when event_name = 'Add to Cart' then 1 end) as added_to_cart
from clique_bait.events e 
join clique_bait.event_identifier ei on e.event_type = ei.event_type
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
where ph.product_category is not null
group by  ph.product_category
),
product_abandoned as
(
select ph.product_category, count(*) abandoned
from clique_bait.events e 
join clique_bait.event_identifier ei on e.event_type = ei.event_type
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
where ei.event_name = 'Add to Cart' 
	and e.visit_id not in (select e1.visit_id 
							from clique_bait.events e1 
							join clique_bait.event_identifier ei1 on e1.event_type = ei1.event_type
							where event_name = 'Purchase')
group by ph.product_category
),
product_purchased as 
(
select ph.product_category, count(*) purchased
from clique_bait.events e 
join clique_bait.event_identifier ei on e.event_type = ei.event_type
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
where ei.event_name = 'Add to Cart' 
	and e.visit_id in (select e1.visit_id 
							from clique_bait.events e1 
							join clique_bait.event_identifier ei1 on e1.event_type = ei1.event_type
							where event_name = 'Purchase')
group by ph.product_category
)
select 
	pf.product_category,
	sum(pf.viewed) as total_viewed, 
	sum(pf.added_to_cart) as total_added_to_cart,
	sum(pa.abandoned) as total_abandoned,
	sum(pp.purchased) as total_purchased
from clique_bait.product_info pf
join product_abandoned pa on pf.product_category = pa.product_category
join product_purchased pp on pf.product_category = pp.product_category
GROUP BY 1
);

SELECT * FROM clique_bait.category_info;
```
| product_category | total_viewed | total_added_to_cart | total_abandoned | total_purchased |
|------------------|--------------|---------------------|-----------------|-----------------|
| Fish             | 4633         | 2789                | 2022            | 6345            |
| Luxury           | 3032         | 1870                | 932             | 2808            |
| Shellfish        | 6204         | 3792                | 3576            | 11592           |

#### 1. Which product had the most views, cart adds and purchases?

```sql
with views as 
(
select *,
	rank() over (order by viewed desc) ranking
from clique_bait.product_info
)
, cart_adds as 
(
select *,
	rank() over (order by added_to_cart desc) ranking
from clique_bait.product_info
)
, purchases as 
(
select *,
	rank() over (order by purchased desc) ranking
from clique_bait.product_info
)
select 
	'Most views' as tag,
	page_name as product_name
from views
where ranking = 1
UNION ALL
select 
	'Most cart adds' as tag,
	page_name as product_name
from cart_adds
where ranking = 1
UNION ALL
select 
	'Most purchases' as tag,
	page_name as product_name
from purchases
where ranking = 1;
```
| tag            | product_name |
|----------------|--------------|
| Most views     | Oyster       |
| Most cart adds | Lobster      |
| Most purchases | Lobster      |

#### 2. Which product was most likely to be abandoned?

```sql
with abandoned as 
(
select *, rank() over (order by abandoned desc) ranking
from clique_bait.product_info
)
select page_name as product_name from abandoned where ranking = 1;
```
|product_name|
|---|
|Russian Caviar|

#### 3. Which product had the highest view to purchase percentage?

```sql
with purchase_per_view_pct as 
(
select 
	page_name, product_category,
	cast(100.0*purchased/viewed as decimal (5,2)) purchase_per_view_pct,
	rank() over (order by 100.0*purchased/viewed desc) ranking
from clique_bait.product_info
)
select 
	page_name as product_name
	, product_category
	, purchase_per_view_pct
from purchase_per_view_pct 
where ranking = 1; 
```
| product_name | product_category | purchase_per_view_pct |
|--------------|------------------|-----------------------|
| Lobster      | Shellfish        | 48.74                 |

#### 4. What is the average conversion rate from view to cart add?

```sql
select 
	round(avg(100.0*added_to_cart/viewed),2) avg_view_to_cart
from clique_bait.product_info;
```
|avg_view_to_cart|
|---|
|60.95|

#### 5. What is the average conversion rate from cart add to purchase?

```sql
select 
	round(avg(100.0*purchased/added_to_cart),2) avg_cart_to_purchase
from clique_bait.product_info;
```
|avg_cart_to_purchase|
|---|
|75.93|

### C. Campaigns Analysis
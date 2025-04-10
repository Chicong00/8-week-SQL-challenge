# 🍕 Pizza Runner: Solution

💻 Work performed on Azure Data Studio 💻

[SQL Syntax](https://github.com/Chicong00/8-week-SQL-challenge/blob/cb3a4a4c864ef48dc11aa08ac2bad6292b99e9c2/Case%20Study%20%232%20-%20Pizza%20Runner/Pizza_runner.sql)

### Cleaning & Transformations
````sql
-- Create customer_orders_cleaned view
DROP VIEW IF EXISTS pizza_runner.customer_orders_cleaned;
CREATE VIEW pizza_runner.customer_orders_cleaned as 
    SELECT
        order_id,
        customer_id,
        pizza_id,
        CASE 
            WHEN exclusions in ('','null', 'NaN') THEN null
            ELSE exclusions
        END as exclusions,
        CASE
            WHEN extras in ('','null', 'NaN') THEN null
            ELSE extras
        END as extras,
        CAST(order_time AS TIMESTAMP) as order_time -- Convert to timestamp for order_time
    FROM pizza_runner.customer_orders;

select * from pizza_runner.customer_orders_cleaned;

````
| order_id | customer_id | pizza_id | exclusions | extras | order_time          |
|----------|-------------|----------|------------|--------|---------------------|
| 1        | 101         | 1        | NULL       | NULL   | 2020-01-01 18:05:02 |
| 2        | 101         | 1        | NULL       | NULL   | 2020-01-01 19:00:52 |
| 3        | 102         | 1        | NULL       | NULL   | 2020-01-02 23:51:23 |
| 3        | 102         | 2        | NULL       | NULL   | 2020-01-02 23:51:23 |
| 4        | 103         | 1        | 4          | NULL   | 2020-01-04 13:23:46 |
| 4        | 103         | 1        | 4          | NULL   | 2020-01-04 13:23:46 |
| 4        | 103         | 2        | 4          | NULL   | 2020-01-04 13:23:46 |
| 5        | 104         | 1        | NULL       | 1      | 2020-01-08 21:00:29 |
| 6        | 101         | 2        | NULL       | NULL   | 2020-01-08 21:03:13 |
| 7        | 105         | 2        | NULL       | 1      | 2020-01-08 21:20:29 |
| 8        | 102         | 1        | NULL       | NULL   | 2020-01-09 23:54:33 |
| 9        | 103         | 1        | 4          | 1, 5   | 2020-01-10 11:22:59 |
| 10       | 104         | 1        | NULL       | NULL   | 2020-01-11 18:34:49 |
| 10       | 104         | 1        | 2, 6       | 1, 4   | 2020-01-11 18:34:49 |

````sql
-- Create runner_orders_cleaned view and change data types for pickup_time, distance, duration, and cancellation columns
DROP VIEW IF EXISTS pizza_runner.runner_orders_cleaned;
CREATE VIEW pizza_runner.runner_orders_cleaned AS 
    SELECT 
        order_id,
        runner_id,
        CASE 
            WHEN pickup_time IN ('', 'NaN', 'null') THEN NULL
            ELSE CAST(pickup_time AS TIMESTAMP) -- Convert to timestamp for pickup_time
        END AS pickup_time,
        -- Clean distance column - extract numeric value only
        CASE 
            WHEN distance IN ('', 'NaN', 'null') THEN NULL 
            ELSE CAST(TRIM(REGEXP_REPLACE(distance, '[^0-9\.]', '', 'g')) AS FLOAT) -- Convert to float for distance in km
        END AS distance_km,
        -- Clean duration column - extract numeric value only
        CASE 
            WHEN duration IN ('', 'NaN', 'null') THEN NULL 
            ELSE CAST(TRIM(REGEXP_REPLACE(duration, '[^0-9]', '', 'g')) AS INT) -- Convert to int for duration in minutes
        END AS duration_mins,
        CASE 
            WHEN cancellation IN ('', 'NaN', 'null') THEN NULL 
            ELSE CAST(cancellation AS VARCHAR(50))
        END AS cancellation
    FROM pizza_runner.runner_orders;

select * from pizza_runner.runner_orders_cleaned;
````
| order_id | runner_id | pickup_time         | distance_km | duration_mins | cancellation            |
| -------- | --------- | ------------------- | ----------- | ------------- | ----------------------- |
| 1        | 1         | 2020-01-01 18:15:34 | 20          | 32            | NULL                    |
| 2        | 1         | 2020-01-01 19:10:54 | 20          | 27            | NULL                    |
| 3        | 1         | 2020-01-03 00:12:37 | 13.4        | 20            | NULL                    |
| 4        | 2         | 2020-01-04 13:53:03 | 23.4        | 40            | NULL                    |
| 5        | 3         | 2020-01-08 21:10:57 | 10          | 15            | NULL                    |
| 6        | 3         | NULL                | NULL        | NULL          | Restaurant Cancellation |
| 7        | 2         | 2020-01-08 21:30:45 | 25          | 25            | NULL                    |
| 8        | 2         | 2020-01-10 00:15:02 | 23.4        | 15            | NULL                    |
| 9        | 2         | NULL                | NULL        | NULL          | Customer Cancellation   |
| 10       | 1         | 2020-01-11 18:50:20 | 10          | 10            | NULL                    |

---

## A. Pizza Metrics
### 1. How many pizzas were ordered ?
````sql
select count(*) pizza_order_count
from pizza_runner.customer_orders_cleaned;
````
|pizza_order_count|
|---|
|14|

### 2. How many unique customer orders were made?
````sql
select COUNT(distinct customer_id) customer_order_count
from pizza_runner.customer_orders_cleaned;
````
|customer_order_count|
|---|
|5|

### 3. How many successful orders were delivered by each runner?
````sql
select count(*) successful_orders
from pizza_runner.runner_orders_cleaned
where cancellation is NULL
````
|successful_orders|
|---|
|8|

### 4. How many of each type of pizza was delivered?
````sql
select 
    pizza_name,
    count(*) order_count
from pizza_runner.runner_orders_cleaned r 
join pizza_runner.customer_orders_cleaned c 
on r.order_id = c.order_id
join pizza_runner.pizza_names p 
on c.pizza_id = p.pizza_id 
where cancellation is NULL 
group by pizza_name;
````
|pizza_name	|order_count|
|---|---|
|Meatlovers	|9|
|Vegetarian	|3|

### 5. How many Vegetarian and Meatlovers were ordered by each customer?
````sql
SELECT 
    customer_id,
    pizza_name,
    count(*) order_count
from pizza_runner.customer_orders_cleaned c 
join pizza_runner.pizza_names p 
on c.pizza_id = p.pizza_id
group by customer_id,pizza_name
order by customer_id;
````
|customer_id|pizza_name|order_count|
|---|---|---|	
|101	|Meatlovers	|2|
|101	|Vegetarian	|1|
|102	|Meatlovers	|2|
|102	|Vegetarian	|1|
|103	|Meatlovers	|3|
|103	|Vegetarian	|1|
|104	|Meatlovers	|3|
|105	|Vegetarian	|1|

### 6. What was the maximum number of pizzas delivered in a single order?
````sql
with cte as
(
    select
        order_id,
        customer_id,
        count(*) pizza_count
    from dbo.#customer_orders_cleaned
    group by order_id, customer_id    
)
select top 1 * from cte
order by pizza_count desc
````
|order_id|customer_id|pizza_count|
|---|---|---|
|4	|103	|3|

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

From my understanding, "change" means the pizza is not the original recipe, and some ingredients will be added (`extras`) or removed (`exclusions`). 

=> If the values in `extras` or `exclusions` are not null -> **Change**  

````sql
select 
    customer_id,
    sum(case 
        when exclusions is null and extras is null then 1 
        else 0 end) as no_change,
    sum(case 
        when extras is not null or exclusions is not null then 1
        else 0 end) as at_least_1_change
from pizza_runner.customer_orders_cleaned c 
join pizza_runner.runner_orders_cleaned r 
on c.order_id =r.order_id
where r.cancellation is null 
GROUP BY customer_id;
````
|customer_id|no_change|at_least_1_change|
|---|---|---|
|101	|2	|0|
|102	|3	|0|
|103	|0	|3|
|104	|1	|2|
|105	|0	|1|

### 8. How many pizzas were delivered that had both exclusions and extras?
````sql
SELECT 
    sum(CASE 
        WHEN exclusions is not null and extras is not null THEN 1 
        ELSE 0 END) as pizza_with_exclusions_extras
from pizza_runner.customer_orders_cleaned c 
join pizza_runner.runner_orders_cleaned r 
on c.order_id = r.order_id 
where r.cancellation is null;
````
|customer_id	|pizza_with_exclusions_extras|
|---|---|
|104	|1|

### 9. What was the total volume of pizzas ordered for each hour of the day?
````sql
SELECT 
    date_part('hour',order_time) hour_of_day, 
    count(order_id) total_orders
from pizza_runner.customer_orders_cleaned 
GROUP by date_part('hour',order_time)
order by 1;
````
|hour_of_day|total_orders|
|---|---|
|11	|1|
|13	|3|
|18	|3|
|19	|1|
|21	|3|
|23	|3|

### 10. What was the volume of orders for each day of the week?
````sql
SELECT 
    to_char(order_time, 'Day') AS day_of_week,
    COUNT(order_id) AS total_orders
FROM pizza_runner.customer_orders_cleaned
GROUP BY EXTRACT(ISODOW FROM order_time), to_char(order_time, 'Day')
ORDER BY EXTRACT(ISODOW FROM order_time);
````
|day_of_week|total_orders|
|---|---|
|Wednesday	|5|
|Thursday	|3
|Friday	|1|
|Saturday	|5|

 **`ISODOW` (ISO-based Day of Week 7 represents Sunday while 1 represents Monday)*

 Including both `ISODOW` and `Day` name ensures accurate grouping and ordering by weekday while still showing the readable name.

---

## B. Runner and Customer Experience
### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
````sql
SELECT
  FLOOR((registration_date - DATE '2021-01-01') / 7) + 1 AS week_number,
  COUNT(*) AS runner_count
FROM pizza_runner.runners
GROUP BY 1
ORDER BY 1;
````
|registration_week|runner_count|
|---|---|
|1	|2|
|2	|1|
|3	|1|

Because the week starts 2021-01-01 so I will count the number of days between the `registration_date` and 2021-01-01, then divide by 7 to know the week number, and `+1` to ensure it starts at week 1 for 2021-01-01 to 2021-01-07

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
````sql
WITH time_taken_cte AS
(
  SELECT 
    c.order_id, 
    c.order_time, 
    r.pickup_time, 
    extract(epoch from (r.pickup_time - c.order_time))/60 AS pickup_minutes
  FROM pizza_runner.customer_orders_cleaned AS c
  JOIN pizza_runner.runner_orders_cleaned AS r
    ON c.order_id = r.order_id
  WHERE r.cancellation is null  
  GROUP BY c.order_id, c.order_time, r.pickup_time
)

SELECT 
  Ceil(AVG(pickup_minutes)) AS avg_pickup_minutes
FROM time_taken_cte
WHERE pickup_minutes > 1;
````
|avg_pickup_minutes|
|---|
|16|

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
````sql
SELECT
  pizza_count,
  Floor(AVG(EXTRACT(EPOCH FROM (sub.pickup_time - sub.order_time)) / 60)) AS avg_prep_time_mins
FROM (
  SELECT
    c.order_id,
    COUNT(c.order_id) AS pizza_count,
    c.order_time,
    r.pickup_time
  FROM pizza_runner.customer_orders_cleaned AS c
  JOIN pizza_runner.runner_orders_cleaned AS r
    ON c.order_id = r.order_id
  WHERE r.cancellation IS NULL
  GROUP BY c.order_id, c.order_time, r.pickup_time
) AS sub
GROUP BY pizza_count
ORDER BY pizza_count;
````
|pizza_count|avg_prep_time|
|---|---|
|1	|12|
|2	|18|
|3	|29|

### 4. What was the average distance travelled for each customer?
````sql
SELECT
    c.customer_id,
    ROUND(AVG(r.distance_km)::numeric, 2) AS avg_distance_km
FROM pizza_runner.runner_orders_cleaned AS r
JOIN pizza_runner.customer_orders_cleaned AS c
  ON r.order_id = c.order_id
WHERE r.cancellation IS NULL
GROUP BY 1;
````
|customer_id|avg_distance|
|---|---|
|101	|20.00|
|102	|16.73|
|103	|23.40|
|104	|10.00|
|105	|25.00|

### 5. What was the difference between the longest and shortest delivery times for all orders?
````sql
SELECT 
    MAX(r.duration_mins) AS max_delivery_time,
    MIN(r.duration_mins) AS min_delivery_time,    
    MAX(r.duration_mins) - MIN(r.duration_mins) AS delivery_time_difference
FROM pizza_runner.runner_orders_cleaned AS r
WHERE r.duration_mins IS not NULL;
````
|max_delivery_time|min_delivery_time|delivery_time_difference|
|---|---|---|
|40	|10	|30|

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
````sql
SELECT 
  r.runner_id, 
  COUNT(r.order_id) order_count,
  distance_km,
  duration_mins,
  ROUND((r.distance_km/r.duration_mins * 60)::numeric, 2) AS avg_speed_km_per_hour
FROM pizza_runner.runner_orders_cleaned AS r
JOIN pizza_runner.customer_orders_cleaned AS c
  ON r.order_id = c.order_id
WHERE distance_km is not NULL
GROUP BY r.runner_id, r.distance_km, r.duration_mins;
````
| runner_id | order_count | distance_km | duration_mins | avg_speed_km_per_hour |
|-----------|-------------|-------------|---------------|-----------|
| 1         | 2           | 10          | 10            | 60        |
| 1         | 1           | 20          | 27            | 44.44     |
| 1         | 2           | 13.4        | 20            | 40.2      |
| 1         | 1           | 20          | 32            | 37.5      |
| 2         | 1           | 23.4        | 15            | 93.6      |
| 2         | 1           | 25          | 25            | 60        |
| 2         | 3           | 23.4        | 40            | 35.1      |
| 3         | 1           | 10          | 15            | 40        |

### 7. What is the successful delivery percentage for each runner?
````sql
select
    runner_id,
    COUNT(*) total_orders,
    sum(
        case
        when cancellation is null then 1 else 0 end) as successful_orders,
    round((100*sum(
        case
        when cancellation is null then 1 else 0 end)/count(*)),0)
     as successfull_percentage
from #runner_orders_cleaned
group by runner_id
````
|runner_id|total_orders|successful_orders|successful_percentage|
|---|---|---|---|
|1	|4	|4	|100|
|2	|4	|3	|75|
|3	|2	|1	|50|


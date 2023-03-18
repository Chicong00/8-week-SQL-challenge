# 🍕 Pizza Runner: Solution

💻 Work performed on Azure Data Studio 💻

[SQL Syntax](https://github.com/Chicong00/8-week-SQL-challenge/blob/cb3a4a4c864ef48dc11aa08ac2bad6292b99e9c2/Case%20Study%20%232%20-%20Pizza%20Runner/Pizza_runner.sql)

### Cleaning & Transformations
````sql
-- customer_orders_cleaned
SELECT
    order_id,
    customer_id,
    pizza_id,
    CASE
        WHEN exclusions = 'null' THEN null
        ELSE exclusions
    END as exclusions,
    CASE
        WHEN extras = 'null' OR extras = 'NaN' THEN null
        ELSE extras
    END as extras,
    order_time
INTO #customer_orders_cleaned
FROM customer_orders 
 
select * from #customer_orders_cleaned
````
|order_id|customer_id|pizza_id|exclusions|extras|order_time|
|---|---|---|---|---|---|
|1	|101	|1	|NULL	|NULL	|2021-01-01 18:05:00|
|2	|101	|1	|NULL	|NULL	|2021-01-01 19:00:00|
|3	|102	|1	|NULL	|NULL	|2021-01-02 23:51:00|
|3	|102	|2	|NULL	|NULL	|2021-01-02 23:51:00|
|4	|103	|1	|4	|NULL	|2021-01-04 13:23:00|
|4	|103	|1	|4	|NULL	|2021-01-04 13:23:00|
|4	|103	|2	|4	|NULL	|2021-01-04 13:23:00|
|5	|104	|1	|NULL	|1	|2021-01-08 21:00:00|
|6	|101	|2	|NULL	|NULL	|2021-01-08 21:03:00|
|7	|105	|2	|NULL	|1	|2021-01-08 21:20:00|
|8	|102	|1	|NULL	|NULL	|2021-01-09 23:54:00|
|9	|103	|1	|4	|1, 5	|2021-01-10 11:22:00|
|10	|104	|1	|NULL	|NULL	|2021-01-11 18:34:00|
|10	|104	|1	|2, 6	|1, 4	|2021-01-11 18:34:00|

````sql
-- runner_orders_cleaned
select
    order_id, runner_id, pickup_time, distance_km, duration_mins,
    case
    when cancellation = '0' then null
    else cancellation
    end as cancellation
into #runner_orders_cleaned
from runner_orders
 
select * from #runner_orders_cleaned
````
|order_id|runner_id|pickup_time|distance_km|duration_mins|cancellation|
|---|---|---|---|---|---|					
|1	|1	|2021-01-01 18:15:00	|20	|32	|NULL|
|2	|1	|2021-01-01 19:10:00	|20	|27	|NULL|
|3	|1	|2021-01-03 00:12:00	|13,4	|20	|NULL|
|4	|2	|2021-01-04 13:53:00	|23,4	|40	|NULL|
|5	|3	|2021-01-08 21:10:00	|10	|15	|NULL|
|6	|3	|NULL	|NULL	|NULL	|Restaurant Cancellation|
|7	|2	|2020-01-08 21:30:00	|25	|25	|NULL|
|8	|2	|2020-01-10 00:15:00	|23,4	|15	|NULL|
|9	|2	|NULL	|NULL	|NULL	|Customer |Cancellation|
|10	|1	|2020-01-11 18:50:00	|10	|10	|NULL|

---

## A. Pizza Metrics
### 1. How many pizzas were ordered ?
````sql
select count(*) pizza_order_count
from #customer_orders_cleaned
````
|pizza_order_count|
|---|
|14|

### 2. How many unique customer orders were made?
````sql
select COUNT(distinct customer_id) customer_order_count
from #customer_orders_cleaned
````
|customer_order_count|
|---|
|5|

### 3. How many successful orders were delivered by each runner?
````sql
select count(*) successful_orders
from #runner_orders_cleaned
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
from dbo.#runner_orders_cleaned r 
join dbo.#customer_orders_cleaned c 
on r.order_id = c.order_id
join dbo.pizza_names p 
on c.pizza_id = p.pizza_id 
where cancellation is NULL
group by pizza_name
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
from dbo.#customer_orders_cleaned c 
join dbo.pizza_names p 
on c.pizza_id = p.pizza_id
group by customer_id,pizza_name
order by customer_id
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
````sql
with cte as
(
    select
        c.customer_id,
     
        case
        when exclusions is null and extras is null then 1 
        else 0
        end as no_change
    ,
     
        case
        when extras is not null or exclusions is not null then 1
        else 0 
        end as at_least_1_change
 
    from dbo.#customer_orders_cleaned c 
    join dbo.#runner_orders_cleaned r 
    on c.order_id =r.order_id
    where r.cancellation is null
)
select
    customer_id,
    sum(no_change) no_change,
    sum(at_least_1_change) at_least_1_change
from cte 
group by customer_id
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
    customer_id,
    count(*) pizza_with_exclusions_extras 
from dbo.#customer_orders_cleaned c 
join dbo.#runner_orders_cleaned r 
on c.order_id = r.order_id 
where cancellation is null and exclusions is not NULL and extras is not null
group by customer_id
````
|customer_id	|pizza_with_exclusions_extras|
|---|---|
|104	|1|

### 9. What was the total volume of pizzas ordered for each hour of the day?
````sql
SELECT
    datepart(hour,order_time) hour_of_day, 
    count(pizza_id) total_orders
from dbo.#customer_orders_cleaned 
GROUP by datepart(hour,order_time)
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
    format(order_time,'dddd') day_of_week,
    count(pizza_id) total_orders 
from dbo.#customer_orders_cleaned
GROUP BY format(order_time,'dddd')
````
|day_of_week|total_orders|
|---|---|
|Friday	|5|
|Monday	|5
|Saturday	|3|
|Sunday	|1|

---

## B. Runner and Customer Experience
### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
````sql
select
    DATEPART(WEEK,registration_date) registration_week,
    count(runner_id) runner_count 
from dbo.runners
group by DATEPART(WEEK,registration_date)
````
|registration_week|runner_count|
|---|---|
|1	|1|
|2	|2|
|3	|1|

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
````sql
WITH time_taken_cte AS
(
  SELECT
    c.order_id, 
    c.order_time, 
    r.pickup_time, 
    DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS pickup_minutes
  FROM #customer_orders_cleaned AS c
  JOIN #runner_orders_cleaned AS r
    ON c.order_id = r.order_id
  WHERE r.cancellation is null 
  GROUP BY c.order_id, c.order_time, r.pickup_time
)
 
SELECT
  AVG(pickup_minutes) AS avg_pickup_minutes
FROM time_taken_cte
WHERE pickup_minutes > 1;
````
|avg_pickup_minutes|
|---|
|16|

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
````sql
WITH Preparation AS (
  SELECT
    c.order_id, 
    c.order_time, 
    r.pickup_time,
    DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS prep_time,
    COUNT(c.pizza_id) AS pizza_count
  FROM dbo.#customer_orders_cleaned c
  JOIN dbo.#runner_orders_cleaned  r
    ON c.order_id = r.order_id
  WHERE r.cancellation IS NULL
  GROUP BY c.order_id, c.order_time, r.pickup_time, 
           DATEDIFF(MINUTE, c.order_time, r.pickup_time)
)
 
SELECT
  pizza_count,
  AVG(prep_time) AS avg_prep_time
FROM Preparation
GROUP BY pizza_count
````
|pizza_count|avg_prep_time|
|---|---|
|1	|12|
|2	|18|
|3	|30|

### 4. What was the average distance travelled for each customer?
````sql
SELECT
    c.customer_id,
    round(avg(distance_km),2) avg_distance 
from dbo.#runner_orders_cleaned  r 
join dbo.#customer_orders_cleaned c
on r.order_id = c.order_id  
WHERE distance_km is not NULL
group by customer_id
````
|customer_id|avg_distance|
|---|---|
|101	|20|
|102	|16.73|
|103	|23.4|
|104	|10|
|105	|25|

### 5. What was the difference between the longest and shortest delivery times for all orders?
````sql
SELECT
    MAX(duration_mins) AS max_delivery_time,
    MIN(duration_mins) AS min_delivery_time,
    MAX(duration_mins) - MIN(duration_mins) AS time_difference
FROM dbo.#runner_orders_cleaned
````
|max_delivery_time|min_delivery_time|time_difference|
|---|---|---|
|40	|10	|30|

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
````sql
select
    runner_id,
    COUNT(r.order_id) order_count,
    distance_km,
    duration_mins,
    concat(round(avg(60*distance_km/duration_mins),2),' km/h') speed 
from dbo.#runner_orders_cleaned r 
join dbo.#customer_orders_cleaned c 
on r.order_id = c.order_id
WHERE duration_mins is not NULL and distance_km is not NULL
group by runner_id, distance_km,duration_mins
````
|runner_id|order_count|distance_km|duration_mins|speed|
|---|---|---|---|---|		
|1	|2	|10	|10	|60 km/h|
|1	|2	|13.4	|20	|40.2 km/h|
|1	|1	|20	|27	|44.44 km/h|
|1	|1	|20	|32	|37.5 km/h|
|2	|1	|23.4	|15	|93.6 km/h|
|2	|3	|23.4	|40	|35.1 km/h|
|2	|1	|25	|25	|60 km/h|
|3	|1	|10	|15	|40 km/h|

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


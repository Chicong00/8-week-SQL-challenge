----- CLEANING & TRANSFORMATIONS -----

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
        order_time
    FROM pizza_runner.customer_orders;

select * from pizza_runner.customer_orders_cleaned;

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

----- A. Pizza Metrics -----
-- 1. How many pizzas were ordered?
select count(*) pizza_order_count
from pizza_runner.customer_orders_cleaned;

-- 2. How many unique customer orders were made?
select COUNT(distinct customer_id) customer_order_count
from pizza_runner.customer_orders_cleaned;

-- 3. How many successful orders were delivered by each runner?
select count(*) successful_orders
from pizza_runner.runner_orders_cleaned
where cancellation is NULL;

-- 4. How many of each type of pizza was delivered?
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

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
    customer_id,
    pizza_name,
    count(*) order_count
from pizza_runner.customer_orders_cleaned c 
join pizza_runner.pizza_names p 
on c.pizza_id = p.pizza_id
group by customer_id,pizza_name
order by customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
with cte as (SELECT 
        order_id,
        customer_id,
        count(*) pizza_count,
        dense_rank() over (order by count(*) desc) as rank_pizza_count 
    from pizza_runner.customer_orders_cleaned
    group by order_id, customer_id)

SELECT order_id,customer_id,pizza_count FROM cte
WHERE rank_pizza_count = 1;


-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
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

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT 
    sum(CASE 
        WHEN exclusions is not null and extras is not null THEN 1 
        ELSE 0 END) as pizza_with_exclusions_extras
from pizza_runner.customer_orders_cleaned c 
join pizza_runner.runner_orders_cleaned r 
on c.order_id = r.order_id 
where r.cancellation is null;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
    date_part('hour',order_time) hour_of_day, 
    count(order_id) total_orders
from pizza_runner.customer_orders_cleaned 
GROUP by date_part('hour',order_time)
order by 1;

-- 10. What was the volume of orders for each day of the week?
SELECT 
    to_char(order_time, 'Day') AS day_of_week,
    COUNT(order_id) AS total_orders
FROM pizza_runner.customer_orders_cleaned
GROUP BY EXTRACT(ISODOW FROM order_time), to_char(order_time, 'Day')
ORDER BY EXTRACT(ISODOW FROM order_time); -- ISODOW(ISO-based Day of Week 7 represents Sunday while 1 represents Monday)

----- B. Runner and Customer Experience -----
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
  FLOOR((registration_date - DATE '2021-01-01') / 7) + 1 AS week_number,
  COUNT(*) AS runner_count
FROM pizza_runner.runners
GROUP BY 1
ORDER BY 1;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
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
  ceil(AVG(pickup_minutes)) AS avg_pickup_minutes
FROM time_taken_cte
WHERE pickup_minutes > 1;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- 4. What was the average distance travelled for each customer?
-- 5. What was the difference between the longest and shortest delivery times for all orders?
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- 7. What is the successful delivery percentage for each runner?
-- Bài làm -> Sai 
with not_canceled as 
(
    select
        runner_id,
        count(c.order_id) total_orders
    from pizza_runner.runner_orders_cleaned r 
    join pizza_runner.customer_orders_cleaned c 
    on r.order_id = c.order_id
    group by runner_id 
),
canceled as 
(
    select
        runner_id,
        count(*) successfull_orders
    from pizza_runner.runner_orders_cleaned r 
    join pizza_runner.customer_orders_cleaned c 
    on r.order_id = c.order_id
    where cancellation is null
    group by runner_id 
)    
select 
    c.runner_id,
    total_orders,
    successfull_orders,
    convert(float,round((100.0*successfull_orders/total_orders),2)) as successful_delivery
from not_canceled n 
join canceled c 
on n.runner_id = c.runner_id

-- Làm lại 
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
from pizza_runner.runner_orders_cleaned
group by runner_id


-- Bài sửa
SELECT 
    COUNT(order_id) total_orders,
    runner_id, 
    ROUND(100 * SUM(
    CASE WHEN distance_km is null THEN 0
    ELSE 1 END) / COUNT(*), 0) AS success_perc
from pizza_runner.runner_orders_cleaned
GROUP BY runner_id;

----- C. Ingredient Optimisation -----
----- D. Pricing and Ratings -----
----- E. Bonus Questions -----


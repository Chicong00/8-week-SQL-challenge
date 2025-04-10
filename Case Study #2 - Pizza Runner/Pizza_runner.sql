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

-- 4. What was the average distance travelled for each customer?
SELECT
    c.customer_id,
    ROUND(AVG(r.distance_km)::numeric, 2) AS avg_distance_km
FROM pizza_runner.runner_orders_cleaned AS r
JOIN pizza_runner.customer_orders_cleaned AS c
  ON r.order_id = c.order_id
WHERE r.cancellation IS NULL
GROUP BY 1;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT 
    MAX(r.duration_mins) AS max_delivery_time,
    MIN(r.duration_mins) AS min_delivery_time,    
    MAX(r.duration_mins) - MIN(r.duration_mins) AS delivery_time_difference
FROM pizza_runner.runner_orders_cleaned AS r
WHERE r.duration_mins IS not NULL;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- speed = distance / time
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
GROUP BY r.runner_id, r.distance_km, r.duration_mins
ORDER BY r.runner_id, avg_speed DESC;

-- 7. What is the successful delivery percentage for each runner?
-- successful delivery percentage = (successful orders / total orders) * 100
-- succesful orders = orders with no cancellation -> cancellation is null
-- total orders = all orders (including canceled ones) -> count all orders
SELECT
    r.runner_id,
    COUNT(r.order_id) total_orders,
    SUM(CASE WHEN r.cancellation IS NULL THEN 1 ELSE 0 END) AS successful_orders,
    ROUND((100.0 * SUM(CASE WHEN r.cancellation IS NULL THEN 1 ELSE 0 END) / COUNT(r.order_id))::numeric, 2) AS success_pct
FROM pizza_runner.runner_orders_cleaned AS r
GROUP BY r.runner_id
ORDER BY 1, 4 DESC;

----- C. Ingredient Optimisation -----

-- 1. What are the standard ingredients for each pizza?
WITH exploded_toppings AS (
  SELECT
    pizza_id,
    TRIM(UNNEST(STRING_TO_ARRAY(toppings, ',')))::INT AS topping_id
  FROM pizza_runner.pizza_recipes
),
pizza_ingredients AS (
  SELECT
    e.pizza_id,
    t.topping_name
  FROM exploded_toppings e
  JOIN pizza_runner.pizza_toppings t
    ON e.topping_id = t.topping_id
)
SELECT pizza_id, STRING_AGG(topping_name, ', ' ORDER BY topping_name) AS ingredients
FROM pizza_ingredients
GROUP BY pizza_id
ORDER BY pizza_id;

-- 2. What was the most commonly added extra?
with exploded_extras as(
SELECT
    order_id,
    pizza_id,
    TRIM(UNNEST(STRING_TO_ARRAY(extras, ',')))::INT AS extra_id
FROM pizza_runner.customer_orders_cleaned
WHERE extras IS NOT NULL
), extras_names as(
SELECT e.*,
       t.topping_name
FROM exploded_extras e
JOIN pizza_runner.pizza_toppings t
ON e.extra_id = t.topping_id
), extras_ranked as(
SELECT
    topping_name,
    COUNT(*) AS extra_count,
    rank() over (ORDER BY COUNT(*) DESC) AS extra_rank
FROM extras_names
GROUP BY 1
)
SELECT topping_name, extra_count
FROM extras_ranked
WHERE extra_rank = 1;

-- 3. What was the most common exclusion?
with exploded_exc as(
SELECT
    order_id,
    pizza_id,
    TRIM(UNNEST(STRING_TO_ARRAY(exclusions, ',')))::INT AS exc_id
FROM pizza_runner.customer_orders_cleaned
WHERE exclusions IS NOT NULL
), exc_names as(
SELECT e.*,
       t.topping_name
FROM exploded_exc e
JOIN pizza_runner.pizza_toppings t
ON e.exc_id = t.topping_id
), exc_ranked as(
SELECT
    topping_name,
    COUNT(*) AS exclusion_count,
    rank() over (ORDER BY COUNT(*) DESC) AS exc_rank
FROM exc_names
GROUP BY 1
)
SELECT topping_name, exclusion_count
FROM exc_ranked
WHERE exc_rank = 1;





----- D. Pricing and Ratings -----
----- E. Bonus Questions -----


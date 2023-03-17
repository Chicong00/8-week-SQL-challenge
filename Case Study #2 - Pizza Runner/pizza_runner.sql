select * from dbo.customer_orders
select * from dbo.pizza_names
select * from dbo.pizza_recipes
SELECT * from dbo.runner_orders
select * from dbo.runners

----- CLEANING & TRANSFORMATIONS -----
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

----- A. Pizza Metrics -----
-- 1. How many pizzas were ordered?
select count(*) pizza_order_count
from #customer_orders_cleaned

-- 2. How many unique customer orders were made?
select COUNT(distinct customer_id) customer_order_count
from #customer_orders_cleaned

-- 3. How many successful orders were delivered by each runner?
select count(*) successful_orders
from #runner_orders_cleaned
where cancellation is NULL

-- 4. How many of each type of pizza was delivered?
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

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
    customer_id,
    pizza_name,
    count(*) order_count
from dbo.#customer_orders_cleaned c 
join dbo.pizza_names p 
on c.pizza_id = p.pizza_id
group by customer_id,pizza_name
order by customer_id

-- 6. What was the maximum number of pizzas delivered in a single order?
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

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT * from dbo.#runner_orders_cleaned
SELECT * from dbo.#customer_orders_cleaned

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

-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT 
    customer_id,
    count(*) pizza_with_exclusions_extras 
from dbo.#customer_orders_cleaned c 
join dbo.#runner_orders_cleaned r 
on c.order_id = r.order_id 
where cancellation is null and exclusions is not NULL and extras is not null 
group by customer_id

-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT 
    datepart(hour,order_time) hour_of_day, 
    count(pizza_id) total_orders
from dbo.#customer_orders_cleaned 
GROUP by datepart(hour,order_time)

-- 10. What was the volume of orders for each day of the week?
SELECT
    format(order_time,'dddd') day_of_week,
    count(pizza_id)
from dbo.#customer_orders_cleaned
GROUP BY format(order_time,'dddd')


----- B. Runner and Customer Experience -----
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select * from runners

select 
    DATEPART(WEEK,registration_date) registration_week,
    count(runner_id) runner_count 
from dbo.runners
group by DATEPART(WEEK,registration_date)

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT * from dbo.runner_orders

select 
    c.order_id,
    order_time,
    pickup_time,
    AVG(DATEDIFF(MINUTE,order_time,pickup_time))
from #runner_orders_cleaned r 
join #customer_orders_cleaned c 
on r.order_id = c.order_id 
where cancellation is NULL 
GROUP by c.order_id, order_time,pickup_time

SELECT 
	r.runner_id,
	AVG(DATEDIFF(MINUTE, c.order_time, r.pickup_time)) AS avg_time_to_hq
FROM   
	#runner_orders_cleaned r,
	#customer_orders_cleaned c
WHERE c.order_id = r.order_id
GROUP  BY r.runner_id;

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
    from dbo.#runner_orders_cleaned r 
    join dbo.#customer_orders_cleaned c 
    on r.order_id = c.order_id
    group by runner_id 
),
canceled as 
(
    select
        runner_id,
        count(*) successfull_orders
    from dbo.#runner_orders_cleaned r 
    join dbo.#customer_orders_cleaned c 
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
from #runner_orders_cleaned
group by runner_id


-- Bài sửa
SELECT 
    COUNT(order_id) total_orders,
    runner_id, 
    ROUND(100 * SUM(
    CASE WHEN distance_km is null THEN 0
    ELSE 1 END) / COUNT(*), 0) AS success_perc
FROM #runner_orders_cleaned
GROUP BY runner_id;

----- C. Ingredient Optimisation -----
----- D. Pricing and Ratings -----
----- E. Bonus Questions -----


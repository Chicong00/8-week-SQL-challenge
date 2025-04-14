select * from foodie_fi.plans
select * from foodie_fi.subscriptions

----- A. CUSTOMER JOURNEY -----
--Based off the 8 sample customers provided in the sample from the subscriptions table, 
--write a brief description about each customer’s onboarding journey.
select s.*,p.plan_name,p.price
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id 
where customer_id in (1,4,6,23,49,58,79,80)
order by customer_id;

----- B. DATA ANALYSIS QUESTIONS -----
--1. How many customers has Foodie-Fi ever had?
select count(distinct(customer_id)) customer_count
from foodie_fi.subscriptions

--2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select 
    MONTH(start_date) month, 
    count(distinct customer_id) trial_subs
from foodie_fi.subscriptions s 
join foodie_fi.plans p  
on s.plan_id = p.plan_id 
where plan_name = 'trial'
group by month(start_date)

--3.What plan start_date values occur after the year 2020 for our dataset? 
--Show the breakdown by count of events for each plan_name

SELECT 
    plan_name,
    count(1) event_count_2021
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id
where year(start_date) >= 2021
group by plan_name
order by event_count_2021

SELECT 
    plan_name,
    count(1) event_count_2020
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id
where year(start_date) < 2021
group by plan_name
order by event_count_2020

select #20_.plan_name, event_count_2020, event_count_2021 
from 
(
   SELECT 
    plan_name,
    count(1) event_count_2020
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id
where year(start_date) < 2021
group by plan_name 
) #20_
left join
(
    SELECT 
    plan_name,
    count(1) event_count_2021
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id
where year(start_date) >= 2021
group by plan_name
) #21_
on #20_.plan_name = #21_.plan_name
order by event_count_2020 DESC

with event21 AS
(
  SELECT 
    plan_name,
    count(1) event_count_2021
  from foodie_fi.subscriptions s 
  join foodie_fi.plans p 
  on s.plan_id = p.plan_id
  where year(start_date) >= 2021
  group by plan_name
  --order by event_count_2021
),
event20 AS
(
  SELECT 
    plan_name,
    count(1) event_count_2020
  from foodie_fi.subscriptions s 
  join foodie_fi.plans p 
  on s.plan_id = p.plan_id
  where year(start_date) < 2021
  group by plan_name
  --order by event_count_2020
)

select event20.plan_name, event_count_2020, event_count_2021 
from event20 
left join event21 
on event20.plan_name = event21.plan_name
order by event_count_2020 DESC


--4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

Lấy ra customer có plan là 'churn' sau đó tính % của churn / tổng số customer 

with churned_cte as
(select distinct s.*,plan_name
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id 
where plan_name = 'churn')

select 
    count(*) churn_count,
    convert(float,round((100.0*count(distinct customer_id)/(select count(distinct customer_id) from foodie_fi.subscriptions)),2)) as churn_percentage
from churned_cte

--5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

Tạo thêm cột ranking của mỗi customer theo thứ tự order_date, từ đó lấy ra những customer có plan_id = 4 ranking = 2
-- Bài làm -> ĐÚNG
with ranking AS
(SELECT  s.*,plan_name,
    ROW_NUMBER() over (partition by customer_id order by start_date) rank_
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id)
 
select
    count(*) churn_count,
    round(100*count(*) / (select count(distinct customer_id) from foodie_fi.subscriptions),0) churn_percentage
from ranking
where plan_name = 'churn' and rank_= 2

--select *
--from ranking
--where plan_name = 'churn' and rank_ = 2 


--Bài sửa
-- To find ranking of the plans by customers and plans
WITH ranking AS (
SELECT 
  s.customer_id, 
  s.plan_id, 
  p.plan_name,
  -- Run a ROW_NUMBER() to rank the plans from 0 to 4
  ROW_NUMBER() OVER (
    PARTITION BY s.customer_id 
    ORDER BY s.plan_id) AS plan_rank 
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p
  ON s.plan_id = p.plan_id)
  
SELECT 
  COUNT(*) AS churn_count,
  ROUND(100 * COUNT(*) / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),0) AS churn_percentage
FROM ranking
WHERE plan_id = 4 -- Filter to churn plan
  AND plan_rank = 2 -- Filter to rank 2 as customers who churned immediately after trial have churn plan ranked as 2

--6. What is the number and percentage of customer plans after their initial free trial?
Số lượng mỗi plan và phần trăm mỗi plan sau lần đầu đky free trial 
<=> Tính toán sau khi customer dùng plan free trial thì plan tiếp theo họ dùng là gì và tỉ lệ % lựa chọn plan đó ntn 

--Bài làm -> ĐÚNG
with ranking AS
(SELECT  
    s.*,plan_name,
    ROW_NUMBER() over (partition by customer_id order by start_date) rank_
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id)
 
select
    plan_name next_plan,
    count(*) plan_count,
    convert(float,round(100.0*count(*) / (select count(distinct customer_id) from foodie_fi.subscriptions),2)) plan_percentage
from ranking
where 
        plan_name = 'churn' and rank_= 2
    or  plan_name = 'basic monthly' and rank_=2
    or  plan_name = 'pro monthly' and rank_=2
    or  plan_name = 'pro annual' and rank_=2
group by plan_name
order by plan_percentage desc 

--Bài sửa 
-- To retrieve next plan's start date located in the next row based on current row
WITH next_plan_cte AS (
SELECT 
  customer_id, 
  plan_id, 
  LEAD(plan_id, 1) OVER( -- Offset by 1 to retrieve the immediate row's value below 
    PARTITION BY customer_id 
    ORDER BY plan_id) as next_plan
FROM foodie_fi.subscriptions)

SELECT 
  next_plan, 
  COUNT(*) AS conversions,
  ROUND(100.0 * COUNT(*) / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),1) AS conversion_percentage
FROM next_plan_cte
WHERE next_plan IS NOT NULL 
  AND plan_id = 0
GROUP BY next_plan
ORDER BY next_plan;

--7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

--????????????????????????????????--
tính số lượng customer và phần trăm customer của 5 plan tại thời điểm 2020-12-31

--Bài làm -> SAI
with cte as 
(select
    s.*,
    plan_name,
    price
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id 
where start_date <= '2020-12-30')

SELECT
    plan_name,
    count(1) customer_count,
    CONVERT(float,round(100.0*count(*)/(select count(distinct customer_id) from cte),2)) 
from cte
group by plan_name

-----
-- Bài sửa (cách khác)
WITH ranked AS 
(
  SELECT
    customer_id,
    plan_name,
    RANK() OVER(PARTITION BY customer_id ORDER BY start_date desc) AS RANK
  FROM subscriptions AS s
  JOIN plans AS p 
  ON s.plan_id = p.plan_id
  WHERE start_date <= '2020-12-31' 
)

SELECT 
  plan_name,
  count(*) customer_count, 
  convert(float,ROUND((100.0*count(*)/(select count(distinct customer_id) from foodie_fi.subscriptions)),2)) percentage_of_plans
from ranked 
WHERE rank = 1
group by plan_name
order by 1



--Bài sửa 
-- To retrieve next plan's start date located in the next row based on current row
WITH next_plan AS(
SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
FROM foodie_fi.subscriptions
WHERE start_date <= '2020-12-31'),
-- To find breakdown of customers with existing plans on or after 31 Dec 2020
customer_breakdown AS (
  SELECT plan_id, COUNT(DISTINCT customer_id) AS customers
    FROM next_plan
    WHERE (next_date IS NOT NULL AND (start_date < '2020-12-31' AND next_date > '2020-12-31'))
      OR (next_date IS NULL AND start_date < '2020-12-31')
    GROUP BY plan_id)

SELECT plan_id, customers, 
  ROUND(100.0 * customers / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),1) AS percentage
FROM customer_breakdown
GROUP BY plan_id, customers
ORDER BY plan_id

--8. How many customers have upgraded to an annual plan in 2020?
có bao nhiêu customer nâng cấp lên plan pro annual trong năm 2020

SELECT 
    count(distinct customer_id) pro_annual_customers
from foodie_fi.subscriptions s  
join foodie_fi.plans p 
on s.plan_id = p.plan_id
where plan_name = 'pro annual' and YEAR(start_date) = 2020

--9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
thời gian trung bình (tính theo ngày) mà 1 customer đăng ký plan pro annual sau khi họ join vào Foodie-Fi 

--Bài làm -> ĐÚNG
-- phải lọc ra 2 bảng trial date và annual date để tính được thời gian từ khi join (tức là trial plan) cho đến khi upgrade lên plan pro annual
-- vì đề bài chỉ muốn biết khoảng thgian từ khi join đến khi upgrade lên annual plan (không quan tâm đến các plan trung gian của customer)
with annual AS
(
select customer_id, start_date annual_date
from foodie_fi.subscriptions
where plan_id = 3
), 
trial as 
(
select customer_id, start_date trial_date
from foodie_fi.subscriptions
where plan_id = 0
)

select 
    round(AVG(DATEDIFF(day,trial_date,annual_date)),0) avg_days_to_annual
from trial t 
join annual a 
on t.customer_id = a.customer_id

-----
with annual AS
(
select customer_id, start_date annual_date
from foodie_fi.subscriptions
where plan_id = 3
)

select 
    round(AVG(DATEDIFF(day,start_date,annual_date)),0) avg_days_to_annual  -- sai vì start_date này sẽ tính bao hàm luôn start_date ở plan annual mà customer đky khi đó khoảng thgian sẽ không chính xác nếu lấy 2 mốc date trừ nhau
from foodie_fi.subscriptions s  
join annual a 
on s.customer_id = a.customer_id

-- Bài sửa
-- Filter results to customers at trial plan = 0
WITH trial_plan AS 
(SELECT 
  customer_id, 
  start_date AS trial_date
FROM foodie_fi.subscriptions
WHERE plan_id = 0
),
-- Filter results to customers at pro annual plan = 3
annual_plan AS
(SELECT 
  customer_id, 
  start_date AS annual_date
FROM foodie_fi.subscriptions
WHERE plan_id = 3
)

SELECT 
  ROUND(AVG(annual_date - trial_date),0) AS avg_days_to_upgrade
FROM trial_plan tp
JOIN annual_plan ap
  ON tp.customer_id = ap.customer_id;

--10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
--Bài giải 
WITH trial_plan AS(
  SELECT 
    customer_id,
    start_date AS join_date
  FROM subscriptions
  WHERE plan_id = 0
),
annual_plan AS(
  SELECT 
    customer_id,
    start_date AS annual_start_date
  FROM subscriptions
  WHERE plan_id = 3
),
buckets AS(
  SELECT 
    tp.customer_id,
    join_date,
    annual_start_date,
    -- create buckets of 30 days period from 1 to 12 (i.e monthly buckets)
    DATEDIFF(DAY, join_date, annual_start_date)/30 + 1 AS bucket
  FROM 
    trial_plan tp
    JOIN annual_plan ap
    ON tp.customer_id = ap.customer_id
)

SELECT 
  CASE 
    WHEN bucket = 1 THEN CONCAT(bucket-1, ' - ', bucket*30, ' days')
    ELSE CONCAT((bucket-1)*30 + 1, ' - ', bucket*30, ' days')
  END AS period,
  COUNT(customer_id) AS total_customers,
  CAST(AVG(DATEDIFF(DAY, join_date, annual_start_date)*1.0) AS decimal(5, 2)) AS average_days
FROM buckets
GROUP BY bucket;

--11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
tính số lượng customer chuyển từ plan pro monthly xuông basic monthly trong 2020
<=> start date pro monthly nằm liền trước start date basic monthly  

--Bài làm -> CHƯA ĐÚNG HOÀN TOÀN 
with ranking AS
(SELECT  
    s.*,plan_name,
    ROW_NUMBER() over (partition by customer_id order by start_date) rank_
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id)

select count(*) downgraded
from ranking
where year(start_date) = 2020 
and plan_name = 'pro monthly' and rank_ = 2 -- vì trial plan mặc định là plan đầu tiên (rank = 0) do đó để thỏa yêu cầu đề bài thì rank của pro monthly và rank của basic monthly lần lượt là 2 và 3 
and plan_name = 'basic monthly' and rank_ = 3  --> Không bao quát được tất cả trường hợp: g/s sau plan trial customer đky annual rồi đky pro monthly tiếp sau là basic monthly thì khi đó rank của pro monthly và basic monthly sẽ không phải là 2 và 3 

--Bài sửa
-- To retrieve next plan's start date located in the next row based on current row
WITH next_plan_cte AS (
SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) as next_plan
FROM foodie_fi.subscriptions)

SELECT 
  COUNT(*) AS downgraded
FROM next_plan_cte
WHERE start_date <= '2020-12-31'
  AND plan_id = 2 
  AND next_plan = 1;

----- C. CHALLENGE PAYMENT QUESTION -----
-- Tạo bảng payments cho năm 2020 :
-- monthly payments luôn cùng 1 ngày start_date đối với bất cứ monthly plan nào
-- upgrade từ basic to monthly or pro plans được giảm bởi số tiền được trả hiện tại trong tháng đó và bắt đầu ngay lập tức
-- upgrade from Pro monthly lên Pro annual được thanh toán vào cuối thời gian thanh toán hiện tại và cũng bắt đầu vào cuối kỳ tháng
-- once a customer churns they will no longer make payments


----- D. OUTSIDE THE BOX QUESTIONS -----
--1. How would you calculate the rate of growth for Foodie-Fi?
-- tính tổng số customer của mỗi tháng, sau đó lấy (slg customer tháng sau - slg customer tháng trước)*100% = %_growth 

--Nháp 
with cte as 
(
  SELECT 
    MONTH(s.start_date) month ,
    YEAR(s.start_date) year,
    COUNT(distinct customer_id) current_customer_count,
    lag(COUNT(distinct customer_id),1) over(order by month(s.start_date)) past_customer_count
  from foodie_fi.subscriptions s 
  where year(start_date) < 2021 and plan_id != 0 and plan_id != 4
  group by YEAR(s.start_date), MONTH(s.start_date)
)

select *,
  concat(convert(float,round((100.0*(current_customer_count - past_customer_count)/100),2)),' %') as growth_percentage 
from cte

-- Bài làm -> Đúng
with cte as 
(
  SELECT 
    MONTH(s.start_date) month ,
    YEAR(s.start_date) year,
    COUNT(distinct customer_id) current_customer_count,
    lag(COUNT(distinct customer_id),1) over(order by year(start_date),month(s.start_date)) past_customer_count
  from foodie_fi.subscriptions s 
  where plan_id != 0 and plan_id != 4
  group by YEAR(s.start_date), MONTH(s.start_date)
  --order by [year],[month]
) 
select *,
  concat(convert(float,round((100.0*(current_customer_count - past_customer_count)/(past_customer_count)),2)),' %') as growth_percentage 
from cte


--2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
--Bài làm 
- Total active customers (= total - churn) by plans, total paying customers (= total - free - churn) by plans
- Growth of subscription by month,year 
- Total revenue 
- Percentage of customers who churn after using the free trial
- Percentage of customers who upgrade after using the free trial
- 
--3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?
- Behavior of customer at the end of the free trial day (7th day after sign up) - Do they upgrade to  other plans or churn?
 
--4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
--5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?





  
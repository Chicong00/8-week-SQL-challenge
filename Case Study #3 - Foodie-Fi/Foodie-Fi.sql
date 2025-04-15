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
from foodie_fi.subscriptions;

--2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select
    EXTRACT(month from start_date) month_number,
    count(distinct customer_id) trial_subs
from foodie_fi.subscriptions s 
join foodie_fi.plans p  
on s.plan_id = p.plan_id 
where plan_name = 'trial'
group by EXTRACT(month from start_date);

--3.What plan start_date values occur after the year 2020 for our dataset? 
--Show the breakdown by count of events for each plan_name
with event21 AS (
  SELECT 
    plan_name,
    count(1) as event_count_2021
  FROM foodie_fi.subscriptions s 
  JOIN foodie_fi.plans p 
    ON s.plan_id = p.plan_id
  WHERE EXTRACT(YEAR FROM start_date) >= 2021
  GROUP BY plan_name
),
event20 AS (
  SELECT 
    plan_name,
    count(1) as event_count_2020
  FROM foodie_fi.subscriptions s 
  JOIN foodie_fi.plans p 
    ON s.plan_id = p.plan_id
  WHERE EXTRACT(YEAR FROM start_date) < 2021
  GROUP BY plan_name
)

SELECT 
  event20.plan_name, 
  event_count_2020, 
  event_count_2021 
FROM event20 
LEFT JOIN event21 
  ON event20.plan_name = event21.plan_name
ORDER BY event_count_2020 DESC;



--4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
--customer with "churn" / total customer 
with churned_cte as
(select distinct s.*,plan_name
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id 
where plan_name = 'churn')

select 
    count(*) churn_count,
    CAST(round((100.0*count(distinct customer_id)/(select count(distinct customer_id) from foodie_fi.subscriptions)),1) as FLOAT) as churn_percentage
from churned_cte;

--5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
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
where plan_name = 'churn' and rank_= 2;

--6. What is the number and percentage of customer plans after their initial free trial?
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
    CAST(round(100.0*count(*) / (select count(distinct customer_id) from foodie_fi.subscriptions),1) AS FLOAT) plan_percentage
from ranking
where 
        plan_name = 'churn' and rank_= 2
    or  plan_name = 'basic monthly' and rank_=2
    or  plan_name = 'pro monthly' and rank_=2
    or  plan_name = 'pro annual' and rank_=2
group by plan_name
order by plan_percentage desc; 

--7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with cte as 
(select
    s.*,
    plan_name,
    price,
    rank() over (partition by customer_id order by start_date desc) as rank_
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id 
where start_date <= '2020-12-31'
order by 1 desc)

SELECT
    plan_name,
    count(1) customer_count,
    CAST(round(100.0*count(*)/(select count(distinct customer_id) from cte),1) AS FLOAT) percentage_of_plans
from cte
where rank_ = 1
group by plan_name
order by 3 desc;

--8. How many customers have upgraded to an annual plan in 2020?
SELECT 
    count(distinct customer_id) pro_annual_customers
from foodie_fi.subscriptions s  
join foodie_fi.plans p 
on s.plan_id = p.plan_id
where plan_name = 'pro annual' and EXTRACT('YEAR' FROM start_date) = 2020;

--9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
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
  ROUND(AVG(annual_date - trial_date )) avg_days_to_annual
from trial t 
join annual a 
on t.customer_id = a.customer_id;

--10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH annual AS (
  SELECT customer_id, start_date AS annual_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 3
),
trial AS (
  SELECT customer_id, start_date AS trial_date
  FROM foodie_fi.subscriptions
  WHERE plan_id = 0
)
SELECT period, total_customers
FROM (
  SELECT
    CASE 
      WHEN ROUND(annual_date - trial_date) <= 30 THEN '0 - 30'
      WHEN ROUND(annual_date - trial_date) <= 60 THEN '31 - 60'
      WHEN ROUND(annual_date - trial_date) <= 90 THEN '61 - 90'
      WHEN ROUND(annual_date - trial_date) <= 120 THEN '91 - 120'
      WHEN ROUND(annual_date - trial_date) <= 150 THEN '121 - 150'
      WHEN ROUND(annual_date - trial_date) <= 180 THEN '151 - 180'
      WHEN ROUND(annual_date - trial_date) <= 210 THEN '181 - 210'
      WHEN ROUND(annual_date - trial_date) <= 240 THEN '211 - 240'
      WHEN ROUND(annual_date - trial_date) <= 270 THEN '241 - 270'
      WHEN ROUND(annual_date - trial_date) <= 300 THEN '271 - 300'
      WHEN ROUND(annual_date - trial_date) <= 330 THEN '301 - 330'
      WHEN ROUND(annual_date - trial_date) <= 360 THEN '331 - 360'
      ELSE '361+'
    END AS period,
    COUNT(*) AS total_customers
  FROM trial t
  JOIN annual a ON t.customer_id = a.customer_id
  GROUP BY period
) sub
ORDER BY 
  CASE 
    WHEN period = '0 - 30' THEN 1
    WHEN period = '31 - 60' THEN 2
    WHEN period = '61 - 90' THEN 3
    WHEN period = '91 - 120' THEN 4
    WHEN period = '121 - 150' THEN 5
    WHEN period = '151 - 180' THEN 6
    WHEN period = '181 - 210' THEN 7
    WHEN period = '211 - 240' THEN 8
    WHEN period = '241 - 270' THEN 9
    WHEN period = '271 - 300' THEN 10
    WHEN period = '301 - 330' THEN 11
    WHEN period = '331 - 360' THEN 12
    ELSE 13
  END;

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





  
# 🥑 Foodie-Fi: Solution

[SQL Syntax](https://github.com/Chicong00/8-week-SQL-challenge/blob/0dd8668f836e07d9008205bbaf720c2f9677b702/Case%20Study%20%233%20-%20Foodie-Fi/Foodie-Fi.sql)

<details>
<summary>
A. Customer Journey
</summary> 
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

````sql
select s.*,p.plan_name,p.price
from dbo.subscriptions s 
join dbo.plans p 
on s.plan_id = p.plan_id 
where customer_id in (1,4,6,23,49,58,79,80)
order by customer_id
````
**Steps**
1. Choose 8 random customers and analyze behavior of them
2. Which plan did they use ? Did they upgrade plan after use free trial ?

**Results**
|customer_id|plan_id|start_date|plan_name|price|
|---|---|---|---|---|
|1|0|2020-08-01|trial|0.00|
|1|1|2020-08-08|basic monthly|9.90|

Customer_id 1 started with a trial subscription and continued with a basic monthly subscription in 7 days after sign-up.

|customer_id|plan_id|start_date|plan_name|price|
|---|---|---|---|---|
|4|0|2020-01-17|trial|0.00|
|4|1|2020-01-24|basic monthly|9.90|
|4|4|2020-04-21|churn|NULL|

Customer_id 4 started with a trial subscription and continued with a basic monthly subscription in 7 days after sign-up and has churned in 3 months after that.

|customer_id|plan_id|start_date|plan_name|price|
|---|---|---|---|---|
|6|0|2020-12-23|trial|0.00|
|6|1|2020-12-30|basic monthly|9.90|
|6|4|2020-02-26|churn|NULL|

Customer_id 6 started with a trial subscription and continued with a basic monthly subscription in 7 days after sign-up and has churned in 2 months after that.

|customer_id|plan_id|start_date|plan_name|price|
|---|---|---|---|---|
|23|0|2020-05-13|trial|0.00|
|23|3|2020-05-20|pro annual|199.00|

Customer_id 23 started with a trial subscription and continued with a pro annual subscription in 7 days after sign-up.

|customer_id|plan_id|start_date|plan_name|price|
|---|---|---|---|---|
|49|0|2020-04-24|trial|0.00|
|49|2|2020-05-01|pro monthly|19.90|
|49|3|2020-08-01|pro annual|199.00|

Customer_id 49 started with a trial subscription and continued with a pro monthly subscription in 7 days after sign-up and has upgraded to a pro annual in 3 days after that.

|customer_id|plan_id|start_date|plan_name|price|
|---|---|---|---|---|
|58|0|2020-07-04|trial|0.00|
|58|1|2020-07-11|basic monthly|9.90|
|58|3|2020-09-24|pro annual|199.90|

Customer_id 58 started with a trial subscription and continued with a basic monthly subscription in 7 days after sign-up and has upgrade to a pro annual in 2 months 13 days after that.

|customer_id|plan_id|start_date|plan_name|price|
|---|---|---|---|---|
|79|0|2020-07-30|trial|0.00|
|79|2|2020-08-06|pro monthly|19.90|

Customer_id 79 started with a trial subscription and continued with a pro monthly subscription in 7 days after sign-up.

|customer_id|plan_id|start_date|plan_name|price|
|---|---|---|---|---|
|80|0|2020-09-23|trial|0.00|
|80|2|2020-09-30|pro monthly|19.90|
|80|4|2020-01-17|churn|NULL|

Customer_id 80 started with a trial subscription and continued with a pro monthly subscription in 7 days after sign-up and has churned in 3 months after that.

</details>

<details>
<summary>
B. Data Analysis Questions
</summary>
  
### 1. How many customers has Foodie-Fi ever had?
````sql
select count(distinct(customer_id)) customer_count
from dbo.subscriptions
````
**Result**  
|customer_count|
|---|
|1000|
  
### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value ?
````sql
select 
    MONTH(start_date) month, 
    count(distinct customer_id) trial_subs
from dbo.subscriptions s 
join dbo.plans p  
on s.plan_id = p.plan_id 
where plan_name = 'trial'
group by month(start_date)
````
**Result**
|month|trial_subs|
|---|---|  
|1|88|
|2|68|
|3|94|
|4|81|
|5|88|
|6|79|
|7|89|
|8|88|
|9|87|
|10|79|
|11|75|
|12|84|
  
### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name ?
  
````sql
with event21 AS
(
  SELECT 
    plan_name,
    count(1) event_count_2021
  from dbo.subscriptions s 
  join dbo.plans p 
  on s.plan_id = p.plan_id
  where year(start_date) >= 2021
  group by plan_name
),
event20 AS
(
  SELECT 
    plan_name,
    count(1) event_count_2020
  from dbo.subscriptions s 
  join dbo.plans p 
  on s.plan_id = p.plan_id
  where year(start_date) < 2021
  group by plan_name
)

select event20.plan_name, event_count_2020, event_count_2021 
from event20 
left join event21 
on event20.plan_name = event21.plan_name
order by event_count_2020 DESC
````
**Result**
|plan_name|event_count_2020|event_count_2021|    
|---|---|---|
|trial|1000|NULL|
|basic monthly|538|8|
|pro monthly|479|60|
|churn|236|71|
|pro annual|195|63| 
                               
### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place ?

````sql
with churned_cte as
(select distinct s.*,plan_name
from dbo.subscriptions s 
join dbo.plans p 
on s.plan_id = p.plan_id 
where plan_name = 'churn')

select 
    count(*) churn_count,
    convert(float,round((100.0*count(distinct customer_id)/(select count(distinct customer_id) from dbo.subscriptions)),2)) as churn_percentage
from churned_cte
````
**Result**
|churn_count|churn_percentage|
|---|---|
|307|30.7|

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number ?
````sql
with ranking AS
(SELECT  s.*,plan_name,
    ROW_NUMBER() over (partition by customer_id order by start_date) rank_
from dbo.subscriptions s 
join dbo.plans p 
on s.plan_id = p.plan_id)
 
select
    count(*) churn_count,
    round(100*count(*) / (select count(distinct customer_id) from dbo.subscriptions),0) churn_percentage
from ranking
where plan_name = 'churn' and rank_= 2
````
**Result**
|churn_count|churn_percentage|
|---|---|
|92|9|

### 6. What is the number and percentage of customer plans after their initial free trial ?

````sql
with ranking AS
(SELECT  
    s.*,plan_name,
    ROW_NUMBER() over (partition by customer_id order by start_date) rank_
from dbo.subscriptions s 
join dbo.plans p 
on s.plan_id = p.plan_id)
 
select
    plan_name next_plan,
    count(*) plan_count,
    convert(float,round(100.0*count(*) / (select count(distinct customer_id) from dbo.subscriptions),2)) plan_percentage
from ranking
where 
        plan_name = 'churn' and rank_= 2
    or  plan_name = 'basic monthly' and rank_=2
    or  plan_name = 'pro monthly' and rank_=2
    or  plan_name = 'pro annual' and rank_=2
group by plan_name
order by plan_percentage desc
````
**Result**
|next_plan|plan_count|plan_percentage|    
|---|---|---|
|basic monthly|546|54.6|
|pro monthly|325|32.5|
|churn|92|9.2|
|pro annual|37|3.7|
  
### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
````sql
WITH ranked AS 
(
  SELECT
    customer_id,
    plan_name,
    RANK() OVER(PARTITION BY customer_id ORDER BY start_date DESC) rank_
  FROM subscriptions AS s
  JOIN plans AS p 
  ON s.plan_id = p.plan_id
  WHERE start_date <= '2020-12-31' 
)

SELECT 
  plan_name,
  count(*) customer_count, 
  convert(float,ROUND((100.0*count(*)/(select count(distinct customer_id) from dbo.subscriptions)),2)) percentage_of_plans
from ranked 
WHERE rank_ = 1
group by plan_name
order by 1
````
**Result**
|plan_name|customer_count|percentage_of_plans|    
|---|---|---|
|basic monthly|224|22.4|
|churn|236|23.6|
|pro annual|195|19.5|
|pro monthly|326|32.6|
|trial|19|1.9|
  
### 8. How many customers have upgraded to an annual plan in 2020 ?
````sql
SELECT 
    count(distinct customer_id) pro_annual_customers
from dbo.subscriptions s  
join dbo.plans p 
on s.plan_id = p.plan_id
where plan_name = 'pro annual' and YEAR(start_date) = 2020
````
**Result**
|pro_annual_customers|
|---|
|195|

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi ?
````sql
with annual AS
(
select customer_id, start_date annual_date
from dbo.subscriptions
where plan_id = 3
), 
trial as 
(
select customer_id, start_date trial_date
from dbo.subscriptions
where plan_id = 0
)

select 
    round(AVG(DATEDIFF(day,trial_date,annual_date)),0) avg_days_to_annual
from trial t 
join annual a 
on t.customer_id = a.customer_id
````
**Result**
|avg_days_to_annual|
|---|
|104|

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc) ?
````sql
````

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020 ?
````sql
WITH next_plan_cte AS (
SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) as next_plan
FROM dbo.subscriptions)

SELECT 
  COUNT(*) AS downgraded
FROM next_plan_cte
WHERE year(start_date) <= 2021  
	AND plan_id = 2 
  AND next_plan = 1
````
**Result**
|downgraded|
|---|
|0|

</details>

<details>
<summary>
C. Challenge Payment Question
</summary>

</details>

<details>
<summary>
D. Outside The Box Questions
</summary>

### 1. How would you calculate the rate of growth for Foodie-Fi?
````sql
with cte as 
(
  SELECT 
    MONTH(s.start_date) month ,
    YEAR(s.start_date) year,
    COUNT(distinct customer_id) current_customer_count,
    lag(COUNT(distinct customer_id),1) over(order by year(start_date),month(s.start_date)) past_customer_count
  from dbo.subscriptions s 
  where plan_id != 0 and plan_id != 4
  group by YEAR(s.start_date), MONTH(s.start_date)
)
select *,
  concat(convert(float,round((100.0*(current_customer_count - past_customer_count)/(past_customer_count)),2)),' %') as growth_percentage 
from cte
````
**Result**
|month|year|current_customer_count|past_customer_count|growth_percentage|
|---|---|---|---|---|
|1|2020|61|NULL|%|
|2|2020|70|61|14.75%|
|3|2020|93|70|32.86%|
|4|2020|84|93|-9.68%|
|5|2020|104|84|23.81%|
|6|2020|105|104|0.96%|
|7|2020|101|105|-3.81%|
|8|2020|130|101|28.71%|
|9|2020|112|130|-13.85%|
|10|2020|124|112|10.71%|
|11|2020|99|124|-20.16%|
|12|2020|109|99|10.1%|
|1|2021|58|109|-46.79%|
|2|2021|29|58|-50%|
|3|2021|24|29|-17.24%|
|4|2021|20|24|-16.67%|

### 2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

- **Customer growth**: how many customers increase by monthly ? What does the ratio look like?
- **Conversion rate**: how many customers continue to use after free trial? What does the ratio look like?
- **Churn rate**: How many customers cancel the subscription by monthly? What does the ratio look like?

### 3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?

- Customers who cancelled the subscription
- Customers who upgraded the subscription
	- From basic monthly to pro monthly
	- From basic monthly to pro annual

### 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

- Why do you want to cancel subscription? What is the primary reason ?
	- Price
	- Content
	- Techinical issues
	- Customer support
	- Found an alternative
	- Others (specify)
- On a 5-point scale, how would you rate your experience?
- On a 5-point scale, how would you rate the price?
- Is there anything you want us to change ?
	- Content (quality and quantity)
	- Video duration (longer or shorter)
	- Price
	- Others (specify)
	
### 5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

- Adjust based on the main reasons leading to the cancellation:
	- Price: more promotions, more discount seasons, more unique content for memberships
	- Service quality: work with the relevant department to fix the issue, improve service quality
	- Found an alternative: do some competitor analysis to see their competitive advantages over us. If necessary, try the product for better experience and evaluation.
- To validate the effectiveness:
	- Churn rate
	- Conversion rate

</details>
</details>


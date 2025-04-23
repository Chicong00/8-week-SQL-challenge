# 🥑 Foodie-Fi: Solution

[SQL Syntax](https://github.com/Chicong00/8-week-SQL-challenge/blob/0dd8668f836e07d9008205bbaf720c2f9677b702/Case%20Study%20%233%20-%20Foodie-Fi/Foodie-Fi.sql)

## A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

````sql
select s.*,p.plan_name,p.price
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id 
where customer_id in (1,4,6,23,49,58,79,80)
order by customer_id;
````
**Steps**
1. Choose 8 random customers and analyze behavior of them
2. Which plan did they use ? Did they upgrade plan after use free trial ?

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

## B. Data Analysis Questions  
### 1. How many customers has Foodie-Fi ever had?
````sql
select count(distinct(customer_id)) customer_count
from foodie_fi.subscriptions;
````
|customer_count|
|---|
|1000|
  
### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value ?
````sql
select
    EXTRACT(month from start_date) month_number,
    count(distinct customer_id) trial_subs
from foodie_fi.subscriptions s 
join foodie_fi.plans p  
on s.plan_id = p.plan_id 
where plan_name = 'trial'
group by EXTRACT(month from start_date);
````
|month_number|trial_subs|
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
````
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
from foodie_fi.subscriptions s 
join foodie_fi.plans p 
on s.plan_id = p.plan_id 
where plan_name = 'churn')

select 
    count(*) churn_count,
    CAST(round((100.0*count(distinct customer_id)/(select count(distinct customer_id) from foodie_fi.subscriptions)),1) as FLOAT) as churn_percentage
from churned_cte;
````
|churn_count|churn_percentage|
|---|---|
|307|30.7|

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number ?

Create a rank column for each customer by start_date, then retrieve customer has plan_id = 4 (churned) and rank = 2 (after free trial)

````sql
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
````
|churn_count|churn_percentage|
|---|---|
|92|9|

### 6. What is the number and percentage of customer plans after their initial free trial ?

Use the same approach of #5, to know the plan after the free trial -> create a rank column, where rank = 1 is the free trial, then rank = 2 is the plan after their initial free trial.

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
|next_plan|plan_count|plan_percentage|    
|---|---|---|
|basic monthly|546|54.6|
|pro monthly|325|32.5|
|churn|92|9.2|
|pro annual|37|3.7|
  
### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

Use the same approach of #5, to count the number of customers by plan at 2020-12-31 -> Create a rank column and sort by descending start date -> Know the latest plan the user is using as of 12-31-2020 by rank = 1

````sql
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
````
|plan_name|customer_count|percentage_of_plans|    
|---|---|---|
|pro monthly|326|32.6|
|churn|236|23.6|
|basic monthly|224|22.4|
|pro annual|195|19.5|
|trial|19|1.9|
  
### 8. How many customers have upgraded to an annual plan in 2020 ?
````sql
SELECT 
    count(distinct customer_id) pro_annual_customers
from foodie_fi.subscriptions s  
join foodie_fi.plans p 
on s.plan_id = p.plan_id
where plan_name = 'pro annual' and EXTRACT('YEAR' FROM start_date) = 2020;
````
|pro_annual_customers|
|---|
|195|

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi ?

The question doesn't ask for a detailed plan from the date the customer joined, so I assume I just need to count the days from the first day to the first day of the annual plan.

````sql
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
````
|avg_days_to_annual|
|---|
|105|

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc) ?
````sql
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
````
| period    | total_customers |
|-----------|-----------------|
| 0 - 30    | 49              |
| 31 - 60   | 24              |
| 61 - 90   | 34              |
| 91 - 120  | 35              |
| 121 - 150 | 42              |
| 151 - 180 | 36              |
| 181 - 210 | 26              |
| 211 - 240 | 4               |
| 241 - 270 | 5               |
| 271 - 300 | 1               |
| 301 - 330 | 1               |
| 331 - 360 | 1               |

### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020 ?

Use the same logic as #09, I will join the pro monthly plan with the basic monthly plan together, then retrieve records with the start_date of the basic monthly > pro monthly

````sql
with pro_mon as
(
SELECT  
    s.customer_id,plan_name, start_date
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p
ON s.plan_id = p.plan_id
where plan_name = 'pro monthly'
)
, basic_mon as
(
SELECT  
    s.customer_id,plan_name, start_date
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p
ON s.plan_id = p.plan_id
WHERE plan_name = 'basic monthly'
)
SELECT count(*) downgraded
FROM pro_mon p
JOIN basic_mon b
ON p.customer_id = b.customer_id
WHERE p.start_date < b.start_date
AND EXTRACT(YEAR FROM p.start_date) = 2020;
````
|downgraded|
|---|
|0|

## C. Challenge Payment Question
The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
- once a customer churns they will no longer make payments

```sql

```
## D. Outside The Box Questions
### 1. How would you calculate the rate of growth for Foodie-Fi?
````sql
with cte as (
SELECT
    EXTRACT(YEAR FROM s.start_date) as year,
    EXTRACT(MONTH FROM s.start_date) as month,
    plan_name,
    COUNT(DISTINCT customer_id) current_customer_count
FROM foodie_fi.subscriptions s
JOIN foodie_fi.plans p ON s.plan_id = p.plan_id
GROUP BY 1,2,3
)
SELECT
    year,
    month,
    plan_name,
    current_customer_count,
    LAG(current_customer_count, 1) OVER (PARTITION BY plan_name ORDER BY year, month) AS past_customer_count,
    ROUND((current_customer_count - LAG(current_customer_count, 1) OVER (PARTITION BY plan_name ORDER BY year, month)) * 100.0 / NULLIF(LAG(current_customer_count, 1) OVER (PARTITION BY plan_name ORDER BY year, month), 0), 2) AS growth_percentage
FROM cte
ORDER BY plan_name, year, month;
````
<details>
<summary> Table result </summary>

| year | month | plan_name     | current_customer_count | past_customer_count | growth_percentage |
|------|-------|---------------|------------------------|---------------------|-------------------|
| 2020 | 1     | basic monthly | 31                     |                     |                   |
| 2020 | 2     | basic monthly | 37                     | 31                  | 19.35             |
| 2020 | 3     | basic monthly | 49                     | 37                  | 32.43             |
| 2020 | 4     | basic monthly | 43                     | 49                  | -12.24            |
| 2020 | 5     | basic monthly | 53                     | 43                  | 23.26             |
| 2020 | 6     | basic monthly | 51                     | 53                  | -3.77             |
| 2020 | 7     | basic monthly | 44                     | 51                  | -13.73            |
| 2020 | 8     | basic monthly | 54                     | 44                  | 22.73             |
| 2020 | 9     | basic monthly | 38                     | 54                  | -29.63            |
| 2020 | 10    | basic monthly | 46                     | 38                  | 21.05             |
| 2020 | 11    | basic monthly | 49                     | 46                  | 6.52              |
| 2020 | 12    | basic monthly | 43                     | 49                  | -12.24            |
| 2021 | 1     | basic monthly | 8                      | 43                  | -81.4             |
| 2020 | 1     | churn         | 9                      |                     |                   |
| 2020 | 2     | churn         | 9                      | 9                   | 0                 |
| 2020 | 3     | churn         | 13                     | 9                   | 44.44             |
| 2020 | 4     | churn         | 18                     | 13                  | 38.46             |
| 2020 | 5     | churn         | 21                     | 18                  | 16.67             |
| 2020 | 6     | churn         | 19                     | 21                  | -9.52             |
| 2020 | 7     | churn         | 28                     | 19                  | 47.37             |
| 2020 | 8     | churn         | 13                     | 28                  | -53.57            |
| 2020 | 9     | churn         | 23                     | 13                  | 76.92             |
| 2020 | 10    | churn         | 26                     | 23                  | 13.04             |
| 2020 | 11    | churn         | 32                     | 26                  | 23.08             |
| 2020 | 12    | churn         | 25                     | 32                  | -21.88            |
| 2021 | 1     | churn         | 19                     | 25                  | -24               |
| 2021 | 2     | churn         | 18                     | 19                  | -5.26             |
| 2021 | 3     | churn         | 21                     | 18                  | 16.67             |
| 2021 | 4     | churn         | 13                     | 21                  | -38.1             |
| 2020 | 1     | pro annual    | 2                      |                     |                   |
| 2020 | 2     | pro annual    | 5                      | 2                   | 150               |
| 2020 | 3     | pro annual    | 7                      | 5                   | 40                |
| 2020 | 4     | pro annual    | 11                     | 7                   | 57.14             |
| 2020 | 5     | pro annual    | 13                     | 11                  | 18.18             |
| 2020 | 6     | pro annual    | 16                     | 13                  | 23.08             |
| 2020 | 7     | pro annual    | 20                     | 16                  | 25                |
| 2020 | 8     | pro annual    | 24                     | 20                  | 20                |
| 2020 | 9     | pro annual    | 25                     | 24                  | 4.17              |
| 2020 | 10    | pro annual    | 32                     | 25                  | 28                |
| 2020 | 11    | pro annual    | 20                     | 32                  | -37.5             |
| 2020 | 12    | pro annual    | 20                     | 20                  | 0                 |
| 2021 | 1     | pro annual    | 24                     | 20                  | 20                |
| 2021 | 2     | pro annual    | 17                     | 24                  | -29.17            |
| 2021 | 3     | pro annual    | 9                      | 17                  | -47.06            |
| 2021 | 4     | pro annual    | 13                     | 9                   | 44.44             |
| 2020 | 1     | pro monthly   | 29                     |                     |                   |
| 2020 | 2     | pro monthly   | 29                     | 29                  | 0                 |
| 2020 | 3     | pro monthly   | 37                     | 29                  | 27.59             |
| 2020 | 4     | pro monthly   | 31                     | 37                  | -16.22            |
| 2020 | 5     | pro monthly   | 39                     | 31                  | 25.81             |
| 2020 | 6     | pro monthly   | 39                     | 39                  | 0                 |
| 2020 | 7     | pro monthly   | 40                     | 39                  | 2.56              |
| 2020 | 8     | pro monthly   | 56                     | 40                  | 40                |
| 2020 | 9     | pro monthly   | 52                     | 56                  | -7.14             |
| 2020 | 10    | pro monthly   | 47                     | 52                  | -9.62             |
| 2020 | 11    | pro monthly   | 32                     | 47                  | -31.91            |
| 2020 | 12    | pro monthly   | 48                     | 32                  | 50                |
| 2021 | 1     | pro monthly   | 26                     | 48                  | -45.83            |
| 2021 | 2     | pro monthly   | 12                     | 26                  | -53.85            |
| 2021 | 3     | pro monthly   | 15                     | 12                  | 25                |
| 2021 | 4     | pro monthly   | 7                      | 15                  | -53.33            |
| 2020 | 1     | trial         | 88                     |                     |                   |
| 2020 | 2     | trial         | 68                     | 88                  | -22.73            |
| 2020 | 3     | trial         | 94                     | 68                  | 38.24             |
| 2020 | 4     | trial         | 81                     | 94                  | -13.83            |
| 2020 | 5     | trial         | 88                     | 81                  | 8.64              |
| 2020 | 6     | trial         | 79                     | 88                  | -10.23            |
| 2020 | 7     | trial         | 89                     | 79                  | 12.66             |
| 2020 | 8     | trial         | 88                     | 89                  | -1.12             |
| 2020 | 9     | trial         | 87                     | 88                  | -1.14             |
| 2020 | 10    | trial         | 79                     | 87                  | -9.2              |
| 2020 | 11    | trial         | 75                     | 79                  | -5.06             |
| 2020 | 12    | trial         | 84                     | 75                  | 12                |


</details>

### 2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

- **Customer growth**: how many customers increase by monthly ? What does the ratio look like?
- **Conversion rate**: how many customers continue to use after free trial? What does the ratio look like?
- **Churn rate**: How many customers cancel the subscription by monthly? What does the ratio look like?

### 3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?

- Customers who cancelled the subscription after trial
- Customers who upgraded the subscription:
	- From basic monthly to pro monthly
	- From basic monthly to pro annual

### 4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?

**General Reason for Cancellation**

1. What is the primary reason you are canceling your subscription?
- Price is not affordable
- Content not interesting
- Techinical issues
- Customer support
- Found a better alternative
- Temporary break
- Others (specify)

**Usage & Satisfaction**

2. How often did you use Foodie-Fi?
(Daily / Weekly / Monthly / Rarely / Never)

3. On a 5-point scale, how would you rate your experience?
(1 - Very Unsatisfied to 5 - Ver Satisfied)

4. On a 5-point scale, how would you rate the price?
(1 - Too cheap to 5 - Too expensive)

**Feature Feedback**

5. Which features did you use the most?
(Open-ended or multiple choice depending on platform features)

6. What features or improvements would have made you stay?
(Open-ended)

	
### 5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?

- Adjust based on the main reasons leading to the cancellation:
	- Price: more promotions, more discount seasons, more unique content for memberships
	- Service quality: work with the relevant department to fix the issue, improve service quality
	- Found an alternative: do some competitor analysis to see their competitive advantages over us. If necessary, try the product for better experience and evaluation.
- To validate the effectiveness:
	- Churn rate
	- Conversion rate



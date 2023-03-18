/*A.Data Cleansing */

select top 10 * from Data_Mart

drop table if exists clean_weekly_sales
select 
	convert(date,week_date) week_date,
	datepart(WEEK,week_date) week_number,
	DATEPART(MONTH,week_date) month_number,
	DATEPART(year,week_date) year_calendar,
	region,
	platform,
	segment,
	customer_type,
	case 
		when segment like '%1%' then 'Young Adults'
		when segment like '%2%' then 'Middle Aged'
		when segment like '%3%' or segment like '%4%' then 'Retirees'
		else 'unknown'
	end as age_band,
	case
		when left(segment,1) = 'C' then 'Couples'
		when left(segment,1) = 'F' then 'Families'
		else 'unknown'
	end as demographic,
	transactions,
	cast(sales as bigint) sales,
	ROUND(CAST(sales AS FLOAT)/transactions, 2) avg_transaction
into clean_weekly_sales
from Data_Mart

select top 20* from clean_weekly_sales

/*B. Data Exploration*/

--1. What day of the week is used for each week_date value?
select distinct
	DATENAME(dw,week_date) day_of_week
from clean_weekly_sales

--2. What range of week numbers are missing from the dataset?
-- Create a table with the number of 1 to 52 corresponding to 52 weeks in the year
declare @startnum int = 1
declare @endnum int = 52;
with allweeks as 
(
	select @startnum as weeknum
	union all
	select weeknum+1 from allweeks where weeknum+1 <= @endnum
)
--select * from allweeks

-- Take the week number from clean_weekly_sales to compare with values in allweeks. Null rows are missing weeks
select distinct weeknum, week_number
from allweeks a 
left join clean_weekly_sales c
on a.weeknum = c.week_number
where week_number is null
order by weeknum

--3. How many total transactions were there for each year in the dataset?
select 
	year_calendar,
	sum(transactions) total_transactions
from clean_weekly_sales
group by year_calendar
order by year_calendar desc

--4. What is the total sales for each region for each month?
select
	region,
	month_number,
	sum(sales) total_sales
from clean_weekly_sales
group by region, month_number
order by region, month_number

--5. What is the total count of transactions for each platform
select 
	platform,
	sum(transactions) total_transactions
from clean_weekly_sales
group by platform

--6. What is the percentage of sales for Retail vs Shopify for each month?

with sale as
(
select 
	year_calendar,
	month_number,
	platform,
	sum(sales) sales,
	sum(sum(sales)) over (partition by year_calendar, month_number) total_sales
from clean_weekly_sales
group by year_calendar,month_number, platform
)
select 
	year_calendar,
	month_number,platform, sum(sales) sales,
	sum(total_sales) total_sales,
	convert(float,round(100.0*sum(sales)/sum(total_sales),2)) Percentage_sales
from sale
group by year_calendar,month_number, platform
order by year_calendar desc ,month_number asc 

--7. What is the percentage of sales by demographic for each year in the dataset?
with demo as 
(
select 
	year_calendar,
	demographic,
	sum(sales) year_sales
from clean_weekly_sales
group by year_calendar, demographic
)
select 
	year_calendar,
	sum(year_sales) total_sales,
	cast(100.0*sum(case when demographic = 'Families' then year_sales end)/sum(year_sales) as decimal(5,2)) as pct_fam,
	cast(100.0*sum(case when demographic = 'Couples' then year_sales end)/sum(year_sales) as decimal(5,2))as pct_coup,
	cast(100.0*sum(case when demographic = 'Unknown' then year_sales end)/sum(year_sales) as decimal(5,2))as pct_unkn
from demo
group by year_calendar
order by year_calendar desc

--8. Which age_band and demographic values contribute the most to Retail sales?
select 
	age_band,
	demographic,
	sum(sales) sales,
	cast(100.0*sum(sales)/(select sum(sales) from clean_weekly_sales where platform = 'Retail') as decimal(5,2)) contribution
from clean_weekly_sales	
where platform = 'Retail'
group by age_band, demographic
order by contribution desc

--9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT 
  year_calendar, 
  platform, 
  ROUND(AVG(avg_transaction),0) AS avg_transaction_row, 
  SUM(sales) / sum(transactions) AS avg_transaction_group
FROM clean_weekly_sales
GROUP BY year_calendar, platform
ORDER BY year_calendar, platform;

/*Before & After Analysis*/

/*Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before*/

--1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
declare @baselineweek int =
(select 
	distinct week_number
from clean_weekly_sales
where week_date = '2020-06-15');
with cte as
(
select 
	sum(case when week_number between @baselineweek-4 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+3 then sales end) after_sales
from clean_weekly_sales
where year_calendar = 2020
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from cte 

--2. What about the entire 12 weeks before and after?
declare @baselineweek int =
(select 
	distinct week_number
from clean_weekly_sales
where week_date = '2020-06-15');
with cte as
(
select 
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from clean_weekly_sales
where year_calendar = 2020
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from cte 

--3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
--4 weeks before and after
declare @baselineweek int =
(select 
	distinct week_number
from clean_weekly_sales
where week_date = '2020-06-15');
with cte as
(
select 
	year_calendar,
	sum(case when week_number between @baselineweek-4 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+3 then sales end) after_sales
from clean_weekly_sales
group by year_calendar
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from cte  
order by year_calendar

--12 weeks before and after
declare @baselineweek int =
(select 
	distinct week_number
from clean_weekly_sales
where week_date = '2020-06-15');
with cte as
(
select 
	year_calendar,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from clean_weekly_sales
group by year_calendar
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from cte 
order by year_calendar

/*D. Bonus Question*/
/*Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

region
platform
age_band
demographic
customer_type*/

--Find the week_number of '2020-06-15' (@weekNum=25)
declare @baselineweek int 
set @baselineweek
=(select 
	distinct week_number
from clean_weekly_sales
where week_date = '2020-06-15');

-- region
with region as
(
select 
	region,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from clean_weekly_sales
group by region
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from region 
order by pct_change 

-- platform
declare @baselineweek int 
set @baselineweek
=(select 
	distinct week_number
from clean_weekly_sales
where week_date = '2020-06-15');

with platform as
(
select 
	platform,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from clean_weekly_sales
group by platform
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from platform 
order by pct_change 

-- age_band
declare @baselineweek int 
set @baselineweek
=(select 
	distinct week_number
from clean_weekly_sales
where week_date = '2020-06-15');

with age_band as
(
select 
	age_band,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from clean_weekly_sales
group by age_band
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from age_band 
order by pct_change 

-- demographic
declare @baselineweek int 
set @baselineweek
=(select 
	distinct week_number
from clean_weekly_sales
where week_date = '2020-06-15');

with demographic as
(
select 
	demographic,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from clean_weekly_sales
group by demographic
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from demographic 
order by pct_change 

-- customer_type
declare @baselineweek int 
set @baselineweek
=(select 
	distinct week_number
from clean_weekly_sales
where week_date = '2020-06-15');

with customer as
(
select 
	customer_type,
	sum(case when week_number between @baselineweek-12 and @baselineweek-1 then sales end) before_sales,
	sum(case when week_number between @baselineweek and @baselineweek+11 then sales end) after_sales
from clean_weekly_sales
group by customer_type
)
select 
	*,
	cast(100.0*(after_sales-before_sales)/before_sales as decimal(5,2)) pct_change
from customer 
order by pct_change 

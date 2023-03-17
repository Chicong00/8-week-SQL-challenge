select top 10 * from users
select top 10 * from events

/*1. Digital Analysis*/
--1. How many users are there?
select count(distinct user_id) total_users
from users

--2. How many cookies does each user have on average?
-- Opt1:
select 
	cast(COUNT(cookie_id)/count(distinct user_id) as decimal(5,2)) avg_cookies_per_user
from users

-- Opt2:
with cookie as
(
select 
	user_id,
	count(cookie_id) cookie_count
from users
group by user_id
)
select cast(avg(cookie_count) as decimal(5,2)) 
from cookie 

--3. What is the unique number of visits by all users per month?
select
	DATEPART(month,event_time) as month,
	count(distinct visit_id) visit_count
from events e 
group by DATEPART(month,event_time)
order by month

--4. What is the number of events for each event type?
select 
	event_name,
	count(*) event_count
from events e 
join event_identifier ei
on e.event_type = ei.event_type
group by event_name
order by event_count desc

--5. What is the percentage of visits which have a purchase event?
select	
	event_name,
	cast(100.0*count(distinct visit_id)/(select count(distinct visit_id) from events) as decimal(5,2)) pct_visit_count
from events e
join event_identifier ei
on e.event_type = ei.event_type
where event_name = 'Purchase'
group by event_name


--6. What is the percentage of visits which view the checkout page but do not have a purchase event?
with checkout_view as 
(
select 
	count(distinct visit_id) visit_count
from events e
left join page_hierarchy p
on e.page_id = p.page_id
left join event_identifier ei
on e.event_type = ei.event_type
where ei.event_name = 'Page View' and p.page_name = 'Checkout'
)
select 
	cast(100-100.0*count(distinct visit_id)/(select visit_count from checkout_view) as decimal(5,2)) pct_view_checkout_not_purchase
from events e 
join event_identifier ei
on e.event_type = ei.event_type
where event_name = 'Purchase'

--7. What are the top 3 pages by number of views?
select  top 3
	p.page_name,
	count(visit_id) visit_count 
from events e
join page_hierarchy p
on e.page_id = p.page_id
join event_identifier ei
on e.event_type = ei.event_type
where event_name = 'Page View'
group by page_name
order by visit_count desc

--8. What is the number of views and cart adds for each product category?
SELECT 
  ph.product_category, 
  SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_views,
  SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds
FROM events AS e
JOIN page_hierarchy AS ph
ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category
ORDER BY page_views DESC;

--9. What are the top 3 products by purchases?
select top 3
	ph.page_name,
	ph.product_category,
	count(*) purchase_count
from events e 
join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
-- Step1 : Products are added to cart 
where event_name = 'Add to cart'
-- Step 2: Add-to-cart products are purchased
and e.visit_id in 
	(select e.visit_id from events e
	join event_identifier ei on e.event_type = ei.event_type
	where event_name = 'Purchase')
group by ph.page_name, ph.product_category 
order by 3 desc

-- Customers who have a 'purchase' action and events in their history
with purchase as 
(
select e.visit_id from events e
	join event_identifier ei on e.event_type = ei.event_type
	where event_name = 'Purchase'
)
select user_id, e.visit_id, ph.page_name, ei.event_name, sequence_number
from events e 
left join purchase p on e.visit_id = p.visit_id 
join users u on e.cookie_id = u.cookie_id
join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
where p.visit_id is not null

-- Customers who do not have 'purchase' action and events in their history
with purchase as 
(
select e.visit_id from events e
	join event_identifier ei on e.event_type = ei.event_type
	where event_name = 'Purchase'
)
select user_id, e.visit_id, ph.page_name, ei.event_name, sequence_number
from events e 
left join purchase p on e.visit_id = p.visit_id 
join users u on e.cookie_id = u.cookie_id
join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
where p.visit_id is null


/*2. Product Funnel Analysis*/
-- How many times was each product viewed?
-- How many times was each product added to cart?
-- How many times was each product added to a cart but not purchased (abandoned)?
-- How many times was each product purchased?

drop table if exists #product_info
drop table #product_info

with product_view_add as
(
select 
	ph.product_id,ph.page_name, ph.product_category, 
	sum(case when event_name = 'Page View' then 1 end) as viewed,
	sum(case when event_name = 'Add to Cart' then 1 end) as added_to_cart
from events e 
join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
where ph.product_category is not null
group by ph.product_id, ph.page_name, ph.product_category
),
product_abandoned as
(
select ph.product_id, ph.page_name, ph.product_category, count(*) abandoned
from events e 
join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
where ei.event_name = 'Add to Cart' 
	and e.visit_id not in (select e1.visit_id 
							from events e1 
							join event_identifier ei1 on e1.event_type = ei1.event_type
							where event_name = 'Purchase')
group by ph.product_id, ph.page_name, ph.product_category
),
product_purchased as 
(
select ph.product_id, ph.page_name, ph.product_category, count(*) purchased
from events e 
join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
where ei.event_name = 'Add to Cart' 
	and e.visit_id in (select e1.visit_id 
							from events e1 
							join event_identifier ei1 on e1.event_type = ei1.event_type
							where event_name = 'Purchase')
group by ph.product_id, ph.page_name, ph.product_category
)
select 
	pva.product_id,pva.page_name,pva.product_category,pva.viewed, pva.added_to_cart,
	pa.abandoned,
	pp.purchased
into #product_info
from product_view_add pva
join product_abandoned pa on pva.product_id = pa.product_id
join product_purchased pp on pva.product_id = pp.product_id
order by pva.product_id asc



/*Additionally, create another table which further aggregates the data for the above points 
but this time for each product category instead of individual products.*/

with product_info as
(
select 
	ph.product_category, 
	sum(case when event_name = 'Page View' then 1 end) as viewd,
	sum(case when event_name = 'Add to Cart' then 1 end) as added_to_cart
from events e 
join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
where ph.product_category is not null
group by  ph.product_category
),
product_abandoned as
(
select ph.product_category, count(*) abandoned
from events e 
join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
where ei.event_name = 'Add to Cart' 
	and e.visit_id not in (select e1.visit_id 
							from events e1 
							join event_identifier ei1 on e1.event_type = ei1.event_type
							where event_name = 'Purchase')
group by ph.product_category
),
product_purchased as 
(
select ph.product_category, count(*) purchased
from events e 
join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
where ei.event_name = 'Add to Cart' 
	and e.visit_id in (select e1.visit_id 
							from events e1 
							join event_identifier ei1 on e1.event_type = ei1.event_type
							where event_name = 'Purchase')
group by ph.product_category
)
select 
	pf.product_category,pf.viewd, pf.added_to_cart,
	pa.abandoned,
	pp.purchased
from product_info pf
join product_abandoned pa on pf.product_category = pa.product_category
join product_purchased pp on pf.product_category = pp.product_category

--1. Which product had the most views, cart adds and purchases?

with views as 
(
select *,
	rank() over (order by viewed desc) ranking
from #product_info
)
select *
from views
where ranking = 1
;
with cart_adds as 
(
select *,
	rank() over (order by added_to_cart desc) ranking
from #product_info
)
select *
from cart_adds
where ranking = 1
;
with purchases as 
(
select *,
	rank() over (order by purchased desc) ranking
from #product_info
)
select *
from purchases
where ranking = 1

--2. Which product was most likely to be abandoned?
with abandoned as 
(
select *, rank() over (order by abandoned desc) ranking
from #product_info
)
select * from abandoned where ranking = 1 

--3. Which product had the highest view to purchase percentage?
with purchase_per_view_pct as 
(
select 
	page_name, product_category,
	cast(100.0*purchased/viewed as decimal (5,2)) purchase_per_view_pct,
	rank() over (order by 100.0*purchased/viewed desc) ranking
from #product_info
)
select *
from purchase_per_view_pct 
where ranking = 1 

--4. What is the average conversion rate from view to cart add?
select 
	cast(avg(cast(100.0*added_to_cart/viewed as decimal (5,2))) as decimal (5,2)) avg_view_to_cart
from #product_info

--5. What is the average conversion rate from cart add to purchase?
select 
	cast(avg(cast(100.0*purchased/added_to_cart as decimal (5,2))) as decimal (5,2)) avg_cart_to_purchase
from #product_info


/* 3. Campaigns Analysis */
with time_ as 
(
select 
	visit_id,
	event_time, 
	rank() over (partition by visit_id order by event_time) ranking
from events
)
select 
	u.user_id, e.visit_id, min(event_time) visit_start_time,
	COUNT(case when event_name = 'Page View' then 1 end) as page_views,
	COUNT(case when event_name = 'Add to Cart' then 1 end) as cart_adds,
	COUNT(case when event_name = 'Purchase' then 1 end) as purchase,
	campaign_name,
	COUNT(case when event_name = 'Ad Impression' then 1 end) as impression,
	COUNT(case when event_name = 'Ad click' then 1 end) as click,
	STRING_AGG(case when ph.product_id is not null and event_name ='Add to Cart' then page_name end,', ') within group (order by e.sequence_number) cart_products
from events e 
join users u on e.cookie_id = u.cookie_id
join event_identifier ei on e.event_type = ei.event_type
left join page_hierarchy ph on e.page_id = ph.page_id
left join campaign_identifier c on e.event_time between c.start_date and c.end_date
where visit_id in (select visit_id from time_ where ranking = 1)
group by user_id, visit_id, c.campaign_name
order by user_id
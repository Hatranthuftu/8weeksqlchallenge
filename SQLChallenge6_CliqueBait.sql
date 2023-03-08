
---------- 2. Digital Analysis
----- How many users are there?
select count(distinct(user_id)) as count_user
from users
-- Answer:
count_user
   500

----- How many cookies does each user have on average?
with c as (
select user_id, cast(count(cookie_id) as decimal(10,2)) as count_cookie
from users
group by user_id
)
select round(cast(avg(count_cookie) as decimal(10,2)), 2) as avg_cookie
from c
-- Answer:
avg_cookie
  5.26

----- What is the unique number of visits by all users per month?
select datepart(m, event_time) as month, count(distinct(visit_id)) as count_visit
from events
group by datepart(m, event_time)
order by datepart(m, event_time)
-- Answer:
month   count_visit
  1	        876
  2	       1488
  3	        916
  4	        248
  5	        36

----- What is the number of events for each event type?
select event_name, count(e.event_type) as count_type
from events e join event_identifier ei on e.event_type = ei.event_type
group by event_name
order by count(e.event_type) desc
-- Answer:
 event_name   count_type
Page View	    20928
Add to Cart	    8451
Purchase	    1777
Ad Impression	876
Ad Click	    702

----- What is the percentage of visits which have a purchase event?
with c as (
select event_name, cast(count(e.event_type) as decimal(10,2)) as count_type
from events e join event_identifier ei on e.event_type = ei.event_type
where event_name = 'Purchase'
group by event_name
)
select convert(decimal(10,2), round(100*count_type/(select count(distinct(visit_id)) from events), 2))
from c
-- Answer: 49.86%

----- What is the percentage of visits which view the checkout page but do not have a purchase event?
with c as (
select visit_id
from events e join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
where page_name = 'Checkout'
),
d as (
select count(distinct(visit_id)) as count_visit
from events e join event_identifier ei on e.event_type = ei.event_type
where visit_id in (select visit_id from c) and 
visit_id not in (select visit_id from events e join event_identifier ei on e.event_type = ei.event_type where event_name = 'Purchase')
)
select cast(round(100*cast(count_visit as decimal(10,2))/(select count(distinct(visit_id)) from events), 2) as decimal(10,2))
from d
-- Answer: 9.15%

----- What are the top 3 pages by number of views?
with a as (
select event_name, count(visit_id) count_visit, row_number() over (order by count(visit_id) desc) as r
from events e join event_identifier ei on e.event_type = ei.event_type
group by event_name
)
select event_name, count_visit
from a
where r <= 3
order by r
-- Answer:
event_name    count_visit
Page View	     20928
Add to Cart	     8451
Purchase	     1777

----- What is the number of views and cart adds for each product category?
select product_category,
count(case when event_name = 'Page View' then event_name end) as count_view,
count(case when event_name = 'Add to Cart' then event_name end) as count_cartadd
from events e join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
where product_category is not null
group by product_category
order by product_category
-- Answer:
product_category count_view  count_cartadd
Fish	           4633	          2789
Luxury	           3032	          1870
Shellfish	       6204	          3792

----- What are the top 3 products by purchases?
with c as (
select page_name, count(page_name) as count_product, row_number() over (order by count(page_name) desc) as r
from events e join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id
where visit_id in (select visit_id from events e join event_identifier ei on e.event_type = ei.event_type where event_name = 'Purchase')
and event_name = 'Add to Cart'
group by page_name
)
select page_name, count_product
from c
where r <= 3
order by r
-- Answer: 
page_name count_product
Lobster	    754
Oyster	    726
Crab	    719

---------- 3. Product Funnel Analysis
----- Using a single SQL query - create a new output table which has the following details:
----How many times was each product viewed?
----How many times was each product added to cart?
----How many times was each product added to a cart but not purchased (abandoned)?
----How many times was each product purchased?
select visit_id, cookie_id, e.page_id, e.event_type, sequence_number, event_time, event_name, page_name, product_category, product_id
into #event
from events e join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy ph on e.page_id = ph.page_id

with c as (
select *, case
when event_name = 'Add to Cart' and visit_id in (select visit_id from #event where event_name = 'Purchase') then 'Buy'
when event_name = 'Add to Cart' and visit_id not in (select visit_id from #event where event_name = 'Purchase') then 'Not buy'
else NULL
end as buy
from #event
)
select page_name,
count(case when event_name = 'Page View' then page_name end) as product_view,
count(case when event_name = 'Add to Cart' then page_name end) as product_add_to_cart,
count(case when buy = 'Not buy' then buy end) as product_abandon,
count(case when buy = 'Buy' then buy end) as product_purchase
into #product_note
from c 
where product_id is not null
group by page_name
order by page_name
-- Answer
page_name     product_view  product_add_to_cart  product_abandon  product_purchase
Abalone	        1525	            932	               233	             699
Black Truffle	1469	            924	               217	             707
Crab	        1564	            949	               230	             719
Kingfish	    1559	            920	               213	             707
Lobster	        1547	            968	               214	             754
Oyster	        1568	            943	               217	             726
Russian Caviar	1563	            946	               249	             697
Salmon	        1559	            938	               227	             711
Tuna	        1515	            931	               234	             697

----- Additionally, create another table which further aggregates the data for the above points 
----- but this time for each product category instead of individual products.
with c as (
select *, case
when event_name = 'Add to Cart' and visit_id in (select visit_id from #event where event_name = 'Purchase') then 'Buy'
when event_name = 'Add to Cart' and visit_id not in (select visit_id from #event where event_name = 'Purchase') then 'Not buy'
else NULL
end as buy
from #event
)
select product_category,
count(case when event_name = 'Page View' then page_name end) as product_view,
count(case when event_name = 'Add to Cart' then page_name end) as product_add_to_cart,
count(case when buy = 'Not buy' then buy end) as product_abandon,
count(case when buy = 'Buy' then buy end) as product_purchase
into #category_note
from c
where product_id is not null
group by product_category
order by product_category
-- Answer:
product_category     product_view  product_add_to_cart  product_abandon  product_purchase
    Fish	              4633	          2789	              674	           2115
    Luxury	              3032	          1870	              466	           1404
    Shellfish	          6204	          3792	              894	           2898

----- Which product had the most views, cart adds and purchases?
with d as (
select *, (product_view + product_add_to_cart + product_purchase) as total
from #product_note
)
select page_name, total
from d
where total = (select max(total) from d)
-- Answer: Lobster: 3296

----- Which product was most likely to be abandoned?
select *
from #product_note
where product_abandon = (select max(product_abandon) from #product_note)
-- Russian Caviar: 249

----- Which product had the highest view to purchase percentage?
select page_name, cast(round(100*cast(product_purchase as decimal(10,2))/(select sum(product_purchase) from #product_note), 2) as decimal(10,2))
from #product_note
group by page_name, product_purchase
order by 100*cast(product_purchase as decimal(10,2))/(select sum(product_purchase) from #product_note) desc
-- Answer: Lobster - 11.75%

----- What is the average conversion rate from view to cart add?
with c as (
select 100*sum(product_add_to_cart)/sum(product_view) as con
from #product_note
)
select avg(con)
from c
-- Answer: 60%

----- What is the average conversion rate from cart add to purchase?
with c as (
select 100*sum(product_purchase)/sum(product_add_to_cart) as con
from #product_note
)
select avg(con)
from c
-- Answer: 75%

---------- 3. Campaigns Analysis
----- Generate a table that has 1 single row for every unique visit_id record and has the following columns:
--user_id
--visit_id
--visit_start_time: the earliest event_time for each visit
--page_views: count of page views for each visit
--cart_adds: count of product cart add events for each visit
--purchase: 1/0 flag if a purchase event exists for each visit
--campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
--impression: count of ad impressions for each visit
--click: count of ad clicks for each visit
--(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

drop table if exists #product_campaign
select page_id, page_name, product_category, product_id, campaign_name, start_date, end_date
into #product_campaign
from page_hierarchy ph, campaign_identifier ci
where product_id between convert(int, left(products, 1)) and convert(int, right(products,1))

select user_id, visit_id,
count(case when event_name = 'Page View' then event_name end) as page_views,
count(case when event_name = 'Add to Cart' then event_name end) as cart_adds,
case when visit_id in (select visit_id from events e join event_identifier ei on e.event_type = ei.event_type where event_name = 'Purchase') then 1 else 0 end as purchase,
--case when convert(date, event_time) between start_date and end_date then campaign_name else NULL end as campaign_name,
count(case when event_name = 'Ad Impression' then event_name end) as impression,
count(case when event_name = 'Ad Click' then event_name end) as click
into #t1
from events e left join users u on e.cookie_id = u.cookie_id
left join event_identifier ei on e.event_type = ei.event_type
left join #product_campaign pc on e.page_id = pc.page_id
group by user_id, visit_id

with c as (select user_id, visit_id, event_time, page_id
from events e left join users u on e.cookie_id = u.cookie_id
where sequence_number = 1)
select user_id, visit_id, event_time, campaign_name
into #t4
from c, #product_campaign pc 
where convert(date, event_time) between start_date and end_date

with na as (select visit_id, isnull(page_name, 'Oysster') as page_name
from events e left join event_identifier ei on e.event_type = ei.event_type
left join #product_campaign pc on e.page_id = pc.page_id
where event_name = 'Add to Cart')
select distinct(b.visit_id), 
substring(
(
select ',' + a.page_name as [text()]
from na a
where a.visit_id = b.visit_id
order by a.visit_id
for xml path ('')
), 2, 1000) name_list
into #t3
from na b

select #t1.user_id, #t1.visit_id, event_time as visit_start_time, page_views, cart_adds, campaign_name, impression, click, name_list as cart_product
from #t1 join #t4 on #t1.visit_id = #t4.visit_id
join #t3 on #t1.visit_id = #t3.visit_id
group by #t1.user_id, #t1.visit_id, event_time, page_views, cart_adds, campaign_name, impression, click, name_list

-- Answer (top 10 lines):
1	0fc437	Feb  4 2020  5:49PM	  10	6	Half Off - Treat Your Shellf(ish)	1	1	Tuna,Russian Caviar,Black Truffle,Abalone,Crab,Oysster
1	30b94d	Mar 15 2020  1:12PM	  18	14	Half Off - Treat Your Shellf(ish)	2	2	Salmon,Kingfish,Tuna,Russian Caviar,Abalone,Lobster,Crab
1	41355d	Mar 25 2020 12:11AM	  12	2	Half Off - Treat Your Shellf(ish)	0	0	Lobster
1	ccf365	Feb  4 2020  7:16PM	  7	    3	Half Off - Treat Your Shellf(ish)	0	0	Lobster,Crab,Oysster
1	eaffde	Mar 25 2020  8:06PM	  20	16	Half Off - Treat Your Shellf(ish)	2	2	Salmon,Tuna,Russian Caviar,Black Truffle,Abalone,Lobster,Crab,Oysster
1	f7c798	Mar 15 2020  2:23AM	  18	6	Half Off - Treat Your Shellf(ish)	0	0	Russian Caviar,Crab,Oysster
2	0635fb	Feb 16 2020  6:42AM	  18	8	Half Off - Treat Your Shellf(ish)	0	0	Salmon,Kingfish,Abalone,Crab
2	3b5871	Jan 18 2020 10:16AM	  9	    6	25% Off - Living The Lux Life	    1	1	Salmon,Kingfish,Russian Caviar,Black Truffle,Lobster,Oysster
2	49d73d	Feb 16 2020  6:21AM	  22	18	Half Off - Treat Your Shellf(ish)	2	2	Salmon,Kingfish,Tuna,Russian Caviar,Black Truffle,Abalone,Lobster,Crab,Oysster
2	910d9a	Feb  1 2020 10:40AM	  16	2	Half Off - Treat Your Shellf(ish)	0	0	Abalone
2	d58cbd	Jan 18 2020 11:40PM	  8	    4	25% Off - Living The Lux Life	    0	0	Kingfish,Tuna,Abalone,Crab
2	e26a84	Jan 18 2020  4:06PM	  6	    2	25% Off - Living The Lux Life	    0	0	Salmon,Oysster
3	9a2f24	Feb 21 2020  3:19AM	  6	    2	Half Off - Treat Your Shellf(ish)	0	0	Kingfish,Black Truffle
3	bf200a	Mar 11 2020  4:10AM	  7	    2	Half Off - Treat Your Shellf(ish)	0	0	Salmon,Crab



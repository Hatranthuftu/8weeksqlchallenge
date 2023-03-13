
----------- High Level Sales Analysis
----- What was the total quantity sold for all products?
select sum(qty) as total_sold
from sales
-- Answer:
total_sold
  45216

----- What is the total generated revenue for all products before discounts?
select sum(qty*price) as price_before_discount
from sales
-- Answer:
price_before_discount
      1289453

----- What was the total discount amount for all products?
select sum(qty*price*discount/100) as total_discount
from sales
-- Answer:
total_discount
  149486

---------- Transaction Analysis
----- How many unique transactions were there?
select count(distinct(txn_id)) as unique_transactions
from sales
-- Answer:
unique_transactions
  2500

----- What is the average unique products purchased in each transaction?
with c as (
select txn_id, cast(count(distinct(prod_id)) as decimal(10,2)) as count_pro
from sales
group by txn_id
)
select round(cast(avg(count_pro) as decimal(10,2)), 2) as avg_pro
from c
-- Answer
avg_pro
6.04

----- What is the average discount value per transaction?
with d as (
select txn_id, cast(avg(discount) as decimal(10,2)) as avg_dis
from sales
group by txn_id
)
select round(cast(avg(avg_dis) as decimal(10,2), 2) as avg_discount
from d
-- Answer:
avg_discount
12.09

----- What is the percentage split of all transactions for members vs non-members?
with e as (
select txn_id, member
from sales
group by txn_id, member
),
f as (
select
100*cast(count(case when member = 't' then member end) as decimal(10,2))/count(txn_id) as mem_txn,
100*cast(count(case when member = 'f' then member end) as decimal(10,2))/count(txn_id) as not_mem_txn
from e
)
select round(cast(not_mem_txn/mem_txn as decimal(10,2)), 2) as percent_split
from f

-- Answer:
percent_split
0.66

----- What is the average revenue for member transactions and non-member transactions?
with c as (
select txn_id, member, cast((sum(qty*price) - sum(qty*price*discount/100)) as decimal(10,2)) as revenue
from sales
group by txn_id, member
)
select 
round(cast(avg(case when member = 't' then revenue end) as decimal(10,2)), 2) as avg_mem_revenue,
round(cast(avg(case when member = 'f' then revenue end) as decimal(10,2)), 2) as avg_not_mem_revenue
from c

-- Answer:
avg_mem_revenue: 456.82
avg_not_mem_revenue: 454.73

---------- Product Analysis
----- What are the top 3 products by total revenue before discount?
with c as (
select product_name, sum(qty*s.price) as revenue, row_number() over (order by sum(qty*s.price) desc) as r 
from sales s left join product_details ps on s.prod_id = ps.product_id
group by product_name
)
select product_name, revenue
from c
where r <= 3
-- Answer:
product_name                    revenue
Blue Polo Shirt - Mens	        217683
Grey Fashion Jacket - Womens	209304
White Tee Shirt - Mens	        152000

----- What is the total quantity, revenue and discount for each segment?
select segment_name, sum(qty) as total_quantity, sum(qty*s.price) as total_revenue, sum(qty*s.price*discount/100) as total_discount
from sales s left join product_details ps on s.prod_id = ps.product_id
group by segment_name
order by segment_name
-- Answer:
segment_name   total_quantity   total_revenue   total_discount
Jacket	           11385	        366983	         42451
Jeans	           11349	        208350	         23673
Shirt	           11265	        406143	         48082
Socks	           11217	        307977	         35280

----- What is the top selling product for each segment?
with c as (
select segment_name, product_name, sum(qty) as total_quantity, dense_rank() over (partition by segment_name order by sum(qty) desc) r
from sales s left join product_details ps on s.prod_id = ps.product_id
group by segment_name, product_name
)
select segment_name, product_name
from c
where r = 1
-- Answer:
segment_name   product_name
Jacket	       Grey Fashion Jacket - Womens
Jeans	       Navy Oversized Jeans - Womens
Shirt	       Blue Polo Shirt - Mens
Socks	       Navy Solid Socks - Mens

----- What is the total quantity, revenue and discount for each category?
select category_name, sum(qty) as total_quantity, sum(qty*s.price) as total_revenue, sum(qty*s.price*discount/100) as total_discount
from sales s left join product_details ps on s.prod_id = ps.product_id
group by category_name
order by category_name
-- Answer:
category_name   total_quantity  total_revenue  total_discount
Mens	             22482	       714120	       83362
Womens	             22734	       575333	       66124

----- What is the top selling product for each category?
with c as (
select category_name, product_name, sum(qty) as total_quantity, dense_rank() over (partition by category_name order by sum(qty) desc) r
from sales s left join product_details ps on s.prod_id = ps.product_id
group by category_name, product_name
)
select category_name, product_name
from c
where r = 1
-- Answer:
category_name            product_name
Mens	               Blue Polo Shirt - Mens
Womens	               Grey Fashion Jacket - Womens

----- What is the percentage split of revenue by product for each segment?
with c as (
select segment_name, product_name, cast((sum(qty*s.price) - sum(qty*s.price*discount/100)) as decimal(10,2)) as revenue
from sales s join product_details ps on s.prod_id = ps.product_id
group by segment_name, product_name
)
select segment_name, product_name, round(cast(100*revenue/(select sum(revenue) from c) as decimal(10,2)), 2) as percent_product
from c
group by segment_name, product_name, revenue
order by segment_name, product_name

-- Answer:
segment_name      product_name              percent_product
Jacket	      Grey Fashion Jacket - Womens	    16.19
Jacket	      Indigo Rain Jacket - Womens	    5.56
Jacket	      Khaki Suit Jacket - Womens	    6.72
Jeans	      Black Straight Jeans - Womens	    9.39
Jeans	      Cream Relaxed Jeans - Womens	    2.90
Jeans	      Navy Oversized Jeans - Womens	    3.91
Shirt	      Blue Polo Shirt - Mens	        16.80
Shirt	      Teal Button Up Shirt - Mens	    2.85
Shirt	      White Tee Shirt - Mens	        11.76
Socks	      Navy Solid Socks - Mens	        10.57
Socks	      Pink Fluro Polkadot Socks - Mens	8.51
Socks	      White Striped Socks - Mens	    4.85

----- What is the percentage split of revenue by segment for each category?
with c as (
select category_name, segment_name, cast((sum(qty*s.price) - sum(qty*s.price*discount/100)) as decimal(10,2)) as revenue
from sales s join product_details ps on s.prod_id = ps.product_id
group by category_name, segment_name
)
select category_name, segment_name, round(cast(100*revenue/(select sum(revenue) from c) as decimal(10,2)), 2) as percent_segment
from c
group by category_name, segment_name, revenue
order by category_name, segment_name

-- Answer:
category_name  segment_name  percent_segment
Mens	        Shirt	        31.41
Mens	        Socks	        23.92
Womens	        Jacket	        28.47
Womens	        Jeans	        16.20

----- What is the percentage split of total revenue by category?
with c as (
select category_name, cast((sum(qty*s.price) - sum(qty*s.price*discount/100)) as decimal(10,2)) as revenue
from sales s join product_details ps on s.prod_id = ps.product_id
group by category_name
)
select category_name, round(cast(100*revenue/(select sum(revenue) from c) as decimal(10,2)), 2) as percent_category
from c
group by category_name, revenue

-- Answer:
category_name  percent_category
Mens	           55.33
Womens	           44.67

----- What is the total transaction “penetration” for each product? 
----- (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
with c as (
select prod_id, cast(count(txn_id) as decimal(10,2)) as cou_trans
from (select prod_id, txn_id from sales s group by prod_id, txn_id) t
group by prod_id
)
select prod_id, round(cast(cou_trans/(select count(distinct(txn_id)) from sales) as decimal(10,4)), 4) as penetration
from c
group by prod_id, cou_trans
-- Answer:
prod_id penetration
2a2353	0.5072
e83aa3	0.4984
b9a74d	0.4972
c4a632	0.5096
c8d436	0.4968
72f5d4	0.5000
f084eb	0.5124
9ec847	0.5100
e31d39	0.4972
2feb6b	0.5032
d5e9a6	0.4988
5d267b	0.5072

----- What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
with c as (
select prod_id, count(prod_id) as cou_pro, dense_rank() over (order by count(prod_id) desc) as r
from (select txn_id, prod_id from sales) t
group by prod_id
)
select prod_id, cou_pro
from c
where r <= 3
order by r
-- Answer:
f084eb	1281
9ec847	1275
c4a632	1274

---------- Reporting Challenge
----- Write a single SQL script that combines all of the previous questions into a scheduled report that 
----- the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.
--- High Level Sales Report
select datepart(m, start_txn_time) as month,
sum(qty) as total_products,
sum(qty*price) as total_revenue,
sum(qty*price*discount/100) as total_discount
from sales
group by datepart(m, start_txn_time)
order by datepart(m, start_txn_time)

month   total_products  total_revenue  total_discount
1	         14788	        420672	       49400
2	         14820	        421554	       49419
3	         15608	        447227	       50667

--- Transaction Report
declare @cou_pro int
set @cou_pro = (select count(distinct(prod_id)) from sales)

declare @cou_discount int
set @cou_discount = (select sum(distinct(discount)) from sales)

select datepart(m, start_txn_time) as month, txn_id,
count(distinct(txn_id)) as unique_trans,
round(cast(avg(@cou_pro) as decimal(10,2)), 2) as avg_product,
round(cast(avg(@cou_discount) as decimal(10,2)), 2) as avg_discount,
round(cast(count(case when member = 't' then txn_id end) as decimal(10,2))/count(case when member = 'f' then txn_id end), 2) as mem_split_non_mem,
round(avg(cast(sum(case when member = 't' then qty*price end) as decimal(10,2))), 2) as avg_mem_revenue,
round(avg(cast(sum(case when member = 'f' then qty*price end) as decimal(10,2))), 2) as avg_non_mem_revenue
from sales
group by datepart(m, start_txn_time), txn_id
order by datepart(m, start_txn_time), txn_id

---------- Bonus Challenge: transform the product_hierarchy and product_prices datasets to the product_details table
--- Create a temp table name category (include 'Men', 'Women')
drop table if exists #category
select *
into #category
from product_hierarchy
where level_name = 'Category'

--- Create a temp table name segment
drop table if exists #segment
select *
into #segment
from product_hierarchy
where level_name = 'Segment'

--- Create a temp table name style
drop table if exists #style
select *
into #style
from product_hierarchy
where level_name = 'Style'

--- Join 3 temp table and create table detail
with h as (
select t.id segment_id, t.parent_id category_id, s.id style_id, segment_name, category_name, s.level_text as style_name, concat(s.level_text, ' ', segment_name, ' - ', category_name) as product_name
from (select a.id, a.parent_id, a.level_text segment_name, b.level_text category_name from #segment a full join #category b on a.parent_id = b.id) t
right join #style s on t.id = s.parent_id
)
select product_id, price, product_name, category_id, segment_id, style_id, category_name, segment_name, style_name
from h join product_prices p on h.style_id = p.id
-- Answer
product_id  price          product_name          category_id  segment_id  style_id  category_name  segment_name   style_name
c4a632	     13	  Navy Oversized Jeans - Womens	      1	           3	      7	        Womens	      Jeans	    Navy Oversized
e83aa3	     32	  Black Straight Jeans - Womens	      1	           3	      8	        Womens	      Jeans	    Black Straight
e31d39	     10	  Cream Relaxed Jeans - Womens	      1	           3	      9	        Womens	      Jeans	    Cream Relaxed
d5e9a6	     23	  Khaki Suit Jacket - Womens	      1	           4	      10	    Womens	      Jacket	Khaki Suit
72f5d4	     19	  Indigo Rain Jacket - Womens	      1	           4	      11	    Womens	      Jacket	Indigo Rain
9ec847	     54	  Grey Fashion Jacket - Womens	      1	           4	      12	    Womens	      Jacket	Grey Fashion
5d267b	     40	  White Tee Shirt - Mens	          2	           5	      13	    Mens	      Shirt	    White Tee
c8d436	     10	  Teal Button Up Shirt - Mens	      2	           5	      14	    Mens	      Shirt	    Teal Button Up
2a2353	     57	  Blue Polo Shirt - Mens	          2	           5	      15	    Mens	      Shirt	    Blue Polo
f084eb	     36	  Navy Solid Socks - Mens	          2	           6	      16	    Mens	      Socks	    Navy Solid
b9a74d	     17	  White Striped Socks - Mens	      2	           6	      17	    Mens	      Socks	    White Striped
2feb6b	     29	  Pink Fluro Polkadot Socks - Mens	  2	           6	      18	    Mens	      Socks	    Pink Fluro Polkadot


---------- A. Customer Nodes Exploration
----- How many unique nodes are there on the Data Bank system?
select count(distinct(node_id)) as num_unique_node
from customer_nodes
-- Answer: There are 5 unique nodes.

----- What is the number of nodes per region?
select region_name, count(node_id) as num_region
from customer_nodes n join regions r on n.region_id = r.region_id
group by region_name
order by count(node_id)
-- Answer:
Europe	616
Asia	665
Africa	714
America	735
Australia	770

----- How many customers are allocated to each region?
select region_name, count(customer_id) as num_region
from customer_nodes n join regions r on n.region_id = r.region_id
group by region_name
order by count(customer_id)
-- Answer:
Europe	    616
Asia	    665
Africa	    714
America	    735
Australia	770

----- How many days on average are customers reallocated to a different node?
with rellocated as (
select *, datediff(day, start_date, end_date) as diff
from customer_nodes
where end_date != '9999-12-31'
),
su as (
select customer_id, node_id, sum(diff) as sum_diff
from rellocated
group by customer_id, node_id)
select round(avg(sum_diff),2) as avg_rellocated
from su
-- Answer: On average, customers are reallocated to a different node every 23 days.

----- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
----- Median
with re as (
select *, datediff(day, start_date, end_date) as diff, row_number() over (order by datediff(day, start_date, end_date)) as r
from customer_nodes
where end_date != '9999-12-31'
)
select diff
from re
where r = 1500 or r = 1501
-- Answer: Median = 15
----- 85 percentile and 90 percentile
declare @total int
set @total = (select count(diff)
from (select *, datediff(day, start_date, end_date) as diff, row_number() over (order by datediff(day, start_date, end_date)) as r
from customer_nodes
where end_date != '9999-12-31'
) t)
declare @per_85 float
set @per_85 = 0.85*@total
declare @per_90 float
set @per_90 = 0.9*@total
select diff
from (select *, datediff(day, start_date, end_date) as diff, row_number() over (order by datediff(day, start_date, end_date)) as r
from customer_nodes where end_date != '9999-12-31') t
where r = @per_85 or r = @per_90

-- Answer:
25
26

---------- B. Customer Transactions
----- What is the unique count and total amount for each transaction type?
select txn_type, count(txn_type) as cou, sum(txn_amount) as total_amount
from customer_transactions
group by txn_type
-- Answer:
withdrawal	1580	793003
deposit	    2671	1359168
purchase	1617	806537

----- What is the average total historical deposit counts and amounts for all customers?
select count(txn_amount) as cou_deposit, avg(txn_amount) as avg_deposit
from customer_transactions
where txn_type = 'deposit'
-- Answer:
2671	508

----- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
with cte as (
select customer_id, month(txn_date) as mon,
sum(case when txn_type = 'deposit' then 0 else 1 end) as deposit,
sum(case when txn_type = 'purchase' then 0 else 1 end) as purchase,
sum(case when txn_type = 'withdrawal' then 0 else 1 end) as  withdrawal
from customer_transactions
group by customer_id, month(txn_date)
)
select mon, count(distinct(customer_id))
from cte
where deposit > 1 and purchase >= 1 and withdrawal >= 1
group by mon
order by mon
-- Answer:
1	170
2	266
3	287
4	96

----- What is the closing balance for each customer at the end of the month?
with closing as (
select customer_id, month(txn_date) mon, case
when txn_type = 'deposit' then txn_amount
when txn_type = 'purchase' then - (txn_amount)
else - (txn_amount)
end as num
from customer_transactions
)
select customer_id, mon, sum(num)
from closing
group by customer_id, mon
order by customer_id, mon
-- Answer: 
1	1	312
1	3	-952
2	1	549
2	3	61
3	1	144
3	2	-965
3	3	-401
3	4	493
4	1	848
4	3	-193
5	1	954
5	3	-2877
5	4	-490
6	1	733
6	2	-785
6	3	392

----- What is the percentage of customers who increase their closing balance by more than 5%?
select customer_id, txn_date, case
when txn_type = 'deposit' then txn_amount
when txn_type = 'purchase' then - (txn_amount)
else - (txn_amount)
end as num, row_number() over (partition by customer_id order by txn_date) as r
into #change
from customer_transactions

with c as (
select customer_id, sum(num) as closing_balance
from #change
group by customer_id
)
select count(c.customer_id)*100/(select count(distinct(customer_id)) from customer_transactions)
from c join (select customer_id, num as begin_balance from #change where r = 1) t on c.customer_id = t.customer_id
where closing_balance >= 105*begin_balance
-- Answer: There are 2% customers.





--------- A. Customer Journey
----- Based off the 8 sample customers provided in the sample from the subscriptions table, 
----- write a brief description about each customer’s onboarding journey.
select customer_id, plan_name, start_date 
from subscriptions s join plans p on s.plan_id = p.plan_id 
where customer_id in (1,2,11,13,15,16,18,19)
-- Answer: Customer 1 started the free trial on 1 August 2020, then started the basic monthly on 8 August 2020.
-- Customer 2 started the trial on 20 September 2020, then started the pro annual on 27 September 2020.
-- Customer 11 started the pro annual on 19 November 2020, then started the chum on 26 November 2020.
-- Customer 13 started the trial on 15 December 2020, then started the basic monthly on 15 December 2020, and started the pro monthly on 29 March 2021
-- Customer 15 started the trial on 17 March 2020, then started the pro monthly on 24 March 2020, and started the chum on 29 April 2020
-- Customer 16 started the trial on 31 May 2020, then started the basic monthly on 07 June 2020, and started the pro annual on 21 Octorber 2020
-- Customer 18 started the trial on 06 July 2020, then started the pro monthly on 13 July 2020
-- Customer 19 started the trial on 22 June 2020, then started the pro monthly on 29 June 2020, and started the pro annual on 29 August 2020

---------- B. Data Analysis Questions
----- How many customers has Foodie-Fi ever had?
select count(distinct(customer_id)) from subscriptions
-- Answer: There are 1000 customers.

----- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value?
select month(start_date), count(s.plan_id) 
from subscriptions s join plans p on s.plan_id = p.plan_id 
where plan_name = 'trial'
group by month(start_date)
-- Answer: 
1	88    7	    89
2	68    8	    88
3	94    9 	87
4	81    10    79
5	88    11	75
6	79    12	84

----- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name?
select plan_name, count(s.plan_id)
from subscriptions s join plans p on s.plan_id = p.plan_id 
where year(start_date) > 2020
group by plan_name
-- Ansswer:
basic monthly	8
churn	        71
pro annual	    63
pro monthly	    60

----- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
declare @churn float
set @churn = (select count(distinct(customer_id))
from subscriptions s join plans p on s.plan_id = p.plan_id 
where plan_name = 'churn')

declare @total float
set @total = (select count(distinct(customer_id)) from subscriptions)

declare @percent float
set @percent = (100*@churn/@total)

select @churn, @percent
-- Answer: There are 307 customers churned, takes 30.7% of all customers.

----- How many customers have churned straight after their initial free trial 
----- what percentage is this rounded to the nearest whole number?
declare @churn_straight int
set @churn_straight =
(select count(s.customer_id)
from (select customer_id, count(plan_id) as count_plan_id from subscriptions group by customer_id having count(plan_id) = 2) t 
join subscriptions s on t.customer_id = s.customer_id
where plan_id = 4)

declare @total float
set @total = (select count(distinct(customer_id)) from subscriptions)

select @churn_straight, round(100*@churn_straight/@total, 0)
-- Answer: There are 92 customers, take 9%.

----- What is the number and percentage of customer plans after their initial free trial?
with sub as (
select plan_id, count(plan_id) as num_plan 
from (select *, row_number() over (partition by customer_id order by start_date) as r from subscriptions) t
where r in (1,2)
group by plan_id
)
select plan_id, num_plan, round(convert(float, 100*num_plan/(select count(distinct(customer_id)) from subscriptions as total)), 2) as percent_plan
from sub
where plan_id != 0
-- Answer:
1	546	54,60
2	325	32,50
3	37	3,70
4	92	9,20

----- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with sub as (
select plan_id, count(plan_id) as num_plan 
from (select *, row_number() over (partition by customer_id order by start_date) as r from subscriptions where start_date <= '2020-12-31') t
group by plan_id
)
select plan_id, num_plan, round(convert(float, 100*num_plan/(select count(distinct(customer_id)) from subscriptions as total)), 2) as percent_plan
from sub
-- Answer
0	1000	100
3	195	    19.50
1	538	    53.80
4	236	    23.60
2	479	    47.90

----- How many customers have upgraded to an annual plan in 2020?
select count(distinct(customer_id)) as customer_annual
from subscriptions s join plans p on s.plan_id = p.plan_id
where plan_name = 'pro annual' and year(start_date) = '2020'
-- Answer: There are 195 customers.

----- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with annual as (
select t.customer_id, start_date, annual_date, datediff(day, start_date, annual_date) as upgrade_annual
from (select customer_id, start_date as annual_date from subscriptions s join plans p on s.plan_id = p.plan_id where s.plan_id = 3) t
join (select customer_id, start_date from subscriptions s join plans p on s.plan_id = p.plan_id where s.plan_id = 0) h
on t.customer_id = h.customer_id)
select avg(upgrade_annual)
from annual
-- Answer: It takes 104 days.

----- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with annual as (
select t.customer_id, start_date, annual_date, datediff(day, start_date, annual_date) as upgrade_annual, case
when datediff(day, start_date, annual_date) <= 30 then '0 - 30 days'
when datediff(day, start_date, annual_date) > 30 and datediff(day, start_date, annual_date) <= 60 then '31 - 60 days'
when datediff(day, start_date, annual_date) > 60 and datediff(day, start_date, annual_date) <= 90 then '61 - 90 days'
when datediff(day, start_date, annual_date) > 90 and datediff(day, start_date, annual_date) <= 120 then '31 - 60 days'
when datediff(day, start_date, annual_date) > 120 and datediff(day, start_date, annual_date) <= 150 then '31 - 60 days'
when datediff(day, start_date, annual_date) > 150 and datediff(day, start_date, annual_date) <= 180 then '31 - 60 days'
when datediff(day, start_date, annual_date) > 180 and datediff(day, start_date, annual_date) <= 210 then '180 - 210 days'
when datediff(day, start_date, annual_date) > 210 and datediff(day, start_date, annual_date) <= 240 then '211 - 240 days'
when datediff(day, start_date, annual_date) > 240 and datediff(day, start_date, annual_date) <= 270 then '241 - 270 days'
when datediff(day, start_date, annual_date) > 270 and datediff(day, start_date, annual_date) <= 300 then '271 - 300 days'
when datediff(day, start_date, annual_date) > 300 and datediff(day, start_date, annual_date) <= 330 then '301 - 330 days'
else '331 - 360 days'
end as period
from (select customer_id, start_date as annual_date from subscriptions s join plans p on s.plan_id = p.plan_id where s.plan_id = 3) t
join (select customer_id, start_date from subscriptions s join plans p on s.plan_id = p.plan_id where s.plan_id = 0) h
on t.customer_id = h.customer_id)
select period, count(period) as num_of_period
from annual
group by period
order by count(period) desc

-- Answer:
31 - 60 days	137
0 - 30 days	    49
61 - 90 days	34
180 - 210 days	26
241 - 270 days	5
211 - 240 days	4
271 - 300 days	1
301 - 330 days	1
331 - 360 days	1

----- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with cus as (
select customer_id, start_date, plan_name, row_number() over(partition by customer_id order by start_date) as r
from subscriptions s join plans p on s.plan_id = p.plan_id
where year(start_date) = 2020 and plan_name in ('pro monthly', 'basic monthly')
)
select count(customer_id)
from cus
where plan_name = 'basic monthly' and r = 2
-- Answer: There is no customers.

---------- C. Challenge Payment Question
select customer_id, s.plan_id, plan_name, start_date as payment_date, price as amount, row_number() over (partition by customer_id order by start_date) as payment_order
from subscriptions s join plans p on s.plan_id = p.plan_id
where s.plan_id != 0

---------- D. Outside The Box Questions
----- How would you calculate the rate of growth for Foodie-Fi?
with rate_growth as (
select month(start_date) as mon, sum(price) as total_month, lead(sum(price)) over(order by month(start_date)) as total_next_month
from subscriptions s join plans p on s.plan_id = p.plan_id
group by month(start_date)
)
select mon, total_next_month/total_month as rate
from rate_growth
-- Answer:
1	0.835542
2	0.845994
3	1.266587
4	0.652545
5	1.148464
6	1.167211
7	1.232826
8	0.993929
9	1.214954
10	0.657571
11	1.050765
12	NULL

----- What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?
select year(start_date) as y, sum(price) as revenue
from subscriptions s join plans p on s.plan_id = p.plan_id
group by year(start_date)
order by year(start_date)
-- Answer: We need to know the revenue, cost and profit. The total revenue of 2020 is 53663.30.

----- What are some key customer journeys or experiences that you would analyse further to improve customer retention?
with journey as (
select t.customer_id, plan_id, start_date, row_number() over (partition by t.customer_id order by plan_id) as cou_plan
from (select customer_id from subscriptions where plan_id = 4) t join subscriptions s on t.customer_id = s.customer_id)
select cou_plan, count(customer_id) as cou_cus
from journey
group by cou_plan
order by count(customer_id) desc
-- Answer: There are 307 customers using 1 plan before churned, 215 customers using 2 plans before churned, 45 customers using 3 plans before churned.


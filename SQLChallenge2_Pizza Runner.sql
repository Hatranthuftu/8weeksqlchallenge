---------- DATA CLEANING
----- Remove null values in exlusions and extras columns and replace with blank space ' ' in customer_orders
update customer_orders
set exclusions = replace(exclusions, 'null', ' ')

update customer_orders
set extras = replace(extras, 'null', ' ')

update customer_orders
set extras = isnull(extras, ' ')

----- Remove null values in exlusions and extras columns and replace with blank space ' ' in runner_orders
select * from runner_orders

update runner_orders
set pickup_time = replace(pickup_time, 'null', ' ')

update runner_orders
set distance = replace(distance, 'null', ' ')

update runner_orders
set duration = replace(duration, 'null', ' ')

update runner_orders
set cancellation = replace(cancellation, 'null', ' ')

update runner_orders
set cancellation = isnull(cancellation, ' ')

----- Remove 'km' in distance column and change to the correct data type
update runner_orders
set distance = trim('km' from distance)

alter table runner_orders
alter column distance float

----- Remove 'mins', 'minutes' in duration column and change to the correct data type
update runner_orders
set duration = trim('minutes' from duration)

alter table runner_orders
alter column duration float

update runner_orders
set duration = trim('minutes' from duration)

----- Change pizza_name in pizza_names, toppings in pizza_recipes, toppings_name in pizza_toppings to the varchar
alter table pizza_names
add pizza_name_1 varchar(100)

update pizza_names
set pizza_name_1 = convert(varchar(100), pizza_name)

alter table pizza_names
drop column pizza_name

alter table pizza_recipes
add toppings_1 varchar(100)

update pizza_recipes
set toppings_1 = convert(varchar(100), toppings)

alter table pizza_recipes
drop column toppings

alter table pizza_toppings
add topping_name_1 varchar(100)

update pizza_toppings
set topping_name_1 = convert(varchar(100), topping_name)

alter table pizza_toppings
drop column topping_name
---------- A. Pizza Metrics
----- How many pizzas were ordered?
select count(pizza_id) as Total_pizza_ordered
from customer_orders
-- Answer: Total of 14 pizzas were ordered.

-----How many unique customer orders were made?
select count(distinct(order_id))
from customer_orders
-- Answer: There are 10 unique customer orders.

----- How many successful orders were delivered by each runner?
select runner_id, count(runner_id) 
from runner_orders
where distance != 0
group by runner_id
-- Answer: Runner 1 has 4 successful delivered orders, Runner 2 has 3 successful delivered orders, Runner 3 has 1 successful delivered order.

----- How many of each type of pizza was delivered?
select pizza_name_1, count(c.pizza_id)
from customer_orders c join runner_orders r on r.order_id = c.order_id
join pizza_names p on c.pizza_id = p.pizza_id
where distance != 0
group by pizza_name_1
-- Answer: There are 9 delivered Meatlovers pizzas and 3 Vegetarian pizzas.

----- How many Vegetarian and Meatlovers were ordered by each customer?
select customer_id, pizza_name_1, count(c.pizza_id) as count_pizza
from customer_orders c join pizza_names p on c.pizza_id = p.pizza_id
group by customer_id, pizza_name_1
order by customer_id, count_pizza desc
-- Answer: Customer 101 ordered 2 Meatlovers pizzas and 1 Vegetarian pizza, Customer 102 ordered 2 Meatlovers pizzas and 2 Vegetarian pizzas.
--Customer 103 ordered 3 Meatlovers pizzas and 1 Vegetarian pizza, Customer 104 ordered 1 Meatlovers pizza
--Customer 105 ordered 1 Vegetarian pizza.

-- What was the maximum number of pizzas delivered in a single order?
with count_id as (
select order_id, count(order_id) as count_id
from customer_orders
group by order_id)
select max(count_id) as max_count
from count_id
-- Answer: Maximum number of pizza delivered in a single order is 3 pizzas.

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
with change as (
select customer_id, case
when (exclusions = ' ') and (extras = ' ') then 'N'
else 'Y'
end as change
from customer_orders c join runner_orders r on c.order_id = r.order_id
where distance != 0)
select customer_id, change, count(change)
from change
group by customer_id, change
order by customer_id
-- Answer: Customer 101 and 102 likes his/her pizzas per the original recipe.
-- Customer 103, 104 and 105 have their own preference for pizza topping and requested at least 1 change (extra or exclusion topping) on their pizza.

----- How many pizzas were delivered that had both exclusions and extras?
select count(pizza_id) 
from customer_orders c join runner_orders r on c.order_id = r.order_id
where distance != 0 and exclusions <> ' ' and extras <> ' ' 
-- Answer: 1 pizza delivered that had both extra and exclusion topping.

----- What was the total volume of pizzas ordered for each hour of the day?
select datepart(hour, [order_time]) as hour_of_day, count(order_id) as pizza_count
from customer_orders
group by datepart(hour, [order_time])
-- Answer: Highest volume of pizza ordered is at 13 (1:00 pm), 18 (6:00 pm) and 21 (9:00 pm), Lowest volume of pizza ordered is at 11 (11:00 am), 19 (7:00 pm) and 23 (11:00 pm).

----- What was the volume of orders for each day of the week?
select format(dateadd(day, 2, order_time),'dddd') as day_in_week, count(order_id) as pizza_count
from customer_orders
group by format(dateadd(day, 2, order_time),'dddd')
-- Answer: There are 5 pizzas ordered on Friday and Monday, There are 3 pizzas ordered on Saturday, There is 1 pizza ordered on Sunday.

---------- B. Runner and Customer Experience
----- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select datepart(week, registration_date) as registration_week, count(runner_id) as runner_signup
from runners
group by datepart(week, registration_date)
-- Answer: On Week 1 of Jan 2021, 2 new runners signed up, On Week 2 and 3 of Jan 2021, 1 new runner signed up.

----- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
with average as (
select c.order_id, c.order_time, r.pickup_time, datediff(minute, c.order_time, r.pickup_time) as mi
from customer_orders c join runner_orders r on c.order_id = r.order_id
where distance != 0
group by c.order_id, c.order_time, r.pickup_time
)
select avg(mi)
from average
-- Answer: The average time taken in minutes by runners to arrive at Pizza Runner HQ to pick up the order is 16 minutes.

----- Is there any relationship between the number of pizzas and how long the order takes to prepare?
with p as (
select c.order_id, c.order_time, r.pickup_time, datediff(minute, c.order_time, r.pickup_time) as prepare, 
count(c.pizza_id) as number_of_pizza
from customer_orders c join runner_orders r on c.order_id = r.order_id
where distance != 0
group by c.order_id, c.order_time, r.pickup_time)
select number_of_pizza, avg(prepare)
from p
group by number_of_pizza
order by number_of_pizza desc
-- Answer: On average, a single pizza order takes 12 minutes to prepare, An order with 3 pizzas takes 30 minutes at an average of 10 minutes per pizza.
-- It takes 18 minutes to prepare an order with 2 pizzas which is 9 minutes per pizza — making 2 pizzas in a single order the ultimate efficiency rate.

----- What was the average distance travelled for each customer?
select customer_id, avg(duration) as avg_time
from customer_orders c join runner_orders r on c.order_id = r.order_id
where duration != 0
group by customer_id
-- Answer: Customer 101's average distance travelled is 29.5, Customer 102's one is 6.3, Customer 103's one is  4, Customer 104's one is 5.7
-- Customer 105's one is 25.

----- What was the difference between the longest and shortest delivery times for all orders?
select max(duration) - min(duration) as difference_time
from runner_orders
where duration != 0
-- Answer: The difference between longest and shortest delivery time for all orders is 31 minutes.

----- What was the average speed for each runner for each delivery and do you notice any trend for these values?
select r.order_id, runner_id, count(pizza_id) as number_of_pizza, (distance*1000)/(duration*60) as speed_m_per_s
from runner_orders r join customer_orders c on r.order_id = c.order_id
where distance != 0
group by r.order_id, runner_id, distance, duration
order by runner_id
-- Answer: Runner 1’s average speed runs from 10 m/s to 167 m/s.
-- Runner 2’s average speed runs from 17 m/s to 97.5 m/s.
-- Runner 3’s average speed is 11 m/s.

----- What is the successful delivery percentage for each runner?
select runner_id, round(100 * sum(
case
when distance = 0 THEN 0
else 1 
end) / count(*), 0) as success_perc
from runner_orders
group by runner_id
-- Answer: Runner 1 has 100% successful delivery, Runner 2 has 75% successful delivery, Runner 3 has 50% successful delivery.

---------- C. Ingredient Optimisation
----- What are the standard ingredients for each pizza?
with d as (select *
from pizza_recipes
cross apply string_split(toppings_1, ','))
select pizza_id, toppings_1, trim(value) each_topping into #pizza_recipes from d

select pizza_name_1, topping_name_1
from #pizza_recipes pr join pizza_names pn on pr.pizza_id = pn.pizza_id
join pizza_toppings pt on pr.each_topping = pt.topping_id
order by pizza_name_1
-- Answer: Meatlovers has Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami
-- Vegetarian has Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce

----- What was the most commonly added extra?
with c as (select * from customer_orders cross apply string_split(extras, ','))
select order_id, customer_id, pizza_id, exclusions, order_time, trim(value) as extra into #customer_extra from c
select topping_name_1, count(extra)
from #customer_extra ce join pizza_toppings pt on ce.extra = pt.topping_id
group by topping_name_1
order by count(extra) desc
-- Answer: Bacon was the most commonly added extra with 4 added extra.

----- What was the most common exclusion?
with c as (select * from customer_orders cross apply string_split(exclusions, ','))
select order_id, customer_id, pizza_id, extras, order_time, trim(value) as exclusion into #customer_exclusion from c
select topping_name_1, count(exclusion)
from #customer_exclusion ce join pizza_toppings pt on ce.exclusion = pt.topping_id
group by topping_name_1
order by count(exclusion) desc
-- Answer: Cheese was the most common exclusion with 4 exclusion.

----- Generate an order item for each record in the customers_orders table in the format of one of the following:
----- Meat Lovers
----- Meat Lovers - Exclude Beef
----- Meat Lovers - Extra Bacon
----- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
select * from #g

select *, SUBSTRING(exclusions,1,1) exc_1, substring(exclusions,4,1) exc_2, SUBSTRING(extras,1,1) ext_1, SUBSTRING(extras,4,1) ext_2 into #customer_order from customer_orders
drop table if exists #g
select order_id, pizza_name_1, pt1.topping_name_1 exc_1, pt2.topping_name_1 exc_2, pt3.topping_name_1 ext_1, pt4.topping_name_1 ext_2 into #g
from #customer_order co left join pizza_toppings pt1 on co.exc_1 = pt1.topping_id
left join pizza_toppings pt2 on co.exc_2 = pt2.topping_id
left join pizza_toppings pt3 on co.ext_1 = pt3.topping_id
left join pizza_toppings pt4 on co.ext_2 = pt4.topping_id
join pizza_names pn on co.pizza_id = pn.pizza_id

select *, case
when exc_1 is null and exc_2 is null and ext_1 is null and ext_2 is null then pizza_name_1
when exc_1 is not null then CONCAT(pizza_name_1, ' - Exclude ', exc_1)
when ext_1 is not null then CONCAT(pizza_name_1, ' - Extra ', ext_1)
when exc_1 is not null and exc_2 is not null then CONCAT(pizza_name_1, ' - Exclude ', exc_1, ', ', exc_2)
when ext_1 is not null and ext_2 is not null then CONCAT(pizza_name_1, ' - Extra ', ext_1, ', ', ext_2)
else CONCAT(pizza_name_1, ' - Exclude ', exc_1, ', ', exc_2, ' - Extra ', ext_1, ', ', ext_2)
end as Note
from #g 

----- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
select * from pizza_recipes

select * into #k
from pizza_recipes
cross apply string_split(toppings_1, ',')
drop table if exists #pizza_recipes
select pizza_id, trim(value) as topping into #pizza_recipes
from #k

select * from #pizza_recipes
select * from #customer_extra

---------- D. Pricing and Ratings
----- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
----- how much money has Pizza Runner made so far if there are no delivery fees?
with price as (
select pizza_name_1, count(c.pizza_id) as number_of_pizza, case
when pizza_name_1 = 'Meatlovers' then count(c.pizza_id)*12
else count(c.pizza_id)*10
end as price
from customer_orders c join runner_orders r on c.order_id = r.order_id
join pizza_names pn on c.pizza_id = pn.pizza_id
where distance != 0
group by pizza_name_1)
select sum(price) as Total_price
from price
-- Answer: They made $138.

----- What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
with extra_price as (
select pizza_id, extra, case
when extra != ' ' then 1
else 0
end as extra_price 
from #customer_extra c join runner_orders r on c.order_id = r.order_id
where distance != 0
group by pizza_id, extra)
select 138 + sum(extra_price)
from extra_price
-- Answer: They made $141

----- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
----- how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data 
----- for ratings for each successful customer order between 1 to 5.
drop table if exists Runner_rating
create table runner_rating (order_id integer, rating integer, review varchar(100)) 

insert into runner_rating values
('1', '1', 'Good'),
('2', '1', NULL),
('3', '4', 'Ok'),
('4', '1', 'Very bad'),
('5', '4', NULL),
('7', '3', 'A little slow'),
('8', '5', 'Very good'),
('10', '5', 'Perfect')

select *
from runner_rating

----- Using your newly generated table - can you join all of the information together to form a table 
----- which has the following information for successful deliveries?
select customer_id, c.order_id, runner_id, rating, order_time, pickup_time, 
datediff(minute, order_time, pickup_time) as time_between_order_and_pickup,
duration, distance/(duration/60) as average_speed, count(c.pizza_id) as total_pizza
from customer_orders c join runner_orders r on c.order_id = r.order_id
join runner_rating rr on c.order_id = rr.order_id
where distance ! = 0
group by customer_id, c.order_id, runner_id, rating, order_time, pickup_time, 
datediff(minute, order_time, pickup_time), duration, distance, distance*60/duration

----- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
----- how much money does Pizza Runner have left over after these deliveries?
with price as (
select c.order_id, pizza_id, distance, case
when pizza_id = 1 then 12 - 0.3*distance
else 10 - 0.3*distance
end as profit
from customer_orders c join runner_orders r on c.order_id = r.order_id
where distance != 0)
select sum(profit) from price
-- Answer: They made $73.38


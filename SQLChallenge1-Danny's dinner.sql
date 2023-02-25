/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(price) as Total_amount
from sales s, menu m
where s.product_id = m.product_id
group by s.customer_id
-- Answer: Customer A spent $76, Customer B spent $74, Customer C spent $36.

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct(order_date))
from sales
group by customer_id
order by customer_id
-- Answer: Customer A visited 4 times, Customer B visited 6 times, Customer C visited 2 times.

-- 3. What was the first item from the menu purchased by each customer?
with c as (
select customer_id, order_date, product_name, dense_rank() over (partition by customer_id order by order_date) as Rownumber
from sales s join menu m on s.product_id = m.product_id
)
select customer_id, product_name
from c
where Rownumber = 1
group by customer_id, product_name
-- Answer: Customer A's first orders are curry and sushi; Customer B's first order is curry; Customer C's first order is ramen.

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 (count(s.product_id)) as most_buy, product_name
from sales s join menu m on s.product_id = m.product_id
group by product_name, s.product_id
order by most_buy desc
--Answer: Most purchased item on the menu is ramen which is 8 times.

-- 5. Which item was the most popular for each customer?
with c as (
select customer_id, product_name, count(s.product_id) as most_buy, DENSE_RANK() over (partition by customer_id order by count(s.product_id) desc) as r
from sales s join menu m on s.product_id = m.product_id
group by customer_id, product_name
)
select customer_id, product_name, most_buy
from c
where r = 1
--Answer: Customer A and C's favourite item is ramen, Customer B enjoys all items on the menu

-- 6. Which item was purchased first by the customer after they became a member?
with c as (
select m.customer_id, order_date, product_id, dense_rank() over (partition by m.customer_id order by order_date) as dr
from sales s join members m on s.customer_id = m.customer_id
where s.order_date >= m.join_date
)
select customer_id, product_name
from c join menu on c.product_id = menu.product_id
where dr = 1
-- Answer: Customer A's first order as member is curry, Customer B's first order as member is sushi.

-- 7. Which item was purchased just before the customer became a member?
with c as (
select m.customer_id, order_date, product_id, dense_rank() over (partition by m.customer_id order by order_date) as dr
from sales s join members m on s.customer_id = m.customer_id
where s.order_date < m.join_date
)
select customer_id, product_name
from c join menu on c.product_id = menu.product_id
where dr = 1
-- Answer: Customer A’s last order before becoming a member is sushi and curry, 
--Customer B’s last order before becoming a member is cury.

--8. What is the total items and amount spent for each member before they became a member?
with c as (
select m.customer_id, order_date, product_id, dense_rank() over (partition by m.customer_id order by order_date) as dr
from sales s join members m on s.customer_id = m.customer_id
where s.order_date < m.join_date
)
select t.customer_id, count(t.product_name) as Total_items, sum(t.Amount) as Total_amount
from 
(select c.customer_id, m.product_name, count(c.product_id)*m.price as Amount
from c join menu m on c.product_id = m.product_id
group by c.customer_id, m.product_name, m.price) t
group by t.customer_id
-- Answer: Customer A spent $ 25 on 2 items, Customer B spent $40 on 2 items.

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with k as (
select customer_id, m.product_name,
case
when m.product_name = 'sushi' then sum(m.price)*20
else sum(m.price)*10
end as Total
from sales s join menu m on s.product_id = m.product_id
group by customer_id, m.product_name)
select customer_id, sum(Total)
from k
group by customer_id
-- Answer: Total points for Customer A is 860, Total points for Customer B is 940, Total points for Customer C is 360.

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with time as (
select s.customer_id, s.order_date, m.product_name, t.join_date, t.end_date
from sales s join (select customer_id, join_date, dateadd(day, 6, join_date) as end_date from members) t on s.customer_id = t.customer_id
join menu m on s.product_id = m.product_id
where s.order_date <= '2021-01-31')
select h.customer_id, sum(money)
from (select time.customer_id, case
when order_date >= join_date and order_date < end_date then price*20
when time.product_name = 'sushi' and order_date < join_date and order_date >= end_date then price*20
else price*10
end as money
from time join menu on time.product_name = menu.product_name) h
group by h.customer_id
-- Answer: Total points for Customer A is 1,370., Total points for Customer B is 720.

-------------------------------------------------------------------------------------------
---------- Bonus Questions
-- Join all the Things
select s.customer_id, s.order_date, m.product_name, m.price,
case
when mm.join_date > s.order_date THEN 'N'
when mm.join_date <= s.order_date THEN 'Y'
else 'N' 
end as member
from sales s left join menu m on s.product_id = m.product_id
left join members mm on s.customer_id = mm.customer_id

-- Rank all the Things
with summary_cte as (
select s.customer_id, s.order_date, m.product_name, m.price,
case
when mm.join_date > s.order_date THEN 'N'
when mm.join_date <= s.order_date THEN 'Y'
else 'N' 
end as member
from sales s left join menu m on s.product_id = m.product_id
left join members mm on s.customer_id = mm.customer_id
)
select *, case
when member = 'N' then NULL
else RANK () over (partition by customer_id, member order by order_date) 
end as ranking
from summary_cte
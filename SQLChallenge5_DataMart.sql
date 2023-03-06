
---------- 1. Data Cleansing Steps

----- Convert the week_date to a DATE format

--- Change week_date into varchar(100)
alter table weekly_sales
alter column week_date varchar(100)

--- Change 'dd/mm/yy' in week_date into 'dd/mm/yyyy'
update weekly_sales
set week_date = replace(week_date, right(week_date,3), concat('/20',right(week_date,2)))

--- Change week_date data type to datetime
update weekly_sales
set week_date = convert(date, week_date, 103)

----- Add a week_number as the second column for each week_date value, 
----- for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
alter table weekly_sales
add week_num int

update weekly_sales
set week_num = datepart(week, week_date)

----- Add a month_number with the calendar month for each week_date value as the 3rd column
alter table weekly_sales
add month_num int

update weekly_sales
set month_num = datepart(month, week_date)

----- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
alter table weekly_sales
add calendar_year int

update weekly_sales
set calendar_year = datepart(year, week_date)

----- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
--segment	age_band
--1	        Young Adults
--2	        Middle Aged
--3 or 4	Retirees
alter table weekly_sales
add age_band varchar(100)

update weekly_sales
set age_band = case
when right(segment,1) = '1' then 'Young Adults'
when right(segment,1) = '2' then 'Middle Aged'
when right(segment,1) = '3' or right(segment,1) = '4' then 'Retirees'
else NULL
end

----- Add a new demographic column using the following mapping for the first letter in the segment values
--segment	demographic
--C	        Couples
--F	        Families
alter table weekly_sales
add demographic varchar(100)

update weekly_sales
set demographic = case
when left(segment,1) = 'C' then 'Counples'
when left(segment,1) = 'F' then 'Families'
else NULL
end

----- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
--- Change the data type segment to varchar(1000)
alter table weekly_sales
alter column segment varchar(100)

update weekly_sales
set segment = replace(segment, 'null', 'unknow')

update weekly_sales
set segment = isnull(age_band, 'unknown')

update weekly_sales
set segment = isnull(demographic, 'unknow')

----- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
alter table weekly_sales
add avg_transaction float

update weekly_sales
set avg_transaction = round(convert(float,sales)/convert(float,transactions), 2)

---------- 2. Data Exploration
----- What day of the week is used for each week_date value?
select distinct(datepart(w, week_date))
from weekly_sales
--- Answer: It's Monday

----- What range of week numbers are missing from the dataset?
--- Creat a table has number from 0 to 9
drop table if exists #num
create table #num
(num int)

insert into #num values
(0),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(8),
(9);

with c as (select a.num + (b.num*10) as n from #num a, #num b where (a.num + (b.num*10)) between 1 and 52)
select distinct(week_num), n
from weekly_sales w full outer join c on w.week_num = c.n
where week_num is null
order by n
-- Answer: 28 weeks is missing from the values.

----- How many total transactions were there for each year in the dataset?
select calendar_year, sum(transactions) as total_transactions
from weekly_sales
group by calendar_year
order by calendar_year
-- Answer:
2018	346406460
2019	365639285
2020	375813651

----- What is the total sales for each region for each month?
select region, month_num, sum(cast(sales as bigint)) as total_sales
from weekly_sales
group by region, month_num
order by region, month_num
-- Answer:
AFRICA	3	567767480
AFRICA	4	1911783504
AFRICA	5	1647244738
AFRICA	6	1767559760
AFRICA	7	1960219710
AFRICA	8	1809596890
AFRICA	9	276320987
ASIA	3	529770793
ASIA	4	1804628707
ASIA	5	1526285399
ASIA	6	1619482889
ASIA	7	1768844756
ASIA	8	1663320609
ASIA	9	252836807
CANADA	3	144634329
CANADA	4	484552594
CANADA	5	412378365
CANADA	6	443846698
CANADA	7	477134947
CANADA	8	447073019
CANADA	9	69067959
EUROPE	3	35337093
EUROPE	4	127334255
EUROPE	5	109338389
EUROPE	6	122813826
EUROPE	7	136757466
EUROPE	8	122102995
EUROPE	9	18877433
OCEANIA	3	783282888
OCEANIA	4	2599767620
OCEANIA	5	2215657304
OCEANIA	6	2371884744
OCEANIA	7	2563459400
OCEANIA	8	2432313652
OCEANIA	9	372465518
SOUTH AMERICA	3	71023109
SOUTH AMERICA	4	238451531
SOUTH AMERICA	5	201391809
SOUTH AMERICA	6	218247455
SOUTH AMERICA	7	235582776
SOUTH AMERICA	8	221166052
SOUTH AMERICA	9	34175583
USA	3	225353043
USA	4	759786323
USA	5	655967121
USA	6	703878990
USA	7	760331754
USA	8	712002790
USA	9	110532368

----- What is the total count of transactions for each platform?
select platform, count(transactions) as count_transactions
from weekly_sales
group by platform
order by platform
-- Answer:
Retail	8568
Shopify	8549

----- What is the percentage of sales for Retail vs Shopify for each month?
with s as (
select calendar_year, platform, month_num, sum(cast(sales as numeric(20,2))) as sum_sales
from weekly_sales
group by calendar_year, platform, month_num
--order by platform, month_num
)
select calendar_year, month_num,
cast(round(100*max(case when platform = 'Retail' then sum_sales else NULL end)/sum(sum_sales), 2) as numeric(20,2)) as retail_percent,
cast(round(100*max(case when platform = 'Shopify' then sum_sales else NULL end)/sum(sum_sales), 2) as numeric(20,2)) as shopify_percent
from s
group by calendar_year, month_num
-- Answer:
2018	3	97.92	2.08
2019	3	97.71	2.29
2020	3	97.30	2.70
2018	4	97.93	2.07
2019	4	97.80	2.20
2020	4	96.96	3.04
2018	5	97.73	2.27
2019	5	97.52	2.48
2020	5	96.71	3.29
2018	6	97.76	2.24
2019	6	97.42	2.58
2020	6	96.80	3.20
2018	7	97.75	2.25
2019	7	97.35	2.65
2020	7	96.67	3.33
2018	8	97.71	2.29
2019	8	97.21	2.79
2020	8	96.51	3.49
2018	9	97.68	2.32
2019	9	97.09	2.91

----- What is the percentage of sales by demographic for each year in the dataset?
with d as (
select demographic, calendar_year, sum(cast(sales as numeric(20,2))) as year_sales
from weekly_sales
where demographic is not null
group by demographic, calendar_year
)
select calendar_year, cast(round(100*max(case when demographic = 'Families' then year_sales else NULL end)/sum(year_sales),2) as numeric(20,2)) as f_percent,
cast(round(100*max(case when demographic = 'Counples' then year_sales else NULL end)/sum(year_sales),2) as numeric(20,2)) as c_percent
from d
group by calendar_year
-- Answer:
2018	54.80	45.20
2019	54.35	45.65
2020	53.26	46.74

----- Which age_band and demographic values contribute the most to Retail sales?
with a as (
select age_band, demographic, sum(cast(sales as bigint)) as sum_sales, row_number() over (order by sum(cast(sales as bigint)) desc) as r
from weekly_sales
where platform = 'Retail' and age_band is not null
group by age_band, demographic
)
select age_band, demographic, sum_sales
from a
where r = 1
-- Answer: 
Retirees	Families	6634686916

----- Can we use the avg_transaction column to find the average transaction size 
----- for each year for Retail vs Shopify? If not - how would you calculate it instead?

select platform, calendar_year, avg(cast(sales as numeric(20,2)))
from weekly_sales
group by platform, calendar_year
-- Answer:
Shopify	2018	100707.075650
Shopify	2019	122098.798387
Retail	2020	4777884.591036
Retail	2018	4415676.231792
Shopify	2020	159223.295271
Retail	2019	4691108.797969

---------- 3. Before & After Analysis
----- What is the total sales for the 4 weeks before and after 2020-06-15? 
----- What is the growth or reduction rate in actual values and percentage of sales?
select distinct(week_num) from weekly_sales where week_date = '2020-06-15'
-- Week_num = 25 ---> Need to find total sales from week 21 to week 28
with w as (
select week_num, sum(cast(sales as numeric(12,2))) as sum_week_num
from weekly_sales
where week_num between 21 and 28 and calendar_year = '2020'
group by week_num),
w_2 as (
select 
sum(case when week_num between 21 and 24 then sum_week_num end) as sum_before,
sum(case when week_num between 25 and 28 then sum_week_num end) as sum_after
from w)

select *, (sum_after - sum_before), round((100*(sum_after - sum_before)/sum_before), 2)
from w_2
-- Answer:
sum_before        sum_after        
2345878357.00	2318994169.00	-26884188.00	-1.150000

----- What about the entire 12 weeks before and after?
with w as (
select week_num, sum(cast(sales as numeric(12,2))) as sum_week_num
from weekly_sales
where week_num between 13 and 36 and calendar_year = '2020'
group by week_num),
w_2 as (
select 
sum(case when week_num between 13 and 24 then sum_week_num end) as sum_before,
sum(case when week_num between 25 and 36 then sum_week_num end) as sum_after
from w)

select *, (sum_after - sum_before), round((100*(sum_after - sum_before)/sum_before), 2)
from w_2
-- Answer:
  sum_before       sum_after
7126273147.00	6973947753.00	-152325394.00	-2.140000

----- How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
with w as (
select week_num, calendar_year, sum(cast(sales as numeric(12,2))) as sum_week_num
from weekly_sales
where week_num between 13 and 36
group by week_num, calendar_year),
w_2 as (
select calendar_year,
sum(case when week_num between 13 and 24 then sum_week_num end) as sum_before,
sum(case when week_num between 25 and 36 then sum_week_num end) as sum_after
from w
group by calendar_year)

select *, (sum_after - sum_before) as sales_variance, round((100*(sum_after - sum_before)/sum_before), 2) as sales_variance_percent
from w_2
-- Answer:
calendar_year  sum_before        sum_after      sales_variance   sales_variance_percent
2018	      6396562317.00	   6500818510.00	104256193.00	        1.630000
2019	      6883386397.00	   6862646103.00	-20740294.00	       -0.300000
2020	      7126273147.00	   6973947753.00	-152325394.00	       -2.140000

---------- 4. Bonus Question
----- Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
----- region
with w as (
select week_num, region, sum(cast(sales as numeric(12,2))) as sum_week_num
from weekly_sales
where week_num between 13 and 36 and calendar_year = '2020'
group by week_num, region),
w_2 as (
select region,
sum(case when week_num between 13 and 24 then sum_week_num end) as sum_before,
sum(case when week_num between 25 and 36 then sum_week_num end) as sum_after
from w
group by region)

select *, (sum_after - sum_before) as sales_variance, convert(decimal(14,2), round((100*(sum_after - sum_before)/sum_before), 2)) as sales_variance_percent
from w_2
order by round((100*(sum_after - sum_before)/sum_before), 2) 
-- Answer: 
ASIA	        1637244466.00	1583807621.00	-53436845.00	-3.26
OCEANIA	        2354116790.00	2282795690.00	-71321100.00	-3.03
SOUTH AMERICA	213036207.00	208452033.00	-4584174.00	    -2.15
CANADA	        426438454.00	418264441.00	-8174013.00	    -1.92
USA	            677013558.00	666198715.00	-10814843.00	-1.60
AFRICA	        1709537105.00	1700390294.00	-9146811.00	    -0.54
EUROPE	        108886567.00	114038959.00	5152392.00	     4.73
-- Asia have the most decrease in all region.

----- platform
with w as (
select week_num, platform, sum(cast(sales as numeric(12,2))) as sum_week_num
from weekly_sales
where week_num between 13 and 36 and calendar_year = '2020'
group by week_num, platform),
w_2 as (
select platform,
sum(case when week_num between 13 and 24 then sum_week_num end) as sum_before,
sum(case when week_num between 25 and 36 then sum_week_num end) as sum_after
from w
group by platform)

select *, (sum_after - sum_before) as sales_variance, convert(decimal(14,2), round((100*(sum_after - sum_before)/sum_before), 2)) as sales_variance_percent
from w_2
order by round((100*(sum_after - sum_before)/sum_before), 2) 
-- Answer:
Retail	6906861113.00	6738777279.00	-168083834.00	-2.43
Shopify	219412034.00	235170474.00	15758440.00	     7.18
-- Retail has decreased and shopify has increased.

----- age_band
with w as (
select week_num, age_band, sum(cast(sales as numeric(12,2))) as sum_week_num
from weekly_sales
where week_num between 13 and 36 and calendar_year = '2020'
group by week_num, age_band),
w_2 as (
select age_band,
sum(case when week_num between 13 and 24 then sum_week_num end) as sum_before,
sum(case when week_num between 25 and 36 then sum_week_num end) as sum_after
from w
group by age_band)

select *, (sum_after - sum_before) as sales_variance, convert(decimal(14,2), round((100*(sum_after - sum_before)/sum_before), 2)) as sales_variance_percent
from w_2
order by round((100*(sum_after - sum_before)/sum_before), 2)
-- Answer:
NULL	     2764354464.00	2671961443.00	-92393021.00	-3.34
Middle Aged	 1164847640.00	1141853348.00	-22994292.00	-1.97
Retirees	 2395264515.00	2365714994.00	-29549521.00	-1.23
Young Adults 801806528.00	794417968.00	-7388560.00	    -0.92
-- All age band are decreased, unknown is the smallest.

----- demographic
with w as (
select week_num, demographic, sum(cast(sales as numeric(12,2))) as sum_week_num
from weekly_sales
where week_num between 13 and 36 and calendar_year = '2020'
group by week_num, demographic),
w_2 as (
select demographic,
sum(case when week_num between 13 and 24 then sum_week_num end) as sum_before,
sum(case when week_num between 25 and 36 then sum_week_num end) as sum_after
from w
group by demographic)

select *, (sum_after - sum_before) as sales_variance, convert(decimal(14,2), round((100*(sum_after - sum_before)/sum_before), 2)) as sales_variance_percent
from w_2
order by round((100*(sum_after - sum_before)/sum_before), 2)
-- Answer:
NULL	    2764354464.00	2671961443.00	-92393021.00	-3.34
Families	2328329040.00	2286009025.00	-42320015.00	-1.82
Counples	2033589643.00	2015977285.00	-17612358.00	-0.87
-- All age band are decreased, unknown is the smallest.

----- customer_type
with w as (
select week_num, customer_type, sum(cast(sales as numeric(12,2))) as sum_week_num
from weekly_sales
where week_num between 13 and 36 and calendar_year = '2020'
group by week_num, customer_type),
w_2 as (
select customer_type,
sum(case when week_num between 13 and 24 then sum_week_num end) as sum_before,
sum(case when week_num between 25 and 36 then sum_week_num end) as sum_after
from w
group by customer_type)

select *, (sum_after - sum_before) as sales_variance, convert(decimal(14,2), round((100*(sum_after - sum_before)/sum_before), 2)) as sales_variance_percent
from w_2
order by round((100*(sum_after - sum_before)/sum_before), 2)
-- Answer:
Guest	    2573436301.00	2496233635.00	-77202666.00	-3.00
Existing	3690116427.00	3606243454.00	-83872973.00	-2.27
New	        862720419.00	871470664.00	8750245.00	     1.01
-- Guest impact and Existing impact decreasing are 3% and 2.27%, while New impact increasing is 1.01%.
select*from task2;
select city from task2;
-- 1. Write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends.
with citywise_highest_spend as(
select city, sum(amount) as citywise_total_spend
from task2
group by City
order by citywise_total_spend desc
limit 5
),
total_spend as(
select sum(amount) as total_amount
from task2
)
select a.City, a.citywise_total_spend,
round(100*(a.citywise_total_spend / b.total_amount),2) as percentage_contribution
from citywise_highest_spend as a
inner join total_spend as b on 1=1;
-- 2. Write a query to print highest spend month and amount spent in that month for each card type.
with datewise_amount as (
select card_type,
	datename(month,[date]) as month_name,
	DATEPART(year,[date]) as year_name,
	sum(amount) as total_spend
from task2
group by DATEPART(year,[date]),
	datename(month,[date]),
	card_type
),
ranking as (
select * ,dense_rank() over (partition by [card_type] order by total_spend) as drank
from datewise_amount
)
select card_type, month_name, year_name, total_spend 
from ranking 
where drank = 1;
-- 3. Write a query to print the transaction details (all columns from the table) for each card type when it reaches a cumulative of 1000000 total spends (We should have 4 rows in the o/p one for each card type).
with cum1 as (
select * , sum(amount) over (partition by (card_type) order by (date),amount) as cumulative_sum
	from task2
),
cum2 as (
select *, dense_rank() over(partition by (card_type) order by cumulative_sum) as drank
	from cum1
	where cumulative_sum >=1000000
)
select * from cum2 
where drank=1;
-- 4. Write a query to find city which had lowest percentage spend for gold card type.
with cit1 as(
select city, sum(amount) as gold_sum
from task2
where card_type='Gold'
group by city
),
cit2 as(
select city, sum(amount) as amt_citywise
from task2
group by city
),
cit3 as (
select cit1.city,
	cit1.gold_sum,
	cit2.amt_citywise,
	round(100*(cit1.gold_sum / cit2.amt_citywise),2) as percentage_contribution
	from cit1
	inner join cit2
	on cit1.city=cit2.city
)
select * from cit3
order by percentage_contribution
limit 1;
-- 5. Write a query to print 3 columns: city, highest_expense_type , lowest_expense_type (example format :Delhi , bills, Fuel).
with cit1 as (
select city, exp_type, sum(amount) as total_spend
from task2
group by city, exp_type
),
cit2 as (
select city,
max(total_spend) as highest_spend,
min(total_spend) as lowest_spend
from cit1
group by city
)
select cit1.city,
max(case when total_spend = highest_spend then exp_type end) as highest_expense_type,
min(case when total_spend = lowest_spend then exp_type end) as lowest_expense_type
from cit1 
inner join cit2
on cit1.city=cit2.city
group by cit1.city
order by cit1.city
-- 6. Write a query to find percentage contribution of spends by females for each expense type.
with cit1 as (
select exp_type, sum(amount) as total_female_spend
from task2
where gender = 'F'
group by exp_type
),
cit2 as (
select exp_type, sum(amount) as total_spend
from task2
group by exp_type
)
select cit1.exp_type,
cit1.total_female_spend,
cit2.total_spend,
round(100*(cit1.total_female_spend/cit2.total_spend),2) as percentage_spend
from cit1
inner join cit2
on cit1.exp_type=cit2.exp_type
order by percentage_spend;
-- 7. Which card and expense type combination saw highest month over month growth in Jan-2014.
with cit1 as (
select card_type, exp_type, datepart(year,[date]) as year_transaction, datepart(month,[date]) as month_transaction,
sum(amount) as total_amount
from task2
group by card_type, exp_type, datepart(year,[date]), datepart(monthm,[date])
),
cit2 as (
select * , lag(total_amount,1)  over(partition by [card type],[exp_type] order by year_transaction, month_transaction) as prev_month_trans_amount
from cit1
),
cit3 as (
select * 100*(total_amount-prev_month_trans_amount)/prev_month_trans_amount as per_growth
cit2
	where year_transaction=2024 and month_transaction=1
)
select*from cit3
order by per_growth desc
limit 1;
-- 8. During weekends which city has highest total spend to total no of transaction’s ratio?
select city, sum(amount) as total_amount, count(1) as total_no_transaction, sum(amount)/count(1) as ratio
from task2
where datepart(weekday,[date]) in ('7','1')
group by city
order by ratio desc
limit 1;
-- 9. Which city took least number of days to reach its 500th transaction after first transaction in that city?
with cit1 as(
select city, count(1) as total_no_of_transactions,
	min(date) as first_date,
	max(date) as last_date
	from task2
	group by city
),
cit2 as (
select * from cit1
	where total_no_of_transaction>=500
),
cit3 as(
select city, date, row_number() over (partition by city order by date) as row_numb from task2
	where city in (select city from cit2)
),
cit4 as (
select cit2.city, cit2.first_day, cit2.lastdate, cit2.total_no_of_transactions, cit3.date as trans_date_500th
	from cit2
	inner join cit3
	on cit2.city=cit3.city
	where city3.row_numb=500
)
select city , first_date, last_date, trans_date_500th, 
datediff(day, first_date, trans_date_500th) as no_of_days_till_500
from cit4
order by no_of_days_till_500
limit 1;
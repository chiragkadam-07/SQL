-- Retrive the total number of orders placed
select count(distinct order_id) from pizza_order_details;


-- Calculate the Revenue generated from pizza sales
select cast(sum(o.quantity * p.price) as decimal(10,2)) as Revenue
from pizza_order_details as o inner join pizzas as p 
on o.pizza_id=p.pizza_id;


-- Identify the highest-priced pizza.
select o.pizza_id as pizza_name, p.price from pizza_order_details as o inner join pizzas as p 
on o.pizza_id=p.pizza_id
order by price desc limit 1;

-- Alternative (using window function)
with cte as (
select pizza_types.name as 'Pizza Name', cast(pizzas.price as decimal(10,2)) as 'Price',
rank() over (order by price desc) as rnk
from pizzas
join pizza_types on pizza_types.pizza_type_id = pizzas.pizza_type_id
)
select 'Pizza Name', Price from cte where rnk =1;


-- Identify the most common pizza size ordered.
SELECT 
    pizzas.size,
    COUNT(DISTINCT order_id) AS 'No of Orders',
    SUM(quantity) AS 'Total Quantity Ordered'
FROM
    pizza_order_details
        JOIN
    pizzas ON pizzas.pizza_id = pizza_order_details.pizza_id
GROUP BY pizzas.size
ORDER BY COUNT(DISTINCT order_id) DESC;


-- List the top 5 most ordered pizza types along with their quantities.
select t.name as 'Pizza', sum(o.quantity) as 'Total Quantity' from pizza_order_details as o inner join pizzas on o.pizza_id=pizzas.pizza_id
inner join pizza_types as t on pizzas.pizza_type_id=t.pizza_type_id group by quantity, name order by sum(quantity) desc limit 5;


-- Find the total quantity of each pizza category ordered (this will help us to understand the category which customers prefer the most).
select t.category, sum(o.quantity) as 'Total Quantity' from pizza_order_details as o join pizzas as p on o.pizza_id=p.pizza_id
join pizza_types as t on p.pizza_type_id=t.pizza_type_id group by t.category order by sum(o.quantity) desc;


-- Determine the distribution of orders by hour of the day (at which time the orders are maximum (for inventory management and resource allocation).
select hour(time) as 'Hour of the day', count(distinct order_id) as 'No of Orders'
from orders
group by hour(time) 
order by count(distinct order_id) desc;


-- Find the category-wise distribution of pizzas (to understand customer behaviour).
select category, count(distinct pizza_type_id) as 'No of pizzas'
from pizza_types
group by category
order by count(distinct pizza_type_id);


-- Group the orders by date and calculate the average number of pizzas ordered per day.
with cte as(
select o.date, sum(p.quantity) as 'Total' from pizza_order_details as p join orders as o on
p.order_id=o.order_id group by o.date) 
select round(avg(`Total`)) as 'Daily AVG Quantity' from cte;

-- alternate using subquery
select avg(`Total Pizza Ordered`) as 'Avg Number of pizzas ordered per day' from 
(
	select o.date, sum(p.quantity) as 'Total Pizza Ordered'
	from pizza_order_details as p
	join orders as o on p.order_id = o.order_id
	group by o.date
) as pizzas_ordered;


-- Determine the top 5 most ordered pizzas based on revenue
select distinct t.name, count(o.quantity) as 'Quantity', sum(o.quantity * p.price) as 'Revenue' from pizza_order_details as o join pizzas as p on 
o.pizza_id=p.pizza_id join pizza_types as t on p.pizza_type_id=t.pizza_type_id group by t.name order by 3 desc limit 5;

-- The most ordered pizza types based on revenue
select distinct o.pizza_id, count(o.quantity) as 'Quantity', round(sum(o.quantity * p.price)) as 'Revenue' from pizza_order_details as o join pizzas as p on 
o.pizza_id=p.pizza_id group by o.pizza_id order by 3 desc;

-- Determine the top 3 most ordered pizza sizes based on revenue
select distinct p.size, count(o.quantity) as 'Quantity', round(sum(o.quantity * p.price)) as 'Revenue' from pizza_order_details as o join pizzas as p on 
o.pizza_id=p.pizza_id group by p.size order by 3 desc;


-- Calculate the percentage contribution of each pizza by pizza name to total revenue (to understand % of contribution of each pizza in the total revenue)
select distinct t.name, count(o.quantity) as 'Quantity', concat(round((sum(o.quantity * p.price)/817860.05*100),1),'%') as 'contribution to Revenue' 
from pizza_order_details as o 
join pizzas as p on o.pizza_id=p.pizza_id 
join pizza_types as t on p.pizza_type_id=t.pizza_type_id 
group by t.name order by 3 desc;


-- Analyze the cumulative revenue generated over day.
with cte as (
select date as 'Date', cast(sum(quantity*price) as decimal(10,2)) as Revenue
from pizza_order_details 
join orders on pizza_order_details.order_id = orders.order_id
join pizzas on pizzas.pizza_id = pizza_order_details.pizza_id
group by date
)
select Date, Revenue, sum(Revenue) over (order by date) as 'Cumulative Sum'
from cte 
group by date, Revenue;

-- Determine the top 3 most ordered pizzas based on revenue for each pizza category.
with cte as (
select t.name, t.category, round(sum(o.quantity * p.price),2) as 'Revenue'
from pizza_order_details as o join pizzas as p on o.pizza_id=p.pizza_id
join pizza_types as t on p.pizza_type_id=t.pizza_type_id 
group by t.name, t.category)
,cte1 as(
select category, name, `Revenue`, rank() over(partition by category order by `Revenue` desc) as rnk from cte)
select category, name, `Revenue` from cte1
where rnk in (1,2,3)
order by category, `Revenue` desc ;


-- Monthly Sales
select monthname(date2) as 'Month', sum(p.quantity) as 'Quantity', round(sum(p.quantity*price),2) as 'Sales' from pizza_orders as o 
join pizza_order_details as p on o.order_id=p.order_id
join pizzas on p.pizza_id=pizzas.pizza_id group by 1;


-- Month on Month % Change
with cte as(
select monthname(date2) as 'Month', sum(p.quantity) as 'Quantity', round(sum(p.quantity*price),2) as 'Sales', 
lead(round(sum(p.quantity*price),2), 1) over() as 'nxSales' 
from pizza_orders as o join pizza_order_details as p on o.order_id=p.order_id
join pizzas on p.pizza_id=pizzas.pizza_id group by 1)
select lead(Month,1) over() as 'month', lead(Quantity) over() as 'Quantity', nxSales as Sales, ((nxSales-Sales)/Sales*100) as 'Monthly Change %'
from cte
group by month;


-- Weekly Sales
select weekofyear(date2) as 'Week', sum(quantity) as 'Quantity', round(sum(quantity*price),2) as 'Sales' from pizza_orders as o 
join pizza_order_details as p on p.order_id=o.order_id
join pizzas on p.pizza_id=pizzas.pizza_id group by 1 order by 1;


-- Week on Week Change 
with cte as(
select weekofyear(date2) as 'Weeks', sum(quantity) as 'Quantity', round(sum(quantity*price),2) as 'Sales', 
lead(round(sum(quantity*price),2)) over(order by weekofyear(date2)) as 'nxweek'
from pizza_orders as o join pizza_order_details as p on p.order_id=o.order_id
join pizzas on p.pizza_id=pizzas.pizza_id group by 1)
select lead(Weeks) over() as 'Weeks', lead(Quantity) over() as 'Quantity', lead(Sales) over() as 'Sales', ((nxweek-Sales)/Sales*100) as 'Weekly Change %' 
from cte
group by Weeks;


-- top 3 negative weeks
with cte as(
select weekofyear(date2) as 'Weeks', sum(quantity) as 'Quantity', round(sum(quantity*price),2) as 'Sales', 
lead(round(sum(quantity*price),2)) over(order by weekofyear(date2)) as 'nxweek'
from pizza_orders as o join pizza_order_details as p on p.order_id=o.order_id
join pizzas on p.pizza_id=pizzas.pizza_id group by 1),
cte1 as(
select lead(Weeks) over() as 'Weeks', lead(Quantity) over() as 'Quantity', lead(Sales) over() as 'Sales', ((nxweek-Sales)/Sales*100) as 'Weekly Change %', 
rank() over(order by ((nxweek-Sales)/Sales*100) desc) as rnk from cte)
(select Weeks, Quantity, Sales, `Weekly Change %` 
from cte1 where rnk in (49,50,51) or rnk in (1,2,3) order by 4 desc);
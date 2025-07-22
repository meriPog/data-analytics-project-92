-- Данный запрос выводит общее количество покупателей из таблицы покупателей
select
 Count (customer_id) as customers_count
from customers
;


-- Десять лучших продавцов, у которых наибольшая выручка
select
  concat(e.first_name, ' ', e.last_name) as seller,  -- объединяет две колонки с именем и фамилией в одну
  count (s.sales_id) as operations,                  -- считает количество проведенных сделок
  floor(sum (s.quantity*p.price))  as income      -- суммарная выручка (количество на цену)
from sales as s
inner join employees as e                            -- соединяет  с таблицей сотрудников
  on s.sales_person_id = e.employee_id
inner join products as p                             -- соединяет с таблицей товаров
  on s.product_id = p.product_id 
group by seller                                      -- группирует по каждому продавцу, чтоб сложилось количество проведенных сделок и сумма выручки  
order by income desc                                 -- сортирует по полю суммарной выручки от большего к меньшему
limit 10                                             -- выводит первые 10 строк таблицы
;


-- Информация о продавцах, чья средняя выручка за сделку меньше средней выручки за сделку по всем продавцам
select 
  concat(e.first_name, ' ', e.last_name) as seller,       -- объединяет две колонки с именем и фамилией в одну
  floor(avg (s.quantity*p.price)) as average_income   -- средняя выручка продавца за сделку с округлением до целого
from sales as s
inner join employees as e                                 -- соединяет с таблицей сотрудников
  on s.sales_person_id = e.employee_id 
inner join products as p                                  -- соединяет с таблицей товаров
  on s.product_id = p.product_id
group by seller                                           -- группирует по каждому продавцу для подсчета средней
having floor(avg (s.quantity*p.price)) < (          -- выводит только те, которые меньше чем (средняя выручка по всем продавцам)
  select 
    round (avg (s.quantity*p.price), 0) as average_income -- соответственно в этом подзапросе средняя выручка по всем продавцам
  from sales as s
  inner join products as p
    on s.product_id = p.product_id)
order by average_income                                   -- сортирует среднюю выручку по возрастанию 
;


-- Данные по выручке по каждому продавцу и дню недели
with a as (                                                -- создает временную таблицу
  select
    concat(e.first_name, ' ', e.last_name) as seller,      -- объединяет две колонки с именем и фамилией в одну
    to_char(s.sale_date, 'day') as day_of_week,            -- выводит день недели
    floor(sum(s.quantity*p.price)) as income,          -- суммарная выручка (количество на цену) 
    extract(isodow from s.sale_date) as day_num            -- номер дня недели пн-1, вт-2 и т.д.
  from sales s
  inner join employees e                                   -- соединяет с таблицей сотрудников 
    on s.sales_person_id = e.employee_id 
  left join products p                                     -- соединяет с таблицей товаров
    on s.product_id = p.product_id
  group by concat(e.first_name, ' ', e.last_name), to_char(s.sale_date, 'day'), extract(isodow from s.sale_date)   -- группирует по каждому продавцу и по дню недели
  )
select                                                     -- выводит все необходимые колонки из временной таблицы 
  seller,                         
  day_of_week,
  income
from a 
order by day_num,  seller                                  -- сортировка по порядковому номеру дня недели, по имени_фамилии
;


-- Количество покупателей по возростным группам
with a as(
  select *,             
    case                                        -- начало создания строк
	  when age between 16 and 25 then '16-25'   -- условие для каждой строки и название 
	  when age between 26 and 40 then '26-40'   
	  when age > 40 then '40+'                  
    end as age_category                         -- конец создания строк
  from customers
  )
select   
  age_category,                                 
  count(customer_id) as age_count               -- считает количество покупателей
from a 
group by age_category                           -- при группировке считает количество покупателей для каждой категории   
order by age_category
;


-- Данные по количеству уникальных покупателей и выручке
with a as (
  select 
    to_char(s.sale_date, 'YYYY-MM') as date,       -- выводит дату в виде  ГОД-МЕСЯЦ
    round(sum(s.quantity*p.price), 2) as income,   -- считает сумму продаж
    s.customer_id as customer_id
  from sales as s
  inner join products as p
    on s.product_id = p.product_id
  group by date, s.customer_id                     -- группирует продажи по дате и покупателю
  )
select 
  date as selling_month,
  count(customer_id) as total_customers,           -- считает количество покупателей   
  floor(sum(income)) as income
from a  
group by date                                      
order by date  
;


-- Первая покупка покупателя пришлась на время проведения специальных акций (акционные товары отпускали со стоимостью равной 0)
with a as (
  select                                                        -- первая таблица содержит id покупателя и дату первой покупки акционного товара
    s.customer_id as customer_id,
    min(s.sale_date) as sale_date 
  from sales s 
  inner join products p
    on s.product_id = p.product_id
  where p.price = 0
  group by s.customer_id
  ), b as (
  select                                                        -- вторая таблица выводит id покупателя, имя и фамилию покупателя и продавца
    c.customer_id as customer_id,
    concat(c.first_name, ' ', c.last_name) as customer,
    concat(e.first_name, ' ', e.last_name) as seller,
   min(s.sale_date) as sale_date 
  from sales s
  inner join employees e
    on s.sales_person_id =  e.employee_id
  inner join customers c
    on s.customer_id = c.customer_id
  inner join products p
    on s.product_id = p.product_id 
  group by  c.customer_id, concat(c.first_name, ' ', c.last_name), concat(e.first_name, ' ', e.last_name)
  )
select                                                         -- объединяет две таблицы и выводит необходимые поля 
  b.customer as customer,
  a.sale_date as sale_date,
  b.seller as seller
from a
inner join b
  on a.customer_id = b.customer_id
and a.sale_date = b.sale_date
order by a.customer_id
;
-- Данный запрос выводит общее количество покупателей из таблицы покупателей
select
 Count (customer_id) as customers_count
from customers
;


-- Десять лучших продавцов, у которых наибольшая выручка
select
  concat(e.first_name, ' ', e.last_name) as seller,  -- объединяет две колонки с именем и фамилией в одну
  count (s.sales_id) as operations,                  -- считает количество проведенных сделок
  round (sum (s.quantity*p.price), 0) as income      -- суммарная выручка (количество на цену)
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
  round (avg (s.quantity*p.price), 0) as average_income   -- средняя выручка продавца за сделку с округлением до целого
from sales as s
inner join employees as e                                 -- соединяет с таблицей сотрудников
  on s.sales_person_id = e.employee_id 
inner join products as p                                  -- соединяет с таблицей товаров
  on s.product_id = p.product_id
group by seller                                           -- группирует по каждому продавцу для подсчета средней
having (round (avg (s.quantity*p.price), 0)) < (          -- выводит только те, которые меньше чем (средняя выручка по всем продавцам)
  select 
    round (avg (s.quantity*p.price), 0) as average_income -- соответственно в этом подзапросе средняя выручка по всем продавцам
  from sales as s
  inner join products as p
    on s.product_id = p.product_id)
order by average_income                                   -- сортирует среднюю выручку по возрастанию 
;

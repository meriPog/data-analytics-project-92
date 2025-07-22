-- Данный запрос выводит общее количество покупателей из таблицы покупателей
select Count(customer_id) as customers_count
from customers;


-- Десять лучших продавцов, у которых наибольшая выручка
select
    -- объединяет две колонки с именем и фамилией в одну
    Concat(e.first_name, ' ', e.last_name) as seller,
    -- считает количество проведенных сделок
    Count(s.sales_id) as operations,
    -- суммарная выручка (количество на цену)
    Floor(Sum(s.quantity * p.price)) as income
from sales as s
-- соединяет  с таблицей сотрудников
inner join employees as e
    on s.sales_person_id = e.employee_id
-- соединяет с таблицей товаров
inner join products as p
    on s.product_id = p.product_id
group by seller
-- сортирует по полю суммарной выручки от большего к меньшему
order by income desc
-- выводит первые 10 строк таблицы
limit 10;


-- Информация о продавцах выручка меньше средней по всем продавцам
select
    -- объединяет две колонки с именем и фамилией в одну
    Concat(e.first_name, ' ', e.last_name) as seller,
    -- средняя выручка продавца за сделку с округлением до целого
    Floor(Avg(s.quantity * p.price)) as average_income
from sales as s
-- соединяет с таблицей сотрудников
inner join employees as e
    on s.sales_person_id = e.employee_id
-- соединяет с таблицей товаров
inner join products as p
    on s.product_id = p.product_id
-- группирует по каждому продавцу для подсчета средней
group by seller
having
    -- выводит только те, которые меньше чем (средняя выручка по всем продавцам)
    Floor(Avg(s.quantity * p.price)) < (
        select Round(Avg(ss.quantity * pp.price), 0) as average_income
        -- соответственно в этом подзапросе средняя выручка по всем продавцам
        from sales as ss
        inner join products as pp
            on ss.product_id = pp.product_id
    )
-- сортирует среднюю выручку по возрастанию 
order by average_income;


-- Данные по выручке по каждому продавцу и дню недели
-- создает временную таблицу
with a as (
    select
        -- объединяет две колонки с именем и фамилией в одну
        Concat(e.first_name, ' ', e.last_name) as seller,
        -- выводит день недели
        To_char(s.sale_date, 'day') as day_of_week,
        -- суммарная выручка (количество на цену) 
        Floor(Sum(s.quantity * p.price)) as income,
        -- номер дня недели пн-1, вт-2 и т.д.
        Extract(isodow from s.sale_date) as day_num
    from sales as s
    -- соединяет с таблицей сотрудников 
    inner join employees as e
        on s.sales_person_id = e.employee_id
    -- соединяет с таблицей товаров
    left join products as p
        on s.product_id = p.product_id
    -- группирует по каждому продавцу и по дню недели
    group by
        Concat(e.first_name, ' ', e.last_name),
        To_char(s.sale_date, 'day'),
        Extract(isodow from s.sale_date)
)

-- выводит все необходимые колонки из временной таблицы 
select
    seller,
    day_of_week,
    income
from a
-- сортировка по порядковому номеру дня недели, по имени_фамилии
order by day_num, seller;


-- Количество покупателей по возростным группам
with a as (
    select
        *,
        case                                        -- начало создания строк
            -- условие для каждой строки и название 
            when age between 16 and 25 then '16-25'
            when age between 26 and 40 then '26-40'
            when age > 40 then '40+'
        end as age_category                         -- конец создания строк
    from customers
)

select
    age_category,
    -- считает количество покупателей
    Count(customer_id) as age_count
from a
-- при группировке считает количество покупателей для каждой категории   
group by age_category
order by age_category;


-- Данные по количеству уникальных покупателей и выручке
with a as (
    select
        -- выводит дату в виде  ГОД-МЕСЯЦ
        s.customer_id,
        To_char(s.sale_date, 'YYYY-MM') as selling,
        Round(Sum(s.quantity * p.price), 2) as income
    from sales as s
    inner join products as p
        on s.product_id = p.product_id
    -- группирует продажи по дате и покупателю
    group by selling, s.customer_id
)

select
    selling as selling_month,
    -- считает количество покупателей   
    Count(customer_id) as total_customers,
    Floor(Sum(income)) as income
from a
group by selling
order by selling;


-- Первая покупка покупателя пришлась на время проведения специальных акций
with a as (
    select
        s.customer_id,
        Min(s.sale_date) as sale_date
    from sales as s
    inner join products as p
        on s.product_id = p.product_id
    where p.price = 0
    group by s.customer_id
),

b as (
    -- вторая таблица выводит id покупателя, имя и фамилию покупателя и продавца
    select
        c.customer_id,
        Concat(c.first_name, ' ', c.last_name) as customer,
        Concat(e.first_name, ' ', e.last_name) as seller,
        Min(s.sale_date) as sale_date
    from sales as s
    inner join employees as e
        on s.sales_person_id = e.employee_id
    inner join customers as c
        on s.customer_id = c.customer_id
    inner join products as p
        on s.product_id = p.product_id
    group by
        c.customer_id,
        Concat(c.first_name, ' ', c.last_name),
        Concat(e.first_name, ' ', e.last_name)
)

-- объединяет две таблицы и выводит необходимые поля 
select
    b.customer,
    a.sale_date,
    b.seller
from a
inner join b
    on
        a.customer_id = b.customer_id
        and a.sale_date = b.sale_date
order by a.customer_id;

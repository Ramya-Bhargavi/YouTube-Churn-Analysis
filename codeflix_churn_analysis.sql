-- converting string type into date type with null values

desc codeflix;

SELECT 
    *
FROM
    codeflix
where
    subscription_end='';
    
-- Add a new column for the DATE type
ALTER TABLE codeflix
ADD COLUMN subscription_date_converted DATE;

-- Convert the string dates to DATE format
UPDATE codeflix
SET subscription_date_converted = CASE
    WHEN subscription_end REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN DATE(STR_TO_DATE(subscription_end, '%Y-%m-%d'))
    WHEN subscription_end REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN DATE(STR_TO_DATE(subscription_end, '%d/%m/%Y'))
    WHEN subscription_end REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN DATE(STR_TO_DATE(subscription_end, '%m-%d-%Y'))
    WHEN subscription_end REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN DATE(STR_TO_DATE(subscription_end, '%m/%d/%Y'))
    ELSE NULL
END;


-- Verify the update
SELECT * FROM codeflix;

-- Optional: Drop the old column and rename the new one
ALTER TABLE codeflix
DROP COLUMN subscription_end;

ALTER TABLE codeflix
RENAME COLUMN subscription_date_converted TO subscription_end;

SELECT 
    *
FROM
    codeflix
where
    subscription_end='';
    
    
SELECT 
    *
FROM
    codeflix
where subscription_end is null;

-- Range of the months we are going to calcuate the CHURN rate

SELECT 
    MIN(subscription_start), MAX(subscription_start)
FROM
    codeflix;

-- considering the churn for first three month of 2017
-- create a temporary table as months which contains 3 months 'jan', 'feb' and 'march' 

WITH months As
(select 
'2017-01-01' as 'first-day',
'2017-01-31' as 'last-day'
union
select 
'2017-02-01' as 'first-day',
'2017-02-21' as 'last-day'
union
select 
'2017-03-01' as 'first-day',
'2017-03-31' as 'last-day')
select * from months;

-- create another temporary name as cross_join which is the cross join of the table 'codeflix' and temporary table 'months'
WITH months As
( select 
'2017-01-01' as 'first-day',
'2017-01-31' as 'last-day'
union
select 
'2017-02-01' as 'first-day',
'2017-02-21' as 'last-day'
union
select 
'2017-03-01' as 'first-day',
'2017-03-31' as 'last-day'
),
cross_join AS
(SELECT 
    *
FROM
    codeflix
	CROSS JOIN
months) 
    
select * from cross_join;


-- created 3rd temporary table name 'status' which have 4 columns 'id','month','is_active87','is_active30'
WITH months As
( select 
'2017-01-01' as 'first_day',
'2017-01-31' as 'last-day'
union
select 
'2017-02-01' as 'first_day',
'2017-02-21' as 'last-day'
union
select 
'2017-03-01' as 'first_day',
'2017-03-31' as 'last-day'
),

cross_join AS -- 2nd
(SELECT * FROM codeflix
CROSS JOIN months),

status as  -- 3rd
(select id, first_day AS month,
Case when
(subscription_start < first_day) and
(subscription_end > first_day or subscription_end is NULL) 
and (segment = 87) 
then 1
else 0
end as is_active_87,
case when 
(subscription_start < first_day) and
(subscription_end > first_day or subscription_end is NULL) 
and (segment = 30) 
then 1
else 0
end as is_active_30
from cross_join)


select * from status ;

-- if the subscription date will be less than the curent mnth starting date we dont consider that as subscriber for that month
-- added more columns in status table with case statement 'is_canceld87' and 'is_canceled30'
-- now status table shows 1 if cx is active 0 if not

WITH months As
( select 
'2017-01-01' as 'first_day',
'2017-01-31' as 'last_day'
union
select 
'2017-02-01' as 'first_day',
'2017-02-21' as 'last_day'
union
select 
'2017-03-01' as 'first_day',
'2017-03-31' as 'last_day'
),
cross_join AS -- 2
(SELECT * FROM codeflix
CROSS JOIN months),
status as -- 3
(select id, first_day AS month,
Case when
(subscription_start < first_day) and
(subscription_end > first_day or subscription_end is NULL) 
and (segment = 87) 
then 1
else 0
end as is_active_87,
case when 
(subscription_start < first_day) and
(subscription_end > first_day or subscription_end is NULL) 
and (segment = 30) 
then 1
else 0
end as is_active_30,
case when 
(subscription_end Between First_day and last_day) and (segment = 87)
then 1
else 0
end as is_canceled_87,
case when 
(subscription_end Between First_day and last_day) and (segment = 87)
then 1
else 0
end as is_canceled_30
from cross_join) 

select * from status
order by id ,month
limit 10;


-- created 4th temprorary table name as status_aggreagte which shows the sum of all the active and canceled ids

WITH months As
( select 
'2017-01-01' as 'first_day',
'2017-01-31' as 'last_day'
union
select 
'2017-02-01' as 'first_day',
'2017-02-21' as 'last_day'
union
select 
'2017-03-01' as 'first_day',
'2017-03-31' as 'last_day'
),
cross_join AS -- 2 
(SELECT * FROM codeflix
CROSS JOIN months),
status as -- 3 
(select id, first_day AS month,
Case when
(subscription_start < first_day) and
(subscription_end > first_day or subscription_end is NULL) 
and (segment = 87) 
then 1
else 0
end as is_active_87,
case when 
(subscription_start < first_day) and
(subscription_end > first_day or subscription_end is NULL) 
and (segment = 30) 
then 1
else 0
end as is_active_30,
case when 
(subscription_end Between First_day and last_day) and (segment = 87)
then 1
else 0
end as is_canceled_87,
case when 
(subscription_end Between First_day and last_day) and (segment = 87)
then 1
else 0
end as is_canceled_30
from cross_join),
status_aggregate as -- 4
(select month, 
sum(is_active_87) as sum_active_87,
sum(is_active_30) as sum_active_30,
sum(is_canceled_87) as sum_canceled_87,
sum(is_canceled_30) as sum_canceled_30 from status
group by month) 

select * from status_aggregate;


-- calcualted the churn by deviding all canceled ids by all active in that perticular month

WITH months As
( select 
'2017-01-01' as 'first_day',
'2017-01-31' as 'last_day'
union
select 
'2017-02-01' as 'first_day',
'2017-02-21' as 'last_day'
union
select 
'2017-03-01' as 'first_day',
'2017-03-31' as 'last_day'
),
cross_join AS
(SELECT * FROM codeflix
CROSS JOIN months),
status as 
(select id, first_day AS month,
Case when
(subscription_start < first_day) and
(subscription_end > first_day or subscription_end is NULL) 
and (segment = 87) 
then 1
else 0
end as is_active_87,
case when 
(subscription_start < first_day) and
(subscription_end > first_day or subscription_end is NULL) 
and (segment = 30) 
then 1
else 0
end as is_active_30,
case when 
(subscription_end Between First_day and last_day) and (segment = 87)
then 1
else 0
end as is_canceled_87,
case when 
(subscription_end Between First_day and last_day) and (segment = 87)
then 1
else 0
end as is_canceled_30
from cross_join),
status_aggregate as 
(select month, 
sum(is_active_87) as sum_active_87,
sum(is_active_30) as sum_active_30,
sum(is_canceled_87) as sum_canceled_87,
sum(is_canceled_30) as sum_canceled_30 from status
group by month)

 select month,
1.0 * sum_canceled_87/sum_active_87 as chrun_rate_87,
1.0 * sum_canceled_30/sum_active_30 as chrun_rate_30
from status_aggregate
order by 1;

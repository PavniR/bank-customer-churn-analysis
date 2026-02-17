-----------------------------------
--DATA VALIDATION
-----------------------------------

--validating and cleaning
SELECT *
FROM bank_customers
WHERE rownumber is null or
customerid is null or 
surname is null or 
creditscore is null or 
geography is null or
gender is null or 
age is null or 
tenure is null or 
balance is null or
numofproducts is null or 
hascrcard is null or 
isactivemember is null or
exited is null or 
complain is null or satisfactionscore is null or
cardtype is null or pointearned is null;

--checking if customerIds are distinct
SELECT count(rownumber) as totalrows, 
count(distinct customerid) as customers
FROM bank_customers;

--validating binary columns 
select distinct hascrcard from bank_customers;
select distinct isactivemember from bank_customers;
select distinct exited from bank_customers;
select distinct complain from bank_customers;
--all have boolean values

--checking value ranges
SELECT DISTINCT gender from bank_customers;
--male & female

SELECT DISTINCT geography,from bank_customers;
--spain, france, germany

SELECT DISTINCT cardtype from bank_customers;
--gold, platinum, diamond, silver

--product-distribution
select numofproducts, count(*)
from bank_customers
group by numofproducts
order by numofproducts;

--card-distribution
select cardtype, count(*) as cust_count
from bank_customers
group by cardtype
order by cust_count; 

--checking ranges for other numeric columns
select min(age) as minAge, max(age) as maxAge, min(creditscore) as minCrScore, max(creditscore) as maxCrScore,
min(tenure) as minTenure, max(tenure) as maxTenure, min(balance) as minBalance, max(balance) as maxBalance
,min(estimatedsalary) as minsalary, max(estimatedsalary) as maxsalary,
min(satisfactionscore) as min_satisfactionscore, max(satisfactionscore) as max_satisfactionscore
from bank_customers; 

--checking for total active members
select count(*)
from bank_customers
where isactivemember = true;

------------------------------------------

--CHURN-RATE-OVERALL
SELECT ROUND(AVG(exited::int) * 100, 2) as churn_rate
FROM bank_customers;

-------------------------------------------
--DEMOGRAPHIC AND SEGMENT ANALYSIS:

--geographical segmentation of churn
SELECT geography, count(*) as customers,
ROUND(AVG(exited::int) * 100, 2) as country_churn_rate
FROM bank_customers
GROUP BY geography;

--gender segmentation
SELECT gender, 
ROUND(AVG(exited::int) * 100, 2) as gender_churn_rate
FROM bank_customers
GROUP BY gender;

--age-wise segmentation
with age_table as(
SELECT CASE 
	WHEN age between 18 and 25 then 'age_18_25'
	WHEN age between 26 and 35 then 'age_26_35'
	WHEN age between 36 and 45 then 'age_36_45'
	WHEN age between 46 and 55 then 'age_46_55'
	WHEN age between 56 and 65 then 'age_56_65'
	ELSE 'age_66_more'
    END AS age_segments, age, exited
FROM bank_customers
)
SELECT age_segments, count(*) as customers,
ROUND(AVG(exited::int) * 100, 2) as churn_rate
FROM age_table
GROUP BY age_segments
ORDER BY age_segments;

--customer segmentation for user-activities
SELECT isactivemember,
ROUND(AVG(exited::int) * 100, 2) as churn_rate
FROM bank_customers
GROUP BY isactivemember;

--product-based segmentation
select numofproducts, count(*) as customers_count,
ROUND(AVG(exited::int) * 100, 2) as churn_rate
FROM bank_customers
group by numofproducts
order by numofproducts;

--finding churn rates for balance buckets
with balance_segment_table as(
select case 
	when balance = 0 then 'no balance'
	when balance between 1 and 50000 then 'low balance'
	when balance between 50001 and 100000 then 'mid balance'
	when balance between 100001 and 150000 then 'high balance'
	else 'very high balance'
	end as balance_status, exited, balance
From bank_customers )
SELECT balance_status, count(*) as total_customers,
ROUND(AVG(exited::int) * 100, 2) as churn_rate
FROM balance_segment_table
GROUP BY balance_status
ORDER BY churn_rate desc;

--analysing the average balance across churned vs non-churned customers
select exited, avg(balance) 
from bank_customers
group by exited

--categorising customers as funded and unfunded per country:
SELECT 
geography, 
balance > 0 as is_funded,
COUNT(*) as total_customers,
ROUND(AVG(exited::int) * 100, 2) as churn_rate 
FROM bank_customers
GROUP BY geography, is_funded
ORDER BY geography, is_funded; 

--checking average balance after removing unfunded customers:
SELECT geography, ROUND(avg(balance)::INT, 2) as avg_balance
from bank_customers
where exited=false
and balance > 0
group by geography; 
--here we can see that amongst funded customers, the average balance is 119k for all three countries

--churn for funded customers with above overall average salary (119k)
SELECT count(customerid), geography, count(*) as customers,
ROUND(avg(balance)::INT, 2) as avg_balance,
ROUND(AVG(exited::int) * 100, 2) as churn_rate
from bank_customers
where balance>=119000  
group by geography;
--highest in germany at 31.77%

--complainers vs non-complainers
select complain, count(*) as total_customers,
ROUND(AVG(exited::int) * 100, 2) as churn_rate
from bank_customers
group by complain;

--high-risk german customers likely to churn
SELECT customerid, surname, balance 
FROM bank_customers 
WHERE exited = false 
AND geography = 'Germany' 
AND isactivemember = false
AND balance > 119000 -- Above German average balance
ORDER BY balance DESC;

--for active members but high churn rate here it could be sign of pre-exit activity spike.
select geography, count(*) as count,
ROUND(AVG(exited::int) * 100, 2) as churn_rate
from bank_customers
where isactivemember=true
group by geography;
--very low for spain and france (10-11%) as compared to germany i.e. 23.72%

--investigating why german churn rates are much higher:
--product-based:
select numofproducts, 
ROUND(AVG(exited::int) * 100, 2) as churn_rate
from bank_customers
where geography='Germany'
group by numofproducts
order by churn_rate desc;

--product based comparison with other countries especially for people with higher balace:
select count(*) as customers,
numofproducts, geography,
ROUND(AVG(exited::int) * 100, 2) as churn_rate
from bank_customers
where balance >= 119000
group by numofproducts, geography
order by churn_rate desc;

--customer-segmentation
select case 
when isactivemember=false and balance>0 then 'inactive_funded' --double churn rates as compared to active members
when isactivemember=false and balance=0 then 'dormant/ghost'
when isactivemember = true and balance > 0 then 'active_funded'
else 'low_value'
end as segments, count(*) as total_customers,
ROUND(AVG(exited::int) * 100, 2) as churn_rate
from bank_customers
group by segments
order by churn_rate desc;

--critical risk segment
select count(*) as total_customers,
ROUND(AVG(exited::int) * 100, 2) as churn_rate
from bank_customers
where complain=true;
--2044 customers and 99.51% churn

--money-lost:
SELECT geography,
SUM(balance) FILTER (WHERE exited=true) as churned_balance
FROM bank_customers
GROUP BY geography;



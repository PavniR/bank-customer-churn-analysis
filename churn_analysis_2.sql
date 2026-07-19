-----------------------------------
--DATA VALIDATION

SELECT * 
FROM bank_customers
limit 10;

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

--no nulls found

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

--checking for inactive members who haven't exited and have >0 balance
select count(*)
from bank_customers
where isactivemember = false 
and exited = false
and balance >0;
--2122 are inactive but haven't exited & have balance>0 - potentially loyal long term customers

--customers who are inactive, have 0 balance but haven't exited
select count(*)
from bank_customers
where isactivemember = false 
and exited = false
and balance =0;
--1424 are inactive, have 0 balance but not exited- potentially churn customers 

--active members with 0 balance 
select count(*)
from bank_customers
where isactivemember = true
and balance =0;
-- 1873/5151

-----------------------------------------

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

--analysing the average balance across xhur
select avg(balance) from bank_customers

select exited, avg(balance) 
from bank_customers
group by exited

select geography, avg(balance)
from bank_customers
group by geography;
--in spain & france, avg balance is much lower (found as not true later after removing accounts with no balance)
--germany has avg balance higher than overall avg

--new-updates:
--the avg. balance may be skewed because customers with 0 balance 
--aren't contributing to avg balance

--categorising customers as funded and unfunded per country and then calculating:
SELECT 
geography, 
balance > 0 as is_funded,
COUNT(*) as total_customers,
--ROUND(AVG(exited::int) * 100, 2) as churn_rate --better exp for churn rate
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
FROM bank_customers
GROUP BY geography, is_funded
ORDER BY geography, is_funded;
--for funded customers churn rate is highest in germany i.e. 32.44% as compared to 18-19% in france and spain. 

--checking average balance after removing unfunded customers:
SELECT geography, ROUND(avg(balance)::INT, 2) as avg_balance
from bank_customers
where exited=false
and balance > 0
group by geography; 
--here we can see that amongst funded customers, the average balance is 119k for all three countries
/*even for all customers including those who exited, the average is now same as 119k for people with balance >0 as concluded via 
similar query but after removing the exit condition */

--calculating churn for these funded customers who are still in bank: (already done in first query for funded vs non-funded though)
SELECT geography, ROUND(avg(balance)::INT, 2) as avg_balance,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where balance > 0
group by geography; 
--churn is still high in germany at 32% whereas much lower in spain and france i.e. 19.26% and 18.26% respectively

--churn for funded customers with above overall average salary (119k)
SELECT count(customerid), geography, count(*) as customers,
ROUND(avg(balance)::INT, 2) as avg_balance,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where balance>=119000  
group by geography;
--highest in germany at 31.77%

--new-updates end 

create temp table creditscore_buckets as (
select case 
when creditscore between 350 and 579 then 'poor'
when creditscore between 580 and 669 then 'fair'
when creditscore between 670 and 739 then 'good'
when creditscore between 740 and 799 then 'very good'
when creditscore between 800 and 850 then 'excellent'
end as creditscore_value, creditscore, exited
from bank_customers
)
select creditscore_value, count(*) as total_customers,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from creditscore_buckets
GROUP BY creditscore_value
ORDER BY churn_rate desc;
/*"poor"	2362	22.02
"very good"	1224	20.67
"fair"	3331	20.56
"excellent"	655	19.54
"good"	2428	18.62*/
--almost flat distrbution. churn still higher in people with poor credit score. low engagement. 

--complainers vs non-complainers
select complain, count(*) as total_customers,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
group by complain;

select complain, round(avg(satisfactionscore)::numeric,2) as avg_satisfaction_score
from bank_customers
group by complain;
--almost same, no correlation between satisfaction scr=ores & complain

select satisfactionscore, count(*) as total_customers,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
group by satisfactionscore
order by churn_rate;
--kind of flat distribution here, not relevant factor for judgement. 

--balance to estimated salary ratio
--if its low, i.e. low engagement becs very low balance & high salary
create temp table balance_salary_ratio as (
select exited, round((balance/estimatedsalary)::numeric,2) as wallet_value
from bank_customers
);


--278 customers in this bucket 
select count(*) as customers,  
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from balance_salary_ratio
where wallet_value < 0.50
and wallet_value != 0.00;
--churn rate for these customers is 23.7% 
--which is greater than avg

select exited, count(*)
from balance_salary_ratio
where wallet_value < 0.50
and wallet_value != 0.00
group by exited;
--out of the initial 278, 66 have already churned 

/*previously we noted that germany has highest churn and highest average balance
hence they are most valueable customers */

--checking germany-related factors:
select geography, 
count(*) as complain_counts,
round(avg(satisfactionscore)::numeric,2) as avg_satisfaction
from bank_customers
where complain = true
group by geography;
--germany & france have highest complains (also more customer count), however both germanay & spain have around 2500 customers


SELECT count(*) 
FROM bank_customers 
WHERE exited = false 
AND geography = 'Germany' 
AND balance > 119000
AND isactivemember = false; 
--375 customers, if they complain, chances that they churn is very very high. 
--[high risk]


--inactive members geographically
select geography, count(*) as customers
from bank_customers
where isactivemember = false
and exited = false
and complain = true
group by geography;
--2 customers in france as well as in germany at risk; high priority customers since 99.1 % people with complain churn

--getting their details:
select geography, customerid, surname
from bank_customers
where isactivemember = false
and exited = false
and complain = true;

--to get list of high-value customers from germany
SELECT customerid, surname, balance 
FROM bank_customers 
WHERE exited = false 
AND geography = 'Germany' 
AND isactivemember = false
--AND complain = true  ; none have complain
AND balance > 119000 -- Above German average balance
ORDER BY balance DESC;
--(returned 375 rows, if they complain, very likely to churn)


--balance x activity: churn

--inactive and no balance (ghost accounts, possibly already moved elsewhere)
select ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where isactivemember = false 
and balance =0; 
--18.35% 

--inactive and have balance: (loss)
select ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where isactivemember = false 
and balance >0;
--31.66% > avg churn

--active and no balance  (pre-churn activity)
select ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where isactivemember = true
and balance =0; 
-- as expected, very low: 9.61%

--active and have balance 
select ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where isactivemember = true
and balance >0; 
--16.93% less than avg


--diagnosing deeper for inactive and have balance:
with balance_segment_table as(
select case 
	when balance = 0 then 'no balance'
	when balance between 1 and 50000 then 'low balance'
	when balance between 50001 and 100000 then 'mid balance'
	when balance between 100001 and 150000 then 'high balance'
	else 'very high balance'
	end as balance_status, exited, isactivemember
From bank_customers )

select balance_status,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from balance_segment_table
where isactivemember = false 
GROUP BY balance_status;

/* amongst inactive users,
"no balance"	18.35 
"low balance"	51.43 -highest
"high balance"	33.49
"mid balance"	27.03
"very high balance"	29.96
*/

--churn by customer lifecycle (tenure)
select tenure,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
GROUP BY tenure
order by tenure;
--very flat districution, all close to avg churn 

--tenure segmentation into buckets
with tenure_buckets as(
select case 
	when tenure = 0 or tenure = 1 then 'onboarding'
	when tenure = 2 or tenure = 3 then 'early relationship'
	when tenure >= 4 and tenure <= 6 then 'mid-term'
	when tenure >= 7 and tenure <= 10 then 'long-term'
	end as tenure_status, exited
From bank_customers )

--select * from tenure_buckets

--churn-rates for tenure buckets
select tenure_status,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from tenure_buckets
group by tenure_status
order by churn_rate desc;
--still relatively flat, tenure is not a primary churn driver. 


--damn this shi is gold 
--checking when in customer-relation lifecycle customers get inactive and low-zero balance as per tenure buckets:
with table1 as(
select customerid, exited, isactivemember, case 
	when tenure = 0 or tenure = 1 then 'onboarding'
	when tenure = 2 or tenure = 3 then 'early relationship'
	when tenure >= 4 and tenure <= 6 then 'mid-term'
	when tenure >= 7 and tenure <= 10 then 'long-term'
	end as tenure_status, 
	case 
	when balance = 0 then 'no balance'
	when balance between 1 and 50000 then 'low balance'
	when balance between 50001 and 100000 then 'mid balance'
	when balance between 100001 and 150000 then 'high balance'
	else 'very high balance'
	end as balance_status, numofproducts, hascrcard
From bank_customers)

/*
select tenure_status, balance_status,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from table1
where isactivemember = false
and (balance_status = 'no balance'
or balance_status = 'low balance')
group by tenure_status, balance_status
order by churn_rate desc;
*/

--less in long-term customers with low balance, highest in mid-term and early and onboarding with low balance. 

--final checkin- if the customers at high risk of churn are high value
--imp for changes for retention 

select count(*), ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from table1
where numofproducts > 2
--and isactivemember = false   -- =184 with 90.22% churn rate
and isactivemember = true; -- = 142 with 80.28% churn

/*
Multi-product customers who disengage are extremely likely to churn, regardless of activity status.
also low in concentration, 3 prod: 266/10k, 4 prod: 60/10k
Multi-product churn is rare but highly decisive once disengagement begins i.e pre exit activity or 
inactivity for extended time.
so these customers are: 
High-value
Low-volume
High-urgency when signals appear
*/

--for active members but high churn rate here it could be sign of pre-exit activity spike.
select geography, count(*) as count,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where isactivemember=true
group by geography;
--very low for spain and france (10-11%) as compared to germany i.e. 23.72%

--investigating why german churn rates are much higher:

--product-based:
select numofproducts, 
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where geography='Germany'
group by numofproducts
order by churn_rate desc;
--similar pattern found.
/*
4-	100.00
3-	89.58   (maybe low product satisfaction or cross sold the wrong products, can't be determined solely from given data.)
1-	42.85
2-	12.12  (cross-sell two products to improve loyalty)
*/

--product based comparison with other countries especially for people with higher balace:
select count(*) as customers,
numofproducts, geography,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where balance >= 119000
group by numofproducts, geography
order by churn_rate desc;

--complain vs non-complainers country-wise churn:
select count(*) as customers, geography, complain,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
group by geography, complain
order by churn_rate desc;
--people with a complain churn at 99.5-99.7% for all countries.

--females
select count(*) as customers, gender, geography,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
group by geography, gender
order by churn_rate desc;

--product vs females
select gender,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where geography='Germany'
and numofproducts=2
group by gender
order by churn_rate desc;
--almost double as compared to males
--so problem is also female oriented 
--female churn 16%, male churn 8%
--but by cross selling two products we can reduce churn in females as compared to overall churn of 37%.

--final chcek with age-groups:
select count(*) as customers, geography,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where age between 46 and 65
and numofproducts=2
group by geography;

/*173	"Spain"	24.28
297	"France"	16.16
148	"Germany"	36.49 */

--customer-segmentation

select case 
when isactivemember=false and balance>0 then 'inactive_funded' --double churn rates as compared to active members
when isactivemember=false and balance=0 then 'dormant/ghost'
when isactivemember = true and balance > 0 then 'active_funded'
else 'low_value'
end as segments, count(*) as total_customers,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
group by segments
order by churn_rate desc;

--segments for germany
select case 
when isactivemember=false and balance>0 then 'inactive_funded' --double churn rates as compared to active members
when isactivemember=false and balance=0 then 'dormant/ghost'
when isactivemember = true and balance > 0 then 'active_funded'
else 'low_value'
end as segments, count(*) as total_customers,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where geography='Germany'
group by segments
order by churn_rate desc;

--segments for France:
select case 
when isactivemember=false and balance>0 then 'inactive_funded' --double churn rates as compared to active members
when isactivemember=false and balance=0 then 'dormant/ghost'
when isactivemember = true and balance > 0 then 'active_funded'
else 'low_value'
end as segments, count(*) as total_customers,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where geography='France'
group by segments
order by churn_rate desc;

--segments for spain:
select case 
when isactivemember=false and balance>0 then 'inactive_funded' --double churn rates as compared to active members
when isactivemember=false and balance=0 then 'dormant/ghost'
when isactivemember = true and balance > 0 then 'active_funded'
else 'low_value'
end as segments, count(*) as total_customers,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where geography='Spain'
group by segments
order by churn_rate desc;

--critical risk segment
select count(*) as total_customers,
ROUND(((COUNT(*) FILTER(WHERE exited=true)::float/COUNT(*)::float)*100)::numeric ,2) as churn_rate
from bank_customers
where complain=true;
--2044 customers and 99.51% churn

--money-lost:
SELECT geography,
SUM(balance) FILTER (WHERE exited=true) as churned_balance
FROM bank_customers
GROUP BY geography;

select max(estimatedsalary) from bank_customers; 

SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY balance) AS median_balance
FROM bank_customers;

--queries for visuals in py
--1.overall churned customers
SELECT exited, COUNT(*) as customers
FROM bank_customers
GROUP BY exited;

--2.churn by geography


select gender, count(*) from bank_customers
group by gender;
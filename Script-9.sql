/* Use DuckDB TO DECODE AND ANALYSE THE DATASET! */
create table raw_csj as 
select
"Program Year / Année du programme" as raw_year,
"Region / Région" as raw_region,
"Activity Constituency" as raw_constituency,
"Organization Common Name / Nom commun de l'organisme" as raw_org_name,
"Amount Paid / Montant payé" as raw_amount,
"Confirmed Jobs Created / Emplois confirmés créés" as raw_jobs
from read_csv_auto("C:\Users\admin\Desktop\YRES\Andi Dong - Summer Job Analysis\csj-dataset - AB, BC, ON.csv");

/* basic checking */
select * from raw_csj limit 5;

/* NULL-VALUE CHECKING */
select
count(*) as total_rows,
count(*) - count(raw_year) as null_year,
count(*) - count(raw_region) as null_region,
count(*) - count(raw_constituency) as null_constituency,
COUNT(*) - COUNT(raw_org_name) as null_org_name,
COUNT(*) - COUNT(raw_amount) as null_amount,
COUNT(*) - COUNT(raw_jobs) as null_jobs
FROM raw_csj;

/* Hence no missing/null value! */

/* Duplicated value checking */
select
raw_year,
raw_region,
raw_constituency,
raw_org_name,
raw_amount,
raw_jobs,
count(*) as duplicate_count
from raw_csj
group by raw_year,raw_region, raw_constituency, raw_org_name,raw_amount,raw_jobs
having count(*) > 1
order BY duplicate_count desc;

/* 有重复项？记住先不急着删除！检擦下重复项长什么样子！*/
SELECT *
FROM raw_csj
WHERE raw_org_name = 'University of Calgary'
AND raw_constituency = 'Calgary Confederation'
ORDER BY raw_year, raw_amount;

/*唔！似乎看来重复项是有道理的，同一年一个机构下的一个组织时会出现一年拿到多个funding并且带来的收益不一样！*/

/* Abnormal Value Checking！ 异常值检查！ */
/*
 year    → 应该只有 2017-2025，有没有奇怪的年份？
region  → 应该只有 Alberta / British Columbia / Ontario，有没有拼写错误？
amount  → 有没有负数？有没有0？
jobs    → 有没有负数？有没有0？
 */

select distinct raw_year from raw_csj order by raw_year;
/* date is reasonable! */

select distinct raw_region from raw_csj order by raw_region;
/* 首先区域合理！但是BC的分类名有点乱！精简处理！ */

select
min(raw_amount) as min_paid,
max(raw_amount) as max_paid,
min(raw_jobs) as min_jobs,
max(raw_jobs) as max_jobs
from raw_csj;

/* 有意思，为什么min paid funding为0的时候，最小的min jobs created为1？ 需要检查下！ */
select *
from raw_csj
where raw_amount = 0;

select * from raw_csj
where raw_jobs = 1
order by raw_amount desc;

/* @#@#@#@#@#@#@#@#@#@#@#@@##@
 好了。首先现总结！
 拿到数据集！先做整体清洗，整体检查，空值重复值不要急着处理先判断！
 做完再对每一列进行检查，检查标准按照业务标准来！比如年份range，数值列是否允许出现0/负数等！
 
 ===============CONCLUSION====================
 本项目做完之后，确实发现如下两个问题！
 1. 169个2021年的case出现了funding为0但是岗位created机会不为0！检查下是否是记录错误！
 2. 两个投资额大于50K的机构，只创造了一个岗位！检查是否是异常值！
 */

/* === SUMMARY === */
/* 这里总结下！ 我们现在唯一需要真正做数据集的只有简化修改region下的BC省份名称！
 * 基于此我们修改后做一份COPY()，备份！跟python里面copy逻辑一样！保护原数据集！
 */

create table stg_csj as 
select 
raw_year as year,
case 
when raw_region LIKE '%British Columbia%' then 'British Columbia'
else raw_region
end as region,
raw_constituency as constituency,
raw_org_name as org_name,
raw_amount as amount,
raw_jobs as jobs
from raw_csj;

select * from stg_csj limit 200;

select distinct region from stg_csj;

/* SQL的基础数据清洗已完成！ 现在开始正式做format table！*/
-- Ontario
create table mart_on_ridings as
select constituency, count(distinct org_name) as total_number_of_organizations,
--2017
sum(case when year = 2017 then amount else 0 end) as funding_2017,
sum(case when year = 2017 then jobs else 0 end) as jobs_2017,
sum(case when year = 2017 then amount else 0 end) / NULLIF(sum(case when year = 2017 then jobs else 0 end), 0) as avg_salary_2017,
--2018
sum(case when year = 2018 then amount else 0 end) as funding_2018,
sum(case when year = 2018 then jobs else 0 end) as jobs_2018,
sum(case when year = 2018 then amount else 0 end) / NULLIF(sum(case when year = 2018 then jobs else 0 end), 0) as avg_salary_2018,
--2019
sum(case when year = 2019 then amount else 0 end) as funding_2019,
sum(case when year = 2019 then jobs else 0 end) as jobs_2019,
sum(case when year = 2019 then amount else 0 end) / NULLIF(sum(case when year = 2019 then jobs else 0 end), 0) as avg_salary_2019,
--2020
sum(case when year = 2020 then amount else 0 end) as funding_2020,
sum(case when year = 2020 then jobs else 0 end) as jobs_2020,
sum(case when year = 2020 then amount else 0 end) / NULLIF(sum(case when year = 2020 then jobs else 0 end), 0) as avg_salary_2020,
--2021
sum(case when year = 2021 then amount else 0 end) as funding_2021,
sum(case when year = 2021 then jobs else 0 end) as jobs_2021,
sum(case when year = 2021 then amount else 0 end) / NULLIF(sum(case when year = 2021 then jobs else 0 end), 0) as avg_salary_2021,
--2022
sum(case when year = 2022 then amount else 0 end) as funding_2022,
sum(case when year = 2022 then jobs else 0 end) as jobs_2022,
sum(case when year = 2022 then amount else 0 end) / NULLIF(sum(case when year = 2022 then jobs else 0 end), 0) as avg_salary_2022,
--2023
sum(case when year = 2023 then amount else 0 end) as funding_2023,
sum(case when year = 2023 then jobs else 0 end) as jobs_2023,
sum(case when year = 2023 then amount else 0 end) / NULLIF(sum(case when year = 2023 then jobs else 0 end), 0) as avg_salary_2023,
--2024
sum(case when year = 2024 then amount else 0 end) as funding_2024,
sum(case when year = 2024 then jobs else 0 end) as jobs_2024,
sum(case when year = 2024 then amount else 0 end) / NULLIF(sum(case when year = 2024 then jobs else 0 end), 0) as avg_salary_2024,
--2025
sum(case when year = 2025 then amount else 0 end) as funding_2025,
sum(case when year = 2025 then jobs else 0 end) as jobs_2025,
sum(case when year = 2025 then amount else 0 end) / NULLIF(sum(case when year = 2025 then jobs else 0 end), 0) as avg_salary_2025
from stg_csj
where region = 'Ontario'
group by constituency
order by constituency;

-- Ontario Top 30 by Jobs created!
create table mart_on_organizations as
with cte_on_1 as 
(select constituency, org_name,sum(jobs) as total_jobs_created,
--2017
sum(case when year = 2017 then amount else 0 end) as funding_2017,
sum(case when year = 2017 then jobs else 0 end) as jobs_2017,
sum(case when year = 2017 then amount else 0 end) / NULLIF(sum(case when year = 2017 then jobs else 0 end), 0) as avg_salary_2017,
--2018
sum(case when year = 2018 then amount else 0 end) as funding_2018,
sum(case when year = 2018 then jobs else 0 end) as jobs_2018,
sum(case when year = 2018 then amount else 0 end) / NULLIF(sum(case when year = 2018 then jobs else 0 end), 0) as avg_salary_2018,
--2019
sum(case when year = 2019 then amount else 0 end) as funding_2019,
sum(case when year = 2019 then jobs else 0 end) as jobs_2019,
sum(case when year = 2019 then amount else 0 end) / NULLIF(sum(case when year = 2019 then jobs else 0 end), 0) as avg_salary_2019,
--2020
sum(case when year = 2020 then amount else 0 end) as funding_2020,
sum(case when year = 2020 then jobs else 0 end) as jobs_2020,
sum(case when year = 2020 then amount else 0 end) / NULLIF(sum(case when year = 2020 then jobs else 0 end), 0) as avg_salary_2020,
--2021
sum(case when year = 2021 then amount else 0 end) as funding_2021,
sum(case when year = 2021 then jobs else 0 end) as jobs_2021,
sum(case when year = 2021 then amount else 0 end) / NULLIF(sum(case when year = 2021 then jobs else 0 end), 0) as avg_salary_2021,
--2022
sum(case when year = 2022 then amount else 0 end) as funding_2022,
sum(case when year = 2022 then jobs else 0 end) as jobs_2022,
sum(case when year = 2022 then amount else 0 end) / NULLIF(sum(case when year = 2022 then jobs else 0 end), 0) as avg_salary_2022,
--2023
sum(case when year = 2023 then amount else 0 end) as funding_2023,
sum(case when year = 2023 then jobs else 0 end) as jobs_2023,
sum(case when year = 2023 then amount else 0 end) / NULLIF(sum(case when year = 2023 then jobs else 0 end), 0) as avg_salary_2023,
--2024
sum(case when year = 2024 then amount else 0 end) as funding_2024,
sum(case when year = 2024 then jobs else 0 end) as jobs_2024,
sum(case when year = 2024 then amount else 0 end) / NULLIF(sum(case when year = 2024 then jobs else 0 end), 0) as avg_salary_2024,
--2025
sum(case when year = 2025 then amount else 0 end) as funding_2025,
sum(case when year = 2025 then jobs else 0 end) as jobs_2025,
sum(case when year = 2025 then amount else 0 end) / NULLIF(sum(case when year = 2025 then jobs else 0 end), 0) as avg_salary_2025
from stg_csj
where region = 'Ontario'
group by constituency, org_name
),
cte_on_2 as (
select constituency, org_name,
funding_2017, jobs_2017, avg_salary_2017,
funding_2018, jobs_2018, avg_salary_2018,
funding_2019, jobs_2019, avg_salary_2019,
funding_2020, jobs_2020, avg_salary_2020,
funding_2021, jobs_2021, avg_salary_2021,
funding_2022, jobs_2022, avg_salary_2022,
funding_2023, jobs_2023, avg_salary_2023,
funding_2024, jobs_2024, avg_salary_2024,
funding_2025, jobs_2025, avg_salary_2025,
row_number() over (partition by constituency order by total_jobs_created desc) as rn
from cte_on_1
)
select constituency, org_name, 
funding_2017, jobs_2017, avg_salary_2017,
funding_2018, jobs_2018, avg_salary_2018,
funding_2019, jobs_2019, avg_salary_2019,
funding_2020, jobs_2020, avg_salary_2020,
funding_2021, jobs_2021, avg_salary_2021,
funding_2022, jobs_2022, avg_salary_2022,
funding_2023, jobs_2023, avg_salary_2023,
funding_2024, jobs_2024, avg_salary_2024,
funding_2025, jobs_2025, avg_salary_2025
from cte_on_2
where rn < 31;


-- British Columbia
create table mart_bc_ridings as
select constituency, count(distinct org_name) as total_number_of_organizations,
--2017
sum(case when year = 2017 then amount else 0 end) as funding_2017,
sum(case when year = 2017 then jobs else 0 end) as jobs_2017,
sum(case when year = 2017 then amount else 0 end) / NULLIF(sum(case when year = 2017 then jobs else 0 end), 0) as avg_salary_2017,
--2018
sum(case when year = 2018 then amount else 0 end) as funding_2018,
sum(case when year = 2018 then jobs else 0 end) as jobs_2018,
sum(case when year = 2018 then amount else 0 end) / NULLIF(sum(case when year = 2018 then jobs else 0 end), 0) as avg_salary_2018,
--2019
sum(case when year = 2019 then amount else 0 end) as funding_2019,
sum(case when year = 2019 then jobs else 0 end) as jobs_2019,
sum(case when year = 2019 then amount else 0 end) / NULLIF(sum(case when year = 2019 then jobs else 0 end), 0) as avg_salary_2019,
--2020
sum(case when year = 2020 then amount else 0 end) as funding_2020,
sum(case when year = 2020 then jobs else 0 end) as jobs_2020,
sum(case when year = 2020 then amount else 0 end) / NULLIF(sum(case when year = 2020 then jobs else 0 end), 0) as avg_salary_2020,
--2021
sum(case when year = 2021 then amount else 0 end) as funding_2021,
sum(case when year = 2021 then jobs else 0 end) as jobs_2021,
sum(case when year = 2021 then amount else 0 end) / NULLIF(sum(case when year = 2021 then jobs else 0 end), 0) as avg_salary_2021,
--2022
sum(case when year = 2022 then amount else 0 end) as funding_2022,
sum(case when year = 2022 then jobs else 0 end) as jobs_2022,
sum(case when year = 2022 then amount else 0 end) / NULLIF(sum(case when year = 2022 then jobs else 0 end), 0) as avg_salary_2022,
--2023
sum(case when year = 2023 then amount else 0 end) as funding_2023,
sum(case when year = 2023 then jobs else 0 end) as jobs_2023,
sum(case when year = 2023 then amount else 0 end) / NULLIF(sum(case when year = 2023 then jobs else 0 end), 0) as avg_salary_2023,
--2024
sum(case when year = 2024 then amount else 0 end) as funding_2024,
sum(case when year = 2024 then jobs else 0 end) as jobs_2024,
sum(case when year = 2024 then amount else 0 end) / NULLIF(sum(case when year = 2024 then jobs else 0 end), 0) as avg_salary_2024,
--2025
sum(case when year = 2025 then amount else 0 end) as funding_2025,
sum(case when year = 2025 then jobs else 0 end) as jobs_2025,
sum(case when year = 2025 then amount else 0 end) / NULLIF(sum(case when year = 2025 then jobs else 0 end), 0) as avg_salary_2025
from stg_csj
where region = 'British Columbia'
group by constituency
order by constituency;

-- British Columbia Top 30 by Jobs created!
create table mart_bc_organizations as
with cte_bc_1 as 
(select constituency, org_name,sum(jobs) as total_jobs_created,
--2017
sum(case when year = 2017 then amount else 0 end) as funding_2017,
sum(case when year = 2017 then jobs else 0 end) as jobs_2017,
sum(case when year = 2017 then amount else 0 end) / NULLIF(sum(case when year = 2017 then jobs else 0 end), 0) as avg_salary_2017,
--2018
sum(case when year = 2018 then amount else 0 end) as funding_2018,
sum(case when year = 2018 then jobs else 0 end) as jobs_2018,
sum(case when year = 2018 then amount else 0 end) / NULLIF(sum(case when year = 2018 then jobs else 0 end), 0) as avg_salary_2018,
--2019
sum(case when year = 2019 then amount else 0 end) as funding_2019,
sum(case when year = 2019 then jobs else 0 end) as jobs_2019,
sum(case when year = 2019 then amount else 0 end) / NULLIF(sum(case when year = 2019 then jobs else 0 end), 0) as avg_salary_2019,
--2020
sum(case when year = 2020 then amount else 0 end) as funding_2020,
sum(case when year = 2020 then jobs else 0 end) as jobs_2020,
sum(case when year = 2020 then amount else 0 end) / NULLIF(sum(case when year = 2020 then jobs else 0 end), 0) as avg_salary_2020,
--2021
sum(case when year = 2021 then amount else 0 end) as funding_2021,
sum(case when year = 2021 then jobs else 0 end) as jobs_2021,
sum(case when year = 2021 then amount else 0 end) / NULLIF(sum(case when year = 2021 then jobs else 0 end), 0) as avg_salary_2021,
--2022
sum(case when year = 2022 then amount else 0 end) as funding_2022,
sum(case when year = 2022 then jobs else 0 end) as jobs_2022,
sum(case when year = 2022 then amount else 0 end) / NULLIF(sum(case when year = 2022 then jobs else 0 end), 0) as avg_salary_2022,
--2023
sum(case when year = 2023 then amount else 0 end) as funding_2023,
sum(case when year = 2023 then jobs else 0 end) as jobs_2023,
sum(case when year = 2023 then amount else 0 end) / NULLIF(sum(case when year = 2023 then jobs else 0 end), 0) as avg_salary_2023,
--2024
sum(case when year = 2024 then amount else 0 end) as funding_2024,
sum(case when year = 2024 then jobs else 0 end) as jobs_2024,
sum(case when year = 2024 then amount else 0 end) / NULLIF(sum(case when year = 2024 then jobs else 0 end), 0) as avg_salary_2024,
--2025
sum(case when year = 2025 then amount else 0 end) as funding_2025,
sum(case when year = 2025 then jobs else 0 end) as jobs_2025,
sum(case when year = 2025 then amount else 0 end) / NULLIF(sum(case when year = 2025 then jobs else 0 end), 0) as avg_salary_2025
from stg_csj
where region = 'British Columbia'
group by constituency, org_name
),
cte_bc_2 as (
select constituency, org_name,
funding_2017, jobs_2017, avg_salary_2017,
funding_2018, jobs_2018, avg_salary_2018,
funding_2019, jobs_2019, avg_salary_2019,
funding_2020, jobs_2020, avg_salary_2020,
funding_2021, jobs_2021, avg_salary_2021,
funding_2022, jobs_2022, avg_salary_2022,
funding_2023, jobs_2023, avg_salary_2023,
funding_2024, jobs_2024, avg_salary_2024,
funding_2025, jobs_2025, avg_salary_2025,
row_number() over (partition by constituency order by total_jobs_created desc) as rn
from cte_bc_1
)
select constituency, org_name, 
funding_2017, jobs_2017, avg_salary_2017,
funding_2018, jobs_2018, avg_salary_2018,
funding_2019, jobs_2019, avg_salary_2019,
funding_2020, jobs_2020, avg_salary_2020,
funding_2021, jobs_2021, avg_salary_2021,
funding_2022, jobs_2022, avg_salary_2022,
funding_2023, jobs_2023, avg_salary_2023,
funding_2024, jobs_2024, avg_salary_2024,
funding_2025, jobs_2025, avg_salary_2025
from cte_bc_2
where rn < 31;


-- Alberta
create table mart_ab_ridings as
select constituency, count(distinct org_name) as total_number_of_organizations,
--2017
sum(case when year = 2017 then amount else 0 end) as funding_2017,
sum(case when year = 2017 then jobs else 0 end) as jobs_2017,
sum(case when year = 2017 then amount else 0 end) / NULLIF(sum(case when year = 2017 then jobs else 0 end), 0) as avg_salary_2017,
--2018
sum(case when year = 2018 then amount else 0 end) as funding_2018,
sum(case when year = 2018 then jobs else 0 end) as jobs_2018,
sum(case when year = 2018 then amount else 0 end) / NULLIF(sum(case when year = 2018 then jobs else 0 end), 0) as avg_salary_2018,
--2019
sum(case when year = 2019 then amount else 0 end) as funding_2019,
sum(case when year = 2019 then jobs else 0 end) as jobs_2019,
sum(case when year = 2019 then amount else 0 end) / NULLIF(sum(case when year = 2019 then jobs else 0 end), 0) as avg_salary_2019,
--2020
sum(case when year = 2020 then amount else 0 end) as funding_2020,
sum(case when year = 2020 then jobs else 0 end) as jobs_2020,
sum(case when year = 2020 then amount else 0 end) / NULLIF(sum(case when year = 2020 then jobs else 0 end), 0) as avg_salary_2020,
--2021
sum(case when year = 2021 then amount else 0 end) as funding_2021,
sum(case when year = 2021 then jobs else 0 end) as jobs_2021,
sum(case when year = 2021 then amount else 0 end) / NULLIF(sum(case when year = 2021 then jobs else 0 end), 0) as avg_salary_2021,
--2022
sum(case when year = 2022 then amount else 0 end) as funding_2022,
sum(case when year = 2022 then jobs else 0 end) as jobs_2022,
sum(case when year = 2022 then amount else 0 end) / NULLIF(sum(case when year = 2022 then jobs else 0 end), 0) as avg_salary_2022,
--2023
sum(case when year = 2023 then amount else 0 end) as funding_2023,
sum(case when year = 2023 then jobs else 0 end) as jobs_2023,
sum(case when year = 2023 then amount else 0 end) / NULLIF(sum(case when year = 2023 then jobs else 0 end), 0) as avg_salary_2023,
--2024
sum(case when year = 2024 then amount else 0 end) as funding_2024,
sum(case when year = 2024 then jobs else 0 end) as jobs_2024,
sum(case when year = 2024 then amount else 0 end) / NULLIF(sum(case when year = 2024 then jobs else 0 end), 0) as avg_salary_2024,
--2025
sum(case when year = 2025 then amount else 0 end) as funding_2025,
sum(case when year = 2025 then jobs else 0 end) as jobs_2025,
sum(case when year = 2025 then amount else 0 end) / NULLIF(sum(case when year = 2025 then jobs else 0 end), 0) as avg_salary_2025
from stg_csj
where region = 'Alberta'
group by constituency
order by constituency;

-- Alberta Top 30 by Jobs created!
create table mart_ab_organizations as
with cte_ab_1 as 
(select constituency, org_name,sum(jobs) as total_jobs_created,
--2017
sum(case when year = 2017 then amount else 0 end) as funding_2017,
sum(case when year = 2017 then jobs else 0 end) as jobs_2017,
sum(case when year = 2017 then amount else 0 end) / NULLIF(sum(case when year = 2017 then jobs else 0 end), 0) as avg_salary_2017,
--2018
sum(case when year = 2018 then amount else 0 end) as funding_2018,
sum(case when year = 2018 then jobs else 0 end) as jobs_2018,
sum(case when year = 2018 then amount else 0 end) / NULLIF(sum(case when year = 2018 then jobs else 0 end), 0) as avg_salary_2018,
--2019
sum(case when year = 2019 then amount else 0 end) as funding_2019,
sum(case when year = 2019 then jobs else 0 end) as jobs_2019,
sum(case when year = 2019 then amount else 0 end) / NULLIF(sum(case when year = 2019 then jobs else 0 end), 0) as avg_salary_2019,
--2020
sum(case when year = 2020 then amount else 0 end) as funding_2020,
sum(case when year = 2020 then jobs else 0 end) as jobs_2020,
sum(case when year = 2020 then amount else 0 end) / NULLIF(sum(case when year = 2020 then jobs else 0 end), 0) as avg_salary_2020,
--2021
sum(case when year = 2021 then amount else 0 end) as funding_2021,
sum(case when year = 2021 then jobs else 0 end) as jobs_2021,
sum(case when year = 2021 then amount else 0 end) / NULLIF(sum(case when year = 2021 then jobs else 0 end), 0) as avg_salary_2021,
--2022
sum(case when year = 2022 then amount else 0 end) as funding_2022,
sum(case when year = 2022 then jobs else 0 end) as jobs_2022,
sum(case when year = 2022 then amount else 0 end) / NULLIF(sum(case when year = 2022 then jobs else 0 end), 0) as avg_salary_2022,
--2023
sum(case when year = 2023 then amount else 0 end) as funding_2023,
sum(case when year = 2023 then jobs else 0 end) as jobs_2023,
sum(case when year = 2023 then amount else 0 end) / NULLIF(sum(case when year = 2023 then jobs else 0 end), 0) as avg_salary_2023,
--2024
sum(case when year = 2024 then amount else 0 end) as funding_2024,
sum(case when year = 2024 then jobs else 0 end) as jobs_2024,
sum(case when year = 2024 then amount else 0 end) / NULLIF(sum(case when year = 2024 then jobs else 0 end), 0) as avg_salary_2024,
--2025
sum(case when year = 2025 then amount else 0 end) as funding_2025,
sum(case when year = 2025 then jobs else 0 end) as jobs_2025,
sum(case when year = 2025 then amount else 0 end) / NULLIF(sum(case when year = 2025 then jobs else 0 end), 0) as avg_salary_2025
from stg_csj
where region = 'Alberta'
group by constituency, org_name
),
cte_ab_2 as (
select constituency, org_name,
funding_2017, jobs_2017, avg_salary_2017,
funding_2018, jobs_2018, avg_salary_2018,
funding_2019, jobs_2019, avg_salary_2019,
funding_2020, jobs_2020, avg_salary_2020,
funding_2021, jobs_2021, avg_salary_2021,
funding_2022, jobs_2022, avg_salary_2022,
funding_2023, jobs_2023, avg_salary_2023,
funding_2024, jobs_2024, avg_salary_2024,
funding_2025, jobs_2025, avg_salary_2025,
row_number() over (partition by constituency order by total_jobs_created desc) as rn
from cte_ab_1
)
select constituency, org_name, 
funding_2017, jobs_2017, avg_salary_2017,
funding_2018, jobs_2018, avg_salary_2018,
funding_2019, jobs_2019, avg_salary_2019,
funding_2020, jobs_2020, avg_salary_2020,
funding_2021, jobs_2021, avg_salary_2021,
funding_2022, jobs_2022, avg_salary_2022,
funding_2023, jobs_2023, avg_salary_2023,
funding_2024, jobs_2024, avg_salary_2024,
funding_2025, jobs_2025, avg_salary_2025
from cte_ab_2
where rn < 31;


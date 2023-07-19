--Getting Overview of Data by fetching Samples
select
    *
from sql_project.india_retail
order by RAND()
limit 50;

-- Checking for Null Values
select
    *
from sql_project.india_retail
where Date IS NULL
   or Centre IS NULL
   or Commodity IS NULL
   or Price_per_Kg IS NULL
   or Region IS NULL ;

--Getting Year of Data
select
    min(EXTRACT(YEAR from Date))as start_year,
    max(EXTRACT(YEAR from Date))as end_year
from sql_project.india_retail ;

--Getting Count of Records BY Year
select
    EXTRACT(YEAR from Date) as Year,
    count(*) as number_of_records
from sql_project.india_retail
group by 1
order by 1;

--Getting count of Categorical Values #there are two tables in this code
with count_of_categories as
    ((select
          Centre ,
          "Centre" as Category,
          count(*) as number_of_records
      from sql_project.india_retail
      group by 1)
    UNION ALL
    (select
         Commodity,
         "Commodity" as Category,
         count(*) as number_of_records
     from sql_project.india_retail
     group by 1 )
    UNION ALL
    (select
         Region,
         "Region" as Category,
         count(*) as number_of_records
     from sql_project.india_retail
     group by 1 )) ,
overview_category as(
    select DISTINCT
        SUM(CASE WHEN Category = "Region" THEN 1 else 0 END) as Region ,
        SUM(CASE WHEN Category = "Commodity" Then 1 else 0 end) as Commodity,
        SUM(CASE WHEN Category = "Centre" Then 1 else 0 END ) as Centre
    from count_of_categories )
select * from overview_category ;


---Uni variate Analysis-----

--Average Price
select
    avg(Price_per_Kg) as avg_price
from sql_project.india_retail ;

--Median Price
with cte as(select *,
       ROW_NUMBER() over (ORDER BY Price_per_Kg) as r_asc,
       COUNT(*) OVER() AS CNT
FROM (select Price_per_Kg from sql_project.india_retail
                          WHERE Price_per_Kg IS NOT NULL))
select
    avg(Price_per_Kg) as median_price
from cte
WHERE r_asc = (CNT + 1)/2
   or r_asc = CNT/2
   or r_asc = (CNT/2) + 1;

--Getting Range of Price
select
    max(Price_per_Kg) as maximum_price,
    min(Price_per_Kg) as minimum_price,
    max(Price_per_Kg) - min(Price_per_Kg) as price_range
from sql_project.india_retail;


---Top to down Approach related to price

--Average/Median Price by Region
with cte as (select
                 Region,
                 Price_per_Kg,
                 ROW_NUMBER() over (PARTITION BY Region ORDER BY Price_per_Kg) as r_asc,
                 Count(Price_per_Kg) OVER(PARTITION BY Region) as cnt
             from sql_project.india_retail),
     median as(
         select Region,
                avg(Price_per_Kg) as Median_Price
         from cte
         where r_asc = (cnt + 1)/2 or r_asc = (cnt/2) or r_asc = (cnt/2) + 1
         group by 1)
select c.Region,avg(Price_per_Kg) as Average_Price ,Median_Price  from cte c INNER JOIN median m ON c.Region = m.Region
group by 1,3 ;

--Average Price by Centre
with cte as (select
                 Centre,
                 Price_per_Kg,
                 ROW_NUMBER() over (PARTITION BY Centre ORDER BY Price_per_Kg) as r_asc,
                 Count(Price_per_Kg) OVER(PARTITION BY Centre) as cnt
             from sql_project.india_retail),
     median as(
         select Centre,
                avg(Price_per_Kg) as Median_Price
         from cte
         where r_asc = (cnt + 1)/2 or r_asc = (cnt/2) or r_asc = (cnt/2) + 1
         group by 1)
select c.Centre,avg(Price_per_Kg) as Average_Price ,Median_Price  from cte c INNER JOIN median m ON c.Centre = m.Centre
group by 1,3 ;


--Average Price by Commodity
with cte as (select Commodity,
                 Price_per_Kg,
                 ROW_NUMBER() over (PARTITION BY Commodity ORDER BY Price_per_Kg) as r_asc,
                 Count(Price_per_Kg) OVER(PARTITION BY Commodity) as cnt
             from sql_project.india_retail),
     median as(
         select Commodity,
                avg(Price_per_Kg) as Median_Price
         from cte
         where r_asc = (cnt + 1)/2 or r_asc = (cnt/2) or r_asc = (cnt/2) + 1
         group by 1)
select c.Commodity,avg(Price_per_Kg) as Average_Price ,Median_Price  from cte c INNER JOIN median m ON c.Commodity = m.Commodity
group by 1,3 ;


--Monthly trend of Price
select
    EXTRACT(Year from Date) as Year,
    EXTRACT(Month from Date) as Month,
    ROUND(sum(Price_per_Kg)) as price
from sql_project.india_retail
group by 1,2
order by 1,2 ;

--Monthly Trend of Price By Region
select
    Region,
    EXTRACT(Month from Date) as Month,
    ROUND(sum(Price_per_Kg)) as price
from sql_project.india_retail
group by 1,2
order by 1,2 ;

--Monthly Trend of Price By Commodity
select
    Commodity,
    EXTRACT(Month from Date) as Month,
    ROUND(sum(Price_per_Kg)) as price
from sql_project.india_retail
group by 1,2
order by 1,2 ;

--Monthly Trend of Price By Centre
select
    Centre,
    EXTRACT(Month from Date) as Month,
    ROUND(sum(Price_per_Kg)) as price
from sql_project.india_retail
group by 1,2
order by 1,2 ;



--percent_total_of_relative_distribution_by_year
with cte as(select
                EXTRACT(Year from Date) as year ,
                Commodity,
                sum(Price_per_Kg) as total_sales
            from sql_project.india_retail
            group by 1,2
            order by 1),
sum_over as(
            select
                *,
                sum(total_sales) over(partition by year) as sum
            from cte )
select *,ROUND(total_sales/sum,2) as percent_total from sum_over
order by 1;



--Index to check how price has fluctuate over time for each region cpi
with cte as(select
                EXTRACT(Year from Date) as year ,
                Region,
                Commodity,
                avg(Price_per_Kg) as avg_sales
            from sql_project.india_retail
            group by 1,2,3
            order by 1),
     sum_over as(
         select
             *,
             FIRST_VALUE(avg_sales) over(partition by Region,Commodity ORDER BY year) as index_price
         from cte )
select
    *,
    (CASE WHEN avg_sales = index_price then 0 else ((avg_sales-index_price)/index_price)*100 END) as percent_total
from sum_over
order by 2;




--yoy_commodity_price_change_for_each_region
with cte as(select
                EXTRACT(Year from Date) as Year ,
                EXTRACT(Month from Date) as Month,
                Region,
                Commodity,
                avg(Price_per_Kg) as avg_sales
            from sql_project.india_retail
            group by 1,2,3,4
            order by 1),
     sum_over as(
         select
             *,
             Lag(avg_sales) over(partition by Region,Commodity ORDER BY Year) as index_price
         from cte )
select
    PARSE_DATE('%Y-%m-%d',CONCAT(Year,"-",Month,"-","01")) as Date,
    Region,
    Commodity,
    avg_sales,
    index_price,
    (avg_sales-index_price)as abs_difference,
    (CASE WHEN  index_price IS Null then 0 else ((avg_sales-index_price)/index_price) * 100 END) as pct_growth_from_previous
from sum_over
order by 3,2,1;



--moving_average_commodities
select
    PARSE_DATE('%Y-%m-%d',CONCAT(Year,"-",Month,"-","01")) as Date,
    Commodity,
    Price_per_Kg,
    avg(Price_per_Kg) OVER(PARTITION BY Commodity,Year ORDER BY Month rows between 11 preceding and current row ) as Moving_Average,
    count(Price_per_Kg) OVER(PARTITION BY Commodity,Year ORDER BY Month rows between 11 preceding and current row ) as Record_count
from (select
    Extract(Year FROM Date) as Year ,
    EXTRACT(Month from Date) as Month ,
    Commodity,
    avg(Price_per_Kg) as Price_per_Kg
from sql_project.india_retail
GROUP BY 1,2,3
order by 3,1,2)
ORDER BY 2,1;

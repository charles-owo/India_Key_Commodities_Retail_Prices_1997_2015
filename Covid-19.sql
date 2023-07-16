select * from sql_project.covid_data order by 1,2 limit 1000
----getting overview of data
select min(date) as start_date , max(date)as last_date
from sql_project.covid_data;

--We're going to work with just Location, Population, Date, total_cases, new_cases, total_deaths,new_deaths
select location, date, population, total_cases, new_cases, total_deaths,new_deaths
from sql_project.covid_data  order by 1,2;

-- Death percentage
select
    location,
    total_population,
    total_cases,
    deaths,
    (total_cases/total_population)*100 as percent_population_affected,
    (deaths/total_cases)*100 as case_fatality_percent,
    (deaths/total_population)*100 as death_rate
from(select
        location,
        max(population)as total_population,
        max(total_cases)as total_cases,
        max(total_deaths)as deaths,
    from sql_project.covid_data
    group by location)
where
    location NOT IN (select DISTINCT(continent) from sql_project.covid_data WHERE continent IS NOT NULL)
    and location NOT IN ('World','Lower middle income','Upper middle income','High income','Low income','European Union')
order by total_population desc ;

---Same But for Continent
select
    *,
    (total_cases/total_population)*100 as percent_population_affected,
    (total_death/total_cases)*100 as case_fatality_percent,
    (total_death/total_population)*100 as death_rate
from(select                         -----Outermost Query
    continent,
    sum(tp) as total_population,
    sum(cd) as total_cases,
    sum(td) as total_death
from(
    select                     -----Outer Query
        continent,
        location ,
        tp,
        td,
        cd
    from(
        select                 -----Innermost Query
            continent,
            location,
            total_deaths,
            new_cases,
            population,
            max(population)Over(partition by continent,location) as tp,
            max(total_deaths) OVER (partition by continent,location) as td,
            max(total_cases) OVER(partition by continent,location) as cd
        from
            sql_project.covid_data
        WHERE
            continent IS NOT NULL )
    GROUP BY continent, location,tp,td,cd)
group by continent) ORDER BY total_death desc ;


--- Calculating Death Percentage by Countries ranked by Highest Human Development Index
with cte as (select
    location,
    max(population) as population,
    max(human_development_index)as HDI,
    max(gdp_per_capita) as gdp,
    max(life_expectancy) as life_expect,
    max(population)as total_population,
    max(total_cases)as total_cases,
    max(total_deaths)as deaths,
from (
         select
             location,
             EXTRACT(YEAR from date)  as Year,
             EXTRACT(MONTH From date) as Month,
             population,
             icu_patients,
             hosp_patients,
             total_tests,
             new_tests,
             gdp_per_capita,
             total_vaccinations,
             people_vaccinated,
             people_fully_vaccinated,
             median_age,
             aged_65_older,
             aged_70_older,
             extreme_poverty,
             male_smokers,
             female_smokers,
             human_development_index,
             life_expectancy,
             total_deaths,
             total_cases,
         from
             sql_project.covid_data
         WHERE location NOT IN (select distinct(continent) from sql_project.covid_data Where continent IS NOT Null)
                and location NOT IN ('European Union','High income','Low income' ,'Lower middle income','Upper middle income','World'))
WHERE human_development_index IS NOT NULL
GROUP BY location )
select location ,
       population,
       HDI,
       gdp,
       (total_cases/total_population)*100 as percent_population_affected,
       (deaths/total_cases)*100 as case_fatality_percent,
       (deaths/total_population)*100 as death_rate
from cte
order by 2 desc ;



--------Analysis of India



---first covid case
select
    date as first_covid_case
from
    sql_project.covid_data
where
    location = "India"
  and total_cases=1;

----Vaccine Coverage

with cte as ( select
                  location,
                  date,
                  EXTRACT(YEAR from date)  as Year,
                  EXTRACT(MONTH From date) as Month,
                  population,
                  icu_patients,
                  hosp_patients,
                  total_tests,
                  new_tests,
                  gdp_per_capita,
                  median_age,
                  aged_65_older,
                  aged_70_older,
                  extreme_poverty,
                  male_smokers,
                  female_smokers,
                  human_development_index,
                  life_expectancy,
                  new_cases,
                  new_vaccinations,
                  total_cases,
                  total_vaccinations,
                  people_vaccinated,
                  people_fully_vaccinated
              from
                  sql_project.covid_data
              where
                      location = 'India'),
dto as (
select location,
       Year,
       Month,
       max(total_vaccinations) as tv,
       max(people_vaccinated) as pv
FROM   cte
GROUP BY location, Year, Month)
select location,Year,Month,pv/tv * 100 as VaccineCoverage from dto
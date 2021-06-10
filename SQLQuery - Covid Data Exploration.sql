/* 
Covid Analysis Data Exploration project 
Source: https://ourworldindata.org/coronavirus
Last Updated data: 2021-06-06 (June 6th, 2021)
--> Skills used: Aggregate Functions, General Exploration, Wildcards, Joins, 
		 CTE's, Temp Tables, Views, Converting Data Types
*/

select * 
from PortfolioProject..covid_deaths 
where continent is not null
order by 3,4 

--select * 
--from PortfolioProject..covid_vaccinations
--order by 3,4 

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..covid_deaths
order by 1, 2

-- Total deaths rate vs Total Cases 
-- Likelihood of dying if you contract covid in your country, using Like+Wildcard
select location, date, total_cases, total_deaths, 
	round(((total_deaths/total_cases)*100),2) as death_percentage
from PortfolioProject..covid_deaths
where location like '%states%'		
order by 1, 2 


-- Total Cases vs Population 
-- Infected percentage of the population 
select location, date, population, total_cases, total_deaths, 
	round(((total_cases/population)*100),2) as 'infected_population%'
from PortfolioProject..covid_deaths
where location like '%states%'
order by 1, 2

-- Countries with Highest infection rate vs its population 
select location, population, max(total_cases) 'Highest_infection_count', 
	round(Max((total_cases/population)*100),2) as infected_rate
from PortfolioProject..covid_deaths
group by location, population
order by infected_rate desc

-- Countries w/ Highest death count per Population
select location, max(cast(total_deaths as int)) total_deaths
from PortfolioProject..covid_deaths
where continent is not null
group by location
order by total_deaths desc

-- BREAKING THINGS DOWN BY CONTINENT 

-- Continents w/ Highest death count
select continent, max(cast(total_deaths as int)) total_deaths
from PortfolioProject..covid_deaths
where continent is not null
group by continent
order by total_deaths desc

-- Global death percentage per day
select date, sum(new_cases) new_cases, sum(cast(new_deaths as int)) deaths,
	round((sum(cast(new_deaths as int))/sum(new_cases)*100),2) as death_percentage
from PortfolioProject..covid_deaths
where continent is not null
group by date
order by 1, 2

-- Global death percentage of new cases vs deaths
select sum(new_cases) new_cases, sum(cast(new_deaths as int)) deaths,   
	concat(round((sum(cast(new_deaths as int))/sum(new_cases)*100),2),'%') as death_percentage
from PortfolioProject..covid_deaths
where continent is not null
order by 1, 2

-- Joining deaths & vaccinations to look for Population vs Vaccinations
-- while doing a Cumulative Sum of Vaccinations by location
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
	sum(cast(v.new_vaccinations as int)) OVER (Partition by d.location order by d.location, d.date) as cumulative_vaccs -- CUMULATIVE SUM by location; partition by location to start over when there's a new location
from PortfolioProject..covid_deaths	d 
join PortfolioProject..covid_vaccinations v
on d.location = v.location and d.date = v.date
where d.continent is not null 
order by 2, 3

-- Creating a CTE to perform calculations on Partition by of previous Query 
With popvsvac (continent, location, date, population, new_vaccinations, cumulative_vaccs)
as (
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
	sum(cast(v.new_vaccinations as int)) OVER (Partition by d.location order by d.location, d.date) as cumulative_vaccs -- CUMULATIVE SUM by location; partition by location to start over when there's a new location
from PortfolioProject..covid_deaths	d 
join PortfolioProject..covid_vaccinations v
on d.location = v.location and d.date = v.date
where d.continent is not null 
-- order by 2, 3) --Not possible to use Order By in Views 
)
Select *, round((cumulative_vaccs/population)*100,3) cumulative_percent
from popvsvac

-- TEMP TABLE 
-- Same as the previous but w/ a Temp Table instead of a CTE 
DROP Table if exists #percent_population_vacc	--for when running this query multiple times 
Create Table #percent_population_vacc
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
cumulative_vaccs numeric
)
Insert into #percent_population_vacc

Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
	sum(cast(v.new_vaccinations as int)) OVER (Partition by d.location order by d.location, d.date) as cumulative_vaccs -- CUMULATIVE SUM by location; partition by location to start over when there's a new location
from PortfolioProject..covid_deaths	d 
join PortfolioProject..covid_vaccinations v
on d.location = v.location and d.date = v.date
where d.continent is not null 

Select *, round((cumulative_vaccs/population)*100,3) cumulative_percent
from #percent_population_vacc

-- Creating a View of Global Vaccination Numbers (to use later in Tableau)
Create View percent_population_vaccinated as 
Select d.continent, d.location, d.date, d.population, v.new_vaccinations,
	sum(cast(v.new_vaccinations as int)) OVER (Partition by d.location order by d.location, d.date) as cumulative_vaccs -- CUMULATIVE SUM by location; partition by location to start over when there's a new location
from PortfolioProject..covid_deaths	d 
join PortfolioProject..covid_vaccinations v
on d.location = v.location and d.date = v.date
where d.continent is not null 


select * 
from percent_population_vaccinated

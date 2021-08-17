/****** Script for SelectTopNRows command from SSMS  ******/
SELECT *
  FROM [IgalTestDB].[dbo].[CovidDeaths]
  order by 3,4

--  /****** Script for SelectTopNRows command from SSMS  ******/
--SELECT *
--  FROM [IgalTestDB].[dbo].CovidVaccinations
--  order by 3,4

--Select data that we are going to be using
Select Location,date, total_cases, new_cases,total_deaths,population 
from IgalTestDB.dbo.CovidDeaths
order by 1,2

--Looking at total cases vs total deaths
--Shows the likelihood of dying if you contract covid in your country
Select Location,date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathsPercentage
from IgalTestDB.dbo.CovidDeaths
where Location like '%Israel%' and total_deaths is not null
order by 1,2

--Looking at total cases vs population
--Shows what percentage of population got covid
Select Location,date,population, total_cases, (total_cases/population)*100 as CasesPercentage
from IgalTestDB.dbo.CovidDeaths
where  total_deaths is not null
order by 1,2

--Looking at Countries with highest infection rate compared to population
Select Location,population, MAX(total_cases) as HighestInfectionCounty, MAX((total_cases/population)*100) as CasesPercentage
from IgalTestDB.dbo.CovidDeaths
where total_deaths is not null
group by Location,population
order by 4 desc

--Looking at Countries with highest Death count per population
Select location, MAX(cast(total_deaths as int)) as TotalDeathsCounty
from IgalTestDB.dbo.CovidDeaths
where total_deaths is not null and continent is not null
group by location
order by 2 desc

--Looking at Continent with highest Death count per population
Select continent, MAX(cast(total_deaths as int)) as TotalDeathsCount
from IgalTestDB.dbo.CovidDeaths
where  continent is not null
group by continent
order by TotalDeathsCount desc

--Global numbers or per country totals and death percentage
select  location,SUM(new_Cases) as TotalCases,SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from CovidDeaths
where continent is not null
group by location
order by 4 desc

--Total Population vs Vaccination
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(cast(vac.new_tests as int)) Over (Partition by dea.location order by dea.location, dea.date),
SUM(cast(vac.new_vaccinations as int)) Over (Partition by dea.location order by dea.location, dea.date) RollingCountVaccinations,
SUM(cast(dea.new_cases as int)) Over (Partition by dea.location order by dea.location, dea.date)
from CovidDeaths as dea
join CovidVaccinations vac 
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null and dea.population is not null and dea.location='Israel'
order by dea.location,dea.date

--Use CTE
With PopVsVac (Continent, Location, Date, Population, new_vaccinations, RollingCountVaccinations)
as
(
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) Over (Partition by dea.location order by dea.location, dea.date) RollingCountVaccinations
from CovidDeaths as dea
join CovidVaccinations vac 
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null and dea.population is not null and dea.location='Israel'

)
select *, (RollingCountVaccinations/Population)*100 from PopVsVac

--Temp Table

--DROP TABLE if exists dbo.#PercentPopulationVaccinated;

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
Population numeric, 
new_vaccinations numeric, 
RollingCountVaccinations numeric
)
Insert into #PercentPopulationVaccinated
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) Over (Partition by dea.location order by dea.location, dea.date) RollingCountVaccinations
from CovidDeaths as dea
join CovidVaccinations vac 
	on dea.location = vac.location 
	and dea.date = vac.date
--where dea.continent is not null and dea.population is not null and dea.location='Israel'

select *, (RollingCountVaccinations/Population)*100 from #PercentPopulationVaccinated

--Create view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated as 
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) Over (Partition by dea.location order by dea.location, dea.date) RollingCountVaccinations
from CovidDeaths as dea
join CovidVaccinations vac 
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null and dea.population is not null and dea.location='Israel'
--order by 1,2
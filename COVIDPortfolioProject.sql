--											 COVID Porfolio Project


--  1.

Select SUM(cast(new_cases as float)) as total_cases, SUM(cast(new_deaths as float)) as total_deaths
, SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2



--  2. 
-- La información extraída en el WHERE statement es para evitar información innecesaria y/o repetida en la consulta

Select location, SUM(cast(new_deaths as float)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%colombia%'
Where continent is null 
and location not in ('World', 'European Union', 'International', 'High income', 
'Upper middle income', 'Lower middle income', 'Low income')
Group by location
order by TotalDeathCount desc



-- 3.

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  
Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%colombia%'
Group by Location, Population
order by PercentPopulationInfected desc



-- 4.

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount, 
Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%colombia%'
Group by Location, Population, date
order by PercentPopulationInfected desc



--5. Vamos a crear una tabla que muestre el porcentaje de poblacion totalmente vacunado 
--  Se creará como una temptable para mas adelante consultarla y saber cual es el pais con mayor 
--  porcentaje de poblacion vacunada y cual con el menor. Asi mismo para cada continente.

DROP table if exists population_percent_vaccinated
CREATE table population_percent_vaccinated
(continent varchar(50),
location varchar(50),
population numeric,
pple_vaccinated numeric,
percent_pple_fully_vaccinated numeric)

INSERT INTO population_percent_vaccinated
SELECT dea.continent, dea.location, dea.population, MAX(CAST(vac.people_fully_vaccinated as FLOAT)) as pple_fully_vaccinated, 
(MAX(CAST(vac.people_fully_vaccinated as FLOAT))/dea.population*100) as percent_pple_fully_vaccinated
FROM CovidDeaths as dea
	JOIN CovidVaccinations as vac
	ON dea.location = vac.location
WHERE dea.continent is not null and dea.location is not null and vac.people_fully_vaccinated is not null
GROUP BY dea.location, dea.continent, dea.population
ORDER BY continent asc, percent_pple_fully_vaccinated desc

SELECT *
FROM population_percent_vaccinated
ORDER BY percent_pple_fully_vaccinated desc


-- Ahora vamos a crear las consultas mencionadas anteriormente.

SELECT continent, AVG(percent_pple_fully_vaccinated) as avg_pple_vaccinated
FROM #population_percent_vaccinated
GROUP BY continent
ORDER BY avg_pple_vaccinated desc



-- 6. 
-- Now we will create a table comparing deaths and vaccinations

SELECT *
FROM CovidDeaths

DROP TABLE if exists deaths
CREATE TABLE deaths
(continent varchar(50),
location varchar (50),
population numeric,
total_cases numeric,
total_deaths numeric,
percentage_of_deaths_from_population float,
percent_of_deaths_from_infected float
)

INSERT INTO deaths
SELECT continent, location, population, SUM(CAST(new_cases as FLOAT)) OVER (PARTITION BY location),
SUM(CAST(new_deaths as FLOAT)) OVER (PARTITION BY location),
(SUM(CAST(new_deaths as FLOAT)) OVER (PARTITION BY location))/population*100,
SUM(CAST(new_deaths as FLOAT)) OVER (PARTITION BY location)/SUM(CAST(new_cases as FLOAT)) OVER (PARTITION BY location)*100
FROM CovidDeaths
WHERE continent is not null and location is not null


SELECT DISTINCT location, continent, population, total_cases, total_deaths, percentage_of_deaths_from_population,
percent_of_deaths_from_infected 
FROM deaths
WHERE location not in ('Hight income', 'Upper middle income','Lower middle income', 'Low income', 'International') 
ORDER BY percentage_of_deaths_from_population desc, percent_of_deaths_from_infected  desc



-- 7. 
-- Ahora vamos a unir la informacion de las personas vacunadas junto con los record de muertes por pais

SELECT DISTINCT dea.location, dea.continent, dea.population, dea.total_cases, dea.total_deaths, dea.percentage_of_deaths_from_population,
dea.percent_of_deaths_from_infected, vac.percent_pple_fully_vaccinated
FROM deaths as dea
	JOIN population_percent_vaccinated as vac
	ON dea.location = vac.location
WHERE dea.location is not null and dea.continent is not null
ORDER BY dea.percent_of_deaths_from_infected desc



-- 8.
-- En esta sección vamos a comparar el # de contagios, # de población que ha muerto y el # de población vacunada 

SELECT dea.location, dea.date, SUM (CAST(dea.new_cases as float)) as Total_cases_per_day, 
SUM(CAST(dea.new_deaths as float)) as Total_deaths_per_day,
SUM(CAST (vac.new_vaccinations as float)) as Total_vaccinations_per_day
FROM CovidDeaths as dea
	JOIN CovidVaccinations as vac
	ON dea.date = vac.date
WHERE dea.continent is not null and dea.location not in ('World', 'High income',
'Upper middle income', 'Europe', 'North America', ' Asia', 'Lower middle income', 'South America', 'European Union',
'Africa', 'Low income', 'Oceania', 'International')
GROUP BY dea.location, dea.date
ORDER BY dea.date

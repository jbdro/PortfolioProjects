--Profiling the CovidDeaths table
SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT null
ORDER BY 3,4;

--Selecting data
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT null
ORDER BY 1,2;

--DATA BY CONTINENT--

--Looking at total cases vs total deaths
--Shows the likelihood of death by continent
SELECT continent,
       SUM(CAST(total_cases AS float)) AS total_cases, 
       SUM(CAST(total_deaths AS float)) AS total_deaths, 
       (SUM(CAST(total_deaths AS float))/SUM(CAST(total_cases AS float)))*100 AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 1;

--Looking at total cases vs population
--Shows what % of population infected by continent
SELECT continent, 
       SUM(CAST(total_cases AS float)) AS total_cases, 
       SUM(CAST(population AS float)) AS total_population, 
       (SUM(CAST(total_cases AS float))/SUM(CAST(population AS float)))*100 AS infected_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 1, 2;

--Loooking at continents with highest infection rate per population
SELECT continent, 
       SUM(CAST(population AS float)) AS total_population, 
       MAX(CAST(total_cases AS int)) AS max_infection_count,
       (MAX(CAST(total_cases AS float))/SUM(CAST(population AS float)))*100 AS infected_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY infected_percentage DESC;

--Breaking highest death count down by continent
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS null AND location NOT IN ('High income','Upper middle income','Lower middle income','Low income')
GROUP BY location
ORDER BY total_death_count DESC;

--DATA BY COUNTRIES--

--Loooking at countries with highest death count
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%' AND (get rid of WHERE)
WHERE continent IS NOT null 
GROUP BY location
ORDER BY total_death_count DESC;

--Looking at total cases vs total deaths
--Shows the likelihood of death by COVID by country
SELECT location,date,total_cases,total_deaths,(CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;

--Looking at total cases vs population
--Shows what % of population got COVID by country
SELECT location,date,total_cases, population,(CAST(total_cases AS float)/CAST(population AS float))*100 AS infected_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%states%' AND continent IS NOT null
ORDER BY 1,2;

--Loooking at countries with highest infection rate per population
SELECT location,population, MAX(CAST(total_cases AS int)) AS max_infection_count,MAX((CAST(total_cases AS float)/CAST(population AS float)))*100 AS infected_percentage
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%states%' AND (get rid of WHERE)
WHERE continent IS NOT null
GROUP BY location, population
ORDER BY infected_percentage DESC;

--DATA BY WORLD--

--By date
SELECT date,
    SUM(CAST(new_cases AS int)) AS total_cases, 
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    CASE 
        WHEN SUM(CAST(new_cases AS float)) = 0 
            THEN 0 
        ELSE (SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float)))*100 
    END AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

--Overall
SELECT
    SUM(CAST(new_cases AS int)) AS total_cases, 
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    CASE 
        WHEN SUM(CAST(new_cases AS float)) = 0 
            THEN 0 
        ELSE (SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float)))*100 
    END AS death_percentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT null
ORDER BY 1;

--Joining .dbos
SELECT *
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
ORDER BY vac.date;

--Looking at total population vs new vaccinations per day; running count
SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations
	,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations_count
	,(rolling_vaccinations_count/population)*100
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
ORDER BY 2,3;

--Using CTE to fix error
WITH PopvsVac (continent,location,date,population,new_vaccinations,rolling_vaccinations_count)
AS
(
SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations
	,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations_count
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
)
SELECT *,(rolling_vaccinations_count/population)*100
FROM PopvsVac

--Using Temp Table to fix error
DROP TABLE IF exists #percent_vaccinated_population
CREATE TABLE #percent_vaccinated_population
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations_count numeric
)

INSERT INTO #percent_vaccinated_population
SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations
	,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations_count
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null

SELECT *,(rolling_vaccinations_count/population)*100
FROM #percent_vaccinated_population;

--Creating view to store data for later visualizations
CREATE VIEW percent_vaccinated_population AS 
SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations
	,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations_count
FROM PortfolioProject.dbo.CovidDeaths AS dea
JOIN PortfolioProject.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null;
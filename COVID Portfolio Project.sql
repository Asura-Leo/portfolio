SELECT *
FROM CovidDeaths
WHERE continent is not null
ORDER BY 2,3

--Selecting data to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Looking at the percentage of total deaths with regards to total cases
SELECT location, date, total_cases, total_deaths,
(CONVERT(FLOAT, total_deaths) / NULLIF(CONVERT(FLOAT, total_cases), 0)) * 100 AS Deathpercentage
FROM CovidDeaths
WHERE location like '%Africa%'
and continent is not null
ORDER BY 1,2

--Showing the percentage of population got COVID
SELECT location, date, population, total_cases,
(CONVERT(FLOAT, total_cases) / NULLIF(CONVERT(FLOAT, population), 0)) * 100 AS population_Infection_percent
FROM CovidDeaths
WHERE location like '%Africa%'
and continent is not null
ORDER BY 1,2

--Looking at countries with the highest infection rate compared to population
SELECT location, population, MAX(total_cases) as highest_infection_count,
(CONVERT(FLOAT, MAX(total_cases)) / NULLIF(CONVERT(FLOAT, population), 0)) * 100 AS population_Infection_percent
FROM CovidDeaths
WHERE continent is not null
GROUP BY population, location
ORDER BY population_Infection_percent DESC

--Looking at countries with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC

--Looking at death percentage of new dates with regards to new cases(grouping by date)
SELECT date, SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths,
(CONVERT(FLOAT, SUM(new_deaths)) / NULLIF(CONVERT(FLOAT, SUM(new_cases)), 0)) * 100 AS Deathpercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--Looking at death percentage of new dates with regards to new cases(grouping by continent)
SELECT continent, SUM(new_cases) AS total_new_cases, SUM(new_deaths) AS total_new_deaths,
(CONVERT(FLOAT, SUM(new_deaths)) / NULLIF(CONVERT(FLOAT, SUM(new_cases)), 0)) * 100 AS Deathpercentage
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY 1,2

--USE CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_vac_count)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vac_count
FROM CovidDeaths dea
JOIN CovidVaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, (rolling_vac_count/population)*100 AS vac_percent
FROM PopvsVac

--TEMP TABLE
DROP TABLE IF exists #PercentPopulationVacc
CREATE TABLE #PercentPopulationVacc
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vac_count numeric
)

INSERT INTO #PercentPopulationVacc
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vac_count
FROM CovidDeaths dea
JOIN CovidVaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
--WHERE dea.continent is not null

SELECT *, (rolling_vac_count/population)*100
FROM #PercentPopulationVacc

--Creating view
CREATE VIEW PercentPopulationVacc AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vac_count
FROM CovidDeaths dea
JOIN CovidVaccinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent is not null

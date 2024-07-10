SELECT*
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

--SELECT*
--From PortfolioProject..CovidVaccinations
--order by 3,4

--Select data thast we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2




--looking at total cases vs total deaths

--Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100
--From PortfolioProject..CovidDeaths
--order by 1,2


---The error you're encountering indicates that one or both of the columns total_cases and total_deaths are of type nvarchar, which is a text data type. In order to perform division, these columns need to be of a numeric type.

--looking at total cases vs total deaths
--shows likelihood of dying if ytou contract covid in your country
SELECT 
    Location, 
    date, 
    total_cases, 
    total_deaths, 
    (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null
ORDER BY 
    1, 2;


--looking at total cases vs population
--Shows what percentage of population got covid

SELECT 
    Location, 
    date, 
	population,
    total_cases,  
    (CAST(total_deaths AS float) / Population) * 100 AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
--Where location like '%states%'
ORDER BY 
    1, 2;

--looking at countries with highest infewction rate compared to population

SELECT 
    Location,  
	population,
    MAX(total_cases) as HighestInfectionCount,  
    MAX((CAST(total_deaths AS float) / Population)) * 100 AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
--Where location like '%states%'
GROUP BY    Location,  
	population
ORDER BY PercentPopulationInfected desc

--Showing countries with highest  Death count  per population

SELECT 
    Location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
GROUP BY    Location
ORDER BY TotalDeathCount desc


--LETS BREAK THINGS DOWN BY CONTINENT




--Showing continents with highest death counts per population

SELECT 
    continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM 
    PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is not null
GROUP BY    continent
ORDER BY TotalDeathCount desc


--Global Numbers


--SELECT  
--    date, 
--    SUM(new_cases) as total_cases,
--	SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
--FROM 
--    PortfolioProject..CovidDeaths
----Where location like '%states%'
--where continent is not null
--Group by date
--ORDER BY 
--    1, 2;

--myway

SELECT   
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS int)) AS total_deaths, 
    CASE 
        WHEN SUM(new_cases) != 0 THEN SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 
        ELSE 0 
    END AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY 
 --   date
ORDER BY 
    1, 2;



--looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


--USE CTE

--with PopvsVac  (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
--as
--(
--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--, SUM(CONVERT(int,vac.new_vaccinations)) OVER (partition by dea.location Order by dea.location, dea.Date) as RollingPeopleVaccinated
----, (RollingPeopleVaccinated/population)*100
--FROM PortfolioProject..CovidDeaths dea
--Join PortfolioProject..CovidVaccinations vac
--	On dea.location = vac.location
--	and dea.date = vac.date
--where dea.continent is not null
----order by 2,3
--)
--Select*, (RollingPeopleVaccinated/population)*100
--FROM PopvsVac


--my way

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.Date) AS RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
SELECT *,
       (RollingPeopleVaccinated / population) * 100 AS PercentVaccinated
FROM PopvsVac;



--Temp Table

DROP Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


INSERT into #PercentPopulationVaccinated
SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.Date) AS RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    --WHERE 
     --   dea.continent IS NOT NULL
		--order by 2,3
	SELECT *,
       (RollingPeopleVaccinated / population) * 100 AS PercentVaccinated
FROM #PercentPopulationVaccinated



--Creating view to store data for later visualization

Create view PercentPopulationVaccinated as
SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
	WHERE 
       dea.continent IS NOT NULL
		--order by 2,3





-- Drop the view if it exists


-- Create the view
-- Drop the view if it exists
IF OBJECT_ID('PercentPopulationVaccinated', 'V') IS NOT NULL
    DROP VIEW PercentPopulationVaccinated;
GO

-- Create the view
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;
GO


IF OBJECT_ID('PercentPopulationVaccinated', 'V') IS NOT NULL
    DROP VIEW PercentPopulationVaccinated;
GO



CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;
GO

select * from PercentPopulationVaccinated





USE mydb;
SELECT *
FROM athlete_events
LIMIT 50;

-- How many olympics games have been held?

SELECT COUNT(DISTINCT Games) AS total_olympic_games
FROM athlete_events
WHERE Games LIKE '%Summer' OR Games LIKE '%Winter'; 

-- List all Olympics games held so far.

SELECT DISTINCT Games
FROM athlete_events
WHERE Games LIKE '%Summer' OR Games LIKE '%Winter'
ORDER BY Games DESC
LIMIT 100;

-- Find the total number of nations who participated in each olympics.

SELECT DISTINCT Games, COUNT(DISTINCT region)
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE Games LIKE '%Summer' OR Games LIKE '%Winter'
GROUP BY Games
ORDER BY Games
LIMIT 100;

-- Which year saw the highest and lowest number of countries participating in the olympics?

SELECT DISTINCT Games, COUNT(DISTINCT region)
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE Games LIKE '%Summer' OR Games LIKE '%Winter'
GROUP BY Games
ORDER BY Games DESC
LIMIT 1; 

SELECT DISTINCT Games, COUNT(DISTINCT region)
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE Games LIKE '%Summer' OR Games LIKE '%Winter'
GROUP BY Games
ORDER BY Games ASC
LIMIT 1;

--  Find the Ratio of male and female athletes participated in all olympic games.

SELECT COUNT(IF(Sex = 'M', 1, NULL)) AS male_count, 
	COUNT(IF(Sex = 'F', 1, NULL)) AS female_count,
COUNT(IF(Sex = 'M', 1, NULL)) / COUNT(IF(Sex = 'F', 1, NULL)) AS ratio
FROM athlete_events
LIMIT 10;

-- Find the top 5 athletes who have won the most gold medals.

SELECT DISTINCT ID, Name, COUNT(Medal) as cnt
FROM athlete_events
WHERE Medal = 'Gold'
GROUP BY ID, Name
ORDER BY cnt DESC
LIMIT 6;

-- Find the top 5 athletes who have won the most medals (gold/silver/bronze).

WITH tbl AS (
SELECT DISTINCT ID, Name, COUNT(Medal) AS cnt
FROM athlete_events
WHERE Medal = 'Gold' OR Medal = 'Silver' OR Medal = 'Bronze'
GROUP BY ID, Name
ORDER BY cnt DESC)
SELECT *, RANK() OVER(ORDER BY cnt DESC) AS most_medals_rank
FROM tbl

-- Find the top 5 most successful countries in olympics. (Success is defined by the number of medals won)

SELECT DISTINCT region, COUNT(Medal) AS cnt
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE Medal = 'Gold' OR Medal = 'Silver' OR Medal = 'Bronze'
GROUP BY region
ORDER BY cnt DESC
LIMIT 5;

-- List the total gold, silver and bronze medals won by each country.

SELECT DISTINCT region, 
COUNT(IF(Medal = 'Gold', 1, NULL)) AS gold_medals, 
COUNT(IF(Medal ='Silver', 1, NULL)) AS silver_medals, 
COUNT(IF(Medal ='Bronze', 1, NULL)) AS bronze_medals
FROM athlete_events JOIN noc_regions USING (NOC)
GROUP BY region
ORDER BY gold_medals DESC;

-- Find the total gold, silver and bronze medals won by each country corresponding to each olympic games.

SELECT DISTINCT Games, region, COUNT(IF(Medal = 'Gold', 1, NULL)) AS gold_medals, 
COUNT(IF(Medal ='Silver', 1, NULL)) AS silver_medals, 
COUNT(IF(Medal ='Bronze', 1, NULL)) AS bronze_medals
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE Games LIKE '%Summer' OR Games LIKE '%Winter' AND Medal IN ('gold', 'bronze', 'silver')
GROUP BY Games, Region
ORDER BY Games, Region
LIMIT 200;

-- In which sport has India has won the most medals.

SELECT DISTINCT Sport, COUNT(Medal) as cnt
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE region = 'India' AND Medal IN ('gold', 'bronze', 'silver')
GROUP BY Sport 
ORDER BY cnt DESC
LIMIT 1;

-- Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.

SELECT Games, COUNT(IF(Medal IN ('gold', 'silver', 'bronze'), 1, NULL)) as cnt
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE region = 'India' AND Sport = 'Hockey'
GROUP BY Games
ORDER BY cnt DESC 
LIMIT 200;

-- Find the oldest athletes who have won gold medals.
SELECT ID, Name, City, Age, Height, weight, medal
FROM athlete_events
WHERE Age <> 'NA' AND Medal = 'Gold'
GROUP BY ID, Name, City, Height, Weight, Age, medal
ORDER BY Age DESC
LIMIT 10;

-- Find the total number of sports played in each olympic games.

SELECT DISTINCT Games, COUNT(DISTINCT Sport) AS sports_cnt
FROM athlete_events
WHERE Games LIKE '%Summer' OR Games LIKE '%Winter'
GROUP BY Games
ORDER BY sports_cnt DESC
LIMIT 100;

-- Identify the sport which was played in all summer olympics.

SELECT COUNT(DISTINCT games)
FROM athlete_events
WHERE Games LIKE '%Summer'
LIMIT 100; -- 29 summer olympics total

SELECT sport, COUNT(1) as cnt
FROM(
SELECT DISTINCT games, sport
FROM athlete_events
WHERE Games LIKE '%Summer'
GROUP BY games, sport
ORDER BY games) as tbl
GROUP by sport
HAVING COUNT(1) = 29
ORDER BY cnt DESC
LIMIT 500;

-- Which Sports were just played only once in the olympics? 

SELECT Sport, COUNT(1) AS cnt
FROM (SELECT DISTINCT games, sport
FROM athlete_events
WHERE Games LIKE '%Summer' OR Games LIKE '%Winter'
GROUP BY games, sport
ORDER BY games) as tbl
GROUP BY sport
HAVING COUNT(1) = 1;

-- Which nation has participated in all of the olympic games? 

SELECT COUNT(DISTINCT Games)
FROM (SELECT DISTINCT games, region
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE Games LIKE '%Winter' OR Games LIKE '%Summer'
GROUP BY Games, region
ORDER BY Games) as tbl; -- total 51 olympic games

SELECT region, COUNT(1) as cnt
FROM (SELECT DISTINCT games, region
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE Games LIKE '%Winter' OR Games LIKE '%Summer'
GROUP BY Games, region
ORDER BY Games) as tbl
GROUP BY region
HAVING COUNT(1) = 51;


-- Which countries have never won a gold medal but have won silver or bronze medals?

SELECT region, medal
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE Medal = 'Gold'
GROUP BY region, medal;

SELECT DISTINCT region, medal
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE region NOT IN (SELECT region
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE Medal = 'Gold'
GROUP BY region, medal)
GROUP BY region, medal
HAVING Medal = 'Silver' OR Medal = 'Bronze'
LIMIT 100;


WITH tbl as (SELECT DISTINCT region, medal
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE region NOT IN (SELECT region
FROM athlete_events JOIN noc_regions USING (NOC)
WHERE Medal = 'Gold'
GROUP BY region, medal)
GROUP BY region, medal
HAVING Medal = 'Silver' OR Medal = 'Bronze'
LIMIT 200)
SELECT distinct region
FROM tbl;



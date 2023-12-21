# World Life Expectancy

# Data cleaning

# Overview of data

SELECT *
FROM world_life_expectancy_staging;
#FROM world_life_expectancy;

# Investigating duplicates
## We are checking if Row_ID is unique
SELECT COUNT(DISTINCT(Row_ID)),  COUNT(Row_ID)
FROM world_life_expectancy_staging;

## Let's check for duplicated rows by data dimensions
## By glancing at the data, we can tell that it shows annual data by country. We can verify duplicate rows on a country & year basis

SELECT ROW_ID
FROM (
        SELECT
        CONCAT(Country, Year),
        ROW_ID,
        ROW_NUMBER() OVER (PARTITION BY CONCAT(Country, Year)
                            ORDER BY CONCAT(Country, Year)) AS row_num
FROM world_life_expectancy_staging
    ) AS row_num_tbl
WHERE row_num > 1; 

## We can identify that row_ids 1252, 2265, and 2929 are duplicates and delete them from table. We do it from world_life_expectancy to keep our staging table pristine

DELETE FROM world_life_expectancy
WHERE Row_ID IN (
SELECT ROW_ID
FROM (
        SELECT
        CONCAT(Country, Year),
        ROW_ID,
        ROW_NUMBER() OVER (PARTITION BY CONCAT(Country, Year)
                            ORDER BY CONCAT(Country, Year)) AS row_num
FROM world_life_expectancy
    ) AS row_num_tbl
WHERE row_num > 1);

## Checking for duplicates again by re-running query gives no results
SELECT ROW_ID
FROM (
        SELECT
        CONCAT(Country, Year),
        ROW_ID,
        ROW_NUMBER() OVER (PARTITION BY CONCAT(Country, Year)
                            ORDER BY CONCAT(Country, Year)) AS row_num
FROM world_life_expectancy
    ) AS row_num_tbl
WHERE row_num > 1; 

# Investigating null and blank values in Status

SELECT *
FROM world_life_expectancy_staging
WHERE Status = "";

## There are a few countries with blank Status. Let's investigate if a country has more than one Status excluding blanks This is important if we want to use existing Status information when re-populating blank Status rows

SELECT COUNT(DISTINCT(Status)), Country
FROM world_life_expectancy
WHERE Status <> ""
GROUP BY Country
HAVING COUNT(DISTINCT(Status)) > 1;

## Every country has been in the same Status for the years reported in this table. Now we can use this information to create a new column

## Here we create a new column StatusMod which has no blank values and compare it to the original column. The only different columns should be the ones with blanks. 

SELECT * FROM
    (SELECT Country, Year, Status,
    CASE
    WHEN Status = "" THEN LAG(Status) OVER()
    ELSE Status
    END AS StatusMod,
    CASE
    WHEN Status = (CASE
                WHEN Status = "" THEN LAG(Status) OVER()
                ELSE Status
                END)
    THEN 1
    ELSE 0
    END AS CheckStatus 
    FROM world_life_expectancy_staging) AS tempquery
WHERE CheckStatus = 0;

## Now we can replace the original Status column with the StatusMod column

ALTER TABLE world_life_expectancy
ADD StatusMod varchar(50)
AFTER `Status`;

#UPDATE world_life_expectancy
#SET StatusMod = 
#CASE
#WHEN Status = "" THEN LAG(Status) OVER()
#ELSE Status
#END;

## MySQL returns that LAG cannot be used in this context, so we try a different approach using the staging (i.e., table without any transformations)

UPDATE world_life_expectancy
SET StatusMod = 'Developing'
WHERE Country IN (SELECT DISTINCT(Country)
                    FROM world_life_expectancy_staging
                    WHERE Status = 'Developing');

UPDATE world_life_expectancy
SET StatusMod = 'Developed'
WHERE Country IN (SELECT DISTINCT(Country)
                    FROM world_life_expectancy_staging
                    WHERE Status = 'Developed');

## We check that only the rows with blanks were modified
SELECT *
FROM world_life_expectancy
WHERE Status <> StatusMod;

## And we replace the column
ALTER TABLE world_life_expectancy
DROP COLUMN Status;

ALTER TABLE world_life_expectancy
CHANGE COLUMN StatusMod Status varchar(50); 

## Investigating missing data in Life expectancy
SELECT Country, Year, CONCAT(Country, Year), `Life expectancy`
FROM world_life_expectancy;

# Let's calculate the AVG of life expectancy between years of missing data using staging table

SELECT
CONCAT(temptbl.Country, temptbl.Year) CountryYear,
ROUND((tbl1.`Life expectancy` + tbl2.`Life expectancy`) / 2, 1) ExpectancyAVG
FROM (SELECT Country, Year, `Life expectancy`
FROM world_life_expectancy_staging
WHERE `Life expectancy` = "") AS temptbl JOIN
world_life_expectancy AS tbl1 ON CONCAT(temptbl.Country, temptbl.Year +1) = CONCAT(tbl1.Country, tbl1.Year) JOIN
world_life_expectancy AS tbl2 ON CONCAT(temptbl.Country, temptbl.Year -1) = CONCAT(tbl2.Country, tbl2.Year);

# Now we fill the blanks with the average of the preceding and suceeding year

UPDATE
world_life_expectancy tbl 
JOIN world_life_expectancy tbl1
    ON CONCAT(tbl.Country, tbl.Year +1) = CONCAT(tbl1.Country, tbl1.Year)
JOIN world_life_expectancy tbl2
    ON CONCAT(tbl.Country, tbl.Year -1) = CONCAT(tbl2.Country, tbl2.Year)
SET tbl.`Life expectancy` = ROUND((tbl1.`Life expectancy` + tbl2.`Life expectancy`) / 2, 1)
WHERE tbl.`Life expectancy` = ""
;

# Exploratory Data Analysis
SELECT
Country,
MIN(`Life expectancy`),
MAX(`Life expectancy`),
ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`), 1) AS ExpectancyGainOrLoss,
IF(MAX(`Life expectancy`) > MIN(`Life expectancy`), 'increased', 'decreased')
FROM world_life_expectancy
GROUP BY
Country
#HAVING IF(MAX(`Life expectancy`) > MIN(`Life expectancy`), 'increased', 'decreased') = 'decreased'
ORDER BY ROUND(MAX(`Life expectancy`) - MIN(`Life expectancy`), 1) DESC;

SELECT
ROUND(AVG(`Life expectancy`),1),
Year
FROM world_life_expectancy
GROUP BY
Year
ORDER BY Year;

## Correlations

SELECT
Country,
ROUND(AVG(`Life expectancy`),0) AVGLifeExpentancy,
ROUND(AVG(GDP),0) AVG_GDP
FROM world_life_expectancy
WHERE `Life expectancy` <> 0 AND GDP <> 0
GROUP BY
Country
ORDER BY AVG_GDP;

SELECT
    *,
    CASE
    WHEN LifeExpectancyClass = GDPClass
    THEN 'Correlated'
    ELSE 'Low or not correlated'
    END AS Correlation
FROM
     (      SELECT
            Country,
            ROUND(AVG(`Life expectancy`),0) AVGLifeExpentancy,
            ROUND(AVG(GDP),0) AVG_GDP,
            CASE
            WHEN ROUND(AVG(`Life expectancy`),0) >= 70
            THEN 'High'
            ELSE 'Low'
            END AS LifeExpectancyClass,
            CASE
            WHEN ROUND(AVG(GDP),0) > 1500
            THEN 'High'
            ELSE 'Low'
            END AS GDPClass
            FROM world_life_expectancy
            WHERE `Life expectancy` <> 0 AND GDP <> 0
            GROUP BY
            Country
    ) TempTbl;
    
SELECT
ROUND(AVG(`Life expectancy`),0) AVGLifeExpentancy,
COUNT(DISTINCT(Country)) AS NumberOfCountries,
Status
FROM world_life_expectancy
GROUP BY
Status;

# Rolling total per country

SELECT
Country,
Year,
`Life expectancy`,
`Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) AS RollingTotal
FROM world_life_expectancy;



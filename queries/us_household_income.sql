# US Household Income

## Let's have an overview of the data

## One table has data on area of land and water per State, City, Geo Coordinates etc in the USA. The other table has data on the mean and median income. The tables are related to each other based on the field id.

SELECT * FROM us_household_income;
SELECT * FROM statistics;

## Identifying duplicates
SELECT
    COUNT(row_id),
    COUNT(id),
    COUNT(DISTINCT(row_id)),
    COUNT(DISTINCT(id))
FROM us_household_income;

## We have come duplicated ids, so we can identify and then remove them 

SELECT
    *
FROM (
        SELECT
            id,
            row_id,
            ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) RowNumber
        FROM
        us_household_income)
    temptbl
WHERE RowNumber > 1;
    
 ## Deleting duplicates   
DELETE FROM us_household_income
WHERE row_id IN (
    SELECT
        row_id
    FROM (
        SELECT
            id,
            row_id,
            ROW_NUMBER() OVER (PARTITION BY id ORDER BY id) RowNumber
        FROM
        us_household_income)
    temptbl
WHERE RowNumber > 1);

## No duplicate issue in Statistics table
SELECT
    COUNT(ID),
    COUNT(DISTINCT(ID))
FROM statistics;

## Let's rename this column
ALTER TABLE statistics
RENAME COLUMN  `ï»¿id` TO ID;

## Let's fix some spelling mistakes
SELECT DISTINCT
State_Name
FROM us_household_income
ORDER BY State_Name ASC;

UPDATE us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

UPDATE us_household_income
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama';

SELECT
    `Primary`,
    COUNT(`Primary`)
FROM
us_household_income
GROUP BY
    `Primary`;
    
UPDATE us_household_income
SET `Primary` = 'Place'
WHERE `Primary` = 'place';

## Let's fill some missing data
UPDATE us_household_income
SET Place = 'Autaugaville'
WHERE City = 'Vinemont'
AND County = 'Autauga County';

## Let's group some data that belong to same category
SELECT
    Type,
    COUNT(Type)
FROM
us_household_income
GROUP BY
    Type;

UPDATE us_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs';

## Let's check for missing data
SELECT
    ALand,
    AWater
FROM
    us_household_income
WHERE AWater IN ('', 0) OR AWater IS NULL OR ALand IN ('', 0) OR ALand IS NULL;

# Exploratory Data Analysis

## Top 10 States regarding land area
SELECT
    State_Name,
    ROUND(SUM(ALand), 0) TotalLandArea,
    ROUND(SUM(AWater), 0) TotalWaterArea
FROM
    us_household_income
GROUP BY
    State_Name
ORDER BY
    SUM(ALand) DESC
    LIMIT 10;
 
## Top 10 States regarding annual income 
## District of Columbia has the highest mean income

SELECT
    tbl1.State_Name State,
    ROUND(AVG(tbl2.Mean), 0) AVGMeanIncome,
    ROUND(AVG(tbl2.Median), 0) AVGMedianIncome
FROM
    us_household_income tbl1 JOIN
    statistics tbl2 ON (tbl1.id = tbl2.id)
WHERE
    tbl2.Mean > 0
GROUP BY
    State
ORDER BY 2 DESC
LIMIT 10;

## Income by type of household
## Municipality Type of household has the highest mean income. It however includes only one data point. We may want to group this data with another Type. CPD might also be grouped with CDP assuming it's a typpo.
SELECT
    tbl1.Type,
    COUNT(tbl1.Type),
    ROUND(AVG(tbl2.Mean), 0) AVGMeanIncome,
    ROUND(AVG(tbl2.Median), 0) AVGMedianIncome
FROM
    us_household_income tbl1 JOIN
    statistics tbl2 ON (tbl1.id = tbl2.id)
WHERE
    tbl2.Mean > 0
GROUP BY
    Type
ORDER BY 3 DESC;

##Top city income in each State
## Here we find out which is the city per state that has the highest mean income

SELECT
    State_Name,
    City,
    AVGMeanIncome
FROM (
    SELECT
        tbl2.State_Name,
        tbl1.City,
        ROUND(AVG(tbl2.Mean), 0) AVGMeanIncome,
        DENSE_RANK() OVER(PARTITION BY tbl2.State_Name ORDER BY AVG(tbl2.Mean) DESC) ranking
    FROM
        us_household_income tbl1 JOIN
        statistics tbl2 ON (tbl1.id = tbl2.id)
    WHERE tbl2.Mean > 0
    GROUP BY
        tbl2.State_Name,
        tbl1.City) temptbl
WHERE ranking = 1
ORDER BY
AVGMeanIncome DESC;




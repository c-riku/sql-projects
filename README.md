# SQL Projects

Data cleaning and exploratory data analysis in **MySQL 8**. Each project starts from raw CSV files, cleans them with SQL, and then explores the cleaned data.

## Projects

### 1. World life expectancy
[`queries/world_life_expectancy.sql`](queries/world_life_expectancy.sql) · data: [`db_seed_files/WorldLifeExpectancy.csv`](db_seed_files/WorldLifeExpectancy.csv)

Annual health and economic indicators per country.

- **Cleaning:** found duplicate country–year rows with `ROW_NUMBER() OVER (PARTITION BY …)` and deleted them; filled blank `Status` values using each country's status in other years; filled missing life expectancy values with the average of the year before and after (self-joins). The raw data stays in a staging table so the original is never changed.
- **Analysis:** life expectancy gain or loss per country, the global average by year, how life expectancy relates to GDP (countries classed as high/low on both), developed vs. developing countries, and rolling totals and year-on-year growth of adult mortality per country and per year.
- **Techniques:** window functions (`ROW_NUMBER`, `LAG`, running `SUM`), CTEs, self-joins, `CASE`, staging tables, aggregation.

### 2. US household income
[`queries/us_household_income.sql`](queries/us_household_income.sql) · data: [`USHouseholdIncome.csv`](db_seed_files/USHouseholdIncome.csv), [`USHouseholdIncome_Statistics.csv`](db_seed_files/USHouseholdIncome_Statistics.csv)

Two related tables, geography (land/water area, city, coordinates) and income statistics (mean and median), joined on `id`.

- **Cleaning:** removed duplicate IDs, fixed a broken column name caused by a byte order mark, corrected misspelled state names, filled missing places, and merged category labels that meant the same thing.
- **Analysis:** top 10 states by land area and by income, income by household type, and the highest-income city in each state.
- **Techniques:** window functions, joins, `GROUP BY`/`HAVING`, `UPDATE` for data correction.

### 3. Bakery database
[`queries/create-bakery-db.sql`](queries/create-bakery-db.sql)

A script that creates a small relational database (products, suppliers, orders, delivery status, customers and employees) with primary and foreign keys and sample data, for practising queries.

## How to run

1. Install MySQL 8 (MySQL Workbench is the easiest way to import data).
2. Create a schema and import each CSV in `db_seed_files/` as a table, using the Table Data Import Wizard:
   - `WorldLifeExpectancy.csv` → `world_life_expectancy` (plus a copy named `world_life_expectancy_staging`)
   - `USHouseholdIncome.csv` → `us_household_income`
   - `USHouseholdIncome_Statistics.csv` → `statistics`
3. Run the queries in `queries/` from top to bottom. The comments explain each step.

The bakery script creates its own database: just run `create-bakery-db.sql`.

## License
[CC0 1.0](LICENSE)

# 🍊 Case study 8: Fresh Segments

## Table of Contents
- [Introduction](#introduction)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question and Solution](#question-and-solution)

***
## Introduction
Danny created Fresh Segments, a digital marketing agency that helps other businesses analyse trends in online ad click behaviour for their unique customer base.

Clients share their customer lists with the Fresh Segments team who then aggregate interest metrics and generate a single dataset worth of metrics for further analysis.

In particular - the composition and rankings for different interests are provided for each client showing the proportion of their customer list who interacted with online assets related to each interest for each month.

Danny has asked for your assistance to analyse aggregated metrics for an example client and provide some high level insights about the customer list and their interests.
## Entity Relationship Diagram
**Table: `Interest Metrics`**
| _month | _year | month_year | interest_id | composition | index_value | ranking | percentile_ranking |
|--------|-------|------------|-------------|-------------|-------------|---------|--------------------|
| 7      | 2018  | 07-2018    | 32486       | 11.89       | 6.19        | 1       | 99.86              |
| 7      | 2018  | 07-2018    | 6106        | 9.93        | 5.31        | 2       | 99.73              |
| 7      | 2018  | 07-2018    | 18923       | 10.85       | 5.29        | 3       | 99.59              |
| 7      | 2018  | 07-2018    | 6344        | 10.32       | 5.1         | 4       | 99.45              |
| 7      | 2018  | 07-2018    | 100         | 10.77       | 5.04        | 5       | 99.31              |
| 7      | 2018  | 07-2018    | 69          | 10.82       | 5.03        | 6       | 99.18              |
| 7      | 2018  | 07-2018    | 79          | 11.21       | 4.97        | 7       | 99.04              |
| 7      | 2018  | 07-2018    | 6111        | 10.71       | 4.83        | 8       | 98.9               |
| 7      | 2018  | 07-2018    | 6214        | 9.71        | 4.83        | 8       | 98.9               |
| 7      | 2018  | 07-2018    | 19422       | 10.11       | 4.81        | 10      | 98.63              |

**Table: `Interest Map`**
| id | interest_name             | interest_summary                                                                   | created_at          | last_modified       |
|----|---------------------------|------------------------------------------------------------------------------------|---------------------|---------------------|
| 1  | Fitness Enthusiasts       | Consumers using fitness tracking apps and websites.                                | 2016-05-26 14:57:59 | 2018-05-23 11:30:12 |
| 2  | Gamers                    | Consumers researching game reviews and cheat codes.                                | 2016-05-26 14:57:59 | 2018-05-23 11:30:12 |
| 3  | Car Enthusiasts           | Readers of automotive news and car reviews.                                        | 2016-05-26 14:57:59 | 2018-05-23 11:30:12 |
| 4  | Luxury Retail Researchers | Consumers researching luxury product reviews and gift ideas.                       | 2016-05-26 14:57:59 | 2018-05-23 11:30:12 |
| 5  | Brides & Wedding Planners | People researching wedding ideas and vendors.                                      | 2016-05-26 14:57:59 | 2018-05-23 11:30:12 |
| 6  | Vacation Planners         | Consumers reading reviews of vacation destinations and accommodations.             | 2016-05-26 14:57:59 | 2018-05-23 11:30:13 |
| 7  | Motorcycle Enthusiasts    | Readers of motorcycle news and reviews.                                            | 2016-05-26 14:57:59 | 2018-05-23 11:30:13 |
| 8  | Business News Readers     | Readers of online business news content.                                           | 2016-05-26 14:57:59 | 2018-05-23 11:30:12 |
| 12 | Thrift Store Shoppers     | Consumers shopping online for clothing at thrift stores and researching locations. | 2016-05-26 14:57:59 | 2018-03-16 13:14:00 |
| 13 | Advertising Professionals | People who read advertising industry news.                                         | 2016-05-26 14:57:59 | 2018-05-23 11:30:12 |


## Question and Solution
### A. Data Exploration and Cleansing

#### 1. Update the `fresh_segments.interest_metrics` table by modifying the `month_year` column to be a date data type with the start of the month
```sql
ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN month_year TYPE DATE
USING TO_DATE(month_year, 'MM-YYYY');
```
month_year column after altering the datatype

| month_year |
|------------|
| 2019-08-01 |
| 2019-07-01 |
| 2019-06-01 |
| 2019-05-01 |
| 2019-04-01 |
| 2019-03-01 |
| 2019-02-01 |
| 2019-01-01 |
| 2018-12-01 |
| 2018-11-01 |
| 2018-10-01 |
| 2018-09-01 |
| 2018-08-01 |
| 2018-07-01 |

#### 2. What is count of records in the `fresh_segments.interest_metrics` for each `month_year` value sorted in chronological order (earliest to latest) with the null values appearing first?
```sql
SELECT
    month_year,
    count(*) AS record_count
FROM fresh_segments.interest_metrics
GROUP BY 1
ORDER BY 1 ASC NULLS FIRST;
```
| month_year | record_count |
|------------|--------------|
| NULL       | 1194         |
| 2018-07-01 | 729          |
| 2018-08-01 | 767          |
| 2018-09-01 | 780          |
| 2018-10-01 | 857          |
| 2018-11-01 | 928          |
| 2018-12-01 | 995          |
| 2019-01-01 | 973          |
| 2019-02-01 | 1121         |
| 2019-03-01 | 1136         |
| 2019-04-01 | 1099         |
| 2019-05-01 | 857          |
| 2019-06-01 | 824          |
| 2019-07-01 | 864          |
| 2019-08-01 | 1149         |

#### 3. What do you think we should do with these null values in the `fresh_segments.interest_metrics`

We should remove them as they are not valid records and will not be useful for our analysis.

```sql
DELETE FROM fresh_segments.interest_metrics
WHERE month_year IS NULL;
```

#### 4. How many `interest_id` values exist in the `fresh_segments.interest_metrics` table but not in the `fresh_segments.interest_map` table? What about the other way around?
```sql
SELECT interest_id::integer AS interest_id_not_in_metrics
FROM fresh_segments.interest_metrics me
EXCEPT DISTINCT
SELECT id
FROM fresh_segments.interest_map ma
```
All the interest_id values exist in the fresh_segments.interest_metrics table also exist in the fresh_segments.interest_map

#### 5. Summarise the `id` values in the `fresh_segments.interest_map` by its total record count in this table

#### 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where `interest_id = 21246` in your joined output and include all columns from `fresh_segments.interest_metrics` and all columns from `fresh_segments.interest_map` except from the id column.
```sql
SELECT
    me.*,
    ma.interest_name,
    ma.interest_summary,
    ma.created_at,
    ma.last_modified
FROM fresh_segments.interest_metrics me
JOIN fresh_segments.interest_map ma ON me.interest_id = ma.id
WHERE me.interest_id = 21246;
```
| _month | _year | month_year | interest_id | composition | index_value | ranking | percentile_ranking | interest_name                    | interest_summary                                      | created_at          | last_modified       |
|--------|-------|------------|-------------|-------------|-------------|---------|--------------------|----------------------------------|-------------------------------------------------------|---------------------|---------------------|
| 7      | 2018  | 2018-07-01 | 21246       | 2.26        | 0.65        | 722     | 0.96               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 8      | 2018  | 2018-08-01 | 21246       | 2.13        | 0.59        | 765     | 0.26               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 9      | 2018  | 2018-09-01 | 21246       | 2.06        | 0.61        | 774     | 0.77               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 10     | 2018  | 2018-10-01 | 21246       | 1.74        | 0.58        | 855     | 0.23               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 11     | 2018  | 2018-11-01 | 21246       | 2.25        | 0.78        | 908     | 2.16               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 12     | 2018  | 2018-12-01 | 21246       | 1.97        | 0.7         | 983     | 1.21               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 1      | 2019  | 2019-01-01 | 21246       | 2.05        | 0.76        | 954     | 1.95               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 2      | 2019  | 2019-02-01 | 21246       | 1.84        | 0.68        | 1109    | 1.07               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 3      | 2019  | 2019-03-01 | 21246       | 1.75        | 0.67        | 1123    | 1.14               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |
| 4      | 2019  | 2019-04-01 | 21246       | 1.58        | 0.63        | 1092    | 0.64               | Readers of El Salvadoran Content | People reading news from El Salvadoran media sources. | 2018-06-11 17:50:04 | 2018-06-11 17:50:04 |

#### 7. Are there any records in your joined table where the `month_year` value is before the `created_at` value from the `fresh_segments.interest_map` table? Do you think these values are valid and why?
```sql
with cte as (
SELECT
    me.*,
    ma.interest_name,
    ma.interest_summary,
    ma.created_at,
    ma.last_modified
FROM fresh_segments.interest_metrics me
JOIN fresh_segments.interest_map ma ON me.interest_id = ma.id
WHERE me.interest_id = 21246
)
SELECT * 
FROM cte
WHERE month_year < created_at;
```
The reulst show no value -> There is no month_year before created_at

If the month_year values exists before created_at then they're not valid 
=> The record in the interest_metrics represents the performance of a specific interest_id based on the client’s customer base interest measured through clicks and interactions -> You can't have user interest or engagement metrics before the interest was even defined/created.

### B. Interest Analysis
#### 1. Which interests have been present in all `month_year` dates in our dataset?

Basically, our dataset has 14 values of month_year so to retrieve the desired interests we just need to count the distinct month_year value group by interest, if the interests value equal to 14 is valid.

```sql
SELECT
    interest_id
FROM fresh_segments.interest_metrics me
GROUP BY 1
HAVING count(DISTINCT month_year) 
    = (SELECT count(distinct month_year) FROM fresh_segments.interest_metrics);
```
We have 480 / 1202 interests are present in all the month_year dates.

**Sample results**
| interest_id | interest_name             |
|-------------|---------------------------|
| 4           | Luxury Retail Researchers |
| 5           | Brides & Wedding Planners |
| 6           | Vacation Planners         |
| 12          | Thrift Store Shoppers     |
| 15          | NBA Fans                  |
| 16          | NCAA Fans                 |
| 17          | MLB Fans                  |

#### 2. Using this same `total_months` measure - calculate the cumulative percentage of all records starting at 14 months - which `total_months` value passes the 90% cumulative percentage value?

```sql
-- Count the total number of months for each interest_id
WITH months_count AS (
SELECT
  interest_id,
  count(DISTINCT month_year) AS total_months
FROM fresh_segments.interest_metrics
WHERE interest_id IS NOT NULL
GROUP BY interest_id
)
-- Count the number of interest_ids for each total_months value
, interests_count AS (
  SELECT
    total_months,
    COUNT(DISTINCT interest_id) AS interest_count
  FROM months_count
  GROUP BY total_months
)

SELECT
  total_months,
  interest_count,
 -- Create running total field using cumulative values of interest count
  ROUND(100 * SUM(interest_count) OVER (ORDER BY total_months DESC) / 
      (SUM(INTEREST_COUNT) OVER ()),2) AS cumulative_percentage
FROM interests_count;
```
| total_months | interest_count | cumulative_percentage |
|--------------|----------------|-----------------------|
| 14           | 480            | 39.93                 |
| 13           | 82             | 46.76                 |
| 12           | 65             | 52.16                 |
| 11           | 94             | 59.98                 |
| 10           | 86             | 67.14                 |
| 9            | 95             | 75.04                 |
| 8            | 67             | 80.62                 |
| 7            | 90             | 88.1                  |
| 6            | 33             | 90.85                 |
| 5            | 38             | 94.01                 |
| 4            | 32             | 96.67                 |
| 3            | 15             | 97.92                 |
| 2            | 12             | 98.92                 |
| 1            | 13             | 100                   |

The interests have 6 months or above account for 90.85%. Interests exist in the range below (total_months from 5 -> 1) this benchmark should be investigated to improve the user interactions.

#### 3. If we were to remove all `interest_id` values which are lower than the `total_months` value we found in the previous question - how many total data points would we be removing?

We found that the cumulative percentage crosses 90% at **total_months = 6** in the previous question.
```sql
-- Step 1: Calculate total_months for each interest_id
WITH months_count AS (
  SELECT
    interest_id,
    COUNT(DISTINCT month_year) AS total_months
  FROM fresh_segments.interest_metrics
  WHERE interest_id IS NOT NULL
  GROUP BY interest_id
)

-- Step 2: Filter out interest_ids with total_months < 6 and count them
SELECT
  COUNT(*) AS removed_interest_ids
FROM months_count
WHERE total_months < 6;
```
|removed_interest_ids|
|---|
|110|

#### 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed `interest` example for your arguments - think about what it means to have less months present from a segment perspective.

#### 5. After removing these interests - how many unique interests are there for each month?
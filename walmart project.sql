select * from walmart
-------------------------------
-- business problems
-- q1- find payment methods with all the transaction and qty sold
SELECT 
    payment_method,
    COUNT(*) AS total_payments,
    SUM(quantity) AS qty_sold
FROM walmart
GROUP BY payment_method;
-------------------------------------
-- q2- identify highest rated category in each branch, displayingg the branch, category avg rating
WITH AvgRatings AS (
    SELECT
        Branch,
        category,
        AVG(rating) AS avg_rating
    FROM walmart
    GROUP BY Branch, category
)
SELECT 
    Branch,
    category,
    avg_rating
FROM (
    SELECT 
        Branch,
        category,
        avg_rating,
        RANK() OVER (PARTITION BY Branch ORDER BY avg_rating DESC) AS `rank`
    FROM AvgRatings
) RankedRatings
WHERE `rank` = 1;
------------------------------------------------
-- q3- identify the business day for each branch based on the number of transactions
WITH PreAggregatedData AS (
    SELECT 
        Branch,
        DAYNAME(STR_TO_DATE(`date`, '%d/%m/%y')) AS day_name,
        COUNT(*) AS num_transactions
    FROM walmart
    GROUP BY Branch, day_name
),
RankedData AS (
    SELECT 
        Branch,
        day_name,
        num_transactions,
        RANK() OVER (PARTITION BY Branch ORDER BY num_transactions DESC) AS `rank`
    FROM PreAggregatedData
)
SELECT *
FROM RankedData
WHERE `rank` = 1;
-------------------------------------------------
-- q4- calculate the totl quantity of items sold per payment methods. list payment methods and total quantity
SELECT 
      payment_method,
      SUM(quantity) as no_qty_sold
FROM walmart
GROUP BY payment_method
-------------------------------------
-- q5- determine the average,minimum,and maximum rating of category products for each city.
-- list the city,average rating,min rating, and max rating

SELECT 
      city,
      category,
      MIN(rating) as min_rating,
	  MAX(rating) as max_rating,
	  AVG(rating) as avg_rating
FROM walmart
GROUP BY city,category
-------------------------------------
-- q6- calculate the total profit for each category by considering total profits as (unit_price * quantity * profit_margin).
-- list category and total profits, ordered from highest to lowest profit.
SELECT
      category,
      SUM(total) as total_revenue,
      SUM(total* profit_margin) as profit
FROM walmart
group by category
-----------------------------------------------
-- q7- determine the most common payment method for each branch. 
-- display branch and the preferred payment methods
WITH cte AS (
    SELECT
        Branch,
        payment_method,
        COUNT(*) AS total_trans,
        RANK() OVER (PARTITION BY Branch ORDER BY COUNT(*) DESC) AS `rank`
    FROM walmart
    GROUP BY Branch, payment_method
)
SELECT * 
FROM cte
WHERE `rank` = 1;
--------------------------
-- q8- categories sales into 3 group morning, afternoon, evening
-- find out which of the shift and number of invoices
SELECT 
    Branch,
    CASE 
        WHEN EXTRACT(HOUR FROM TIME(time)) < 12 THEN 'morning'
        WHEN EXTRACT(HOUR FROM TIME(time)) BETWEEN 12 AND 17 THEN 'afternoon'
        ELSE 'evening'
    END AS day_time,
    COUNT(*) AS transaction_count
FROM walmart
GROUP BY Branch, day_time
ORDER BY Branch, day_time DESC;
----------------------------------------
-- q9- identify 5 branch with highest decrease ratio in revenue compare to last year(current year 2023 and last year 2022)
-- rdr== last_rev-cr_rev/ls_rev*100
WITH RevenueData AS (
    SELECT 
        Branch,
        YEAR(STR_TO_DATE(`date`, '%d/%m/%Y')) AS year,
        SUM(total) AS total_revenue
    FROM walmart
    WHERE YEAR(STR_TO_DATE(`date`, '%d/%m/%Y')) IN (2022, 2023)
    GROUP BY Branch, year
),
RevenueComparison AS (
    SELECT 
        r2022.Branch,
        r2022.total_revenue AS last_year_revenue,
        r2023.total_revenue AS current_year_revenue,
        ROUND(((r2022.total_revenue - r2023.total_revenue) / r2022.total_revenue) * 100, 2) AS rdr
    FROM RevenueData r2022
    JOIN RevenueData r2023
        ON r2022.Branch = r2023.Branch
    WHERE r2022.year = 2022 AND r2023.year = 2023
),
RankedBranches AS (
    SELECT 
        Branch,
        last_year_revenue,
        current_year_revenue,
        rdr,
        RANK() OVER (ORDER BY rdr DESC) AS `rank`
    FROM RevenueComparison
)
SELECT 
    Branch,
    ROUND(last_year_revenue, 2) AS last_year_revenue,
    ROUND(current_year_revenue, 2) AS current_year_revenue,
    rdr
FROM RankedBranches
WHERE `rank` <= 5
ORDER BY rdr DESC;

# Walmart-Sales-Data

**Project Overview** This project is an end-to-end data analysis solution designed to extract critical business insights from Walmart sales data. We utilize Python for data processing and analysis, SQL for advanced querying, and structured problem-solving techniques to solve key business questions. The project is ideal for data analysts looking to develop skills in data manipulation, SQL querying, and data pipeline creation.

---

## **Project Steps**

### **1. Set Up the Environment**

- **Tools Used**: Visual Studio Code (VS Code), Python, SQL (MySQL)
- **Goal**: Create a structured workspace within VS Code and organize project folders for smooth development and data handling.

### **2. Set Up Kaggle API**

- **API Setup**: Obtain your Kaggle API token from Kaggle by navigating to your profile settings and downloading the JSON file.
- **Configure Kaggle**:
  - Place the downloaded `kaggle.json` file in your local `.kaggle` folder.
  - Use the command `kaggle datasets download -d <dataset-path>` to pull datasets directly into your project.

### **3. Download Walmart Sales Data**

- **Data Source**: Use the Kaggle API to download the Walmart sales datasets from Kaggle.
- **Dataset Link**: [Walmart Sales Dataset](https://www.kaggle.com/)
- **Storage**: Save the data in the `data/` folder for easy reference and access.

### **4. Install Required Libraries and Load Data**

- **Libraries**: Install necessary Python libraries using:
  ```bash
  pip install pandas numpy sqlalchemy mysql-connector-python
  ```
- **Loading Data**: Read the data into a Pandas DataFrame for initial analysis and transformations.

### **5. Explore the Data**

- **Goal**: Conduct an initial data exploration to understand data distribution, check column names, types, and identify potential issues.
- **Analysis**: Use functions like `.info()`, `.describe()`, and `.head()` to get a quick overview of the data structure and statistics.

### **6. Data Cleaning**

- **Remove Duplicates**: Identify and remove duplicate entries to avoid skewed results.
- **Handle Missing Values**: Drop rows or columns with missing values if they are insignificant; fill values where essential.
- **Fix Data Types**: Ensure all columns have consistent data types (e.g., dates as `datetime`, prices as `float`).
- **Currency Formatting**: Use `.replace()` to handle and format currency values for analysis.
- **Validation**: Check for any remaining inconsistencies and verify the cleaned data.

### **7. Feature Engineering**

- **Create New Columns**: Calculate the `Total Amount` for each transaction by multiplying `unit_price` by `quantity` and adding this as a new column.
- **Enhance Dataset**: Adding this calculated field will streamline further SQL analysis and aggregation tasks.

### **8. Load Data into MySQL**

- **Set Up Connections**: Connect to MySQL using `sqlalchemy` and load the cleaned data into the database.
- **Table Creation**: Set up tables in MySQL using Python SQLAlchemy to automate table creation and data insertion.
- **Verification**: Run initial SQL queries to confirm that the data has been loaded accurately.

### **9. SQL Analysis: Complex Queries and Business Problem Solving**

This section outlines key business questions and the SQL queries used to answer them. Each query will help to understand and derived the insights .

#### **Q1: Find payment methods with all the transactions and quantity sold**
```sql
SELECT 
    payment_method,
    COUNT(*) AS total_payments,
    SUM(quantity) AS qty_sold
FROM walmart
GROUP BY payment_method;
```

#### **Q2: Identify the highest-rated category in each branch**
*Displays the branch, category, and average rating.*
```sql
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
```

#### **Q3: Identify the business day for each branch based on the number of transactions**
```sql
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
```

#### **Q4: Calculate the total quantity of items sold per payment method**
```sql
SELECT 
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;
```

#### **Q5: Determine the average, minimum, and maximum rating of category products for each city**
```sql
SELECT 
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart
GROUP BY city, category;
```

#### **Q6: Calculate the total profit for each category**
```sql
SELECT
    category,
    SUM(total) AS total_revenue,
    SUM(total * profit_margin) AS profit
FROM walmart
GROUP BY category;
```

#### **Q7: Determine the most common payment method for each branch**
```sql
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
```

#### **Q8: Categorize sales into morning, afternoon, and evening shifts**
```sql
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
```

#### **Q9: Identify the 5 branches with the highest revenue decrease ratio (RDR)**
```sql
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
```

---

## **Requirements**

- **Python**: Version 3.8+
- **SQL Database**: MySQL
- **Python Libraries**:
  - `pandas`, `numpy`, `sqlalchemy`, `mysql-connector-python`
- **Kaggle API Key**: For data downloading

---
## **Results and Insights**
This section include analysis findings:

**Sales Insights:** Key categories, branches with highest sales, and preferred payment methods.
**Profitability:** Insights into the most profitable product categories and locations.
**Customer Behavior:** Trends in ratings, payment preferences, and peak shopping hours.

---
## **Acknowledgments**
**Data Source:** Kaggle’s Walmart Sales Dataset
**Inspiration:** Walmart’s business case studies on sales and supply chain optimization.


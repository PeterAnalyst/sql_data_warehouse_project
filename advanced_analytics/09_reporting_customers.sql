/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO
CREATE VIEW gold.report_customer AS
WITH bases_query AS (
  /*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------*/
SELECT
	S.order_number,
	c.customer_key,
	c.customer_number,
	CONCAT(c.firstname, ' ', c.lastname) AS customer_name,
	c.birthdate,
	C.country,
	s.order_date,
	s.quantity,
	s.product_key,
	s.sales_amount
FROM gold.facts_sales s
LEFT JOIN gold.dim_customer c
ON s.customer_key = c.customer_key
WHERE s.order_date IS NOT NULL
),
aggregated_customer AS(
  /*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
SELECT
	customer_key,
	customer_number,
	customer_name,
	birthdate,
	country,
	DATEDIFF(YEAR, birthdate, GETDATE()) AS age,
	MAX(order_date) AS last_order_date,
	DATEDIFF(MONTH,MIN(order_date), MAX(order_date)) AS lifespan,
	COUNT(DISTINCT order_number) AS total_order,
	COUNT(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_product,
	SUM(sales_amount) AS total_spent
FROM bases_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	birthdate,
	country,
	DATEDIFF(YEAR, birthdate, GETDATE())
)
SELECT
	customer_key,
	customer_number,
	customer_name,
	country,
	age,
	lifespan,
	total_spent,
	CASE 
  		WHEN lifespan >= 12 AND total_spent > 5000 THEN 'VIP'
  		WHEN lifespan >= 12 AND total_spent < 5000 THEN 'REGULAR'
  		ELSE 'NEW'
	END AS customer_segment,
	CASE
  		WHEN age < 20 THEN 'Below 20'
  		WHEN age BETWEEN 20 AND 29 THEN '20 - 29'
  		WHEN age BETWEEN 30 AND 39 THEN '30 - 39'
  		WHEN age BETWEEN 40 AND 49 THEN '40 - 49'
  		ELSE '50 and Above'
	END AS 'age_categories',
	last_order_date,
	DATEDIFF(MONTH,last_order_date, GETDATE()) AS recency,
	total_order,
	total_quantity,
	total_product,
	-- Compute average order value (AVO)
	CASE 
  		WHEN total_order = 0 THEN 0
  		ELSE total_spent/total_order
	END AS avg_order_values,
	-- Compute average monthly spent
	CASE 
  		WHEN lifespan = 0 THEN total_spent
  		ELSE total_spent/lifespan
	END AS avg_monthly_spent
FROM aggregated_customer

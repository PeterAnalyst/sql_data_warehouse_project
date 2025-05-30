/*
==================================================================================================
Product Report
==================================================================================================
Purpose:
	-This report consolidates key product metrics and behaviour.

Highlights:
	1. Gather essential fields such as product name, category, subcategory, and cost.
	2. Segment products by revenue to identify high-performers, MidRange, or Low-Performers
	3. Aggregates products-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in month)
	4. Calculate valuable KPIs:
		- recency (months since last sale)
		- average order revenue (AOR)
		- average monthly revenue
==================================================================================================
*/
-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_products AS

WITH products_metrics AS(
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
  SELECT
      s.order_number,
      s.order_date,
      s.sales_amount,
      s.quantity,
      p.product_name,
      p.product_key,
      p.category,
      p.sub_category,
      p.cost,
      c.customer_key,
      c.country
  FROM gold.facts_sales s
  LEFT JOIN gold.dim_products p
  	ON	p.product_key = s.product_key
  LEFT JOIN gold.dim_customer c
  	ON s.customer_key = c.customer_key
  WHERE order_date IS NOT NULL
  ),
  aggregated_products AS(
  /*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
  SELECT 
    	product_key,
    	product_name,
    	category,
    	sub_category,
    	cost,
    	country,
    	COUNT(DISTINCT order_number) AS total_order,
    	SUM(quantity) AS total_quantity_sold,
    	MAX(order_date) AS first_order_date,
  /*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
  --------------------------------------------------------------------------*/
    	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    	DATEDIFF(MONTH, MAX(order_date), GETDATE()) AS recency,
    	SUM(sales_amount) AS total_sales,
    	COUNT(DISTINCT customer_key) AS total_customers
  FROM products_metrics
  GROUP BY 
    	product_key,
    	product_name,
    	category,
    	sub_category,
    	cost,
    	country
  )
  SELECT 
    	product_key,
    	product_name,
    	category,
    	sub_category,
    	cost,
    	country,
    	total_order,
    	total_quantity_sold,
    	first_order_date,
    	lifespan,
    	recency,
    	total_sales,
    	CASE 
    		WHEN total_sales > 50000 THEN 'High-Performer'
    		WHEN total_sales > 10000 THEN 'Mid-Range'
    		ELSE 'Low-Performer'
    	END AS product_segment,
    	total_customers,
    	ROUND(AVG(CAST(total_sales AS FLOAT)/NULLIF(total_order,0)), 1) AS avg_order_rev,
    	-- average order revenue (AOR)
    	CASE 
    		WHEN lifespan = 0 THEN total_sales
    		ELSE total_sales/lifespan 
    	END AS avg_month_rev
  FROM aggregated_products
  GROUP BY 
    	product_key,
    	product_name,
    	category,
    	sub_category,
    	cost,
    	country,
    	total_order,
    	total_quantity_sold,
    	first_order_date,
    	lifespan,
    	recency,
    	total_sales,
    	total_customers;

/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
  this script performs quality checks to validate the integrity, consistency,
  and accuracy of the Gold layer. 
  These checks ensures:
    - Uniqueness of surrogate keys in dimention tables
    - Referentialintegrity between fact and dimentions tables
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
    - Run these checks after data loading silver layer.
    - Investigate and resolve any discrepancies found during checks
=============================================================================
*/

--=============================================================================
--Checking 'gold.dim_customer '
--=============================================================================
-- Check for the uniqueness of Customer key in gold.dim_customer 
-- Expectation: No Result
SELECT 
	customer_key, 
	COUNT(*) 
FROM gold.dim_customer
GROUP BY customer_key
HAVING COUNT(*) > 1

--=============================================================================
--Checking 'gold.dim_products'
--=============================================================================
-- Check for the uniqueness of Product key in gold.dim_products
-- Expectation: No Result

SELECT 
  product_key,
COUNT(*) AS duplicates
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


--=============================================================================
--Checking 'gold.facts_sales'
--=============================================================================
-- Check the data model connectivity between fact and dimensions

SELECT 
  * 
FROM gold.facts_sales f 
LEFT JOIN gold.dim_customer c 
    ON f.customer_key = c.customer_key 
LEFT JOIN gold.dim_products p 
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL

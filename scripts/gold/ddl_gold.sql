/*
=====================================================================================
DDL Script: Gold Views
=====================================================================================
Script Purpose:
  This script creates views for the Gold layer in the data warehouse.
  The Gold layer represents the final dimention and fact tables(Star Schema)

  Each view performs transformations and combines data from the Silver layer
  to produce a clean, enriched, and business-ready dataset.

Usage:
  - These views can be queried directly for analytics and reporting
===================================================================================
*/
-- ================================================================================
-- Create Dimention: gold.dim_customers
-- ================================================================================
IF OBJECT_ID('gold.dim_customer', 'V') IS NOT NULL
	DROP VIEW gold.dim_customer;
GO

CREATE VIEW gold.dim_customer AS
SELECT
	ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key -- Surrogate key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS firstname,
	ci.cst_lastname AS lastname,
	la.country AS country,
	ci.cst_marital_status AS marital_status,
	CASE 
			WHEN ci.cst_gndr = 'n/a' OR ci.cst_gndr IS NULL THEN COALESCE(ca.gen,'n/a')
			ELSE ci.cst_gndr
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	  ON	ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	  ON	ci.cst_key = la.cid

-- ================================================================================
-- Create Dimention: gold.dim_products
-- ================================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_products;
GO
  
CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY prd_id) AS product_key -- Surrogate key,
	pd.prd_id AS product_id,
	pd.prd_key AS product_number,
	pd.prd_nm AS product_name,
	pd.cat_id AS category_id,
	ca.cat AS category,
	ca.subcat AS sub_category,
	ca.maintenance AS maintenance,
	pd.prd_cost AS cost,
	pd.prd_line AS product_line,
	pd.prd_start_dt AS start_date
FROM silver.crm_prd_info pd
LEFT JOIN silver.erp_px_cat_g1v2 ca
  ON pd.cat_id = ca.id
WHERE prd_end_dt IS NULL;

-- ================================================================================
-- Create Dimention: gold.facts_sales
-- ================================================================================
IF OBJECT_ID('gold.facts_sales', 'V') IS NOT NULL
	DROP VIEW gold.facts_sales;
GO
  
CREATE VIEW gold.facts_sales AS
SELECT 
  sd.sls_ord_num AS order_number,
  cu.customer_key AS customer_key,
  pd.product_key AS product_key,
  sd.sls_order_dt AS order_date,
  sd.sls_ship_dt AS ship_date,
  sd.sls_due_dt AS due_date,
  sd.sls_sales AS sales_amount,
  sd.sls_quantity AS quantity,
  sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_customer cu
    ON  sd.sls_cust_id = cu.customer_id
LEFT JOIN gold.dim_products pd
    ON sd.sls_prd_key = pd.product_number

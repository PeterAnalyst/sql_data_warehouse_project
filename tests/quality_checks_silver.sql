/*
=========================================================================================================
Quality Checks
=========================================================================================================
Script Purpose:
  This script performs various quality checks for data consistency, accuracy, and standardization accross 
  the 'silver' schemas. It includes checks for
  - Null or duplicate primary keys
  - Unwanted spaces in string fields.
  - Data standardization and consistency.
  - Invalid date randes and orders.
  - Data consistency between related fields.

Usage Notes:
   - Run these checks after data loading Silver layer.
   - Investigate and resolve any discrepancies found during the checks.
========================================================================================================
*/

========================================================================================================
-- Checking 'silver.crm_cust_info'
  
--Check for Nulls or Duplicates in primary key
-- EXPECTATION: No Result

SELECT 
cst_id,
COUNT(*) AS number_of_appearance
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id is NULL;



/*So what I am doing here is to check the from the previous codes the primary keys that are duplicates, 
and try take the most recent records by first ranking them by the date of creations and taking the recent record
*/

SELECT 
*
FROM (
SELECT 
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM silver.crm_cust_info
)t WHERE flag_last = 1;



/* Checking for unwanted spaces
EXPECTATION : No Result
If there are spaces eliminate using trim function
*/

SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

--Cleaning 
/* Note that for the standization we checked for every possible senerio both the marital status and gender e.t.c
The idea was to make it a standard and more readable like changing the letter 'S' to single and so on
*/
-- Data Standization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info;
====================================================================================================================
-- Checking 'silver.crm_sales_details'



-- 1. Checking for bad date OR different dates errors
  
---- Expectation : No Negative or ZERO values
SELECT 
*
FROM silver.crm_sales_details
WHERE  sls_ship_dt <=0 OR sls_order_dt <= 0 OR LEN(sls_order_dt) < 8 OR sls_order_dt IS NULL ;

--1 checking error (i.e zero) 
--i
SELECT sls_order_dt
FROM silver.crm_sales_details
WHERE ISDATE(sls_order_dt) = 0 OR LEN(sls_order_dt) != 8;

--ii
SELECT sls_ship_dt
FROM silver.crm_sales_details
WHERE ISDATE(sls_ship_dt) = 0 OR LEN(sls_ship_dt) != 8;

--iii
SELECT sls_due_dt
FROM silver.crm_sales_details
WHERE ISDATE(sls_due_dt) = 0 OR LEN(sls_ship_dt) != 8;

--2 Checking if order date is greater than both ship date and due date
SELECT
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt


--3 CHECKING sls_sales, sls_quantity and sls_price
----- EXPECTATION: No NULL OR Negative Value

SELECT 
sls_sales,
sls_quantity,
sls_price
FROM silver.crm_sales_details
WHERE sls_sales <= 0 OR sls_sales IS NULL OR sls_price <= 0 OR sls_price IS NULL;

====================================================================================================================
-- Checking 'silver.crm_prd_info'

--Checking for Duplicates
-- EXPECTATION: NO Result
SELECT 
prd_id,
COUNT(*) AS number_of_appearance
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;


--Checking for Extra spaces
-- EXPECTATION: No Results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)


--Checking for NULL's or Negative Numbers in prd_cost
-- EXPECTATION: No Results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

--Checking for dates where start date is greater than end date
-- EXPECTATION: No Results
-----DONE
SELECT 
	*
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;


--Standardizing prd_line
-- EXPECTATION: all short words are expected to be in full

SELECT DISTINCT prd_line
FROM silver.crm_prd_info;

====================================================================================================================
-- Checking 'silver.erp_cust_az12'
  
-- Checking for Duplicates
SELECT 
	*,
	ROW_NUMBER() OVER (PARTITION BY cid ORDER BY cid) AS no_of_Appearance
FROM silver.erp_cust_az12;

-- FIXING cid in the silver.erp_cust_az12 to make it fit 

SELECT
*,
CASE WHEN TRIM(cid) LIKE 'NAS%' THEN  SUBSTRING(cid,4,LEN(cid))
	ELSE cid
END AS ID
FROM silver.erp_cust_az12;

--Checking for dates that are over a hundred Years old or dates into the future or NULL 
SELECT 
	*
FROM silver.erp_cust_az12
WHERE bdate IS NULL 
	OR YEAR(bdate) <= YEAR(GETDATE())-100 
	OR YEAR(bdate) >= YEAR(GETDATE());

-- Standardizing gender
SELECT DISTINCT gen
FROM silver.erp_cust_az12;

====================================================================================================================
-- Checking 'silver.erp_loc_a101'

-- DATA NORMALISATION and STANDARDIZATION
-- Checking for duplicate countrys
SELECT DISTINCT country
FROM silver.erp_loc_a101;

====================================================================================================================
-- Checking 'silver.erp_px_cat_g1v2'

-- Checking for duplicates
SELECT DISTINCT cat
FROM silver.erp_px_cat_g1v2;

SELECT DISTINCT subcat
FROM silver.erp_px_cat_g1v2;

SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2;

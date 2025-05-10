/*
===============================================================================
Stored Procedure: Load silver layer (bronze => silver)
===============================================================================
Script Purpose:
	This stored procedure performs the ETL (Extract, Transform, Load) process to 
	populate the 'silver' schema tables from the 'bronze' schema.

	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.

	Parameters:
		None.
		This stored procedure does not accept any parameters or return any values.

	Usage Example:
	EXEC silver.load_silver
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT ' =======================================================';
		PRINT 'Loading silver layer';
		PRINT '=======================================================';

		PRINT '---------------------------------------------------------';
		PRINT 'Loading CRM Tables'
		PRINT '---------------------------------------------------------';

		SET @start_time = GETDATE()
		PRINT '>>> Trucating Table : silver.crm_cust_info';
		--Truncating and Inserting file into silver.crm_cust_info table
		TRUNCATE TABLE silver.crm_cust_info;

		PRINT '>>> Inserting the data into : silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info (cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		SELECT
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE 
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				ELSE 'n/a'
			END cst_marital_status,
			CASE 
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				ELSE 'n/a'
			END cst_gndr,
			cst_create_date
		FROM (
			SELECT 
			*,
			ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
			) t
		WHERE flag_last = 1;
		SET @end_time = GETDATE();
		PRINT '>> Load durations: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
		PRINT '---------------------------------'


		SET @start_time =GETDATE();
		PRINT '>>> Trucating Table : silver.crm_prd_info';
		--Truncating and Inserting file into silver.crm_prd_info table
		TRUNCATE TABLE silver.crm_prd_info;

		PRINT '>>> Inserting the data into: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info (prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,-- I craeted new category key from the original prd_key
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,-- I craeted new prd_key from the original prd_key
			prd_nm,
			ISNULL(prd_cost, 0) AS prd_cost,
			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
			END AS prd_line,
			prd_start_dt,
			DATEADD(DAY,-1,LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
		FROM bronze.crm_prd_info;
		SET @end_time =GETDATE();
		PRINT '>> Load durations: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------------------------';


		SET @start_time =GETDATE()
		PRINT '>>> Trucating Table : silver.crm_sales_details';
		-- Truncating and loading file into silver.crm_sales_details
		TRUNCATE TABLE silver.crm_sales_details;

		PRINT '>>> Inserting the data into: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE 
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END AS sls_order_dt,
			CASE 
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END AS sls_ship_dt,
			CASE 
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END AS sls_due_dt,
			CASE 
				WHEN sls_sales != sls_quantity * ABS(sls_price) OR sls_sales IS NULL THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END AS sls_sales,
			sls_quantity,
			CASE 
				WHEN sls_price <= 0 OR sls_price IS NULL THEN sls_sales / sls_quantity
				ELSE sls_price
			END AS sls_price
		FROM bronze.crm_sales_details
		;
		SET @end_time = GETDATE();
		PRINT '>> Load durations: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '--------------------------------------';



		PRINT '---------------------------------------------------------';
		PRINT 'Loading ERP Tables'
		PRINT '---------------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>>> Trucating Table : silver.erp_cust_az12';
		-- Truncating and loading file into silver.erp_cust_az12 table
		TRUNCATE TABLE silver.erp_cust_az12;

		PRINT '>>> Inserting the data into: silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12(
			cid,
			bdate,
			gen)
		SELECT
			cid,
			bdate,
			gen
		FROM (
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY cid ORDER BY cid) AS counted,
			CASE 
				WHEN TRIM(cid) LIKE 'NAS%' THEN  SUBSTRING(cid,4,LEN(cid))
				ELSE cid
			END AS cid,
			CASE 
				WHEN YEAR(bdate) <YEAR(GETDATE())-100  
					OR YEAR(bdate) > YEAR(GETDATE()) THEN NULL
				ELSE bdate
			END AS bdate,
			CASE
				WHEN TRIM(UPPER(gen)) = 'F' THEN 'Female'
				WHEN TRIM(UPPER(gen)) = 'M' THEN 'Male'
				WHEN TRIM(UPPER(gen)) = '' OR TRIM(UPPER(gen)) IS NULL  THEN 'n/a'
				ELSE gen
			END AS gen
		FROM bronze.erp_cust_az12) AS cleaned
		WHERE counted =1;
		SET @end_time = GETDATE();
		PRINT '>> Load durations: ' + CAST(Datediff(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------------------------';



		SET @start_time = GETDATE();
		PRINT '>>> Trucating Table : silver.erp_loc_a101';
		-- Truncating and loading file into silver.erp_loc_a101 table
		TRUNCATE TABLE silver.erp_loc_a101;

		PRINT '>>> Inserting the data into: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101(
			cid,
			country
		)
		SELECT 
			cid,
			country
		FROM (SELECT
				ROW_NUMBER() OVER (PARTITION BY REPLACE(cid, '-', '') ORDER BY REPLACE(cid, '-', '')) AS counted,
				REPLACE(cid, '-', '') AS cid,
				CASE 
					WHEN TRIM(country) = 'DE' THEN 'Germany'
					WHEN TRIM(country) IN ('US','USA') THEN 'United States'
					WHEN TRIM(country) IS NULL OR TRIM(country) = '' THEN 'n/a'
					ELSE country
				END AS 'country'
			FROM bronze.erp_loc_a101) t
		WHERE counted = 1;
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' +CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '----------------------------';

		SET @start_time = GETDATE();
		PRINT '>>> Trucating Table : silver.erp_px_cat_g1v2';
		-- Truncating and loading file into silver.erp_px_cat_g1v2 table
		TRUNCATE TABLE silver.erp_px_cat_g1v2;

		INSERT INTO silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT * FROM bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
		PRINT '>> Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '----------------------------------'

		SET @batch_end_time = GETDATE()
		PRINT '==================================='
		PRINT 'Loading silver Layer is completed'
		PRINT '>> Total Load duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '==================================='
	END TRY

	BEGIN CATCH
		PRINT '========================================================'
		PRINT 'ERROR OCCURED DURING LOADING silver LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE ();
		PRINT 'Error Message' + CAST(ERROR_NUMBER () AS NVARCHAR);
				PRINT 'Error Message' + CAST(ERROR_STATE () AS NVARCHAR);
		PRINT '========================================================'
	END CATCH

	
	
END


 EXEC silver.load_silver;

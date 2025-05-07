# 🏗️ SQL Data Warehouse Project (Medallion Architecture)

An end-to-end data warehouse built using SQL Server, demonstrating ETL pipelines, data modeling (star schema), and data quality checks.


# 🛠️ Sales Data Pipeline Project

This project demonstrates an end-to-end ETL (Extract, Transform, Load) pipeline using SQL, organized into **Bronze**, **Silver**, and **Gold** layers following the Medallion Architecture pattern. The data originates from CRM and ERP systems and flows through various transformation stages to become analytics-ready.

---

# 📖 Project Overview

The project involves:

1. **Data Architecture**: Designing a Modern Data Warehouse Using Medallion Architecture Bronze, Silver, and Gold layers.
2. **ETL Pipelines**: Extracting, transforming, and loading data from source systems into the warehouse.
3. **Data Modeling**: Developing fact and dimension tables optimized for analytical queries.
4. **Analytics & Reporting**: Creating SQL-based reports and dashboards for actionable insights.

---

## 🎯 Project Goals and Requirements

Data Sources: Import data from two source systems (ERP and CRM) as CSV files.
Data Quality: Pre-clean and fix data quality issues prior to analysis.
Integration: Integrate both sources into a single, user-friendly data model for analytical queries.
Scope: Use the most recent dataset only; historization of data is not required.
Tools used: Microsoft SQL Server, T-SQL
Documentation: Document the data model well in order to address business stakeholders as well as analytics teams

---
# 📁 Project Structure

data-warehouse-project/
│
├── datasets                          |  # Raw datasets used for the project (ERP and CRM data)
├── scripts                           |  # SQL scripts for ETL and transformations
│  ├── bronze                         |  # Scripts for extracting and loading raw data
│  ├── silver                         |  # Scripts for cleaning and transforming data
│  ├── gold                           |  # Scripts for creating analytical models
│
├── tests/                            |  # Test scripts and quality files
│
├── images                            |  # ERD & architecture diagrams
├── README.md                         |  # Project overview and instructions
├── LICENSE                           |  # License information for the repository
├── .gitignore                        |  # Files and directories to be ignored by Git
└── requirements.txt                  |  # Dependencies and requirements for the project

---

## 🔄 Data Pipeline Flow

![Data Pipeline Architecture](images/data_pipeline_architecture.png)

---

## 🌐 Layer Descriptions

###  Bronze Layer
- Raw ingestion of customer, product, and sales data
- No transformation
- Stored in `bronze_layer.sql`

###  Silver Layer
- Cleaned and standardized data
- Data Normalization
- Stored in `silver_layer.sql`

###  Gold Layer
- Cleaned and trusted views for analysis and Modelled into star schema
- Star schema: fact and dimension tables
- Scripts:
  - `gold_dim_customer.sql`
  - `gold_dim_products.sql`
  - `gold_facts_sales.sql`

---

## 📊 Star Schema

![Star Schema ERD](images/star_schema_erd.png)

**Fact Table**:
- `facts_sales` (sales data)

**Dimension Tables**:
- `dim_customer` (customer attributes)
- `dim_products` (product attributes)

---

## 🧹 Data Quality Checks

Stored in `data_quality_checks.sql`

### ✅ Examples:
- Checking for duplicate `customer_id` and `prd_id`
- Cleaning null or invalid genders using fallback from alternate source
- Ensuring only valid products (i.e., `prd_end_dt IS NULL`) are used

```sql
CASE 
  WHEN ci.cst_gndr = 'n/a' OR ci.cst_gndr IS NULL THEN COALESCE(ca.gen,'n/a')
  ELSE ci.cst_gndr
END AS gender
```

🔑 ## Key SQL Views Created

| View Name           | Description                |
| ------------------- | -------------------------- |
| `gold.dim_customer` | Cleaned customer data      |
| `gold.dim_products` | Product info with category |
| `gold.facts_sales`  | Final sales fact table     |


Author
Peter Junior Nwachineke

📧 [Email](peter.j.nwachineke@gmail.com)

💼 [LinkedIn](https://www.linkedin.com/in/peter-j-nwachineke-819291247/)

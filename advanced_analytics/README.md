# Advanced Analytics

This folder contains advanced SQL analytics built on top of the Gold layer from the Medallion Architecture.

Each file focuses on a different type of business insight:

### File Descriptions

| File | Description |
|------|-------------|
| `01_measures_exploration.sql` | Explores key aggregated metrics like total sales, profit, and customer count. |
| `02_magnitude_analysis.sql` | Measures the size of variables (e.g., total revenue by product or region). |
| `03_ranking_analysis.sql` | Ranks entities such as products or customers by sales, revenue, or profit. |
| `04_change_over_time.sql` | Analyzes trends such as monthly growth, year-over-year comparisons. |
| `05_cumulative_analysis.sql` | Shows running totals or cumulative performance metrics. |
| `06_performance_analysis.sql` | Evaluates KPIs like profit margins, sales targets, and category performance. |
| `07_data_segmentation.sql` | Breaks down data by customer segments, product categories, or regions. |
| `08_part_to_whole.sql` | Analyzes parts of a whole — e.g., product contributions to total revenue. |
| `09_reporting_customers.sql` | Summarizes customer behavior such as repeat purchases, loyalty, etc. |
| `10_report_products.sql` | Provides reports on top-performing or underperforming products. |

---

### 🔍 Data Source
These SQL scripts were developed using the Gold layer outputs from the [SQL Data Warehouse Project](https://github.com/PeterAnalyst/sql_data_warehouse_project).

---

### 🛠️ Tools
- SQL Server
- Medallion Architecture (Bronze → Silver → Gold → Advanced Analytics)

---

### 📌 Note
Each script is self-contained and modular. You can run them directly on the Gold-layer tables (after all previous transformations have been completed).

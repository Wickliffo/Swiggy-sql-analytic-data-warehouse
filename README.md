<img width="1024" height="1536" alt="A star schema diagra" src="https://github.com/user-attachments/assets/229d34ff-6275-48d8-ab62-f84dad770410" />
# 🍽️ Swiggy Data Warehouse Project

## 📌 Overview
This project demonstrates the **end-to-end process of building a star schema data warehouse** for Swiggy orders data.  
It covers **data validation, cleaning, dimensional modeling, ETL pipeline creation, indexing, and KPI reporting** using SQL Server.

---

## 🛠️ Steps Taken

### 1️⃣ Data Validation & Cleaning
- Checked for **NULL values** across key fields (State, City, Order_Date, Restaurant_Name, etc.).
- Converted **blank strings to NULLs** for consistency.
- Removed **duplicate records** using a `ROW_NUMBER()` CTE.
- ✅ **Problem solved:** Ensured data integrity and consistency before loading into the warehouse.

---

### 2️⃣ Schema Design (Star Schema)
- Created **dimension tables**:
  - `dim_date` → calendar attributes (Year, Month, Quarter, Week, Day).
  - `dim_location` → State, City, Location.
  - `dim_restaurant` → Restaurant names.
  - `dim_category` → Food categories.
  - `dim_dish` → Dish names.
- Created **fact table**:
  - `fact_swiggy_orders` → Measures (Price, Rating, Rating_Count) linked to dimensions.
- ✅ **Problem solved:** Structured the data into a **star schema** for efficient analytics.

---

### 3️⃣ Populating Dimension Tables
- Inserted **distinct values** from source data into each dimension.
- Ensured **referential integrity** by linking fact table foreign keys to dimensions.
- ✅ **Problem solved:** Avoided redundancy and ensured clean dimension lookups.

---

### 4️⃣ Populating Fact Table
- Loaded transactional data into `fact_swiggy_orders` by joining with dimension tables.
- ✅ **Problem solved:** Established a **central fact table** for analysis.

---

### 5️⃣ Performance Optimization
- Created **indexes** on source and dimension tables.
- Indexed **foreign keys** in the fact table for faster joins.
- ✅ **Problem solved:** Improved query performance for large datasets.

---

### 6️⃣ Validation & KPIs
- Verified row counts between source and fact tables.
- Built **KPI queries**:
  - Total Orders
  - Total Revenue
  - Average Dish Price
  - Average Rating
- ✅ **Problem solved:** Confirmed data accuracy and produced meaningful business insights.

---

### 7️⃣ Trend Analysis
- **Monthly Trends** → Orders grouped by Year, Month, Month_Name.  
- **Quarterly Trends** → Orders grouped by Year and Quarter.  
- **Yearly Trends** → Orders grouped by Year.  
- **Weekly Trends** → Orders grouped by weekday (Mon–Sun).  
- **Top Cities** → Ranked by order volume.  
- ✅ **Problem solved:** Delivered **time-based and location-based insights** for decision-making.

---

## 📊 Key Learnings
- Importance of **data cleaning** before ETL.  
- How to design and populate a **star schema**.  
- Using **indexes** to optimize query performance.  
- Building **KPI dashboards** directly from SQL queries.  

---

## 🚀 Next Steps
- Connect the warehouse to **Power BI** for interactive dashboards.  
- Automate ETL with **Azure Data Factory**.  
- Extend schema with **customer and delivery dimensions**.  

---

## ⚖️ Tech Stack
- **SQL Server** (ETL + schema design + KPIs)  
- **T-SQL** (queries, joins, indexing)  
- **Data Warehouse Modeling** (Star Schema)  

---

## 📌 Author
👤 **Wickliff**  
Focused on **data engineering, ETL pipelines, and analytics** for Kenya’s digital economy.  

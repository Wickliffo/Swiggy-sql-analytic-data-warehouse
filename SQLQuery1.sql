-- ============================================================
-- 1️⃣ DATA VALIDATION AND CLEANING
-- ============================================================

-- Check for NULLs
SELECT  
      SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
      SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
      SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
      SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant_name,
      SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
      SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
      SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_dish_name,
      SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price_inr,
      SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
      SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM dbo.Swiggy_Data;

-- Convert blanks to NULLs for consistency
UPDATE dbo.Swiggy_Data
SET State = NULL WHERE State = '';
UPDATE dbo.Swiggy_Data
SET City = NULL WHERE City = '';
UPDATE dbo.Swiggy_Data
SET Location = NULL WHERE Location = '';
UPDATE dbo.Swiggy_Data
SET Restaurant_Name = NULL WHERE Restaurant_Name = '';
UPDATE dbo.Swiggy_Data
SET Category = NULL WHERE Category = '';
UPDATE dbo.Swiggy_Data
SET Dish_Name = NULL WHERE Dish_Name = '';

-- Remove duplicates
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
                PARTITION BY City, Order_Date, Restaurant_Name, Location,
                             Category, Dish_Name, Price_INR, Rating, Rating_Count
                ORDER BY (SELECT NULL)
           ) AS rn
    FROM dbo.Swiggy_Data
)
DELETE FROM cte WHERE rn > 1;

-- ============================================================
-- 2️⃣ CREATE DIMENSION TABLES
-- ============================================================

-- dim_date
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_date')
BEGIN
    CREATE TABLE dbo.dim_date(
        date_id INT IDENTITY(1,1) PRIMARY KEY,
        Full_date DATE,
        Year INT,
        Month INT,
        Month_Name VARCHAR(20),
        Quarter INT,
        Week INT,
        Day INT
    );
END

-- dim_location
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_location')
BEGIN
    CREATE TABLE dbo.dim_location(
        location_id INT IDENTITY(1,1) PRIMARY KEY,
        State VARCHAR(150),
        City VARCHAR(150),
        Location VARCHAR(150)
    );
END

-- dim_restaurant (fixed spelling)
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_restaurant')
BEGIN
    CREATE TABLE dbo.dim_restaurant(
        restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
        Restaurant_Name VARCHAR(150)
    );
END

-- dim_category
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_category')
BEGIN
    CREATE TABLE dbo.dim_category(
        category_id INT IDENTITY(1,1) PRIMARY KEY,
        Category VARCHAR(200)
    );
END

-- dim_dish
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_dish')
BEGIN
    CREATE TABLE dbo.dim_dish(
        dish_id INT IDENTITY(1,1) PRIMARY KEY,
        Dish_Name VARCHAR(200)
    );
END

-- fact_swiggy_orders
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'fact_swiggy_orders')
BEGIN
    CREATE TABLE dbo.fact_swiggy_orders(
        order_id INT IDENTITY(1,1) PRIMARY KEY,
        date_id INT,
        Price_INR DECIMAL(10,2),
        Rating DECIMAL(4,2),
        Rating_Count INT,
        location_id INT,
        restaurant_id INT,
        category_id INT,
        dish_id INT,
        CONSTRAINT FK_fact_date FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
        CONSTRAINT FK_fact_location FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
        CONSTRAINT FK_fact_restaurant FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
        CONSTRAINT FK_fact_category FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
        CONSTRAINT FK_fact_dish FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
    );
END

-- ============================================================
-- 3️⃣ POPULATE DIMENSION TABLES
-- ============================================================

-- Clear dimensions before reload (optional if incremental)
TRUNCATE TABLE dim_date;
TRUNCATE TABLE dim_location;
TRUNCATE TABLE dim_restaurant;
TRUNCATE TABLE dim_category;
TRUNCATE TABLE dim_dish;

-- dim_date
INSERT INTO dim_date (Full_date, Year, Month, Month_Name, Quarter, Week, Day)
SELECT DISTINCT
    Order_Date,
    YEAR(Order_Date),
    MONTH(Order_Date),
    DATENAME(MONTH, Order_Date),
    DATEPART(QUARTER, Order_Date),
    DATEPART(WEEK, Order_Date),
    DAY(Order_Date)
FROM dbo.Swiggy_Data
WHERE Order_Date IS NOT NULL;

-- dim_location
INSERT INTO dim_location(State, City, Location)
SELECT DISTINCT State, City, Location
FROM dbo.Swiggy_Data
WHERE State IS NOT NULL AND City IS NOT NULL AND Location IS NOT NULL;

-- dim_restaurant
INSERT INTO dim_restaurant(Restaurant_Name)
SELECT DISTINCT Restaurant_Name
FROM dbo.Swiggy_Data
WHERE Restaurant_Name IS NOT NULL;

-- dim_category
INSERT INTO dim_category(Category)
SELECT DISTINCT Category
FROM dbo.Swiggy_Data
WHERE Category IS NOT NULL;

-- dim_dish
INSERT INTO dim_dish(Dish_Name)
SELECT DISTINCT Dish_Name
FROM dbo.Swiggy_Data
WHERE Dish_Name IS NOT NULL;

-- ============================================================
-- 4️⃣ POPULATE FACT TABLE
-- ============================================================

TRUNCATE TABLE fact_swiggy_orders;

INSERT INTO fact_swiggy_orders(
    date_id, Price_INR, Rating, Rating_Count,
    location_id, restaurant_id, category_id, dish_id
)
SELECT
    dd.date_id,
    s.Price_INR,
    s.Rating,
    s.Rating_Count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM dbo.Swiggy_Data s
JOIN dim_date dd ON dd.Full_date = s.Order_Date
JOIN dim_location dl ON dl.State = s.State AND dl.City = s.City AND dl.Location = s.Location
JOIN dim_restaurant dr ON dr.Restaurant_Name = s.Restaurant_Name
JOIN dim_category dc ON dc.Category = s.Category
JOIN dim_dish dsh ON dsh.Dish_Name = s.Dish_Name;

-- ============================================================
-- 5️⃣ CREATE INDEXES FOR PERFORMANCE
-- ============================================================

-- On source table
CREATE INDEX idx_swiggy_order_date ON dbo.Swiggy_Data(Order_Date);
CREATE INDEX idx_swiggy_location ON dbo.Swiggy_Data(State, City, Location);
CREATE INDEX idx_swiggy_restaurant ON dbo.Swiggy_Data(Restaurant_Name);
CREATE INDEX idx_swiggy_category ON dbo.Swiggy_Data(Category);
CREATE INDEX idx_swiggy_dish ON dbo.Swiggy_Data(Dish_Name);

-- On dimension tables
CREATE UNIQUE INDEX idx_dim_restaurant_name ON dbo.dim_restaurant(Restaurant_Name);
CREATE UNIQUE INDEX idx_dim_category ON dbo.dim_category(Category);
CREATE UNIQUE INDEX idx_dim_dish ON dbo.dim_dish(Dish_Name);
CREATE UNIQUE INDEX idx_dim_location ON dbo.dim_location(State, City, Location);
CREATE UNIQUE INDEX idx_dim_date_full ON dbo.dim_date(Full_date);

-- On fact table foreign keys
CREATE INDEX idx_fact_date ON dbo.fact_swiggy_orders(date_id);
CREATE INDEX idx_fact_location ON dbo.fact_swiggy_orders(location_id);
CREATE INDEX idx_fact_restaurant ON dbo.fact_swiggy_orders(restaurant_id);
CREATE INDEX idx_fact_category ON dbo.fact_swiggy_orders(category_id);
CREATE INDEX idx_fact_dish ON dbo.fact_swiggy_orders(dish_id);

-- ============================================================
-- 6️⃣ VALIDATION
-- ============================================================

SELECT COUNT(*) AS total_source_rows FROM dbo.Swiggy_Data;
SELECT COUNT(*) AS total_fact_rows FROM dbo.fact_swiggy_orders;

SELECT TOP 10 *
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
JOIN dim_category c ON f.category_id = c.category_id
JOIN dim_dish ds ON f.dish_id = ds.dish_id;

--KPI 
--TOTAL ORDERS
SELECT COUNT(*) AS Total_Orders
FROM fact_swiggy_orders;

-- TOTAL REVENUES
SELECT FORMAT(SUM(CONVERT (FLOAT ,Price_INR))/1000000,'N2')+ 'INR million' AS Total_Revenue
FROM fact_swiggy_orders;

--AVERAGE DISH PRICE
SELECT FORMAT(AVG(CONVERT (FLOAT ,Price_INR)),'N2')+ 'INR ' AS Total_Average
FROM fact_swiggy_orders;
--AVERAGE RATING
SELECT AVG(Rating) AS  Avg_rating
FROM fact_swiggy_orders;

--Monthly order trends
SELECT d.Year,d.Month,d.Month_Name,
COUNT(*) AS Total_Month_Trend
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year,d.Month,d.Month_Name
ORDER BY SUM(Price_INR) DESC

--QUARTELY TRENDS
SELECT d.Year,d.Quarter,
COUNT(*) AS Total_quarter_Trend
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year,d.Quarter
ORDER BY d.Year,d.Quarter


-- YEARLY TRENDS
SELECT d.Year,
COUNT(*) AS Total_quarter_Trend
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year

--WEEKLY TRENDS MONDAY - SUNDAY
SELECT 
     DATENAME(WEEKDAY,d.Full_date) AS day_name,
     COUNT(*) AS Total_orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY DATENAME(WEEKDAY,d.Full_date) ,DATEPART(WEEKDAY,d.Full_date)
ORDER BY DATEPART(WEEKDAY,d.Full_date)

-- TOP 10 CITIES BY ORDER VOLUME
SELECT TOP 10
l.City,
COUNT(*) AS Total_Order
FROM fact_swiggy_orders f
JOIN dim_location l 
ON l.location_id = f.location_id
GROUP BY l.City
ORDER BY COUNT(*) DESC



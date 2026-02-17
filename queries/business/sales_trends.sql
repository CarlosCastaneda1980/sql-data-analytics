-- Sales Trend Analytics Queries
-- These queries help identify sales patterns and trends

-- Year-over-year sales comparison
SELECT 
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    SUM(total_amount) AS monthly_revenue,
    LAG(SUM(total_amount)) OVER (PARTITION BY MONTH(order_date) ORDER BY YEAR(order_date)) AS prev_year_revenue,
    ROUND(((SUM(total_amount) - LAG(SUM(total_amount)) OVER (PARTITION BY MONTH(order_date) ORDER BY YEAR(order_date))) / 
           LAG(SUM(total_amount)) OVER (PARTITION BY MONTH(order_date) ORDER BY YEAR(order_date))) * 100, 2) AS yoy_growth_pct
FROM orders
WHERE status = 'completed'
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY year DESC, month DESC;

-- Sales by day of week
SELECT 
    DAYNAME(order_date) AS day_of_week,
    DAYOFWEEK(order_date) AS day_num,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value
FROM orders
WHERE status = 'completed'
GROUP BY DAYNAME(order_date), DAYOFWEEK(order_date)
ORDER BY day_num;

-- Sales by hour of day
SELECT 
    HOUR(order_date) AS hour_of_day,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_order_value
FROM orders
WHERE status = 'completed'
GROUP BY HOUR(order_date)
ORDER BY hour_of_day;

-- Best and worst performing products
(
    SELECT 
        'Top 5 Best Sellers' AS category,
        p.product_name,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY p.product_id, p.product_name
    ORDER BY units_sold DESC
    LIMIT 5
)
UNION ALL
(
    SELECT 
        'Bottom 5 Sellers' AS category,
        p.product_name,
        SUM(oi.quantity) AS units_sold,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY p.product_id, p.product_name
    ORDER BY units_sold ASC
    LIMIT 5
);

-- Moving average of daily sales (7-day)
WITH daily_sales AS (
    SELECT 
        DATE(order_date) AS sale_date,
        SUM(total_amount) AS daily_revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY DATE(order_date)
)
SELECT 
    sale_date,
    daily_revenue,
    AVG(daily_revenue) OVER (ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7day
FROM daily_sales
ORDER BY sale_date DESC;

-- Sales velocity (orders per day trend)
SELECT 
    DATE(order_date) AS order_day,
    COUNT(order_id) AS orders_count,
    SUM(total_amount) AS revenue,
    COUNT(order_id) / 24.0 AS orders_per_hour,
    AVG(COUNT(order_id)) OVER (ORDER BY DATE(order_date) ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_orders_7day
FROM orders
WHERE status = 'completed'
    AND order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(order_date)
ORDER BY order_day DESC;

-- Seasonal sales patterns
SELECT 
    QUARTER(order_date) AS quarter,
    YEAR(order_date) AS year,
    SUM(total_amount) AS quarterly_revenue,
    COUNT(DISTINCT order_id) AS total_orders,
    AVG(total_amount) AS avg_order_value
FROM orders
WHERE status = 'completed'
GROUP BY QUARTER(order_date), YEAR(order_date)
ORDER BY year DESC, quarter DESC;

-- Product category trends over time
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    p.category,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m'), p.category
ORDER BY month DESC, revenue DESC;

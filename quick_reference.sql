-- ============================================
-- Quick Reference Guide
-- ============================================
-- This file provides quick snippets for common
-- analytics tasks. Use these as starting points
-- for your own custom queries.
-- ============================================

-- ==========================================
-- QUICK INSIGHTS
-- ==========================================

-- Get overall business metrics at a glance
SELECT 
    (SELECT COUNT(*) FROM customers WHERE customer_status = 'active') AS active_customers,
    (SELECT COUNT(*) FROM orders WHERE order_status = 'completed') AS total_orders,
    (SELECT ROUND(SUM(order_amount), 2) FROM orders WHERE order_status = 'completed') AS total_revenue,
    (SELECT ROUND(AVG(order_amount), 2) FROM orders WHERE order_status = 'completed') AS avg_order_value,
    (SELECT COUNT(DISTINCT customer_id) FROM orders WHERE order_status = 'completed') AS customers_with_orders;

-- ==========================================
-- TOP LISTS
-- ==========================================

-- Top 5 customers by revenue
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    ROUND(SUM(o.order_amount), 2) AS total_revenue
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'completed'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
ORDER BY total_revenue DESC
LIMIT 5;

-- Top 5 product categories by revenue
SELECT 
    product_category,
    COUNT(*) AS order_count,
    ROUND(SUM(order_amount), 2) AS total_revenue
FROM orders
WHERE order_status = 'completed'
GROUP BY product_category
ORDER BY total_revenue DESC
LIMIT 5;

-- ==========================================
-- CUSTOMER VALUE ANALYSIS
-- ==========================================

-- Quick customer value classification
SELECT 
    CASE 
        WHEN SUM(o.order_amount) >= 3000 THEN 'High Value'
        WHEN SUM(o.order_amount) >= 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS segment,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    ROUND(SUM(o.order_amount), 2) AS total_revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_status = 'completed'
WHERE c.customer_status = 'active'
GROUP BY segment
ORDER BY total_revenue DESC;

-- ==========================================
-- RECENT ACTIVITY
-- ==========================================

-- Orders in the last 30 days
SELECT 
    COUNT(*) AS recent_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(order_amount), 2) AS revenue_last_30_days,
    ROUND(AVG(order_amount), 2) AS avg_order_value
FROM orders
WHERE order_status = 'completed'
    AND order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY);

-- Customers who haven't ordered in 90+ days (at risk)
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(CURRENT_DATE, MAX(o.order_date)) AS days_since_last_order
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'completed'
    AND c.customer_status = 'active'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
HAVING days_since_last_order >= 90
ORDER BY days_since_last_order DESC;

-- ==========================================
-- GROWTH METRICS
-- ==========================================

-- Month-over-month revenue comparison (current vs previous month)
WITH current_month AS (
    SELECT 
        ROUND(SUM(order_amount), 2) AS revenue
    FROM orders
    WHERE order_status = 'completed'
        AND DATE_FORMAT(order_date, '%Y-%m') = DATE_FORMAT(CURRENT_DATE, '%Y-%m')
),
previous_month AS (
    SELECT 
        ROUND(SUM(order_amount), 2) AS revenue
    FROM orders
    WHERE order_status = 'completed'
        AND DATE_FORMAT(order_date, '%Y-%m') = DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH), '%Y-%m')
)
SELECT 
    c.revenue AS current_month_revenue,
    p.revenue AS previous_month_revenue,
    ROUND(c.revenue - p.revenue, 2) AS revenue_change,
    ROUND((c.revenue - p.revenue) * 100.0 / NULLIF(p.revenue, 0), 2) AS growth_percentage
FROM current_month c, previous_month p;

-- ==========================================
-- CUSTOMER ACQUISITION
-- ==========================================

-- New customers by month
SELECT 
    DATE_FORMAT(registration_date, '%Y-%m') AS month,
    COUNT(*) AS new_customers
FROM customers
WHERE customer_status = 'active'
GROUP BY DATE_FORMAT(registration_date, '%Y-%m')
ORDER BY month DESC
LIMIT 12;

-- New customer conversion rate (% who made first purchase)
SELECT 
    DATE_FORMAT(c.registration_date, '%Y-%m') AS registration_month,
    COUNT(DISTINCT c.customer_id) AS new_customers,
    COUNT(DISTINCT o.customer_id) AS customers_who_purchased,
    ROUND(COUNT(DISTINCT o.customer_id) * 100.0 / COUNT(DISTINCT c.customer_id), 2) AS conversion_rate
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_status = 'completed'
WHERE c.customer_status = 'active'
GROUP BY DATE_FORMAT(c.registration_date, '%Y-%m')
ORDER BY registration_month DESC
LIMIT 12;

-- ==========================================
-- PRODUCT PERFORMANCE
-- ==========================================

-- Product category trends (last 3 months)
SELECT 
    product_category,
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(*) AS orders,
    ROUND(SUM(order_amount), 2) AS revenue
FROM orders
WHERE order_status = 'completed'
    AND order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 3 MONTH)
GROUP BY product_category, DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month DESC, revenue DESC;

-- ==========================================
-- GEOGRAPHIC INSIGHTS
-- ==========================================

-- Top states by revenue
SELECT 
    c.state,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(o.order_id) AS orders,
    ROUND(SUM(o.order_amount), 2) AS total_revenue,
    ROUND(SUM(o.order_amount) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'completed'
    AND c.customer_status = 'active'
GROUP BY c.state
ORDER BY total_revenue DESC
LIMIT 10;

-- ==========================================
-- CUSTOM QUERIES TEMPLATE
-- ==========================================

-- Template: Filter by date range
/*
SELECT ...
FROM orders o
WHERE o.order_status = 'completed'
    AND o.order_date BETWEEN '2023-01-01' AND '2023-12-31'
*/

-- Template: Filter by customer segment
/*
SELECT ...
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_status = 'active'
    AND o.order_status = 'completed'
GROUP BY ...
HAVING SUM(o.order_amount) >= 3000  -- High value customers
*/

-- Template: Adding custom time windows
/*
SELECT 
    ...,
    CASE 
        WHEN o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 30 DAY) THEN 'Last 30 Days'
        WHEN o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY) THEN 'Last 90 Days'
        ELSE 'Older'
    END AS time_period
FROM orders o
...
*/

-- ============================================
-- Revenue Analysis Queries
-- ============================================
-- These queries analyze revenue performance across
-- different segments and dimensions for business insights
-- ============================================

-- ============================================
-- 1. Total Revenue by Customer Segment
-- ============================================
-- Calculates total revenue for each customer value segment
-- ============================================
WITH customer_segments AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        COALESCE(SUM(o.order_amount), 0) AS total_spent,
        CASE 
            WHEN COALESCE(SUM(o.order_amount), 0) >= 3000 THEN 'High Value'
            WHEN COALESCE(SUM(o.order_amount), 0) >= 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
        AND o.order_status = 'completed'
    WHERE c.customer_status = 'active'
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT 
    customer_segment,
    COUNT(customer_id) AS customer_count,
    SUM(total_spent) AS total_revenue,
    AVG(total_spent) AS avg_revenue_per_customer,
    MIN(total_spent) AS min_customer_value,
    MAX(total_spent) AS max_customer_value,
    ROUND(SUM(total_spent) * 100.0 / SUM(SUM(total_spent)) OVER (), 2) AS revenue_percentage
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_revenue DESC;

-- ============================================
-- 2. Average Revenue Per Customer
-- ============================================
-- Calculates average revenue metrics per customer
-- ============================================
SELECT 
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN c.customer_id END) AS customers_with_orders,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.order_amount), 0) AS total_revenue,
    COALESCE(SUM(o.order_amount) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 0) AS avg_revenue_per_customer,
    COALESCE(SUM(o.order_amount) / NULLIF(COUNT(o.order_id), 0), 0) AS avg_order_value,
    COALESCE(COUNT(o.order_id) * 1.0 / NULLIF(COUNT(DISTINCT CASE WHEN o.order_id IS NOT NULL THEN c.customer_id END), 0), 0) AS avg_orders_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_status = 'completed'
WHERE c.customer_status = 'active';

-- ============================================
-- 3. Revenue by Product Category
-- ============================================
-- Analyzes revenue performance by product category
-- ============================================
SELECT 
    COALESCE(o.product_category, 'Unknown') AS product_category,
    COUNT(o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    SUM(o.order_amount) AS total_revenue,
    AVG(o.order_amount) AS avg_order_value,
    MIN(o.order_amount) AS min_order_value,
    MAX(o.order_amount) AS max_order_value,
    ROUND(SUM(o.order_amount) * 100.0 / SUM(SUM(o.order_amount)) OVER (), 2) AS revenue_percentage
FROM orders o
WHERE o.order_status = 'completed'
GROUP BY o.product_category
ORDER BY total_revenue DESC;

-- ============================================
-- 4. Revenue Trends by Month
-- ============================================
-- Shows revenue trends over time with growth metrics
-- ============================================
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS order_month,
        COUNT(order_id) AS orders,
        COUNT(DISTINCT customer_id) AS unique_customers,
        SUM(order_amount) AS revenue
    FROM orders
    WHERE order_status = 'completed'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    order_month,
    orders,
    unique_customers,
    revenue,
    LAG(revenue) OVER (ORDER BY order_month) AS previous_month_revenue,
    revenue - LAG(revenue) OVER (ORDER BY order_month) AS revenue_change,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY order_month)) * 100.0 / 
          NULLIF(LAG(revenue) OVER (ORDER BY order_month), 0), 2) AS revenue_growth_percentage
FROM monthly_revenue
ORDER BY order_month;

-- ============================================
-- 5. Revenue by Customer Lifetime (Cohort Analysis)
-- ============================================
-- Analyzes revenue by customer registration cohort
-- ============================================
SELECT 
    DATE_FORMAT(c.registration_date, '%Y-%m') AS cohort_month,
    COUNT(DISTINCT c.customer_id) AS cohort_size,
    COUNT(DISTINCT o.customer_id) AS customers_with_orders,
    ROUND(COUNT(DISTINCT o.customer_id) * 100.0 / COUNT(DISTINCT c.customer_id), 2) AS conversion_rate,
    COALESCE(SUM(o.order_amount), 0) AS total_revenue,
    COALESCE(SUM(o.order_amount) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 0) AS revenue_per_cohort_customer,
    COALESCE(COUNT(o.order_id) * 1.0 / NULLIF(COUNT(DISTINCT o.customer_id), 0), 0) AS avg_orders_per_buying_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_status = 'completed'
WHERE c.customer_status = 'active'
GROUP BY DATE_FORMAT(c.registration_date, '%Y-%m')
ORDER BY cohort_month;

-- ============================================
-- 6. Revenue by RFM Segment
-- ============================================
-- Analyzes revenue distribution across RFM segments
-- ============================================
WITH rfm_scores AS (
    SELECT 
        c.customer_id,
        COALESCE(MAX(o.order_date), c.registration_date) AS last_order_date,
        COALESCE(COUNT(o.order_id), 0) AS frequency,
        COALESCE(SUM(o.order_amount), 0) AS monetary,
        CASE 
            WHEN MAX(o.order_date) IS NULL THEN 1
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 30 THEN 5
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 90 THEN 4
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 180 THEN 3
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 365 THEN 2
            ELSE 1
        END AS recency_score,
        CASE 
            WHEN COUNT(o.order_id) >= 5 THEN 5
            WHEN COUNT(o.order_id) >= 4 THEN 4
            WHEN COUNT(o.order_id) >= 3 THEN 3
            WHEN COUNT(o.order_id) >= 2 THEN 2
            ELSE 1
        END AS frequency_score,
        CASE 
            WHEN COALESCE(SUM(o.order_amount), 0) >= 5000 THEN 5
            WHEN COALESCE(SUM(o.order_amount), 0) >= 3000 THEN 4
            WHEN COALESCE(SUM(o.order_amount), 0) >= 1000 THEN 3
            WHEN COALESCE(SUM(o.order_amount), 0) >= 500 THEN 2
            ELSE 1
        END AS monetary_score
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
        AND o.order_status = 'completed'
    WHERE c.customer_status = 'active'
    GROUP BY c.customer_id, c.registration_date
),
rfm_segments AS (
    SELECT 
        customer_id,
        frequency AS total_orders,
        monetary AS total_spent,
        recency_score,
        frequency_score,
        monetary_score,
        CASE 
            WHEN (recency_score + frequency_score + monetary_score) >= 13 THEN 'Champions'
            WHEN (recency_score + frequency_score + monetary_score) >= 10 THEN 'Loyal Customers'
            WHEN (recency_score + frequency_score + monetary_score) >= 7 AND recency_score >= 3 THEN 'Potential Loyalists'
            WHEN (recency_score + frequency_score + monetary_score) >= 7 AND recency_score < 3 THEN 'At Risk'
            WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
            WHEN recency_score <= 2 THEN 'Lost Customers'
            ELSE 'Needs Attention'
        END AS rfm_segment
    FROM rfm_scores
)
SELECT 
    rfm_segment,
    COUNT(customer_id) AS customer_count,
    SUM(total_spent) AS total_revenue,
    AVG(total_spent) AS avg_revenue_per_customer,
    SUM(total_orders) AS total_orders,
    AVG(total_orders) AS avg_orders_per_customer,
    ROUND(SUM(total_spent) * 100.0 / SUM(SUM(total_spent)) OVER (), 2) AS revenue_percentage,
    ROUND(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER (), 2) AS customer_percentage
FROM rfm_segments
GROUP BY rfm_segment
ORDER BY total_revenue DESC;

-- ============================================
-- 7. Geographic Revenue Analysis
-- ============================================
-- Analyzes revenue performance by geographic location
-- ============================================
SELECT 
    c.state,
    c.country,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.order_amount), 0) AS total_revenue,
    COALESCE(AVG(o.order_amount), 0) AS avg_order_value,
    COALESCE(SUM(o.order_amount) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 0) AS revenue_per_customer,
    COALESCE(COUNT(o.order_id) * 1.0 / NULLIF(COUNT(DISTINCT c.customer_id), 0), 0) AS orders_per_customer,
    ROUND(COALESCE(SUM(o.order_amount), 0) * 100.0 / SUM(SUM(COALESCE(o.order_amount, 0))) OVER (), 2) AS revenue_percentage
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_status = 'completed'
WHERE c.customer_status = 'active'
GROUP BY c.state, c.country
HAVING total_revenue > 0
ORDER BY total_revenue DESC;

-- ============================================
-- 8. Top Performing Customers
-- ============================================
-- Lists top customers by revenue with detailed metrics
-- ============================================
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    c.city,
    c.state,
    c.registration_date,
    COUNT(o.order_id) AS total_orders,
    SUM(o.order_amount) AS total_revenue,
    AVG(o.order_amount) AS avg_order_value,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) AS customer_lifetime_days,
    CASE 
        WHEN DATEDIFF(MAX(o.order_date), MIN(o.order_date)) > 0 
        THEN SUM(o.order_amount) / DATEDIFF(MAX(o.order_date), MIN(o.order_date)) * 30
        ELSE 0
    END AS estimated_monthly_revenue
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_status = 'completed'
WHERE c.customer_status = 'active'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.city, c.state, c.registration_date
HAVING total_revenue > 0
ORDER BY total_revenue DESC
LIMIT 20;

-- ============================================
-- 9. Customer Retention and Revenue Impact
-- ============================================
-- Analyzes customer retention rates and their revenue impact
-- ============================================
WITH customer_order_months AS (
    SELECT 
        c.customer_id,
        DATE_FORMAT(c.registration_date, '%Y-%m') AS registration_month,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        o.order_amount
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
        AND o.order_status = 'completed'
    WHERE c.customer_status = 'active'
),
retention_analysis AS (
    SELECT 
        registration_month,
        COUNT(DISTINCT customer_id) AS cohort_size,
        COUNT(DISTINCT CASE WHEN order_month = registration_month THEN customer_id END) AS month_0,
        COUNT(DISTINCT CASE WHEN PERIOD_DIFF(
            CAST(CONCAT(SUBSTRING(order_month, 1, 4), SUBSTRING(order_month, 6, 2)) AS UNSIGNED),
            CAST(CONCAT(SUBSTRING(registration_month, 1, 4), SUBSTRING(registration_month, 6, 2)) AS UNSIGNED)
        ) = 1 THEN customer_id END) AS month_1,
        COUNT(DISTINCT CASE WHEN PERIOD_DIFF(
            CAST(CONCAT(SUBSTRING(order_month, 1, 4), SUBSTRING(order_month, 6, 2)) AS UNSIGNED),
            CAST(CONCAT(SUBSTRING(registration_month, 1, 4), SUBSTRING(registration_month, 6, 2)) AS UNSIGNED)
        ) = 2 THEN customer_id END) AS month_2,
        COUNT(DISTINCT CASE WHEN PERIOD_DIFF(
            CAST(CONCAT(SUBSTRING(order_month, 1, 4), SUBSTRING(order_month, 6, 2)) AS UNSIGNED),
            CAST(CONCAT(SUBSTRING(registration_month, 1, 4), SUBSTRING(registration_month, 6, 2)) AS UNSIGNED)
        ) = 3 THEN customer_id END) AS month_3,
        SUM(order_amount) AS cohort_total_revenue
    FROM customer_order_months
    GROUP BY registration_month
)
SELECT 
    registration_month,
    cohort_size,
    month_0 AS customers_month_0,
    month_1 AS customers_month_1,
    month_2 AS customers_month_2,
    month_3 AS customers_month_3,
    ROUND(month_1 * 100.0 / NULLIF(month_0, 0), 2) AS retention_rate_month_1,
    ROUND(month_2 * 100.0 / NULLIF(month_0, 0), 2) AS retention_rate_month_2,
    ROUND(month_3 * 100.0 / NULLIF(month_0, 0), 2) AS retention_rate_month_3,
    cohort_total_revenue,
    ROUND(cohort_total_revenue / NULLIF(cohort_size, 0), 2) AS revenue_per_customer
FROM retention_analysis
ORDER BY registration_month;

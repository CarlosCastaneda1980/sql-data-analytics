-- ============================================
-- Customer Segmentation Queries
-- ============================================
-- These queries segment customers based on various
-- business metrics for targeted marketing and analysis
-- ============================================

-- ============================================
-- 1. Customer Segmentation by Purchase Value
-- ============================================
-- Segments customers into High, Medium, and Low value
-- based on their total purchase amount
-- ============================================
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.city,
    c.state,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.order_amount), 0) AS total_spent,
    COALESCE(AVG(o.order_amount), 0) AS avg_order_value,
    CASE 
        WHEN COALESCE(SUM(o.order_amount), 0) >= 3000 THEN 'High Value'
        WHEN COALESCE(SUM(o.order_amount), 0) >= 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_status = 'completed'
WHERE c.customer_status = 'active'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.city, c.state
ORDER BY total_spent DESC;

-- ============================================
-- 2. Customer Segmentation by Purchase Frequency
-- ============================================
-- Segments customers based on how often they purchase
-- ============================================
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    COUNT(o.order_id) AS order_count,
    COALESCE(SUM(o.order_amount), 0) AS total_spent,
    CASE 
        WHEN COUNT(o.order_id) >= 5 THEN 'Frequent Buyer'
        WHEN COUNT(o.order_id) >= 2 THEN 'Regular Buyer'
        WHEN COUNT(o.order_id) = 1 THEN 'One-Time Buyer'
        ELSE 'No Purchase'
    END AS purchase_frequency_segment
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_status = 'completed'
WHERE c.customer_status = 'active'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
ORDER BY order_count DESC, total_spent DESC;

-- ============================================
-- 3. Customer Segmentation by Recency
-- ============================================
-- Segments customers based on when they last made a purchase
-- ============================================
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(CURRENT_DATE, MAX(o.order_date)) AS days_since_last_order,
    CASE 
        WHEN MAX(o.order_date) IS NULL THEN 'Never Purchased'
        WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 30 THEN 'Recent Customer'
        WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 90 THEN 'Active Customer'
        WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 180 THEN 'At Risk'
        ELSE 'Churned'
    END AS recency_segment
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_status = 'completed'
WHERE c.customer_status = 'active'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
ORDER BY last_order_date DESC;

-- ============================================
-- 4. RFM Analysis (Recency, Frequency, Monetary)
-- ============================================
-- Comprehensive customer segmentation using RFM model
-- Scores customers on three dimensions for targeted marketing
-- ============================================
WITH rfm_scores AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        COALESCE(MAX(o.order_date), c.registration_date) AS last_order_date,
        COALESCE(COUNT(o.order_id), 0) AS frequency,
        COALESCE(SUM(o.order_amount), 0) AS monetary,
        -- Recency score (1-5, where 5 is most recent)
        CASE 
            WHEN MAX(o.order_date) IS NULL THEN 1
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 30 THEN 5
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 90 THEN 4
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 180 THEN 3
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 365 THEN 2
            ELSE 1
        END AS recency_score,
        -- Frequency score (1-5, based on order count)
        CASE 
            WHEN COUNT(o.order_id) >= 5 THEN 5
            WHEN COUNT(o.order_id) >= 4 THEN 4
            WHEN COUNT(o.order_id) >= 3 THEN 3
            WHEN COUNT(o.order_id) >= 2 THEN 2
            WHEN COUNT(o.order_id) >= 1 THEN 1
            ELSE 1
        END AS frequency_score,
        -- Monetary score (1-5, based on total spent)
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
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.registration_date
)
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    last_order_date,
    frequency AS total_orders,
    monetary AS total_spent,
    recency_score,
    frequency_score,
    monetary_score,
    (recency_score + frequency_score + monetary_score) AS rfm_total_score,
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
ORDER BY rfm_total_score DESC, monetary DESC;

-- ============================================
-- 5. Customer Segmentation by Geography
-- ============================================
-- Analyzes customer distribution and performance by location
-- ============================================
SELECT 
    c.state,
    c.country,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.order_amount), 0) AS total_revenue,
    COALESCE(AVG(o.order_amount), 0) AS avg_order_value,
    COALESCE(SUM(o.order_amount) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 0) AS revenue_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id 
    AND o.order_status = 'completed'
WHERE c.customer_status = 'active'
GROUP BY c.state, c.country
ORDER BY total_revenue DESC;

-- ============================================
-- 6. Customer Segmentation by Product Category
-- ============================================
-- Identifies customer preferences based on purchase categories
-- ============================================
WITH customer_category_purchases AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        o.product_category,
        COUNT(o.order_id) AS category_orders,
        SUM(o.order_amount) AS category_spent
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id 
        AND o.order_status = 'completed'
    WHERE c.customer_status = 'active'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, o.product_category
),
customer_primary_category AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        email,
        product_category AS primary_category,
        category_spent,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY category_spent DESC) AS rn
    FROM customer_category_purchases
)
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    primary_category,
    category_spent AS primary_category_spent
FROM customer_primary_category
WHERE rn = 1
ORDER BY category_spent DESC;

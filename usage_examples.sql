-- ============================================
-- Usage Examples and Best Practices
-- ============================================
-- This file demonstrates how to use the queries
-- in real-world scenarios with example outputs
-- and interpretation guides
-- ============================================

-- ============================================
-- EXAMPLE 1: Identify High-Value At-Risk Customers
-- ============================================
-- Business Goal: Find valuable customers who haven't purchased recently
-- for targeted retention campaigns
-- ============================================

-- Step 1: Get high-value customers with their last purchase date
WITH high_value_customers AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.city,
        c.state,
        COUNT(o.order_id) AS total_orders,
        SUM(o.order_amount) AS total_spent,
        MAX(o.order_date) AS last_order_date,
        DATEDIFF(CURRENT_DATE, MAX(o.order_date)) AS days_since_last_order
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'completed'
        AND c.customer_status = 'active'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.city, c.state
    HAVING SUM(o.order_amount) >= 3000  -- High value threshold
)
SELECT 
    customer_id,
    customer_name,
    email,
    city,
    state,
    total_orders,
    ROUND(total_spent, 2) AS total_spent,
    last_order_date,
    days_since_last_order,
    CASE 
        WHEN days_since_last_order > 180 THEN 'URGENT: High Risk'
        WHEN days_since_last_order > 90 THEN 'WARNING: At Risk'
        ELSE 'OK: Recently Active'
    END AS risk_level
FROM high_value_customers
WHERE days_since_last_order > 90  -- Haven't ordered in 90+ days
ORDER BY total_spent DESC, days_since_last_order DESC;

-- Expected Output:
-- customer_id | customer_name | email                 | total_spent | days_since_last_order | risk_level
-- 1           | John Smith    | john.smith@email.com  | 6370.50     | 120                   | WARNING: At Risk
-- ...

-- Action: Send personalized win-back email with special offer
-- Recommendation: 15-20% discount based on their historical spending

-- ============================================
-- EXAMPLE 2: Monthly Revenue Dashboard
-- ============================================
-- Business Goal: Create executive dashboard showing
-- key revenue metrics and trends
-- ============================================

WITH monthly_metrics AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        COUNT(DISTINCT customer_id) AS active_customers,
        COUNT(order_id) AS total_orders,
        SUM(order_amount) AS revenue,
        AVG(order_amount) AS avg_order_value
    FROM orders
    WHERE order_status = 'completed'
        AND order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    month,
    active_customers,
    total_orders,
    ROUND(revenue, 2) AS revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(revenue / active_customers, 2) AS revenue_per_customer,
    ROUND(total_orders * 1.0 / active_customers, 2) AS orders_per_customer,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0 / 
          NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2) AS mom_growth_pct
FROM monthly_metrics
ORDER BY month DESC;

-- Expected Output Example:
-- month   | revenue   | active_customers | mom_growth_pct | Action
-- 2024-01 | 2590.00   | 3                | +15.2%         | Growing - maintain momentum
-- 2023-12 | 2250.00   | 2                | -5.8%          | Declining - investigate
-- ...

-- ============================================
-- EXAMPLE 3: Product Category Performance Report
-- ============================================
-- Business Goal: Identify which product categories
-- to focus marketing and inventory investment on
-- ============================================

WITH category_performance AS (
    SELECT 
        product_category,
        COUNT(order_id) AS order_count,
        COUNT(DISTINCT customer_id) AS unique_customers,
        SUM(order_amount) AS total_revenue,
        AVG(order_amount) AS avg_order_value,
        SUM(order_amount) / COUNT(DISTINCT customer_id) AS revenue_per_customer
    FROM orders
    WHERE order_status = 'completed'
        AND order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY)
    GROUP BY product_category
),
category_rankings AS (
    SELECT 
        product_category,
        order_count,
        unique_customers,
        ROUND(total_revenue, 2) AS total_revenue,
        ROUND(avg_order_value, 2) AS avg_order_value,
        ROUND(revenue_per_customer, 2) AS revenue_per_customer,
        ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 2) AS revenue_share,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM category_performance
)
SELECT 
    product_category,
    order_count,
    unique_customers,
    total_revenue,
    avg_order_value,
    revenue_per_customer,
    revenue_share,
    revenue_rank,
    CASE 
        WHEN revenue_rank = 1 THEN 'Star Category - Maximize'
        WHEN revenue_rank <= 3 THEN 'Core Category - Maintain'
        WHEN revenue_share < 5 THEN 'Niche Category - Evaluate'
        ELSE 'Secondary Category - Monitor'
    END AS strategic_priority
FROM category_rankings
ORDER BY revenue_rank;

-- Expected Output Example:
-- category    | total_revenue | revenue_share | strategic_priority
-- Electronics | 15,890.00     | 42.5%         | Star Category - Maximize
-- Appliances  | 8,450.00      | 22.6%         | Core Category - Maintain
-- Clothing    | 3,220.00      | 8.6%          | Secondary Category - Monitor
-- ...

-- ============================================
-- EXAMPLE 4: Customer Segmentation Action Plan
-- ============================================
-- Business Goal: Create targeted marketing campaigns
-- for different customer segments
-- ============================================

WITH customer_rfm AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        MAX(o.order_date) AS last_order_date,
        COUNT(o.order_id) AS order_frequency,
        SUM(o.order_amount) AS total_spent,
        CASE 
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 30 THEN 5
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 90 THEN 4
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 180 THEN 3
            WHEN DATEDIFF(CURRENT_DATE, MAX(o.order_date)) <= 365 THEN 2
            ELSE 1
        END AS recency_score,
        CASE 
            WHEN COUNT(o.order_id) >= 5 THEN 5
            WHEN COUNT(o.order_id) >= 3 THEN 3
            ELSE 1
        END AS frequency_score,
        CASE 
            WHEN SUM(o.order_amount) >= 3000 THEN 5
            WHEN SUM(o.order_amount) >= 1000 THEN 3
            ELSE 1
        END AS monetary_score
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'completed'
        AND c.customer_status = 'active'
    GROUP BY c.customer_id, c.first_name, c.last_name, c.email
)
SELECT 
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'New Customers'
        WHEN recency_score <= 2 AND monetary_score >= 4 THEN 'At Risk VIPs'
        WHEN recency_score <= 2 THEN 'Churned'
        ELSE 'Potential'
    END AS segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spent), 2) AS avg_customer_value,
    ROUND(SUM(total_spent), 2) AS segment_revenue,
    -- Marketing recommendations
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 
            THEN 'VIP Treatment: Exclusive previews, loyalty rewards, personal shopper'
        WHEN recency_score >= 3 AND frequency_score >= 3 
            THEN 'Nurture: Regular engagement, product recommendations, member benefits'
        WHEN recency_score >= 4 AND frequency_score <= 2 
            THEN 'Onboard: Educational content, getting started guides, welcome series'
        WHEN recency_score <= 2 AND monetary_score >= 4 
            THEN 'WIN BACK: Aggressive discounts (20%+), personalized outreach, surveys'
        WHEN recency_score <= 2 
            THEN 'Last Chance: Final discount offer, feedback request, unsubscribe option'
        ELSE 'Engage: Standard marketing, seasonal promotions, category updates'
    END AS marketing_strategy
FROM customer_rfm
GROUP BY segment, marketing_strategy
ORDER BY segment_revenue DESC;

-- ============================================
-- EXAMPLE 5: Cohort Retention Analysis
-- ============================================
-- Business Goal: Understand how well we retain customers
-- from different registration periods
-- ============================================

WITH customer_cohorts AS (
    SELECT 
        c.customer_id,
        DATE_FORMAT(c.registration_date, '%Y-%m') AS cohort_month,
        o.order_date,
        PERIOD_DIFF(
            CAST(DATE_FORMAT(o.order_date, '%Y%m') AS UNSIGNED),
            CAST(DATE_FORMAT(c.registration_date, '%Y%m') AS UNSIGNED)
        ) AS months_since_registration
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
        AND o.order_status = 'completed'
    WHERE c.customer_status = 'active'
)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN months_since_registration = 0 THEN customer_id END) AS month_0,
    COUNT(DISTINCT CASE WHEN months_since_registration = 1 THEN customer_id END) AS month_1,
    COUNT(DISTINCT CASE WHEN months_since_registration = 2 THEN customer_id END) AS month_2,
    COUNT(DISTINCT CASE WHEN months_since_registration = 3 THEN customer_id END) AS month_3,
    -- Retention rates
    ROUND(COUNT(DISTINCT CASE WHEN months_since_registration = 1 THEN customer_id END) * 100.0 / 
          NULLIF(COUNT(DISTINCT CASE WHEN months_since_registration = 0 THEN customer_id END), 0), 2) AS retention_month_1,
    ROUND(COUNT(DISTINCT CASE WHEN months_since_registration = 2 THEN customer_id END) * 100.0 / 
          NULLIF(COUNT(DISTINCT CASE WHEN months_since_registration = 0 THEN customer_id END), 0), 2) AS retention_month_2,
    -- Health indicator
    CASE 
        WHEN COUNT(DISTINCT CASE WHEN months_since_registration = 1 THEN customer_id END) * 100.0 / 
             NULLIF(COUNT(DISTINCT CASE WHEN months_since_registration = 0 THEN customer_id END), 0) >= 40 
            THEN 'Excellent'
        WHEN COUNT(DISTINCT CASE WHEN months_since_registration = 1 THEN customer_id END) * 100.0 / 
             NULLIF(COUNT(DISTINCT CASE WHEN months_since_registration = 0 THEN customer_id END), 0) >= 25 
            THEN 'Good'
        ELSE 'Needs Improvement'
    END AS retention_health
FROM customer_cohorts
WHERE cohort_month >= DATE_FORMAT(DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH), '%Y-%m')
GROUP BY cohort_month
ORDER BY cohort_month DESC;

-- Expected Insight:
-- If Month 1 retention < 25%: Focus on onboarding experience
-- If Month 2-3 drops significantly: Improve early engagement
-- If steady decline: Product-market fit issues

-- ============================================
-- QUERY OPTIMIZATION TIPS
-- ============================================

-- 1. Use indexes for frequently filtered columns
-- Already created in schema.sql for:
--    - customer_id (foreign keys)
--    - order_date
--    - order_status
--    - product_category

-- 2. Use WHERE clause to filter before JOINs
-- GOOD:
-- SELECT ... FROM orders o WHERE o.order_status = 'completed'
-- BAD:
-- SELECT ... FROM orders o ... HAVING order_status = 'completed'

-- 3. Use LIMIT for large result sets when testing
-- Add LIMIT 100 at the end during development

-- 4. Use EXPLAIN to analyze query performance
-- EXPLAIN SELECT ...

-- 5. Avoid SELECT * in production queries
-- Specify only the columns you need

-- ============================================
-- INTERPRETATION GUIDELINES
-- ============================================

-- RFM Scores Interpretation:
-- Score 5: Excellent (act to maintain)
-- Score 4: Very Good (nurture further)
-- Score 3: Average (room for improvement)
-- Score 2: Below Average (needs attention)
-- Score 1: Poor (critical action needed)

-- Revenue Growth Benchmarks:
-- > 20% MoM: Exceptional growth
-- 10-20% MoM: Strong growth
-- 5-10% MoM: Healthy growth
-- 0-5% MoM: Slow growth
-- < 0% MoM: Decline (investigate)

-- Customer Retention Benchmarks:
-- Month 1: 30-40% is typical for e-commerce
-- Month 3: 20-30% is typical for e-commerce
-- Month 6: 15-25% is typical for e-commerce

-- Customer Lifetime Value (CLV) Benchmarks:
-- CLV should be at least 3x Customer Acquisition Cost (CAC)
-- CLV = Average Order Value × Purchase Frequency × Customer Lifespan

-- ============================================
-- REPORTING BEST PRACTICES
-- ============================================

-- 1. Always specify date ranges explicitly
-- WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31'

-- 2. Round monetary values to 2 decimal places
-- ROUND(SUM(order_amount), 2)

-- 3. Handle NULL values appropriately
-- COALESCE(SUM(order_amount), 0)

-- 4. Add percentage calculations for context
-- ROUND(value * 100.0 / total, 2) AS percentage

-- 5. Use meaningful column aliases
-- total_spent instead of sum_amount

-- 6. Sort results by the most important metric
-- ORDER BY total_revenue DESC

-- 7. Group time-series data consistently
-- DATE_FORMAT(order_date, '%Y-%m') for monthly
-- DATE_FORMAT(order_date, '%Y-W%u') for weekly
-- DATE(order_date) for daily

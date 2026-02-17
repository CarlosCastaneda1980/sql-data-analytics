-- Customer Analytics Queries
-- These queries help understand customer behavior and engagement

-- Customer cohort analysis by acquisition month
SELECT 
    DATE_FORMAT(c.created_at, '%Y-%m') AS cohort_month,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT CASE WHEN o.order_date IS NOT NULL THEN c.customer_id END) AS customers_with_orders,
    ROUND(COUNT(DISTINCT CASE WHEN o.order_date IS NOT NULL THEN c.customer_id END) * 100.0 / COUNT(DISTINCT c.customer_id), 2) AS activation_rate_pct,
    AVG(o.total_amount) AS avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'completed'
GROUP BY DATE_FORMAT(c.created_at, '%Y-%m')
ORDER BY cohort_month DESC;

-- Customer retention analysis
WITH first_purchase AS (
    SELECT 
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS first_order_month
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
),
monthly_orders AS (
    SELECT 
        o.customer_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        fp.first_order_month
    FROM orders o
    JOIN first_purchase fp ON o.customer_id = fp.customer_id
    WHERE o.status = 'completed'
)
SELECT 
    first_order_month,
    COUNT(DISTINCT CASE WHEN order_month = first_order_month THEN customer_id END) AS month_0,
    COUNT(DISTINCT CASE WHEN order_month = DATE_FORMAT(DATE_ADD(STR_TO_DATE(first_order_month, '%Y-%m'), INTERVAL 1 MONTH), '%Y-%m') THEN customer_id END) AS month_1,
    COUNT(DISTINCT CASE WHEN order_month = DATE_FORMAT(DATE_ADD(STR_TO_DATE(first_order_month, '%Y-%m'), INTERVAL 2 MONTH), '%Y-%m') THEN customer_id END) AS month_2,
    COUNT(DISTINCT CASE WHEN order_month = DATE_FORMAT(DATE_ADD(STR_TO_DATE(first_order_month, '%Y-%m'), INTERVAL 3 MONTH), '%Y-%m') THEN customer_id END) AS month_3
FROM monthly_orders
GROUP BY first_order_month
ORDER BY first_order_month DESC;

-- Customer segmentation by purchase frequency
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-time'
        WHEN order_count BETWEEN 2 AND 5 THEN 'Occasional'
        WHEN order_count BETWEEN 6 AND 10 THEN 'Regular'
        ELSE 'Loyal'
    END AS customer_segment,
    COUNT(DISTINCT customer_id) AS customer_count,
    AVG(total_spent) AS avg_lifetime_value,
    SUM(total_spent) AS total_revenue
FROM (
    SELECT 
        customer_id,
        COUNT(order_id) AS order_count,
        SUM(total_amount) AS total_spent
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
) customer_stats
GROUP BY customer_segment
ORDER BY 
    CASE customer_segment
        WHEN 'One-time' THEN 1
        WHEN 'Occasional' THEN 2
        WHEN 'Regular' THEN 3
        WHEN 'Loyal' THEN 4
    END;

-- Average time between purchases
WITH purchase_dates AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_order_date
    FROM orders
    WHERE status = 'completed'
)
SELECT 
    AVG(DATEDIFF(order_date, prev_order_date)) AS avg_days_between_purchases,
    MIN(DATEDIFF(order_date, prev_order_date)) AS min_days_between_purchases,
    MAX(DATEDIFF(order_date, prev_order_date)) AS max_days_between_purchases
FROM purchase_dates
WHERE prev_order_date IS NOT NULL;

-- Customer churn analysis (customers who haven't purchased in 90+ days)
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_last_order,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, customer_name, c.email
HAVING DATEDIFF(CURDATE(), MAX(o.order_date)) > 90
ORDER BY days_since_last_order DESC;

-- New vs returning customers by month
WITH customer_first_order AS (
    SELECT 
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS first_order_month
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    COUNT(DISTINCT CASE WHEN DATE_FORMAT(o.order_date, '%Y-%m') = cfo.first_order_month THEN o.customer_id END) AS new_customers,
    COUNT(DISTINCT CASE WHEN DATE_FORMAT(o.order_date, '%Y-%m') != cfo.first_order_month THEN o.customer_id END) AS returning_customers,
    COUNT(DISTINCT o.customer_id) AS total_customers
FROM orders o
JOIN customer_first_order cfo ON o.customer_id = cfo.customer_id
WHERE o.status = 'completed'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month DESC;

-- Customer lifetime value by acquisition source
SELECT 
    ca.campaign_id,
    cp.campaign_name,
    COUNT(DISTINCT ca.customer_id) AS customers_acquired,
    AVG(customer_value.lifetime_value) AS avg_lifetime_value,
    SUM(customer_value.lifetime_value) AS total_value_generated
FROM customer_acquisitions ca
JOIN campaigns cp ON ca.campaign_id = cp.campaign_id
LEFT JOIN (
    SELECT 
        customer_id,
        SUM(total_amount) AS lifetime_value
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
) customer_value ON ca.customer_id = customer_value.customer_id
GROUP BY ca.campaign_id, cp.campaign_name
ORDER BY avg_lifetime_value DESC;

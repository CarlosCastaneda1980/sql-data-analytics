-- Key Performance Indicators (KPI) Queries
-- These queries help track essential business metrics

-- Daily KPI Dashboard
SELECT 
    DATE(o.order_date) AS metric_date,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS active_customers,
    SUM(o.total_amount) AS daily_revenue,
    AVG(o.total_amount) AS avg_order_value,
    SUM(oi.quantity) AS units_sold,
    COUNT(DISTINCT CASE WHEN first_order.is_first THEN o.customer_id END) AS new_customers,
    COUNT(DISTINCT s.session_id) AS total_sessions,
    ROUND(COUNT(DISTINCT o.customer_id) * 100.0 / NULLIF(COUNT(DISTINCT s.customer_id), 0), 2) AS conversion_rate_pct
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN sessions s ON DATE(o.order_date) = DATE(s.session_date)
LEFT JOIN (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date,
        1 AS is_first
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
) first_order ON o.customer_id = first_order.customer_id 
    AND DATE(o.order_date) = DATE(first_order.first_order_date)
WHERE o.status = 'completed'
    AND o.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(o.order_date)
ORDER BY metric_date DESC;

-- Monthly KPI Summary
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS active_customers,
    SUM(o.total_amount) AS monthly_revenue,
    AVG(o.total_amount) AS avg_order_value,
    SUM(oi.quantity) AS total_units_sold,
    COUNT(DISTINCT new_customers.customer_id) AS new_customers,
    COUNT(DISTINCT repeat_customers.customer_id) AS repeat_customers
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN (
    SELECT customer_id, MIN(DATE_FORMAT(order_date, '%Y-%m')) AS first_month
    FROM orders WHERE status = 'completed'
    GROUP BY customer_id
) new_customers ON o.customer_id = new_customers.customer_id 
    AND DATE_FORMAT(o.order_date, '%Y-%m') = new_customers.first_month
LEFT JOIN (
    SELECT customer_id
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
    HAVING COUNT(order_id) > 1
) repeat_customers ON o.customer_id = repeat_customers.customer_id
WHERE o.status = 'completed'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month DESC;

-- Product performance KPIs
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    COUNT(DISTINCT oi.order_id) AS orders_containing_product,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue,
    AVG(oi.unit_price) AS avg_selling_price,
    SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.cost) AS gross_profit,
    ROUND((SUM(oi.quantity * oi.unit_price) - SUM(oi.quantity * p.cost)) * 100.0 / 
          NULLIF(SUM(oi.quantity * oi.unit_price), 0), 2) AS profit_margin_pct
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status = 'completed'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;

-- Customer health score
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_last_order,
    DATEDIFF(MAX(o.order_date), MIN(o.order_date)) / NULLIF(COUNT(o.order_id) - 1, 0) AS avg_days_between_orders,
    CASE 
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) <= 30 THEN 'Active'
        WHEN DATEDIFF(CURDATE(), MAX(o.order_date)) <= 90 THEN 'At Risk'
        ELSE 'Churned'
    END AS health_status
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'completed'
GROUP BY c.customer_id, customer_name
HAVING COUNT(o.order_id) > 0
ORDER BY lifetime_value DESC;

-- Channel performance KPIs
SELECT 
    c.channel,
    COUNT(DISTINCT c.campaign_id) AS active_campaigns,
    SUM(cm.impressions) AS total_impressions,
    SUM(cm.clicks) AS total_clicks,
    SUM(cm.conversions) AS total_conversions,
    SUM(cm.spend) AS total_spend,
    ROUND(SUM(cm.clicks) * 100.0 / NULLIF(SUM(cm.impressions), 0), 2) AS ctr_pct,
    ROUND(SUM(cm.conversions) * 100.0 / NULLIF(SUM(cm.clicks), 0), 2) AS conversion_rate_pct,
    ROUND(SUM(cm.spend) / NULLIF(SUM(cm.clicks), 0), 2) AS cpc,
    ROUND(SUM(cm.spend) / NULLIF(SUM(cm.conversions), 0), 2) AS cpa
FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
WHERE cm.metric_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY c.channel
ORDER BY total_conversions DESC;

-- Inventory turnover rate (if applicable)
SELECT 
    p.category,
    SUM(oi.quantity) AS units_sold_30d,
    AVG(oi.quantity) AS avg_units_per_order,
    COUNT(DISTINCT oi.order_id) AS orders_count,
    ROUND(SUM(oi.quantity) / 30.0, 2) AS avg_daily_sales
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'completed'
    AND o.order_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY p.category
ORDER BY units_sold_30d DESC;

-- Growth metrics
WITH monthly_metrics AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        COUNT(DISTINCT order_id) AS orders,
        COUNT(DISTINCT customer_id) AS customers,
        SUM(total_amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT 
    month,
    orders,
    customers,
    revenue,
    ROUND((orders - LAG(orders) OVER (ORDER BY month)) * 100.0 / 
          NULLIF(LAG(orders) OVER (ORDER BY month), 0), 2) AS orders_growth_pct,
    ROUND((customers - LAG(customers) OVER (ORDER BY month)) * 100.0 / 
          NULLIF(LAG(customers) OVER (ORDER BY month), 0), 2) AS customers_growth_pct,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0 / 
          NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2) AS revenue_growth_pct
FROM monthly_metrics
ORDER BY month DESC;

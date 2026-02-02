-- Customer Acquisition Cost (CAC) Analytics Queries
-- These queries help understand the cost of acquiring new customers

-- Overall CAC by channel
SELECT 
    c.channel,
    SUM(cm.spend) AS total_spend,
    COUNT(DISTINCT ca.customer_id) AS customers_acquired,
    ROUND(SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 2) AS cac,
    AVG(customer_value.lifetime_value) AS avg_customer_ltv,
    ROUND(AVG(customer_value.lifetime_value) / NULLIF(SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 0), 2) AS ltv_to_cac_ratio
FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
LEFT JOIN customer_acquisitions ca ON c.campaign_id = ca.campaign_id
LEFT JOIN (
    SELECT 
        customer_id,
        SUM(total_amount) AS lifetime_value
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
) customer_value ON ca.customer_id = customer_value.customer_id
GROUP BY c.channel
ORDER BY cac;

-- CAC trend over time
SELECT 
    DATE_FORMAT(ca.acquisition_date, '%Y-%m') AS month,
    SUM(cm.spend) AS total_spend,
    COUNT(DISTINCT ca.customer_id) AS customers_acquired,
    ROUND(SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 2) AS cac
FROM customer_acquisitions ca
JOIN campaigns c ON ca.campaign_id = c.campaign_id
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
    AND DATE_FORMAT(cm.metric_date, '%Y-%m') = DATE_FORMAT(ca.acquisition_date, '%Y-%m')
GROUP BY DATE_FORMAT(ca.acquisition_date, '%Y-%m')
ORDER BY month DESC;

-- CAC by campaign
SELECT 
    c.campaign_id,
    c.campaign_name,
    c.channel,
    c.budget,
    SUM(cm.spend) AS total_spend,
    COUNT(DISTINCT ca.customer_id) AS customers_acquired,
    ROUND(SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 2) AS cac,
    ROUND(c.budget / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 2) AS projected_cac
FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
LEFT JOIN customer_acquisitions ca ON c.campaign_id = ca.campaign_id
GROUP BY c.campaign_id, c.campaign_name, c.channel, c.budget
ORDER BY cac;

-- LTV to CAC ratio analysis
SELECT 
    c.campaign_name,
    c.channel,
    COUNT(DISTINCT ca.customer_id) AS customers_acquired,
    ROUND(SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 2) AS cac,
    AVG(customer_value.lifetime_value) AS avg_ltv,
    ROUND(AVG(customer_value.lifetime_value) / NULLIF(SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 0), 2) AS ltv_to_cac_ratio,
    CASE 
        WHEN AVG(customer_value.lifetime_value) / NULLIF(SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 0) >= 3 THEN 'Excellent'
        WHEN AVG(customer_value.lifetime_value) / NULLIF(SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 0) >= 2 THEN 'Good'
        WHEN AVG(customer_value.lifetime_value) / NULLIF(SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 0) >= 1 THEN 'Break Even'
        ELSE 'Poor'
    END AS performance_rating
FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
LEFT JOIN customer_acquisitions ca ON c.campaign_id = ca.campaign_id
LEFT JOIN (
    SELECT 
        customer_id,
        SUM(total_amount) AS lifetime_value
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
) customer_value ON ca.customer_id = customer_value.customer_id
GROUP BY c.campaign_id, c.campaign_name, c.channel
HAVING COUNT(DISTINCT ca.customer_id) > 0
ORDER BY ltv_to_cac_ratio DESC;

-- Payback period analysis
SELECT 
    c.campaign_name,
    COUNT(DISTINCT ca.customer_id) AS customers_acquired,
    ROUND(SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 2) AS cac,
    AVG(first_order.order_value) AS avg_first_order_value,
    ROUND((SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0)) / 
          NULLIF(AVG(first_order.order_value), 0), 2) AS orders_to_payback
FROM campaigns c
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
LEFT JOIN customer_acquisitions ca ON c.campaign_id = ca.campaign_id
LEFT JOIN (
    SELECT 
        customer_id,
        total_amount AS order_value
    FROM (
        SELECT 
            customer_id,
            total_amount,
            ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS rn
        FROM orders
        WHERE status = 'completed'
    ) ranked_orders
    WHERE rn = 1
) first_order ON ca.customer_id = first_order.customer_id
GROUP BY c.campaign_id, c.campaign_name
HAVING COUNT(DISTINCT ca.customer_id) > 0
ORDER BY orders_to_payback;

-- CAC efficiency by cohort
SELECT 
    DATE_FORMAT(ca.acquisition_date, '%Y-%m') AS cohort_month,
    c.channel,
    COUNT(DISTINCT ca.customer_id) AS customers_acquired,
    ROUND(SUM(cm.spend) / NULLIF(COUNT(DISTINCT ca.customer_id), 0), 2) AS cac,
    AVG(DATEDIFF(first_purchase.first_order_date, ca.acquisition_date)) AS avg_days_to_first_purchase,
    COUNT(DISTINCT CASE WHEN first_purchase.first_order_date IS NOT NULL THEN ca.customer_id END) AS activated_customers,
    ROUND(COUNT(DISTINCT CASE WHEN first_purchase.first_order_date IS NOT NULL THEN ca.customer_id END) * 100.0 / 
          COUNT(DISTINCT ca.customer_id), 2) AS activation_rate_pct
FROM customer_acquisitions ca
JOIN campaigns c ON ca.campaign_id = c.campaign_id
LEFT JOIN campaign_metrics cm ON c.campaign_id = cm.campaign_id
    AND DATE_FORMAT(cm.metric_date, '%Y-%m') = DATE_FORMAT(ca.acquisition_date, '%Y-%m')
LEFT JOIN (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
) first_purchase ON ca.customer_id = first_purchase.customer_id
GROUP BY DATE_FORMAT(ca.acquisition_date, '%Y-%m'), c.channel
ORDER BY cohort_month DESC, c.channel;

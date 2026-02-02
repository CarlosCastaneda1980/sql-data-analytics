-- Customer Analysis
-- Purpose: Analyze customer segments and revenue performance
-- Context: Business analytics reporting

SELECT
    c.segment AS customer_segment,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(o.revenue) AS total_revenue,
    AVG(o.revenue) AS avg_revenue_per_order
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY c.segment
ORDER BY total_revenue DESC;

-- Part 1 Task 5: Reporting Queries

-- (a) Tier every product by total Delivered revenue.
-- The subquery makes total_revenue available to the outer CASE expression.
SELECT product_name,
       total_revenue,
       CASE
           WHEN total_revenue >= 3000 THEN 'High'
           WHEN total_revenue >= 1000 THEN 'Medium'
           ELSE 'Low'
       END AS revenue_tier
FROM (
    SELECT p.product_id,
           p.product_name,
           COALESCE(SUM(o.amount_inr), 0) AS total_revenue
    FROM products AS p
    LEFT JOIN orders AS o
        ON p.product_id = o.product_id
       AND o.status = 'Delivered'
    GROUP BY p.product_id, p.product_name
) AS product_revenue
ORDER BY total_revenue DESC, product_name;

-- (b) Monthly-by-category report.
SELECT
    p.category AS category,
    strftime('%Y-%m', o.order_date) AS month,
    COUNT(o.order_id) AS order_count,
    SUM(o.amount_inr) AS total_revenue,
    AVG(o.amount_inr) AS avg_revenue
FROM orders AS o
INNER JOIN products AS p
    ON o.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.category, strftime('%Y-%m', o.order_date)
ORDER BY p.category, month;

-- (c) Category target performance.
WITH category_revenue AS (
    SELECT p.category,
           SUM(o.amount_inr) AS total_revenue
    FROM orders AS o
    INNER JOIN products AS p
        ON o.product_id = p.product_id
    WHERE o.status = 'Delivered'
    GROUP BY p.category
)
SELECT
    cr.category,
    cr.total_revenue,
    ct.target_revenue_inr,
    ct.target_revenue_inr - cr.total_revenue AS variance,
    ((cr.total_revenue - ct.target_revenue_inr) * 100.0)
        / ct.target_revenue_inr AS percentage_variance,
    CASE
        WHEN cr.total_revenue >= ct.target_revenue_inr
            THEN 'Above Target'
        WHEN ((ct.target_revenue_inr - cr.total_revenue) * 100.0)
             / ct.target_revenue_inr <= 15
            THEN 'Below Target - Watch'
        ELSE 'Below Target - Critical'
    END AS target_status
FROM category_revenue AS cr
INNER JOIN category_targets AS ct
    ON cr.category = ct.category
ORDER BY cr.category;

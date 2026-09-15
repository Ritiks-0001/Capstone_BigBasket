-- Part 1 Task 4: Aggregation and Joins

-- (a) INNER JOIN + Delivered filter + GROUP BY + HAVING
SELECT p.category,
       COUNT(o.order_id) AS total_orders,
       SUM(o.amount_inr) AS total_revenue,
       AVG(o.amount_inr) AS avg_revenue
FROM orders AS o
INNER JOIN products AS p
    ON o.product_id = p.product_id
WHERE o.status = 'Delivered'
GROUP BY p.category
HAVING total_revenue > 10000
ORDER BY total_revenue DESC;

-- (b) LEFT JOIN: every product, including products with zero orders.
-- COUNT(o.order_id), not COUNT(*), preserves zero for unmatched products.
SELECT p.product_id,
       p.product_name,
       COUNT(o.order_id) AS total_orders
FROM products AS p
LEFT JOIN orders AS o
    ON p.product_id = o.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_orders ASC, p.product_name ASC;

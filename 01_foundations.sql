-- Part 1 Task 3: SQL Foundations

-- SELECT + WHERE: orders from a specific city
SELECT *
FROM orders
WHERE customer_id IN (
    SELECT customer_id
    FROM customers
    WHERE city = 'Mumbai'
);

-- DISTINCT: every category
SELECT DISTINCT category
FROM products
ORDER BY category;

-- ORDER BY + LIMIT: 5 highest-value orders
SELECT order_id, order_date, amount_inr
FROM orders
ORDER BY amount_inr DESC
LIMIT 5;

-- Alias AS: count orders by status
SELECT status, COUNT(*) AS total_orders
FROM orders
GROUP BY status
ORDER BY total_orders DESC;

-- IN: orders paid using two selected payment modes
SELECT order_id, payment_mode, amount_inr
FROM orders
WHERE payment_mode IN ('UPI', 'Credit Card')
ORDER BY order_id;

-- BETWEEN: orders in the stated amount range
SELECT order_id, amount_inr
FROM orders
WHERE amount_inr BETWEEN 100 AND 500
ORDER BY amount_inr;

-- NOT BETWEEN: orders outside the stated amount range
SELECT order_id, amount_inr
FROM orders
WHERE amount_inr NOT BETWEEN 100 AND 500
ORDER BY amount_inr;

-- IS NULL: orders with no rating (Cancelled or Pending)
SELECT order_id, status, rating
FROM orders
WHERE rating IS NULL
ORDER BY order_id;

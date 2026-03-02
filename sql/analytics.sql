-- ========================================
-- DATASET OVERVIEW
-- ========================================

SELECT COUNT(DISTINCT customer_city) FROM customers;
SELECT COUNT(*) FROM orders;

SELECT AVG(payment_value), payment_type
FROM order_payments
GROUP BY payment_type;


-- ========================================
-- BUSINESS PERFORMANCE AND REVENUE ANALYSIS
-- ========================================

-- Total transaction volume
SELECT COUNT(*) AS total_orders
FROM orders;

-- Total revenue across all orders
SELECT SUM(payment_value) AS total_revenue
FROM order_payments;

-- Monthly revenue with MoM growth rate, order count, and average order value
-- Growth is driven by order volume, not higher spend per order
CREATE OR REPLACE VIEW growth_overall AS
SELECT
    month,
    ROUND(monthly_revenue),
    ROUND(
        100.0 * (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month))
        / LAG(monthly_revenue) OVER (ORDER BY month)
    ) AS growth_percent,
    num_orders,
    ROUND(avg_order_value) AS average_order_value
FROM (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(p.payment_value) AS monthly_revenue,
        COUNT(DISTINCT o.order_id) AS num_orders,
        AVG(p.payment_value) AS avg_order_value
    FROM orders o
    JOIN order_payments p ON o.order_id = p.order_id
    GROUP BY month
) t
ORDER BY month;
-- Note: last two months of 2018 show low counts due to incomplete data
SELECT * FROM growth_overall;


-- ========================================
-- DELIVERY PERFORMANCE
-- ========================================

-- Overall average: ~12 days
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date - order_purchase_timestamp))) / 86400, 2)
    || ' days' AS avg_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- ~8% of orders arrive later than estimated
SELECT
    ROUND(
        COUNT(*) FILTER (WHERE order_delivered_customer_date > order_estimated_delivery_date) * 100.0 / COUNT(*), 2
    ) || '%' AS percent_late
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- Delivery speed and late rate by state
-- Fastest ~9 days, slowest ~30 days — global average hides strong regional variation
CREATE OR REPLACE VIEW deliveries AS
SELECT
    c.customer_state,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400), 2) AS avg_delivery_days,
    ROUND(COUNT(*) FILTER (WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date) * 100.0 / COUNT(*), 2) AS late_delivery_percent,
    COUNT(*) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;

SELECT * FROM deliveries;


-- ========================================
-- CUSTOMER ANALYSIS
-- ========================================

-- New customers acquired per month
CREATE OR REPLACE VIEW new_customers AS
WITH customer_orders AS (
    SELECT customer_id, MIN(order_purchase_timestamp) AS first_order_date
    FROM orders
    GROUP BY customer_id
)
SELECT
    DATE_TRUNC('month', first_order_date) AS cohort_month,
    COUNT(*) AS new_customers
FROM customer_orders
GROUP BY cohort_month
ORDER BY cohort_month;

SELECT * FROM new_customers;

-- Only ~3% of customers place more than one order
CREATE OR REPLACE VIEW customer_repeat AS
WITH customer_orders AS (
    SELECT c.customer_unique_id, COUNT(o.order_id) AS total_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE total_orders > 1) AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE total_orders > 1) / COUNT(*), 2) AS repeat_customer_percent
FROM customer_orders;

SELECT * FROM customer_repeat;

-- Repeat customers are ~3% of users but generate ~6% of revenue
WITH customer_orders AS (
    SELECT c.customer_unique_id, COUNT(o.order_id) AS total_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
order_values AS (
    SELECT o.order_id, c.customer_unique_id, SUM(p.payment_value) AS order_value
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    GROUP BY o.order_id, c.customer_unique_id
)
SELECT
    CASE WHEN co.total_orders > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
    ROUND(SUM(ov.order_value), 2) AS total_revenue,
    ROUND(100.0 * SUM(ov.order_value) / SUM(SUM(ov.order_value)) OVER (), 2) AS revenue_percent
FROM order_values ov
JOIN customer_orders co ON ov.customer_unique_id = co.customer_unique_id
GROUP BY customer_type;

-- Test whether late deliveries reduce repeat purchases — they don't
WITH customer_stats AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders,
        MAX(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS had_late_delivery
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)
SELECT
    had_late_delivery,
    ROUND(100.0 * COUNT(*) FILTER (WHERE total_orders > 1) / COUNT(*), 2) AS repeat_rate_percent,
    COUNT(*) AS total_customers
FROM customer_stats
GROUP BY had_late_delivery;


-- ========================================
-- PRODUCT REVENUE CONCENTRATION
-- ========================================

-- Top 10 categories by order volume
CREATE OR REPLACE VIEW product_orders AS
SELECT p.product_category_name, COUNT(*) AS total_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_orders DESC
LIMIT 10;

SELECT * FROM product_orders;

-- Top 10 categories by revenue — top 10 account for ~63% of total revenue
CREATE OR REPLACE VIEW product_revenue AS
WITH order_revenue AS (
    SELECT order_id, SUM(payment_value) AS total_order_revenue
    FROM order_payments
    GROUP BY order_id
)
SELECT
    p.product_category_name,
    ROUND(SUM(orv.total_order_revenue), 2) AS total_revenue,
    ROUND(100.0 * SUM(orv.total_order_revenue) / SUM(SUM(orv.total_order_revenue)) OVER (), 2) AS revenue_percent,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN order_revenue orv ON oi.order_id = orv.order_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;

SELECT * FROM product_revenue;


-- ========================================
-- CUSTOMER SATISFACTION
-- ========================================

-- ~77% of reviews are 4-5 stars; ~15% are 1-2 stars
-- High satisfaction but low retention → retention is structural, not experience-driven
CREATE OR REPLACE VIEW score AS
SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percent
FROM reviews
GROUP BY review_score
ORDER BY review_score;

SELECT * FROM score;

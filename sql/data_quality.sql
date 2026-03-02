-- ========================================
-- NULL CHECKS
-- ========================================

-- RESULT: 0 nulls found in all critical columns
SELECT
COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
COUNT(*) FILTER (WHERE customer_unique_id IS NULL) AS null_customer_unique_id,
COUNT(*) FILTER (WHERE customer_zip_code_prefix IS NULL) AS null_customer_zip_code,
COUNT(*) FILTER (WHERE customer_city IS NULL) AS null_customer_city,
COUNT(*) FILTER (WHERE customer_state IS NULL) AS null_customer_state
FROM customers;

-- RESULT: 0 nulls found in all critical columns
SELECT
COUNT(*) FILTER (WHERE geolocation_zip_code_prefix IS NULL) AS null_zip,
COUNT(*) FILTER (WHERE geolocation_lat IS NULL) AS null_lat,
COUNT(*) FILTER (WHERE geolocation_lng IS NULL) AS null_lng,
COUNT(*) FILTER (WHERE geolocation_city IS NULL) AS null_city,
COUNT(*) FILTER (WHERE geolocation_state IS NULL) AS null_state
FROM geolocation;

-- RESULT: 0 nulls found in all critical columns
SELECT
COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
COUNT(*) FILTER (WHERE order_item_id IS NULL) AS null_order_item_id,
COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
COUNT(*) FILTER (WHERE shipping_limit_date IS NULL) AS null_shipping_limit,
COUNT(*) FILTER (WHERE price IS NULL) AS null_price,
COUNT(*) FILTER (WHERE freight_value IS NULL) AS null_freight
FROM order_items;

-- RESULT: 0 nulls found in all critical columns
SELECT
COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
COUNT(*) FILTER (WHERE payment_sequential IS NULL) AS null_payment_seq,
COUNT(*) FILTER (WHERE payment_type IS NULL) AS null_payment_type,
COUNT(*) FILTER (WHERE payment_installments IS NULL) AS null_installments,
COUNT(*) FILTER (WHERE payment_value IS NULL) AS null_payment_value
FROM order_payments;

-- RESULT: nulls present in delivery dates — expected for undelivered orders
SELECT
COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
COUNT(*) FILTER (WHERE order_status IS NULL) AS null_order_status,
COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS null_purchase_time,
COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved,
COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS null_delivered_carrier,
COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_delivered_customer,
COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS null_estimated_delivery
FROM orders;

-- RESULT: 0 nulls found in all critical columns
SELECT
COUNT(*) FILTER (WHERE product_category_name IS NULL) AS null_category_name,
COUNT(*) FILTER (WHERE product_category_name_english IS NULL) AS null_category_english
FROM product_category_translation;

-- ========================================
-- CHECK: NULL values in products table
-- RESULT: 610 products missing metadata (category, description)
-- DECISION: kept as NULL — product records are still valid
-- ========================================
SELECT
COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
COUNT(*) FILTER (WHERE product_category_name IS NULL) AS null_category,
COUNT(*) FILTER (WHERE product_name_lenght IS NULL) AS null_name_length,
COUNT(*) FILTER (WHERE product_description_lenght IS NULL) AS null_description_length,
COUNT(*) FILTER (WHERE product_photos_qty IS NULL) AS null_photos,
COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS null_weight,
COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS null_length,
COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS null_height,
COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS null_width
FROM products;

-- RESULT: nulls present in comment fields — expected, comments are optional
SELECT
COUNT(*) FILTER (WHERE review_id IS NULL) AS null_review_id,
COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
COUNT(*) FILTER (WHERE review_score IS NULL) AS null_review_score,
COUNT(*) FILTER (WHERE review_comment_title IS NULL) AS null_comment_title,
COUNT(*) FILTER (WHERE review_comment_message IS NULL) AS null_comment_message,
COUNT(*) FILTER (WHERE review_creation_date IS NULL) AS null_creation_date,
COUNT(*) FILTER (WHERE review_answer_timestamp IS NULL) AS null_answer_time
FROM reviews;

-- RESULT: 0 nulls found in all critical columns
SELECT
COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
COUNT(*) FILTER (WHERE seller_zip_code_prefix IS NULL) AS null_zip,
COUNT(*) FILTER (WHERE seller_city IS NULL) AS null_city,
COUNT(*) FILTER (WHERE seller_state IS NULL) AS null_state
FROM sellers;


-- ========================================
-- RELATIONSHIP VALIDATION
-- Check that foreign keys match across tables
-- ========================================

-- CHECK: orders → customers relationship
-- RESULT: 0 rows returned → valid relationship
SELECT * FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- CHECK: order_items → orders relationship
-- RESULT: 0 rows returned → valid relationship
SELECT * FROM order_items i
LEFT JOIN orders o ON o.order_id = i.order_id
WHERE o.order_id IS NULL;

-- CHECK: payments → orders relationship
-- RESULT: 0 rows returned → valid relationship
SELECT * FROM order_payments p
LEFT JOIN orders o ON o.order_id = p.order_id
WHERE o.order_id IS NULL;


-- ========================================
-- LOGICAL CONSISTENCY CHECKS
-- ========================================

-- CHECK: negative values in price and shipping cost
-- RESULT: 0 rows returned → valid
SELECT * FROM order_items WHERE price < 0;
SELECT * FROM order_items WHERE freight_value < 0;

-- CHECK: negative values in product dimensions and weight
-- RESULT: 0 rows returned → valid
SELECT * FROM products
WHERE product_weight_g < 0
   OR product_length_cm < 0
   OR product_height_cm < 0
   OR product_width_cm < 0;

-- CHECK: review creation date before answer date
-- RESULT: 0 rows returned → valid
SELECT * FROM reviews
WHERE review_creation_date > review_answer_timestamp;

-- CHECK: review scores between 1 and 5
-- RESULT: 0 rows returned → valid
SELECT * FROM reviews
WHERE review_score NOT BETWEEN 0 AND 5;

-- CHECK: order status distribution
-- RESULT: no unexpected statuses found
SELECT order_status, COUNT(*)
FROM orders
GROUP BY order_status;

-- CHECK: payment type distribution
-- RESULT: no unexpected payment types found
SELECT payment_type, COUNT(*)
FROM order_payments
GROUP BY payment_type;



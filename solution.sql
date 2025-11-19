/*
CaseStudy
Họ tên: Phan Thị Ngọc Linh
MSSV: 22280052
*/

--1. What percentage of accesses include Purchase event?
-- Behavior user (event_type) = 3

WITH total AS(
	SELECT 
		COUNT(DISTINCT visit_id) AS total_visit
	FROM hqtcsdl.events 
)
SELECT
	 ROUND(COUNT(e.event_type) * 100.0/ t.total_visit, 4) AS pertentage_purchase
FROM  hqtcsdl.events e
JOIN total t ON 1=1
WHERE e.event_type = 3
GROUP BY t.total_visit;

--2. What percentage of accesses viewed the checkout page but did not include Purchase event?

WITH page_view AS (
    SELECT 
        COUNT(e.visit_id) AS total_checkout_views
    FROM hqtcsdl.events e
    WHERE e.page_id = 12
    AND e.event_type = 1  -- Đếm số lượt xem trang Checkout (event_type = 1)
),
without_purchase AS (
    SELECT 
        COUNT(DISTINCT e.visit_id) AS not_purchase
    FROM hqtcsdl.events e
    WHERE e.page_id = 12  -- Trang Checkout
    AND e.event_type = 1  -- Lượt xem trang Checkout
    AND e.visit_id NOT IN (
        SELECT DISTINCT e2.visit_id
        FROM hqtcsdl.events e2
        WHERE e2.event_type = 3  -- Không có sự kiện mua hàng (event_type = 3) trong cùng cái phiên làm việc đó
    )
)
SELECT 
    ROUND((w.not_purchase * 100.0) / pv.total_checkout_views, 4) AS percentage_without_purchase
FROM without_purchase w, page_view pv;


--3. What are the top 3 most viewed pages?
SELECT * FROM hqtcsdl.page_hierarchy;

WITH page_view AS(
	SELECT 
		p.page_name,
		COUNT(e.event_type)AS total_view
	FROM hqtcsdl.events e
	LEFT JOIN  hqtcsdl.page_hierarchy p 
		ON e.page_id = p.page_id
	WHERE e.event_type = 1
	GROUP BY p.page_name
)
SELECT p.page_name
FROM page_view p
ORDER BY p.total_view DESC
LIMIT 3;

--4. Số lượt xem và số lần thêm vào giỏ hàng cho từng danh mục sản phẩm là bao nhiêu?
-- page view(1), add to cart(2) of product_category
SELECT 
	p.product_category,
	COUNT(CASE WHEN e.event_type = 1 THEN 1 END) AS page_view,   -- Đếm số lượt xem trang
    COUNT(CASE WHEN e.event_type = 2 THEN 1 END) AS add_to_cart  -- Đếm số lần thêm vào giỏ
FROM  hqtcsdl.events e
JOIN hqtcsdl.page_hierarchy p
	ON e.page_id = p.page_id
WHERE p.product_category IS NOT NULL
	AND e.event_type IN (1, 2)  -- 1: page view, 2: add to cart
GROUP BY p.product_category
ORDER BY p.product_category;

--5. 3 sản phẩm có số lượt mua nhiều nhất là gì?
WITH user_action AS(
	SELECT 
		    e.visit_id,
		    e.cookie_id,
		    p.product_id,
		    p.page_name,
		    p.product_category,
		    e.event_type,
		    e.sequence_number,
		    e.event_time
		FROM hqtcsdl.events e
		JOIN hqtcsdl.page_hierarchy p
		    ON e.page_id = p.page_id
		ORDER BY e.visit_id, e.cookie_id, e.sequence_number
),
user_purchase AS(
-- delete users without purchase actions
	SELECT DISTINCT
		ua.visit_id,
		ua.cookie_id
	FROM user_action ua
	WHERE ua.event_type = 3
), full_action_u_purchase AS(
	SELECT 
		ua.visit_id,
		ua.cookie_id,
		ua.product_id,
		ua.page_name,
		ua.product_category,
		ua.event_type,
		ua.sequence_number

	FROM user_action ua
	JOIN user_purchase up
		ON ua.visit_id = up.visit_id
		AND ua.cookie_id = up.cookie_id
) 
SELECT 
	f.page_name AS product_name,
	COUNT(CASE WHEN f.event_type = 2 THEN 1 END) AS total_purchase
FROM full_action_u_purchase f
GROUP BY f.page_name
ORDER BY total_purchase DESC
LIMIT 3;

/*
6. Sử dụng một truy vấn SQL duy nhất - tạo một bảng đầu ra mới có các chi tiết
sau:
- Mỗi sản phẩm được xem bao nhiêu lần? --event_type = 1
- Mỗi sản phẩm được thêm vào giỏ hàng bao nhiêu lần? --even_type = 2
- Mỗi sản phẩm được thêm vào giỏ hàng nhưng không được mua (bị bỏ rơi)
bao nhiêu lần? -- event_type = 2 not in (3)
- Mỗi sản phẩm được mua bao nhiêu lần? -- same 5
*/
CREATE TABLE  hqtcsdl.products AS
WITH users AS(
	SELECT 
		    e.visit_id,
		    e.cookie_id,
		    p.product_id,
		    p.page_name,
		    e.event_type
		FROM hqtcsdl.events e
		JOIN hqtcsdl.page_hierarchy p
		    ON e.page_id = p.page_id
		ORDER BY e.visit_id, e.cookie_id, e.sequence_number
),
user_purchase AS(
-- delete users without purchase actions
	SELECT DISTINCT
		u.visit_id
	FROM users u
	WHERE u.event_type = 3
)
SELECT 
	u.product_id,
	u.page_name AS product_name,
	COUNT(CASE WHEN u.event_type = 1 THEN 1 END) AS view,  -- Đếm số lần xem danh mục sản phẩm
	COUNT(CASE WHEN u.event_type = 2 THEN 1 END) AS add_to_cart,  -- Đếm số lần thêm vào giỏ hàng
	COUNT(CASE WHEN u.event_type = 2
		AND u.visit_id NOT IN (SELECT DISTINCT p.visit_id FROM user_purchase p) THEN 1 END) AS add_to_cart_without_purchase,  -- Đếm số lần thêm vào giỏ nhưng không mua
	COUNT(CASE WHEN u.event_type = 2
		AND u.visit_id IN (SELECT DISTINCT p.visit_id FROM user_purchase p) THEN 1 END) AS purchase
FROM users u
WHERE u.product_id IS NOT NULL
GROUP BY u.product_id, u.page_name
ORDER BY u.product_id;

--7. Hãy tạo một bảng khác để tổng hợp thêm dữ liệu tương tự như câu 6 nhưng lần này là cho từng danh mục sản phẩm thay vì từng sản phẩm riêng lẻ
CREATE TABLE hqtcsdl.product_category AS
WITH users AS(
	SELECT 
		    e.visit_id,
			e.cookie_id,
		    p.product_category,
		    e.event_type
		FROM hqtcsdl.events e
		JOIN hqtcsdl.page_hierarchy p
		    ON e.page_id = p.page_id
		ORDER BY e.visit_id, e.cookie_id, e.sequence_number
),
user_purchase AS(
-- delete users without purchase actions
	SELECT DISTINCT
		u.visit_id
	FROM users u
	WHERE u.event_type = 3
)
SELECT 
	u.product_category,
	COUNT(CASE WHEN u.event_type = 1 THEN 1 END) AS view,  -- Đếm số lần xem danh mục sản phẩm
	COUNT(CASE WHEN u.event_type = 2 THEN 1 END) AS add_to_cart,  -- Đếm số lần thêm vào giỏ hàng
	COUNT(CASE WHEN u.event_type = 2
		AND u.visit_id NOT IN (SELECT DISTINCT p.visit_id FROM user_purchase p) THEN 1 END) AS add_to_cart_without_purchase,  -- Đếm số lần thêm vào giỏ nhưng không mua
	COUNT(CASE WHEN u.visit_id IN (SELECT DISTINCT p.visit_id FROM user_purchase p)
					AND u.event_type = 2 THEN 1 END) AS purchase
FROM users u
WHERE u.product_category IS NOT NULL
GROUP BY u.product_category;

--8. Sản phẩm nào có nhiều lượt xem, thêm vào giỏ hàng và mua nhất?
-- theo 3 tiêu chí
SELECT 
    product_id, 
    product_name,
    view,
    add_to_cart,
    purchase,
    (view + add_to_cart + purchase) AS total_score
FROM hqtcsdl.products
ORDER BY total_score DESC
LIMIT 1;



SELECT 'view' AS metric, product_id, product_name, view AS value
FROM hqtcsdl.products
WHERE view = (SELECT MAX(view) FROM hqtcsdl.products)

UNION ALL

SELECT 'add_to_cart', product_id, product_name, add_to_cart
FROM hqtcsdl.products
WHERE add_to_cart = (SELECT MAX(add_to_cart) FROM hqtcsdl.products)

UNION ALL

SELECT 'purchase', product_id, product_name, purchase
FROM hqtcsdl.products
WHERE purchase = (SELECT MAX(purchase) FROM hqtcsdl.products);


--9. Sản phẩm nào có khả năng bị bỏ rơi (thêm vào giỏ hàng nhưng không được mua) nhiều nhất?
SELECT 
	p.product_name,
	P.add_to_cart_without_purchase 
FROM hqtcsdl.products p
ORDER BY P.add_to_cart_without_purchase DESC
LIMIT 1;


--10. Sản phẩm nào có tỷ lệ phần trăm lượt xem thành mua (view to purchase) cao nhất?
SELECT
	p.product_name,
	ROUND(p.purchase *100.0/p.view, 4) AS view_to_purchase
FROM hqtcsdl.products p
ORDER BY view_to_purchase DESC
LIMIT 1;

--11. Tỷ lệ chuyển đổi trung bình từ lượt xem thành thêm vào giỏ hàng (from view to cart add) là bao nhiêu?
SELECT
	ROUND(SUM(p.add_to_cart) * 1.0 / SUM(p.view), 4) AS view_to_cart_add
FROM hqtcsdl.products p;

--12. Tỷ lệ chuyển đổi trung bình từ thêm vào giỏ hàng thành mua (from cart add to purchase) là bao nhiêu?
SELECT
	ROUND(SUM(p.purchase) * 1.0 / SUM(p.add_to_cart), 4) AS cart_add_to_purchase
FROM hqtcsdl.products p;


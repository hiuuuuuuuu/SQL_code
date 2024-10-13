
SET search_path = pizza_runner;



--UPDATE
UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation IS NOT NULL
AND cancellation NOT IN ('Restaurant Cancellation', 'Customer Cancellation');

--UPDATE
UPDATE runner_orders
SET distance = NULL
WHERE distance = 'null'

UPDATE runner_orders
SET distance = TRIM(REPLACE(REPLACE(distance, 'km', ''), ' ', '')) || ' km'
WHERE distance IS NOT NULL;

--UPDATE
UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null'


--UPDATE
UPDATE runner_orders
SET duration = NULL
WHERE duration = 'null'

ALTER TABLE runner_orders
ALTER COLUMN duration TYPE  VARCHAR(20);


UPDATE runner_orders
SET duration = CASE
                    WHEN duration LIKE '% mins' THEN duration
					WHEN duration LIKE '% minutes'THEN REPLACE(duration,' minutes', ' mins')
					WHEN duration LIKE '%mins'THEN REPLACE(duration,'mins', ' mins')
					WHEN duration LIKE '% minute'THEN REPLACE(duration,' minute', ' mins')
					WHEN duration LIKE '%minutes' THEN REPLACE(duration,'minutes', ' mins')
                    ELSE CONCAT(duration, ' mins')
                END
WHERE duration IS NOT NULL;

select * from runner_orders;

/* 1.Có bao nhiêu pizza đã được đặt?*/

SELECT 
	COUNT(order_id) AS total_pizzas_order
FROM customer_orders;

/* 2.Có bao nhiêu đơn đặt hàng khác nhau đã được đặt?*/

SELECT 
	COUNT(DISTINCT order_id) AS total_orders
FROM customer_orders;

/* 3.Với mỗi runner, bao nhiêu đơn đặt hàng đã được giao thành công?*/

SELECT 
	r.runner_id, 
	COUNT(r_o.order_id) AS successul_orders
FROM 
	runners r
LEFT JOIN runner_orders r_o ON r.runner_id=r_o.runner_id 
WHERE 
	cancellation IS NULL
GROUP BY 
	r.runner_id;


/* 4.Với mỗi customer, bao nhiêu pizza loại ‘Vegetarian’ và ‘Meatlovers’ đã được đặt?*/

SELECT 
	co.customer_id,
	COUNT(CASE WHEN pizza_name='Vegetarian' THEN 1 ELSE NULL END)  AS vegetarian_pizzas,
	COUNT(CASE WHEN pizza_name='Meatlovers' THEN 1 ELSE NULL END)  AS Meatlovers_pizzas
FROM 
	customer_orders co 
JOIN 
	pizza_names pn ON pn.pizza_id=co.pizza_id
GROUP BY
	co.customer_id;

/* 5.Số lượng pizza tối đa được giao của một đơn hàng là bao nhiêu?*/
SELECT 
	c.customer_id,
	COUNT(c.pizza_id) AS total_pizza
FROM 
	runner_orders ro JOIN customer_orders c ON ro.order_id=c.order_id
WHERE
	ro.cancellation IS NULL
GROUP BY 
	c.customer_id
ORDER BY
	total_pizza DESC
LIMIT 1;

	--cách 2
SELECT 
	order_id,
	COUNT(pizza_id) AS max_pizzas 
FROM 
	customer_orders
WHERE 
	order_id IN (SELECT order_id FROM runner_orders WHERE cancellation IS NULL)
GROUP BY
	order_id
ORDER BY
	max_pizzas DESC
LIMIT 1;



/* 6.Khối lượng đơn đặt hàng mỗi ngày trong tuần là bao nhiêu?*/    


SELECT
	TO_CHAR(order_time,'Day') AS day_of_week,
	COUNT(DISTINCT order_id) AS day_order_volumn
FROM 
	customer_orders
GROUP BY
	day_of_week;


/* 7.Có bao nhiêu runners đăng ký mỗi tuần? (tuần bắt đầu 2021-01-01)*/

SELECT 
	TO_CHAR(registration_date,'W') AS week,
	COUNT(*) AS num_signups
FROM
	runners
GROUP BY
	week
ORDER BY
	week;

/* 8.Thời gian trung bình tính bằng phút để mỗi runner đến trụ sở Pizza Runner để nhận đơn hàng là bao nhiêu?*/
WITH customer_order_distinct AS(
SELECT
	DISTINCT order_id, customer_id, order_time
FROM
	customer_orders
),
duration AS (
SELECT
	r.runner_id,
	(pickup_time::TIMESTAMP - order_time:: TIMESTAMP) AS duration
FROM 
	customer_order_distinct c JOIN runner_orders r ON c.order_id=r.order_id
WHERE
	r.pickup_time IS NOT NULL
)
SELECT 
	runner_id,
	EXTRACT(MINUTE FROM AVG(duration))  AS avg_arrival_time
FROM 
	duration
GROUP BY
	runner_id


/* 9.Với mỗi customer, quãng đường trung bình cần phải đi là bao nhiêu?*/

UPDATE runner_orders
SET distance=REPLACE(distance,' km','')

WITH distinct_orders AS(
SELECT DISTINCT
	order_id,customer_id,order_time
FROM
	customer_orders
)
SELECT
	d.customer_id,
	ROUND(AVG(r.distance::NUMERIC),2) AS avg_distance
FROM
	distinct_orders d JOIN runner_orders r ON r.order_id=d.order_id
WHERE
	r.cancellation IS NULL
GROUP BY
	d.customer_id;

/* 10.Sự chênh lệch giữa thời gian giao hàng lâu nhất và ngắn nhất cho tất cả các đơn hàng là bao nhiêu?*/

SELECT
	MAX(duration::INT) - MIN(duration::INT) AS diff_duration
FROM
	runner_orders;


SELECT
	MAX(REPLACE(duration, ' mins', '')::numeric) -
	MIN(REPLACE(duration, ' mins', '')::numeric) AS mins_different
	
FROM
	runner_orders

/* 11.Tốc độ trung bình của mỗi runner trong mỗi lần giao hàng là bao nhiêu?*/
UPDATE runner_orders
SET duration=REPLACE(duration,' mins','')

SELECT 
    runner_id,
	order_id,
	(distance::FLOAT/duration::INT)::NUMERIC(5,2) AS delivery_speed
FROM 
    runner_orders
WHERE 
    distance IS NOT NULL


/* 12.Tỷ lệ phần trăm giao hàng thành công của mỗi runner là bao nhiêu?*/ 

SELECT 	 
	runner_id,
	COUNT(CASE WHEN cancellation IS NULL THEN 1 END)*100 / COUNT(*) AS success_rate_percentage
FROM 
	runner_orders
GROUP BY 
	runner_id;


/*Các thành phần tiêu chuẩn cho mỗi pizza là gì?*/
SELECT
	pn.pizza_name,
	STRING_AGG(pt.topping_name,',') AS standard_toppings
	--string_agg ghép các thành phần nguyên liệu thành một chuỗi
FROM 
	pizza_names pn 
JOIN 
	pizza_recipes pr ON pn.pizza_id=pr.pizza_id
JOIN 
	pizza_toppings pt ON pt.topping_id IN 
								(SELECT UNNEST(string_to_array(pr.toppings, ',')::int[]))
GROUP BY                   -- string_to_array chuyển đổi giá trị trong cột toppings thành mảng
	pn.pizza_name;         --UNNEST phân tách phần tử trong mảng thành hàng đơn lẻ        



/*	Topping nào thường được thêm vào nhất?	*/
SELECT 
	pt.topping_name,
	COUNT(*) AS extras_topping
FROM
	customer_orders co
JOIN 
	pizza_toppings pt ON pt.topping_id IN(SELECT UNNEST(string_to_array(co.extras, ',')::int[]))
GROUP BY
	pt.topping_name
ORDER BY
	extras_topping DESC
LIMIT 1;


/* 	Topping nào thường bị loại ra nhất?	*/
SELECT 
	pt.topping_name,
	COUNT(*) AS  exclusion_count
FROM 
	customer_orders co
JOIN 
	pizza_toppings pt ON pt.topping_id IN (SELECT UNNEST(string_to_array(co.exclusions, ',')::int[]))
GROUP BY 
	pt.topping_name
ORDER BY 
	exclusion_count DESC
LIMIT 1;

/* Tổng số lượng của từng thành phần được sử dụng trong tất cả các loại pizza được giao là bao nhiêu,
sắp xếp theo số lượng từ cao đến thấp?*/

--thêm vào
WITH extras_tb AS(
SELECT
	UNNEST(STRING_TO_ARRAY(extras,','))::INTEGER AS extra_topping_id,
	COUNT(*) AS extra_count
FROM
	customer_orders
WHERE
	extras IS NOT NULL AND order_id NOT IN (SELECT order_id FROM runner_orders WHERE cancellation IS NOT NULL)
GROUP BY
	extra_topping_id
),
--loại ra	
exclusions_tb AS(
SELECT
	UNNEST(STRING_TO_ARRAY(exclusions,','))::INTEGER AS exc_topping_id,
	COUNT(*) AS exc_count
FROM
	customer_orders
WHERE
	exclusions IS NOT NULL AND order_id NOT IN (SELECT order_id FROM runner_orders WHERE cancellation IS NOT NULL)
GROUP BY
	exc_topping_id
),
--tổng
normal_tb AS (
SELECT
	UNNEST(STRING_TO_ARRAY(pr.toppings,','))::INTEGER AS topping_id,
	COUNT(*) AS normal_count
FROM
	customer_orders co 
JOIN
	pizza_recipes pr ON  co.pizza_id=pr.pizza_id
WHERE
	order_id IN (SELECT order_id FROM runner_orders WHERE cancellation IS NULL)
GROUP BY
	topping_id
),    
final_pizza AS(
SELECT 
	nt.topping_id,
	pt.topping_name,
	nt.normal_count AS summ,
	COALESCE(extra_count, 0) AS extra,  -- chuyển các giá trị null sang 0 
	COALESCE(exc_count,0) AS exclusion
FROM 
	 normal_tb nt 
	 LEFT JOIN  extras_tb  ON extra_topping_id=nt.topping_id 
	 LEFT JOIN  exclusions_tb  ON exc_topping_id=nt.topping_id
	 LEFT JOIN pizza_toppings pt ON pt.topping_id=nt.topping_id
)
SELECT
	topping_name,
	summ + extra - exclusion AS total_topping
FROM 
	final_pizza
ORDER BY
	total_topping DESC;

/* 17.Nếu 1 pizza Meat Lovers có giá $12, Vegetarian có giá $10, và không thêm phí cho sự thay đổi
thì tổng số tiền Pizza Runner thu được là bao nhiêu (không tính phí giao hàng)? */

SELECT
	SUM(CASE WHEN pizza_id=1 THEN 12 ELSE 10 END) AS revenue
FROM 
	customer_orders
WHERE
	order_id  IN (SELECT order_id FROM runner_orders WHERE cancellation IS NULL);

select * from customer_orders;
select * from runner_orders;
select * from pizza_names;
/* 18.Nếu thêm $1 cho mỗi extras thêm vào (ví dụ thêm cheese thì thêm $1) thì tổng số tiền Pizza Runner
thu được là bao nhiêu? */

SELECT
	SUM(CASE WHEN pizza_id=1 THEN 12 ELSE 10 END) +
	SUM(NULLIF(array_length(STRING_TO_ARRAY(extras, ',')::INT[],1),NULL)) AS total_amount
FROM 
	customer_orders
WHERE
	order_id  IN (SELECT order_id FROM runner_orders WHERE cancellation IS NULL);



/*
Nếu 1 pizza Meat Lovers có giá $12, Vegetarian có giá $10 và không thêm phí cho phần extra, 
mỗi runner được trả $0.30 trên km đi lại - Tổng số tiền Pizza Runner thu được sau khi trừ khoản
phí giao hàng cho các runner là bao nhiêu?  */
SELECT(
SELECT
	SUM(CASE WHEN pizza_id=1 THEN 12 ELSE 10 END) 
FROM 
	customer_orders
WHERE
	order_id  IN (SELECT order_id FROM runner_orders WHERE cancellation IS NULL)
)-
(SELECT
	SUM(distance::NUMERIC*0.3)
FROM
	runner_orders
WHERE
	distance IS NOT NULL
) AS amount;

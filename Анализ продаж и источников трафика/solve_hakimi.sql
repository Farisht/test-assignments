CREATE TABLE purchases (
	lastsignTrafficSource VARCHAR(50),
    purchaseID BIGINT,
    purchaseRevenue NUMERIC,
    purchaseDateTime TIMESTAMP
);

CREATE TABLE products (
    productsPurchaseID BIGINT,
    productsID BIGINT,
    productsPrice NUMERIC
);

SELECT *
FROM purchases
LIMIT 5;

SELECT *
FROM products
LIMIT 5;

SELECT COUNT(*)
FROM purchases;

SELECT COUNT(*)
FROM products;


-- 1. Количество товаров, купленных в понедельник, в разбивке по источникам. 
-- Источники по убыванию количества товаров.

SELECT p.lastsignTrafficSource AS traffic,
	COUNT(*) AS products_count
FROM purchases AS p
JOIN products AS prod ON p.purchaseID = prod.productsPurchaseID
WHERE EXTRACT(ISODOW FROM p.purchaseDateTime) = 1
GROUP BY p.lastsignTrafficSource
ORDER BY products_count desc;

-- 2. Выведите таблицу, в которой для каждого дня будут выведены id и цена товаров, которых было куплено больше всего в этот день. 
-- В таблице будет три столбца: дата, id товара, цена товара.

WITH product_counts AS(
	SELECT p.purchaseDateTime::date AS purchase_date,
	    prod.productsID,
		prod.productsPrice,
		COUNT(*) AS purchase_count
	FROM purchases AS p
	JOIN products AS prod ON p.purchaseID = prod.productsPurchaseID
	GROUP BY p.purchaseDateTime::date, prod.productsID, prod.productsPrice
	
),
ranked_products AS (
	SELECT purchase_date, productsID, productsPrice, purchase_count,
		RANK() OVER(PARTITION BY purchase_date ORDER BY purchase_count DESC) AS rnk
	FROM product_counts
)

SELECT purchase_date, productsID, productsPrice
FROM ranked_products
WHERE rnk = 1
ORDER BY purchase_date
-- лидирует один и тот же товар под айди 137958 с ценой 0, дополнительно проверим общий топ товаров за весь период
SELECT
    prod.productsID,
    prod.productsPrice,
    COUNT(*) AS purchase_count
FROM products AS prod
GROUP BY
    prod.productsID,
    prod.productsPrice
ORDER BY purchase_count DESC
LIMIT 5;

-- 3. Распределите товары по трём категориям: стоимость товара меньше или равна 4000; больше 4000 и меньше или равно 7000; больше 7000. 
-- Выведите для всех товаров таблицу-словарь из трёх колонок: id товара, цена товара, категория.
SELECT productsID AS product_id, productsPrice AS price,
CASE
WHEN productsPrice <= 4000 THEN '<= 4000'
WHEN productsPrice <= 7000 THEN '> 4000 and <= 7000'
ELSE '> 7000'
END AS category
FROM products;

-- 4. Определите для каждого товара последнюю дату, когда он появлялся в датасете, и id покупки, в которой этот товар был куплен. 
-- Выведите топ-5 товаров, которые не покупались дольше всего, дату последней покупки, и id продажи. 
-- В таблице будет три столбца: id товара, дата последней покупки, и id продажи.

WITH ranked_products AS (
SELECT prod.productsID, p.purchaseDateTime::date AS purchase_date, p.purchaseID, 
	ROW_NUMBER() OVER (PARTITION BY prod.productsID ORDER BY p.purchaseDateTime  DESC) AS rn
FROM purchases as p
JOIN products as prod ON p.purchaseID = prod.productsPurchaseID
)
SELECT productsID, purchase_date AS last_purchase_date, purchaseID
FROM ranked_products
WHERE rn = 1
ORDER BY last_purchase_date, productsID
LIMIT 5;

-- 5. Для каждого источника определите среднее количество времени, прошедшее между покупками, в которых был товар с id 293316. 
-- Время, прошедшее с первого месяца, также учитывайте, как будто первая покупка была в последний день предыдущего месяца. 
-- В таблице будет две колонки: источник и среднее время между покупками.

WITH product_purchases AS (
SELECT p.lastsignTrafficSource  AS traffic,
p.purchaseDateTime, LAG(p.purchaseDateTime) OVER (
PARTITION BY p.lastsignTrafficSource ORDER BY p.purchaseDateTime) AS previous_purchase

FROM purchases AS p
JOIN products AS prod ON p.purchaseID  = prod.productsPurchaseID
WHERE prod.productsID = 293316
),

different_time as(
SELECT traffic, 
purchaseDateTime - COALESCE(previous_purchase, DATE_TRUNC('month', purchaseDateTime) - INTERVAL '1 day'
) AS time_between
FROM product_purchases
)

SELECT traffic, JUSTIFY_INTERVAL(AVG(time_between)) AS avg_time_between
FROM different_time
GROUP BY traffic
ORDER BY traffic;

--Хакими Фаришта 

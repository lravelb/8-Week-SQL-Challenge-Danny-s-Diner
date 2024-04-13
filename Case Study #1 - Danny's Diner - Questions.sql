# 8 Week SQL Challenge - Case Study #1 - Danny's Diner

# Case Study - Question 1 - What is the total amount each customer spent at the restaurant?

USE dannys_dinner;

SELECT 
    s.customer_id, SUM(m.price) AS total_spent
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

# Case Study - Question 2 - How many days has each customer visited the restaurant?

SELECT 
    customer_id, COUNT(DISTINCT order_date) AS days_visited
FROM
    sales
GROUP BY customer_id
ORDER BY customer_id;

# Case Study - Question 3 - What was the first item from the menu purchased by each customer?

SELECT 
    s.customer_id, m.product_name as first_item_purchased
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
WHERE
    s.order_date = (SELECT MIN(order_date))
GROUP BY s.customer_id
ORDER BY s.customer_id;

# Case Study - Question 4 - What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
    m.product_name, COUNT(s.product_id) AS times_purchased
FROM
    menu m
        JOIN
    sales s ON m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY times_purchased DESC
LIMIT 1;

# Case Study - Question 5 - Which item was the most popular for each customer?

WITH product_rank AS (
SELECT 
    s.customer_id,
    m.product_name,
    COUNT(s.product_id) AS times_purchased,
    DENSE_RANK() OVER (
    PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) as product_rank
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, times_purchased
FROM product_rank
WHERE product_rank  = 1;

# Case Study - Question 6 - Which item was purchased first by the customer after they became a member?

WITH after_became_member AS (
SELECT
mm.customer_id,
s.product_id,
ROW_NUMBER() OVER(
PARTITION BY m.customer_id
ORDER BY s.order_date) AS row_num
FROM members mm 
JOIN sales s ON mm.customer_id = s.customer_id
AND s.order_date > m.join_date)
SELECT
abm.customer_id,
m.product_name
FROM after_became_member abm
JOIN menu m ON abm.product_id = m.product_id
WHERE row_num = 1
ORDER BY abm.customer_id ASC;

# Case Study - Question 7 - Which item was purchased just before the customer became a member?

WITH before_became_member AS (
SELECT
mm.customer_id,
s.product_id,
ROW_NUMBER() OVER(
PARTITION BY m.customer_id
ORDER BY s.order_date DESC) AS row_num
FROM members mm
JOIN sales s ON mm.customer_id = s.customer_id
AND s.order_date < m.join_date)
SELECT
bbm.customer_id,
m.product_name
FROM before_became_member bbm
JOIN menu m ON bbm.product_id = m.product_id
WHERE row_num = 1
ORDER BY bbm.customer_id ASC;

# Case Study - Question 8 - What is the total items and amount spent for each member before they became a member?

SELECT 
    mm.customer_id,
    COUNT(s.product_id) AS total_items,
    SUM(m.price) AS total_amount_spent
FROM
    members mm
        JOIN
    sales s ON mm.customer_id = s.customer_id
        JOIN
    menu m ON s.product_id = m.product_id
WHERE
    s.order_date < mm.join_date
GROUP BY mm.customer_id
ORDER BY mm.customer_id;

# Case Study - Question 9 - If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH customer_points AS (
SELECT
product_id,
CASE
WHEN product_id = 1 THEN price * 20 # product_id 1 = Sushi
ELSE price * 10
END AS points
FROM menu)
SELECT 
s.customer_id,
SUM(cp.points) as total_points
FROM sales s
JOIN customer_points cp on s.product_id = cp.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

# Case Study - Question 10 - In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH first_week_offer AS 
    (SELECT s.customer_id, mm.join_date, s.order_date,
        date_add(mm.join_date, interval(6) DAY) first_week, m.product_name, m.price
    FROM sales s
    LEFT JOIN members mm
      ON s.customer_id = mm.customer_id
    LEFT JOIN menu m
        ON s.product_id = m.product_id)
SELECT customer_id,
    SUM(CASE
            WHEN order_date BETWEEN join_date AND first_week THEN 20 * price 
            WHEN (order_date NOT BETWEEN join_date AND first_week) AND product_name = 'sushi' THEN 20 * price
            ELSE 10 * price
        END) points
FROM first_week_offer fwo
WHERE order_date < '2021-02-01' and customer_id BETWEEN 'A' AND 'B'
GROUP BY customer_id;

# Case Study - Bonus 1 - Join all the things

SELECT
s.customer_id,
s.order_date,
m.product_name,
m.price,
CASE 
	WHEN me.join_date > s.order_date THEN 'N'
    WHEN me.join_date <= s.order_date THEN 'Y'
    ELSE 'N' END AS `member`
FROM
 sales s
LEFT JOIN members me ON s.customer_id = me.customer_id
JOIN menu m ON s.product_id = m.product_id
ORDER BY s.customer_id, order_date;

# Case Study - Bonus 2 - Rank all the things

WITH all_joined AS(
SELECT
s.customer_id,
s.order_date,
m.product_name,
m.price,
CASE 
	WHEN me.join_date > s.order_date THEN 'N'
    WHEN me.join_date <= s.order_date THEN 'Y'
    ELSE 'N' END AS `member`
FROM
 sales s
LEFT JOIN members me ON s.customer_id = me.customer_id
JOIN menu m ON s.product_id = m.product_id
ORDER BY s.customer_id, order_date)
SELECT
*,
CASE
WHEN `member` = 'N' then null
ELSE RANK() OVER(PARTITION BY customer_id, `member` ORDER BY order_date)
END AS ranking
FROM all_joined;
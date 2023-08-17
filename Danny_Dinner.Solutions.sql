--The total amount each customer spent at the restaurant
SELECT sales.customer_id, SUM(price) as Total_Amount_Spent_By_Customer
FROM sales
LEFT JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;


--How many days has each customer visited the restaurant
SELECT customer_id, COUNT(DISTINCT(order_date)) AS visit_count
FROM sales
GROUP BY customer_id;

--The first item from the menu purchased by each customer
SELECT sales.customer_id,product_name, order_date
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
ORDER BY order_date ASC;

--The most purchased item on the menu and how many times was it purchased by all customers
SELECT product_name, COUNT(product_name) AS order_count
FROM menu
INNER JOIN sales
ON menu.product_id = sales.product_id
GROUP BY product_name
ORDER BY order_count DESC
LIMIT 1;


--The most popular item for each customer
WITH rank_order AS (
	SELECT customer_id, product_name, COUNT(product_id) AS popularity_count,
	DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) DESC )
	FROM menu m
	JOIN sales s
	USING (product_id)
	GROUP BY customer_id,product_name, product_id)
SELECT customer_id, product_name, popularity_count
FROM rank_order
WHERE DENSE_RANK = 1;


--Which item was purchased first by the customer after they became a member
WITH rank_order AS (
SELECT *, 
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date)
FROM sales AS s
JOIN members AS m
USING (customer_id)
WHERE m.join_date <= s.order_date)
SELECT customer_id, product_name, order_date, join_date
FROM rank_order
JOIN menu AS mu
USING (product_id)
WHERE DENSE_RANK = 1;


--Which item was purchased just before the customer became a member
WITH rank_order AS (
SELECT *,
      DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC)
      FROM sales AS s
      JOIN members AS m
      USING (customer_id)
      WHERE order_date < join_date)
SELECT customer_id, product_name, order_date, join_date
FROM rank_order
JOIN menu AS mu
USING (product_id)
WHERE DENSE_RANK = 1;


--What is the total items and amount spent for each member before they became a member
SELECT customer_id, COUNT(DISTINCT(product_id)) as total_items, 
  SUM(price) as amount_spent 
FROM sales
JOIN members
USING (customer_id)
JOIN menu
USING (product_id)
WHERE sales.order_date < members.join_date
GROUP BY customer_id;


--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(points) AS points
FROM (SELECT sales.customer_id,
	         CASE WHEN sales.product_id = 1 THEN menu.price  * 20
	         ELSE price * 10
         	 END AS points
	 FROM sales
	 JOIN menu
	   ON sales.product_id = menu.product_id) points
GROUP BY customer_id
ORDER BY points DESC;


--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January
SELECT customer_id, SUM(points) AS total_points
FROM (SELECT sales.customer_id,
	         CASE WHEN order_date - join_date >= 0 AND order_date - join_date <= 6 THEN menu.price  * 20
	         WHEN menu.product_name IS NOT NULL THEN menu.price * 20
	         ELSE price * 10
         	 END AS points
	 FROM members
	 JOIN sales
	   ON members.customer_id = sales.customer_id
	 JOIN menu
	   ON sales.product_id = menu.product_id
	  WHERE EXTRACT(MONTH FROM order_date) = 1 AND EXTRACT(YEAR FROM order_date) = 2021) points
GROUP BY customer_id
ORDER BY total_points DESC;
USE dannysdiner;

#1 What is the total amount each customer spent at the restaurant?
SELECT 
	customer_id, SUM(price) as total_spent
FROM 
	sales S
JOIN menu M ON S.product_id = M.product_id
GROUP BY 1
ORDER BY 1 ASC
;

#2 How many days has each customer visited the restaurant?
SELECT 
	customer_id,
    COUNT(distinct order_date) as noofvisits
FROM
	sales
GROUP BY 1
ORDER BY 1 ASC;

#3 What was the first item from the menu purchased by each customer?
WITH MinOD AS (
SELECT 
	customer_id,
    MIN(order_date) AS min_order_date
FROM
	sales S
GROUP BY 1
)
SELECT 
	DISTINCT order_date, 
    S.customer_id, 
    product_name
FROM 
	Sales S
JOIN MinOD MO ON S.customer_id = MO.customer_id
JOIN Menu M on S.product_id = M.product_id
WHERE 
	S.order_date = MO.min_order_date
;

#4 What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	product_name, 
    COUNT(*) AS noofpurchases
FROM 
	sales S
JOIN menu M on S.product_id = M.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1
;

#5 Which item was the most popular for each customer?
SELECT 
	customer_id, 
	product_name
FROM
	(
		SELECT 
			customer_id, 
			product_name, 
			DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(customer_id) DESC) AS rnk
		FROM 
			sales S
		JOIN menu M ON S.product_id = M.product_id
		GROUP BY 1, 2
	)sub
WHERE 
	rnk = 1
;

#6 Which item was first purchased by the customer after they became a member?
SELECT 
	customer_id, 
    product_name
FROM
(
	SELECT 
		S.customer_id, 
        product_name, 
        S.product_id, 
        order_date, 
        join_date, 
        MIN(order_date) OVER(PARTITION BY S.customer_id) AS min_order_date
	FROM 
		sales S
	JOIN menu M ON S.product_id = M.product_id
	JOIN members MB ON S.customer_id = MB.customer_id
	WHERE 
		order_date >= join_date
	ORDER BY 3 ASC
)sub
WHERE 
	order_date = min_order_date
;

#7 Which item was purchased just before the customer became a member?
SELECT 
	customer_id, 
	product_name
FROM
(
	SELECT 
		S.customer_id, 
        product_name, 
        S.product_id, 
        order_date, 
        join_date, 
        MAX(order_date) OVER(PARTITION BY S.customer_id) AS max_order_date
	FROM 
		sales S
	JOIN menu M ON S.product_id = M.product_id
	JOIN members MB ON S.customer_id = MB.customer_id
	WHERE 
		order_date < join_date
	ORDER BY 3 ASC
)sub
WHERE 
	order_date = max_order_date
;

#8 What is the total items and amount spent for each member before they became a member?
SELECT 
	S.customer_id, 
    COUNT(*) AS noofitems, 
    SUM(price) AS totalamount
FROM 
	sales S
JOIN Menu M on M.product_id = S.product_id
JOIN Members MB on MB.customer_id = S.customer_id
WHERE 
	order_date < join_date
GROUP BY 1
ORDER BY 1 ASC
;

#9 If each $1 spent equates to 10 points and sushi has a 2x multiplier - how many points would each customer have?
SELECT 
	customer_id,
	SUM(CASE
			WHEN S.product_id = 1 THEN price*20
			ELSE price*10
	    END) AS points
FROM
	sales S
JOIN menu M on M.product_id = S.product_id
GROUP BY 1
ORDER BY 1 ASC
;

#10 If in the first week after a customer joins the program(including their join date) they earn 2x points on all items, not just sushi - 
#how many points do customers A and B have at the end of January?
SELECT
	S.customer_id,
    SUM(
		CASE
			WHEN order_date < join_date AND S.product_id = 1 THEN price*20
			WHEN order_date < join_date AND S.product_id != 1 THEN price*10
			WHEN order_date >= join_date AND order_date < TIMESTAMPADD(WEEK, 1, join_date) THEN price*20
			WHEN order_date >= TIMESTAMPADD(WEEK, 1, join_date) AND S.product_id = 1 THEN price*20
			WHEN order_date >= TIMESTAMPADD(WEEK, 1, join_date) AND S.product_id != 1 THEN price*10
		END) AS points
FROM 
	sales S
JOIN menu M on M.product_id = S.product_id
JOIN members MB on MB.customer_id = S.customer_id
WHERE 
	MONTH(order_date) = 1
GROUP BY 1
ORDER BY 1 ASC
;

#11 Join all three tables and add a new column saying whether the customer is a member or not.
SELECT 
	S.customer_id, 
    order_date, 
    product_name, 
    price,
    CASE
		WHEN order_date < join_date THEN 'N'
        WHEN order_date >= join_date THEN 'Y'
        WHEN join_date is NULL THEN 'N'
	END AS member
FROM 
	sales S
LEFT JOIN menu M on S.product_id = M.product_id
LEFT JOIN members MB ON MB.customer_id = S.customer_id
;


#12 Rank customer products in the chronological order of their order, only when they were members.
#If they were not members, do not rank those orders.
WITH membership AS (
SELECT 
	S.customer_id, 
    order_date, 
    product_name, 
    price,
    CASE
		WHEN order_date < join_date THEN 'N'
        WHEN order_date >= join_date THEN 'Y'
        WHEN join_date is NULL THEN 'N'
	END AS member
FROM 
	sales S
LEFT JOIN menu M on S.product_id = M.product_id
LEFT JOIN members MB ON MB.customer_id = S.customer_id
),
rankedmembers AS (
SELECT
	customer_id,
    order_date,
    product_name,
    price,
    member,
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rnk
FROM membership
WHERE member = 'Y'
),
unrankedmembers AS(
SELECT
	customer_id,
    order_date,
    product_name,
    price,
    member,
    NULL AS rnk
FROM membership
WHERE member = 'N'
)
SELECT *
FROM rankedmembers
UNION ALL
SELECT *
FROM unrankedmembers
ORDER BY customer_id ASC, order_date ASC
;
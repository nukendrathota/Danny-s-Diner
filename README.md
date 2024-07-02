# Danny's Diner
![image](https://github.com/nukendrathota/Danny-s-Diner/assets/148835589/7390e0c9-c6c4-4b9e-b279-c7bc8566a06e)
## Introduction
Danny's Diner is the first of the 8 week SQL Case Study Challenges by Danny Ma. You can find all of the challenges [here](https://8weeksqlchallenge.com/).

Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.

## Problem Statement
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

You can inspect the entity relationship diagram and example data below.
![Copy of Danny's Diner](https://github.com/nukendrathota/Danny-s-Diner/assets/148835589/dcc9b1c0-f60a-412a-b6c9-8663312b979a)

## Table Preview
Here's a preview of the three tables limited to their first 5 rows.

### Sales Table
The sales table captures all customer_id level purchases with an corresponding order_date and product_id information for when and what menu items were ordered.
| customer_id | order_date | product_id |
|-------------|------------|------------|
| A           | 2021-01-01 | 1          |
| A           | 2021-01-01 | 2          |
| A           | 2021-01-07 | 2          |
| A           | 2021-01-10 | 3          |
| A           | 2021-01-11 | 3          |
| A           | 2021-01-11 | 3          |
| B           | 2021-01-01 | 2          |
| B           | 2021-01-02 | 2          |
| B           | 2021-01-04 | 1          |
| B           | 2021-01-11 | 1          |
| B           | 2021-01-16 | 3          |
| B           | 2021-02-01 | 3          |
| C           | 2021-01-01 | 3          |
| C           | 2021-01-01 | 3          |
| C           | 2021-01-07 | 3          |

### Menu Table
The menu table maps the product_id to the actual product_name and price of each menu item.
| product_id | product_name | price |
|------------|--------------|-------|
| 1          | sushi        | 10    |
| 2          | curry        | 15    |
| 3          | ramen        | 12    |


### Members Table
The final members table captures the join_date when a customer_id joined the beta version of the Danny’s Diner loyalty program.
| customer_id | join_date  |
|-------------|------------|
| A           | 2021-01-07 |
| B           | 2021-01-09 |

## Case Study Questions
### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT
  customer_id,
  SUM(price) as total_spent
FROM
  sales S
JOIN menu M ON S.product_id = M.product_id
GROUP BY 1
ORDER BY 1 ASC
;
```
| customer_id | total_spent |
|-------------|-------------|
| A           | 76          |
| B           | 74          |
| C           | 36          |

### 2. How many days has each customer visited the restaurant?

```sql
SELECT
  customer_id,
  COUNT(distinct order_date) as noofvisits
FROM
  sales
GROUP BY 1
ORDER BY 1 ASC;
```
| customer_id | noofvisits |
|-------------|------------|
| A           | 4          |
| B           | 6          |
| C           | 2          |

### 3. What was the first item from the menu purchased by each customer?

```sql
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
  sales S
JOIN MinOD MO ON S.customer_id = MO.customer_id
JOIN Menu M on S.product_id = M.product_id
WHERE
  S.order_date = MO.min_order_date
;
```
| order_date  | customer_id | product_name |
|-------------|-------------|--------------|
| 2021-01-01  | A           | sushi        |
| 2021-01-01  | A           | curry        |
| 2021-01-01  | B           | curry        |
| 2021-01-01  | C           | ramen        |

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
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
```
| product_name | noofpurchases |
|--------------|---------------|
| ramen        | 8             |

### 5. Which item was the most popular for each customer?
```sql
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
```
| customer_id | product_name |
|-------------|--------------|
| A           | ramen        |
| B           | curry        |
| B           | sushi        |
| B           | ramen        |
| C           | ramen        |

### 6. Which item was purchased first by the customer after they became a member?
```sql
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
```
| customer_id | product_name |
|-------------|--------------|
| B           | sushi        |
| A           | curry        |

### 7. Which item was purchased just before the customer became a member?
```sql
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
```
| customer_id | product_name |
|-------------|--------------|
| A           | sushi        |
| B           | sushi        |
| A           | curry        |

### 8. What is the total items and amount spent for each member before they became a member?
```sql
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
```
| customer_id | noofitems | totalamount |
|-------------|-----------|-------------|
| A           | 2         | 25          |
| B           | 3         | 40          |

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
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
```
| customer_id | points |
|-------------|--------|
| A           | 860    |
| B           | 940    |
| C           | 360    |

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
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
```
| customer_id | points |
|-------------|--------|
| A           | 1370   |
| B           | 820    |


## Bonus Questions
These questions are intended to help Danny and his team use these tables to quickly derive insights without needing to join the underlying tables using SQL.

### 11. Join all three tables and add a new column saying whether the customer is a member or not.
```sql
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
```
| customer_id | order_date  | product_name | price | member |
|-------------|-------------|--------------|-------|--------|
| A           | 2021-01-01  | sushi        | 10    | N      |
| A           | 2021-01-01  | curry        | 15    | N      |
| A           | 2021-01-07  | curry        | 15    | Y      |
| A           | 2021-01-10  | ramen        | 12    | Y      |
| A           | 2021-01-11  | ramen        | 12    | Y      |
| A           | 2021-01-11  | ramen        | 12    | Y      |
| B           | 2021-01-01  | curry        | 15    | N      |
| B           | 2021-01-02  | curry        | 15    | N      |
| B           | 2021-01-04  | sushi        | 10    | N      |
| B           | 2021-01-11  | sushi        | 10    | Y      |
| B           | 2021-01-16  | ramen        | 12    | Y      |
| B           | 2021-02-01  | ramen        | 12    | Y      |
| C           | 2021-01-01  | ramen        | 12    | N      |
| C           | 2021-01-01  | ramen        | 12    | N      |
| C           | 2021-01-07  | ramen        | 12    | N      |

### 12. Rank customer products in the chronological order of their order, only when they were members. If they were not members, do not rank those orders.
```sql
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
  FROM
    membership
  WHERE
    member = 'Y'
),
unrankedmembers AS (
  SELECT
    customer_id,
    order_date,
    product_name,
    price,
    member,
    NULL AS rnk
  FROM
    membership
  WHERE
    member = 'N'
)
SELECT *
FROM
  rankedmembers
UNION ALL
SELECT *
FROM
  unrankedmembers
ORDER BY customer_id ASC, order_date ASC
;
```
| customer_id | order_date  | product_name | price | member | rnk |
|-------------|-------------|--------------|-------|--------|-----|
| A           | 2021-01-01  | sushi        | 10    | N      | NULL |
| A           | 2021-01-01  | curry        | 15    | N      | NULL |
| A           | 2021-01-07  | curry        | 15    | Y      | 1    |
| A           | 2021-01-10  | ramen        | 12    | Y      | 2    |
| A           | 2021-01-11  | ramen        | 12    | Y      | 3    |
| A           | 2021-01-11  | ramen        | 12    | Y      | 3    |
| B           | 2021-01-01  | curry        | 15    | N      | NULL |
| B           | 2021-01-02  | curry        | 15    | N      | NULL |
| B           | 2021-01-04  | sushi        | 10    | N      | NULL |
| B           | 2021-01-11  | sushi        | 10    | Y      | 1    |
| B           | 2021-01-16  | ramen        | 12    | Y      | 2    |
| B           | 2021-02-01  | ramen        | 12    | Y      | 3    |
| C           | 2021-01-01  | ramen        | 12    | N      | NULL |
| C           | 2021-01-01  | ramen        | 12    | N      | NULL |
| C           | 2021-01-07  | ramen        | 12    | N      | NULL |

## Bonus
I have also solved this challenge using Tableau Prep. You can find the Tableau Prep Solution [here](https://github.com/nukendrathota/Danny-s-Diner/tree/0ec81359ee371e5f566738c65d428a53733421d8/tableau%20prep).

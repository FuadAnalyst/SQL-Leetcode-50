-- Select section

-- 1. Recyclable and Low Fat Products
SELECT product_id 
FROM Products
WHERE low_fats = 'Y' AND recyclable = 'Y';

-- 2. Find Customer Referee
SELECT name
FROM Customer
WHERE referee_id != 2 OR referee_id IS NULL;

-- 3. Big Countries
SELECT name, population, area
FROM World
WHERE area >= 3000000 OR population >= 25000000;

-- 4. Article Views I
SELECT DISTINCT author_id AS id
FROM Views
WHERE author_id = viewer_id
ORDER BY 1 ASC;

-- 5. Invalid Tweets
SELECT tweet_id
FROM Tweets
WHERE LENGTH(content) > 15;


-- Basic Joins section

-- 6. Replace Employee ID With The Unique Identifier
SELECT unique_id, name
FROM Employees e
LEFT JOIN EmployeeUNI eu USING(id);

-- 7. Product Sales Analysis I
SELECT product_name, year, price
FROM Sales 
INNER JOIN Product USING(product_id)
GROUP BY sale_id;

-- 8. Customer Who Visited but Did Not Make Any Transactions
SELECT customer_id, COUNT(*) AS count_no_trans
FROM Visits
WHERE visit_id NOT IN (
    SELECT visit_id 
    FROM Transactions
)
GROUP BY 1;

-- 9. Rising Temperature
with cte_yest AS (
    SELECT id, recordDate, temperature, 
    LAG(temperature) OVER (ORDER BY recordDate) AS yest_temp,
    LAG(recordDate) OVER (ORDER BY recordDate) AS yest_date
    FROM Weather
)
SELECT id
FROM cte_yest
WHERE temperature > yest_temp AND 
DATE_PART('Day', recordDate::TIMESTAMP - yest_date::TIMESTAMP) = 1

-- 10. Average Time of Process per Machine
with cte_1 AS (
    SELECT a1.machine_id, a1.timestamp, a2.machine_id AS machine_id2 , a2.timestamp AS timestamp2
    FROM Activity a1
    INNER JOIN Activity a2 ON a1.machine_id = a2.machine_id
    AND a1.process_id = a2.process_id
    AND a1.activity_type = 'start' AND a2.activity_type = 'end'
)
SELECT machine_id, ROUND(AVG(timestamp2 - timestamp)::DECIMAL, 3) AS processing_time
FROM cte_1
GROUP BY 1;

-- 11. Employee Bonus
SELECT name, bonus
FROM Employee e
LEFT JOIN Bonus b USING(empId)
WHERE bonus < 1000 OR bonus IS NULL;

-- 12. Students and Examinations
SELECT s.student_id, s.student_name, sub.subject_name, COUNT(e.subject_name) AS attended_exams
FROM Students s
CROSS JOIN Subjects sub
LEFT JOIN Examinations e ON e.student_id = s.student_id AND e.subject_name = sub.subject_name
GROUP BY 1,2,3
ORDER BY 1,3;

-- 13. Managers with at Least 5 Direct Reports
with cte1 AS (
    SELECT e1.name, COUNT(e2.managerId) AS c
    FROM Employee e1 
    INNER JOIN Employee e2 ON e1.id = e2.managerId
    GROUP BY e1.id
)
SELECT name
FROM cte1
WHERE c >= 5;

-- or
SELECT name
FROM Employee
WHERE id in (
	SELECT managerId
	FROM Employee
	GROUP BY 1
	HAVING count(*) >= 5
);

-- 14. Confirmation Rate
WITH cte1 as (
    SELECT s.user_id,
    SUM(
        CASE 
            WHEN action = 'confirmed' THEN 1
            ELSE 0
        END
    ) AS action_num, COUNT(action) as action_count
    FROM Signups s
    LEFT JOIN Confirmations c using(user_id)
    GROUP BY 1
)
SELECT user_id, COALESCE(ROUND(action_num/action_count, 2)::DECIMAL, 0) AS confirmation_rate
FROM cte1;


-- Basic Aggregate Functions section

-- 15. Not Boring Movies
SELECT id, movie, description, rating
FROM Cinema
WHERE mod(id, 2) <> 0 AND description <> 'boring'
ORDER BY rating DESC;

-- 16. Average Selling Price
with cte_1 AS (
    SELECT p.product_id, 
    ROUND(SUM(
        CASE WHEN purchase_date BETWEEN start_date AND end_date 
        THEN price * units
        END
    )::DECIMAL, 2) AS average_price
    FROM Prices p
    LEFT JOIN UnitsSold us USING(product_id)
    GROUP BY 1
)
SELECT product_id, COALESCE(ROUND(average_price / sub.sum_units, 2), 0) AS average_price
FROM cte_1 LEFT JOIN (
    SELECT product_id, sum(units) AS sum_units
    FROM UnitsSold
    GROUP BY 1
) sub USING(product_id)

-- 17. Project Employees I
SELECT project_id, ROUND(AVG(experience_years), 2) AS average_years
FROM Project p
INNER JOIN Employee e ON p.employee_id = e.employee_id 
GROUP BY 1

-- 18. Percentage of Users Attended a Contest
SELECT contest_id, ROUND(COUNT(user_id) / (SELECT COUNT(*) FROM Users) * 100, 2) AS percentage
FROM Register 
GROUP BY contest_id
ORDER BY percentage DESC, contest_id ASC

-- 19. Queries Quality and Percentage
SELECT query_name, 
    ROUND(SUM(rating / position) / COUNT(query_name), 2) AS quality, 
    ROUND(SUM(rating < 3) / COUNT(rating) * 100, 2) AS poor_query_percentage
FROM Queries
WHERE query_name IS NOT NULL
GROUP BY query_name;

-- 20. Monthly Transactions I
SELECT DATE_FORMAT(trans_date, '%Y-%m') AS month, 
	   country, 
       COUNT(state) AS trans_count, 
	   SUM(IF(state='approved', 1, 0)) AS approved_count,
	   SUM(amount) AS trans_total_amount,
	   SUM(IF(state='approved', amount, 0)) AS approved_total_amount
FROM Transactions
GROUP BY 1, 2;

-- 21. Immediate Food Delivery II
WITH cte1 AS (
    SELECT delivery_id, customer_id, order_date, customer_pref_delivery_date,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_num
    FROM Delivery
),
cte2 AS (
    SELECT delivery_id, customer_id, SUM(IF(customer_pref_delivery_date = order_date, 1, 0)) AS immediate
    FROM cte1
    WHERE order_num = 1
    GROUP BY 1,2
)
SELECT ROUND(SUM(immediate) / COUNT(*) * 100, 2) AS immediate_percentage
FROM cte2;

-- 22. Game Play Analysis IV
with cte1 AS (
	SELECT *, lead(event_date) OVER (PARTITION BY player_id ORDER BY event_date) AS next_date
	FROM Activity
	ORDER BY player_id, event_date
),
cte2 AS (
	SELECT player_id, event_date, datediff(next_date, event_date) AS diff
	FROM cte1
)
SELECT ROUND(COUNT(diff) / (SELECT COUNT(player_id) FROM Activity), 2) AS fraction 
FROM cte2
WHERE diff = 1;

-- or
SELECT player_id, event_date, sub.first_login + 1
FROM (
	SELECT player_id, MIN(event_date) AS first_login 
    FROM Activity 
    GROUP BY 1
) sub INNER JOIN Activity USING(player_id);


-- Sorting and Grouping section

-- 23. Number of Unique Subjects Taught by Each Teacher
SELECT teacher_id, COUNT(DISTINCT subject_id) as cnt
FROM Teacher
GROUP BY 1;

-- 24. User Activity for the Past 30 Days I
SELECT activity_date AS day, COUNT(DISTINCT user_id) as active_users
FROM Activity
WHERE activity_date <= DATE('2019-07-27') AND DATEDIFF('2019-07-27', activity_date) < 30
GROUP BY 1;

-- 25. Product Sales Analysis III
with cte1 as (
    SELECT product_id, year as first_year, quantity, price,
    dense_rank() over (partition by product_id order by year) as dr
    FROM Sales
)
SELECT product_id, first_year, quantity, price
FROM cte1
WHERE dr = 1;

-- 26. Classes More Than 5 Students
SELECT class
FROM Courses
GROUP BY 1
HAVING COUNT(class) >= 5;

-- 27. Find Followers Count
SELECT user_id, COUNT(DISTINCT follower_id) AS followers_count
FROM Followers
GROUP BY 1
ORDER BY 1;

-- 28. Biggest Single Number
SELECT MAX(num) AS num
FROM (
    SELECT num
    FROM MyNumbers
    GROUP BY 1
    HAVING COUNT(num) = 1
);

-- 29. Customers Who Bought All Products
with cte_cust as (
    SELECT customer_id, COUNT(DISTINCT product_key) AS unique_prod
    FROM Customer
    GROUP BY 1
),
cte_prod as (
    SELECT COUNT(DISTINCT product_key) AS unique_key
    FROM Product
)
SELECT customer_id
FROM cte_cust
INNER JOIN cte_prod ON cte_cust.unique_prod = cte_prod.unique_key;


-- Advanced Select and Joins section

-- 30. The Number of Employees Which Report to Each Employee
SELECT e1.employee_id, e1.name, COUNT(e2.reports_to) AS reports_count, ROUND(AVG(e2.age), 0) AS average_age 
FROM Employees e1
inner join Employees e2 on e1.employee_id = e2.reports_to 
GROUP BY 1
ORDER BY 1;

-- 31. Primary Department for Each Employee
SELECT employee_id, department_id
FROM Employee
WHERE primary_flag = 'Y' OR 
employee_id IN (
    SELECT employee_id 
    FROM Employee 
    GROUP BY 1 
    HAVING COUNT(*) = 1
);

-- 32. Triangle Judgement
SELECT x, y, z, 
    CASE WHEN x + y > z AND x + z > y AND y + z > x THEN 'Yes'
    ELSE 'No'
    END AS triangle
FROM Triangle;

-- 33. Consecutive Numbers
with cte1 AS (
    SELECT id, num AS ConsecutiveNums,
    LAG(num) OVER (ORDER BY id) AS prev,
    LEAD(num) OVER (ORDER BY id) AS next
    FROM Logs
)
SELECT DISTINCT ConsecutiveNums
FROM cte1
WHERE ConsecutiveNums = next AND ConsecutiveNums = prev;

-- 34. Product Price at a Given Date
with cte_1 AS (
    SELECT DISTINCT product_id, new_price as price, 
    row_number() OVER (PARTITION BY product_id ORDER BY change_date DESC) as rn
    FROM Products
    WHERE change_date <= '2019-08-16'
)
SELECT product_id, price
FROM cte_1
WHERE rn = 1
    UNION 
SELECT DISTINCT product_id, 10 AS price
FROM Products
WHERE product_id NOT IN (
    SELECT product_id 
    FROM Products 
    WHERE change_date <= '2019-08-16'
);

-- 35. Last Person to Fit in the Bus
WITH cte_1 AS (
    SELECT person_name, 
    SUM(weight) OVER (ORDER BY turn) AS sum_loop
    FROM Queue
)
SELECT person_name
FROM cte_1
WHERE sum_loop <= 1000
ORDER BY sum_loop DESC
LIMIT 1;

-- 36. Count Salary Categories
SELECT 'Low Salary' AS category,
SUM(CASE WHEN income < 20000 THEN 1 ELSE 0 END) AS accounts_count
FROM Accounts
	UNION
SELECT 'Average Salary' AS category,
SUM(CASE WHEN income >= 20000 AND income <= 50000 THEN 1 ELSE 0 END) AS accounts_count
FROM Accounts
	UNION
SELECT 'High Salary' AS category,
SUM(CASE WHEN income > 50000 THEN 1 ELSE 0 END) AS accounts_count
FROM Accounts;


-- Subqueries section

-- 37. Employees Whose Manager Left the Company
SELECT employee_id
FROM Employees
WHERE salary < 30000 AND manager_id NOT IN (
    SELECT employee_id
    FROM Employees
)
ORDER BY employee_id;

-- 38. Exchange Seats
SELECT id,
CASE 
	WHEN id%2 = 0 THEN (lag(student) over (order by id))
	ELSE COALESCE(lead(student) over (order by id), student)
END as "student"
FROM Seat;

-- 39. Movie Rating
with cte_1 as (
    SELECT name AS results
    FROM Users u 
    INNER JOIN MovieRating mr ON u.user_id = mr.user_id
    GROUP BY 1
    ORDER BY COUNT(*) DESC, 1
    LIMIT 1
),
cte_2 as (
    SELECT title AS results
    FROM Movies m 
    INNER JOIN MovieRating mr ON m.movie_id = mr.movie_id
    WHERE EXTRACT(MONTH FROM created_at) = 2 AND EXTRACT(YEAR FROM created_at) = 2020
    GROUP BY 1
    ORDER BY AVG(rating) DESC, 1 -- Even if i use agg function here in ORDER BY, i still have to write GROUP BY
    LIMIT 1
)
SELECT * FROM cte_1
    UNION ALL
SELECT * FROM cte_2;

-- 40. Restaurant Growth
with cte_1 AS (
    SELECT visited_on, SUM(amount) as sum_amount
    FROM Customer
    GROUP BY 1
),
cte_2 AS (
	SELECT visited_on, 
	SUM(sum_amount) OVER (ORDER BY visited_on, visited_on rows between 6 preceding and current row) AS amount,
	ROUND(AVG(sum_amount) OVER (ORDER BY visited_on, visited_on rows between 6 preceding and current row)::DECIMAL, 2) AS average_amount
	FROM cte_1
)
SELECT * FROM cte_2
WHERE visited_on - INTERVAL '6 days' IN (SELECT visited_on FROM cte_1);

-- 41. Friend Requests II: Who Has the Most Friends
SELECT id, COUNT(*) as num
FROM(
    SELECT requester_id AS id
    FROM RequestAccepted
        UNION ALL
    SELECT accepter_id AS id
    FROM RequestAccepted
)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 42. Investments in 2016
SELECT ROUND(SUM(tiv_2016)::DECIMAL, 2) AS tiv_2016
FROM Insurance
WHERE tiv_2015 IN (
    SELECT tiv_2015
    FROM Insurance
    GROUP BY 1
    HAVING COUNT(*) > 1
) AND (lat, lon) NOT IN (
    SELECT lat, lon
    FROM Insurance
    GROUP BY 1, 2
    HAVING COUNT(lat) > 1 AND COUNT(lon) > 1
);

-- 43. Department Top Three Salaries (Hard)
with cte_1 AS (
    SELECT d.name as Department, e.name as Employee, e.salary as Salary,
    dense_rank() over (partition by d.name order by salary desc) as rn
    FROM Employee e 
    INNER JOIN Department d ON e.departmentId = d.id
)
SELECT Department, Employee, Salary
FROM cte_1
WHERE rn <= 3;


-- Advanced String Functions / Regex / Clause section

-- 44. Fix Names in a Table
SELECT user_id, CONCAT(UPPER(SUBSTRING(name, 1, 1)), LOWER(SUBSTRING(name, 2))) AS name
FROM Users
ORDER BY user_id;

-- 45. Patients With a Condition
SELECT patient_id, patient_name, conditions
FROM Patients
WHERE conditions LIKE 'DIAB1%' OR conditions LIKE '% DIAB1%';

-- 46. Delete Duplicate Emails
DELETE FROM Person
WHERE id NOT IN (
    SELECT min_id FROM (
        SELECT min(Id) AS min_id 
        FROM Person 
        GROUP BY Email
    ) AS a
);

-- 47. Second Highest Salary
with cte_1 AS (
    SELECT salary, 
    dense_rank() over (order by salary desc) as rn
    FROM Employee
)
SELECT MAX(salary) AS SecondHighestSalary
FROM cte_1
WHERE rn = 2;

-- 48. Group Sold Products By The Date
SELECT sell_date, COUNT(DISTINCT product) AS num_sold, STRING_AGG(DISTINCT product, ',' ORDER BY product) AS products
FROM Activities
GROUP BY 1
ORDER BY 1;

-- 49. List the Products Ordered in a Period
SELECT product_name, SUM(unit) AS unit
FROM Products p
INNER JOIN Orders o USING(product_id)
WHERE TO_CHAR(o.order_date,'YYYY-MM') ='2020-02'
GROUP BY 1
HAVING SUM(unit) >= 100
ORDER BY unit desc;

-- 50. Find Users With Valid E-Mails
SELECT *
FROM Users
WHERE mail ~ '^[a-zA-Z][a-zA-Z0-9_.-]*@leetcode[.]com$';







-- 1. Identify the number of employees within each department that share the same birth month. Your output should list the department, birth month, and the number of employees from that department who were born in that month. If a month has no employees born in it within a specific department, report this month as having 0 employees.
WITH RECURSIVE all_months AS (SELECT DISTINCT profession, 1 AS months
FROM employee_list
UNION ALL
SELECT profession, months+1
FROM all_months
WHERE months<12),
CTE2 AS (SELECT profession, birth_month, COUNT(*) as num_of_births
FROM employee_list
GROUP BY profession, birth_month)
SELECT a.profession, a.months, COALESCE(num_of_births, 0)
FROM all_months a LEFT JOIN CTE2 b ON a.profession=b.profession AND a.months=b.birth_month 


-- 2. Find the 3-month rolling average of total revenue from purchases given a table with users, their purchase amount, and date purchased. Do not include returns which are represented by negative purchase values. Output the year-month (YYYY-MM) and 3-month rolling average of revenue, sorted from earliest month to latest month.
-- A 3-month rolling average is defined by calculating the average total revenue from all user purchases for the current month and previous two months. The first two months will not be a true 3-month rolling average since we are not given data from last year. Assume each month has at least one purchase.
WITH CTE AS (select  
    DATE_FORMAT(created_at, '%Y-%m') as monthly_format, 
    SUM(purchase_amt) as monthly_total
from amazon_purchases
WHERE purchase_amt >0
GROUP BY monthly_format
ORDER BY monthly_format )
SELECT monthly_format, 
CASE WHEN monthly_total <>0 AND previous_month <>0 AND two_months_ago <>0 THEN (monthly_total+previous_month+two_months_ago)/3 
    WHEN previous_month=0 AND two_months_ago=0 THEN monthly_total
    WHEN two_months_ago=0 AND previous_month>0 THEN (monthly_total+previous_month)/2
ELSE NULL END as not_null
FROM(SELECT 
    *,   
    COALESCE(LAG(monthly_total) OVER(ORDER BY monthly_format),0) as previous_month,
    COALESCE(LAG(monthly_total, 2) OVER(ORDER BY monthly_format),0) as two_months_ago
FROM CTE
ORDER BY monthly_format) tbl2


-- 3. Find the number of days a US track has stayed in the 1st position for both the US and worldwide rankings on the same day. Output the track name and the number of days in the 1st position. Order your output alphabetically by track name.
-- If the region 'US' appears in dataset, it should be included in the worldwide ranking.
WITH CTE AS (SELECT date, trackname
FROM spotify_daily_rankings_2017_us
WHERE position=1
ORDER BY 2),
CTE2 AS (SELECT date, trackname
FROM spotify_worldwide_daily_song_ranking
WHERE region='us' AND position=1)
SELECT a.trackname, COUNT(a.date)
FROM CTE a JOIN CTE2 b ON a.date=b.date AND a.trackname=b.trackname
GROUP BY a.trackname
ORDER BY 1 

-- 4. Find the number of employees who received the bonus and who didn't. Bonus values in employee table are corrupted so you should use  values from the bonus table. Be aware of the fact that employee can receive more than bonus.
-- Output value inside has_bonus column (1 if they had bonus, 0 if not) along with the corresponding number of employees for each.
WITH CTE AS (select id, 
    CASE WHEN bonus_amount IS NOT NULL THEN 1 ELSE 0 END AS has_bonus
from employee a LEFT JOIN bonus b ON a.id=b.worker_ref_id)
SELECT has_bonus, COUNT(DISTINCT id)
FROM CTE
GROUP BY has_bonus

-- 5. Find the top 5 highest paid and top 5 least paid employees in 2012. Output the employee name along with the corresponding total pay with benefits.
-- Sort records based on the total payment with benefits in ascending order.
SELECT employeename, totalpaybenefits
FROM (select employeename, totalpaybenefits, 
RANK() OVER(ORDER BY totalpaybenefits DESC) AS ranked
from sf_public_salaries
WHERE year=2012
ORDER BY totalpaybenefits DESC) tbl
WHERE ranked BETWEEN 1 AND 5 OR
ranked BETWEEN 66 AND 70
ORDER BY totalpaybenefits 


-- 6. Find the gender ratio between the number of men and women who participated in each Olympics.
-- Output the Olympics name along with the corresponding number of men, women, and the gender ratio. If there are Olympics with no women, output a NULL instead of a ratio.
SELECT games, 
    COUNT(CASE WHEN sex='F' THEN sex ELSE NULL END) AS fem_cnt,
    COUNT(CASE WHEN sex='M' THEN sex ELSE NULL END) As male_cnt,
   COUNT(CASE WHEN sex='M' THEN sex ELSE NULL END)/ COUNT(CASE WHEN sex='F' THEN sex ELSE NULL END) As gender_ratio
FROM (select games, id, sex
from olympics_athletes_events
GROUP BY games, id, sex) tbl
GROUP BY games
ORDER BY 3 DESC


-- 7. Write a query to find the number of days between the longest and least tenured employee still working for the company. Your output should include the number of employees with the longest-tenure, the number of employees with the least-tenure, and the number of days between both the longest-tenured and least-tenured hiring dates. 
WITH CTE AS (select *, 
COALESCE(termination_date, '2019-11-22') as new_term_date,
DATEDIFF(COALESCE(termination_date, '2019-11-22'),hire_date) as time_working
from uber_employees)
SELECT COUNT(CASE WHEN time_working =(SELECT MAX(time_working) from CTE) THEN time_working ELSE NULL END) as longest_tenure,
COUNT(CASE WHEN time_working =(SELECT MIN(time_working) from CTE) THEN time_working ELSE NULL END) as shortest_tenure,
(SELECT MAX(time_working) from CTE)-(SELECT MIN(time_working) from CTE) as hiring_dates
FROM CTE
WHERE time_working =(SELECT MAX(time_working) from CTE) 
OR time_working= (SELECT MIN(time_working) from CTE)

-- 8.Which company had the biggest month call decline from March to April 2020? Return the company_id and calls difference for the company with the highest decline.
SELECT company_id, cnt-previous_month
FROM (SELECT  EXTRACT(MONTH FROM date) as monthly_date, company_id, COUNT(call_id) as cnt,
    LAG(COUNT(call_id)) OVER(PARTITION BY company_id ORDER BY EXTRACT(month from date) ASC) as previous_month
FROM rc_calls a LEFT JOIN rc_users b 
    ON a.user_id=b.user_id
GROUP BY EXTRACT(MONTH FROM date), company_id
ORDER BY 1) tbl
WHERE previous_month IS NOT NULL
ORDER BY cnt-previous_month 
LIMIT 1

-- 9.You have been asked to calculate the average earnings per order segmented by a combination of weekday (all 7 days) and hour using the column customer_placed_order_datetime.
-- The gross order total is the total of the order before adding the tip and deducting the discount and refund.
-- Note: In your output, the day of the week should be represented in text format (i.e., Monday). Also, round earnings to 2 decimals
SELECT week_name, hour_format, ROUND(AVG(net_total_order), 2)
FROM (select 
    DAYNAME(customer_placed_order_datetime) as week_name, 
    EXTRACT(HOUR FROM customer_placed_order_datetime) as hour_format,
    order_total+tip_amount-discount_amount-refunded_amount as net_total_order
from doordash_delivery) tbl
GROUP BY week_name, hour_format

-- 10.The company you work for has asked you to look into the average order value per hour during rush hours in the San Jose area. Rush hour is from 15H - 17H inclusive.
-- You have also been told that the column order_total represents the gross order total for each order. Therefore, you'll need to calculate the net order total.
-- The gross order total is the total of the order before adding the tip and deducting the discount and refund.
-- Use the column customer_placed_order_datetime for your calculations.
SELECT hour, AVG(net_order_total)
FROM (select 
    EXTRACT(HOUR FROM customer_placed_order_datetime) as hour,
    order_total,
    tip_amount,
    refunded_amount,
    discount_amount,
    order_total+tip_amount-discount_amount-refunded_amount AS net_order_total
from delivery_details
WHERE EXTRACT(HOUR FROM customer_placed_order_datetime) IN (15, 16, 17)
    AND lower(delivery_region) LIKE '%san jose%') tbl
GROUP BY hour 


-- 11.Write a query to calculate the longest period (in days) that the company has gone without hiring anyone. Also, calculate the longest period without firing anyone. Limit yourself to dates inside the table (last hiring/termination date should be the latest hiring /termination date from table), don't go into future.
WITH CTE AS (SELECT 
    hired,
    LAG(hired) OVER(ORDER BY hired ASC),
    DATEDIFF(hired, LAG(hired) OVER(ORDER BY hired ASC)) as time_btw_hire
FROM (select 
    DISTINCT hire_date as hired
from uber_employees
ORDER BY hire_date ASC) tbl),
CTE2 AS (
SELECT fired,LAG(fired) OVER(ORDER BY fired ASC), 
DATEDIFF(fired, LAG(fired) OVER(ORDER BY fired ASC)) as time_btw_fire
FROM(select 
    DISTINCT termination_date as fired
	from uber_employees
	WHERE termination_date IS NOT NULL) tbl2)
SELECT MAX(time_btw_fire), MAX(time_btw_hire)
FROM CTE2 FULL JOIN CTE 


-- 12.The company you work with wants to find out what merchants are most popular for new customers.
-- You have been asked to find how many orders and first-time orders each merchant has had. First-time orders are meant from the perspective of a customer, and are the first order that a customer ever made. In order words, for how many customers was this the first-ever merchant they ordered with?
-- Note: Recently, new restaurants have been registered on the system; however, because they may not have received any orders yet, your answer should exclude restaurants that have not received any orders.
-- Your output should contain the name of the merchant, the total number of their orders, and the number of these orders that were first-time orders.
WITH CTE AS (
	SELECT name, COUNT(id) as total_orders
	FROM (
		select a.id, a.customer_id, a.order_timestamp, a.merchant_id, b.name
		from order_details a LEFT JOIN merchant_details b ON a.merchant_id=b.id) as tbl
		GROUP BY name),
CTE2 AS (SELECT name, COUNT(id) as first_time_orders
		FROM 
			(select a.id, a.customer_id, a.order_timestamp, a.merchant_id, b.name, RANK() OVER(PARTITION BY customer_id ORDER BY order_timestamp) as ranked
			from order_details a LEFT JOIN merchant_details b ON a.merchant_id=b.id) tbl2
		WHERE ranked=1
		GROUP BY name)
SELECT a.name, a.total_orders, IFNULL(b.first_time_orders, 0)
FROM CTE a LEFT JOIN CTE2 b ON a.name=b.name


-- 13. List the IDs of customers who made at least 3 orders in both 2020 and 2021.
SELECT user_id
FROM (select *,
	CASE WHEN order_date LIKE '%2020%' THEN 1 ELSE 0 END as 2020_purchase,
	CASE WHEN order_date LIKE '%2021%' THEN 1 ELSE 0 END as 2021_purchase
	from amazon_orders) tbl
GROUP BY user_id
HAVING sum(2021_purchase) >2 AND SUM(2020_purchase)>2
 
 
-- 14. A group of travelers embark on world tours starting with their home cities. Each traveler has an undecided itinerary that evolves over the course of the tour. Some travelers decide to abruptly end their journey mid-travel and live in their last destination.
-- Given the dataset of dates on which they travelled between different pairs of cities, can you find out how many travellers ended back in their home city? For simplicity, you can assume that each traveler made at most one trip between two cities in a day.
WITH CTE AS (
	select a.traveler, MIN(a.date) as start_date, b.end_date as final_date
	from travel_history a JOIN 
        (select traveler, MAX(date) as end_date
        from travel_history 
        GROUP BY traveler) 
                                b ON a.traveler=b.traveler
GROUP BY a.traveler)
SELECT COUNT(c.traveler)
FROM CTE c JOIN travel_history d ON c.start_date=d.date AND c.traveler=d.traveler
    JOIN travel_history e ON c.final_date=e.date AND c.traveler=e.traveler
WHERE d.start_city=e.end_city

-- 15.Write a query to get the list of managers whose salary is less than twice the average salary of employees reporting to them. For these managers, output their ID, salary and the average salary of employees reporting to them.
WITH CTE AS (
	select a.manager_empl_id AS managers_id, AVG(salary) AS salary_per_manager
	from map_employee_hierarchy a JOIN dim_employee b ON a.empl_id=b.empl_id
	GROUP BY a.manager_empl_id),
CTE2 AS (
	SELECT a.manager_empl_id AS managers_id2, b.salary as managers_salary
	FROM map_employee_hierarchy a JOIN dim_employee b 
    ON a.manager_empl_id=b.empl_id
	GROUP BY manager_empl_id)
SELECT managers_id, salary_per_manager, managers_salary
FROM CTE b JOIN CTE2 d ON b.managers_id=d.managers_id2
WHERE managers_salary < (salary_per_manager*2.0)


-- 16. The company you work for is looking at their delivery drivers' first-ever delivery with the company.
-- You have been tasked with finding what percentage of drivers' first-ever completed orders have a rating of 0.
-- Note: Please remember that if an order has a blank value for actual_delivery_time, it has been canceled and therefore does not count as a completed delivery.
SELECT 
	SUM(CASE WHEN delivery_rating=0 THEN 1 ELSE 0 END)/SUM(CASE WHEN delivery_rating IS NOT NULL THEN 1 ELSE 0 END)*100.0 as total_ratings
FROM (
	select driver_id, actual_delivery_time, delivery_rating,
    RANK() OVER(PARTITION BY driver_id ORDER BY actual_delivery_time ASC) as ranked
	FROM delivery_orders
	WHERE actual_delivery_time IS NOT NULL) tbl
WHERE ranked=1

-- 17. What is the last name of the employee or employees who are responsible for the most orders?
SELECT last_name
FROM (select 
    resp_employee_id,
    last_name, 
    COUNT(order_id) as cnt, 
    RANK() OVER(ORDER BY COUNT(order_id) DESC) as ranked
from shopify_orders a LEFT JOIN  shopify_employees b 
    ON a.resp_employee_id=b.id
GROUP BY resp_employee_id, last_name) tbl
WHERE ranked=1


-- 18.Find the product with the most orders from users in Germany. Output the market name of the product or products in case of a tie.
WITH CTE AS (select product_id, COUNT(product_id) as cnt
from shopify_users a LEFT JOIN shopify_orders b 
    ON a.id=b.user_id
    LEFT JOIN map_product_order c
    ON b.order_id =c.order_id
WHERE lower(country) LIKE '%germany%'
GROUP BY product_id
ORDER BY cnt DESC)
SELECT market_name
FROM (SELECT market_name, cnt, RANK() OVER(ORDER BY cnt DESC) as ranked
FROM dim_product d JOIN CTE e ON d.prod_sku_id=e.product_id) tbl
WHERE ranked=1


-- 19.After a new user creates an account and starts watching videos, the user ID, video ID, and date watched are captured in the database. Find the top 3 videos most users have watched as their first 3 videos. Output the video ID and the number of times it has been watched as the users' first 3 videos. In the event of a tie, output all the videos in the top 3 that users watched as their first 3 videos.
WITH CTE AS (SELECT video_id, COUNT(*) as watched_cnt, DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) as watched_rank
FROM (select 
    *,
    RANK() OVER(PARTITION BY user_id ORDER BY watched_at) as ranked
FROM videos_watched) tbl
WHERE ranked IN (1,2,3)
GROUP BY video_id
ORDER BY 2 DESC)
SELECT video_id, watched_cnt
FROM CTE 
WHERE watched_rank < 4

-- 20. Christmas is quickly approaching, and your team anticipates an increase in sales. To predict the busiest restaurants, they wanted to identify the top two restaurants by ID in terms of sales in 2022. The output should include the restaurant IDs and their corresponding sales.
-- Note: Please remember that if an order has a blank value for actual_delivery_time, it has been canceled and therefore does not count towards monthly sales.
SELECT restaurant_id, total_sales
FROM (select 
    restaurant_id, 
    SUM(sales_amount) as total_sales,
    RANK() OVER(ORDER BY SUM(sales_amount) DESC) as ranked
FROM delivery_orders a JOIN order_value b 
    ON a.delivery_id=b.delivery_id
WHERE actual_delivery_time IS NOT NULL 
    AND EXTRACT(year from order_placed_time)=2022
GROUP BY restaurant_id) tbl
WHERE ranked < 3


-- 21. Tiktok want to find out what were the top two most active user days during an advertising campaign they ran in the first week of August 2022 (between the 1st to the 7th). Identify the two days with the highest user activity during the advertising campaign. They've also specified that user activity must be measured in terms of unique users.
-- Output the day, date, and number of users. Be careful that some function can add a padding (whitespaces) around the string, for a solution to be correct you should trim the extra padding.
SELECT TRIM(DAYNAME(date_visited)), date_visited, distinct_user_cnt
FROM (SELECT 
    EXTRACT(DAY FROM date_visited) as day_format, 
    date_visited, 
    COUNT(DISTINCT TRIM(user_id)) as distinct_user_cnt,
    RANK() OVER(ORDER BY COUNT(DISTINCT TRIM(user_id)) DESC ) as ranked
from user_streaks
WHERE date_visited BETWEEN '2022-08-01' AND '2022-08-07'
GROUP BY 1, 2
ORDER BY 3 DESC) tbl
WHERE ranked < 3

-- 22. You have been asked to calculate the rolling average for book sales in 2022.
-- Output the month, the sales for that month, and an extra column containing the rolling average rounded to the nearest whole number.
select
    EXTRACT(month FROM order_date) as month, 
    SUM(unit_price*quantity) AS monthly_sales,
    ROUND(AVG(SUM(unit_price*quantity)) OVER(ORDER BY EXTRACT(month FROM order_date)),0) as rolling_avg
from amazon_books a JOIN book_orders b ON a.book_id=b.book_id
WHERE EXTRACT(YEAR FROM order_date)=2022
GROUP BY 1

-- 23. It's time to find out who is the top employee. You've been tasked with finding the employee (or employees, in the case of a tie) who have received the most votes.
-- A vote is recorded when a customer leaves their 10-digit phone number in the free text customer_response column of their sign up response (occurrence of any number sequence with exactly 10 digits is considered as a phone number). Output the top employee and the number of customer responses that left a number.
SELECT employee_id, cnt
FROM(
	select employee_id, COUNT(customer_response) as cnt,
	RANK() OVER(ORDER BY COUNT(customer_response) DESC ) as ranked
	FROM customer_responses
	WHERE customer_response  REGEXP '([0-9])'
	GROUP BY employee_id) tbl
WHERE ranked =1

-- 24. You have been asked to compare sales of the current month, May, to those of the previous month, April.
-- The company requested that you only display products whose sales have increased by more than 10% from the previous month to the current month.
-- Your output should include the product id and the percentage growth in sales.
WITH CTE AS (SELECT monthly_format, product_id, total_sales,
    LAG(total_sales) OVER(PARTITION BY product_id ORDER BY monthly_format) as previous_monthly_sales
FROM (select 
    EXTRACT(MONTH FROM date) as monthly_format, 
    product_id, 
    SUM(cost_in_dollars*units_sold) as total_sales
from online_orders
WHERE EXTRACT(MONTH FROM date) IN (4, 5)
GROUP BY EXTRACT(MONTH FROM date), product_id
ORDER BY 1, 2) tbl)
SELECT  product_id,
(previous_monthly_sales-total_sales)/previous_monthly_sales*100.0*-1
FROM CTE 
WHERE (previous_monthly_sales-total_sales)/previous_monthly_sales*100.0*-1 > 9


-- 25.Find the most expensive products on Amazon for each product category. Output category, product name and the price (as a number)
SELECT product_category, product_name,price_int
FROM (
SELECT 
    product_category, 
    CAST(REPLACE(price, '$', '') AS float) as price_int, 
    product_name,
    RANK() OVER(PARTITION BY product_category ORDER BY CAST(REPLACE(price, '$', '') AS float) DESC) as ranked
FROM innerwear_amazon_com) as tbl
WHERE ranked =1


-- 26. Find the 80th percentile of hours studied. Output hours studied value at specified percentile.
SELECT DISTINCT hrs_studied
FROM (
SELECT hrs_studied, PERCENT_RANK() OVER(ORDER BY hrs_studied) as percentiles
FROM sat_scores
) tbl
WHERE percentiles LIKE '%0.80%'


-- 27. Find the average number of days between the booking and check-in dates for AirBnB hosts. Order the results based on the average number of days in descending order.
SELECT id_host, AVG(ABS(DATEDIFF(ds_checkin, ts_booking_at)))
FROM airbnb_contacts
GROUP BY id_host
HAVING AVG(ABS(DATEDIFF(ds_checkin, ts_booking_at))) IS NOT NULL
ORDER BY 2 DESC


-- 28. Find the first and last inspections for vermin infestations per municipality. Output the result along with the business postal code.
SELECT business_postal_code, DATE_FORMAT(MIN(inspection_date), '%Y-%m-%d'), DATE_FORMAT(MAX(inspection_date), '%Y-%m-%d')
FROM sf_restaurant_health_violations
WHERE lower(violation_description) LIKE '%vermin infestation%'
GROUP BY business_postal_code


-- 29. Find top crime categories in 2014 based on the number of occurrences. Output the number of crime occurrences alongside the corresponding category name. Order records based on the number of occurrences in descending order
SELECT category, COUNT(incidnt_num)
FROM sf_crime_incidents_2014_01
WHERE EXTRACT(YEAR FROM date)=2014
GROUP BY category
ORDER BY 2 DESC


-- 30. Find employees who earn the same salary. Output the worker id along with the first name and the salary in descending order.
SELECT a.worker_id, a.first_name, a.salary
FROM worker a JOIN worker b ON a.salary=b.salary AND a.worker_id<>b.worker_id
ORDER BY a.salary DESC


-- 31. You have been asked to find the employee with the highest salary in each department. Output the department name, full name of the employee(s), and corresponding salary.
SELECT department, CONCAT(first_name, ' ', last_name), salary
FROM worker
WHERE salary IN (select MAX(salary)
FROM worker
GROUP BY department)


-- 32. Find the 10 lowest rated hotels. Output the hotel name along with the corresponding average score.
SELECT hotel_name, average_score
FROM (SELECT 
    hotel_name,
    average_score, 
    RANK() OVER(ORDER BY average_score) as ranked
from hotel_reviews
GROUP BY 1, 2) tbl
WHERE ranked < 11


-- 33. Find the number of athletes who participated in the Olympics that hosted in European cities. European cities: Berlin, Athina, Lillehammer, London, Albertville and Paris.
SELECT COUNT(DISTINCT id)
FROM olympics_athletes_events
WHERE lower(city) IN ('berlin', 'athina', 'lillehammer', 'london', 'albertville', 'paris')


-- 34. Find the median age of gold medal winners across all Olympics.
SELECT age
FROM (select age, ROW_NUMBER() OVER(ORDER BY age DESC) as assigned_row
from olympics_athletes_events
WHERE lower(medal) = 'gold'
ORDER BY age DESC) tbl
WHERE assigned_row = (SELECT COUNT(*)/2 from olympics_athletes_events
WHERE lower(medal) = 'gold')


-- 35. Find the employee who earned the lowest total payment with benefits from a list of employees who earned more from other payments compared to their base pay. Output the first name of the employee along with the corresponding total payment with benefits.
SELECT SUBSTRING_INDEX(employeename,' ', 1), totalpaybenefits
FROM sf_public_salaries
WHERE totalpaybenefits = (select MIN(totalpaybenefits)
FROM sf_public_salaries
WHERE totalpay > basepay)


-- 36. Find all combinations of 3 numbers that sum up to 8. Output 3 numbers in the combination but avoid summing up a number with itself.
SELECT DISTINCT a.number, b.number, c.number
FROM transportation_numbers a 
    JOIN transportation_numbers b 
    ON a.number <> b.number
    JOIN transportation_numbers c
    ON b.number<>c.number AND a.number<>c.number
WHERE a.number+b.number+c.number=8


-- 37. Find the global churn rate of Lyft drivers across all years. Output the rate as a ratio.
select 
    COUNT(CASE WHEN end_date IS NOT NULL THEN end_date ELSE NULL END )/ COUNT(*)
from lyft_drivers


-- 38. Find all provinces which produced more wines in 'winemag_p1' than they did in 'winemag_p2'. Output the province and the corresponding wine count. Order records by the wine count in descending order.
WITH CTE AS (SELECT province, COUNT(*) as cnt1
FROM winemag_p1
GROUP BY province
ORDER BY 2 DESC),
CTE2 AS (SELECT province, COUNT(*) as cnt2
FROM winemag_p2
GROUP BY province
ORDER BY 2 DESC)
SELECT a.province, a.cnt1
FROM CTE a JOIN CTE2 b 
    ON a.province=b.province
WHERE a.cnt1 > b.cnt2
ORDER BY 2 DESC


-- 39. Find the vintage years of all wines from the country of Macedonia. The year can be found in the 'title' column. Output the wine (i.e., the 'title') along with the year. The year should be a numeric or int data type.
SELECT title, CAST(year_from_title AS unsigned)
FROM (select title, 
substring_index(substring_index(title, ' ', 2), ' ',-1) AS year_from_title
from winemag_p2
WHERE lower(country) = 'macedonia') tbl


-- 40. Find the average age of guests reviewed by each host.
Output the user along with the average age.
WITH CTE AS (SELECT from_user AS host, to_user AS guest
FROM airbnb_reviews
WHERE from_type='host')
SELECT b.host,  AVG(a.age)
FROM airbnb_guests a JOIN CTE b
    ON a.guest_id=b.guest
GROUP BY b.host
ORDER BY 1


-- 41. Find matching pairs of Meta/Facebook employees such that they are both of the same nation, different age, same gender, and at different seniority levels. Output ids of paired employees.
SELECT a.id, b.id
FROM facebook_employees a JOIN facebook_employees b 
    ON a.id<>b.id AND a.location=b.location AND a.age<>b.age AND a.gender=b.gender AND a.is_senior<>b.is_senior


-- 42. Find how many events happened on MacBook-Pro per company in Argentina from users that do not speak Spanish. Output the company id, language of users, and the number of events performed by users.
SELECT company_id, language, COUNT(event_name)
FROM playbook_events JOIN playbook_users USING (user_id)
WHERE lower(device) LIKE '%macbook%pro%' AND lower(location) = 'argentina' AND lower(language) <> 'spanish'
GROUP BY company_id


-- 43. You have been asked to find the employees with the highest and lowest salary.
-- Your output should include the employee's ID, salary, and department, as well as a column salary_type that categorizes the output by: * 'Highest Salary' represents the highest salary * 'Lowest Salary' represents the lowest salary
SELECT worker_id, salary, department,
CASE 
    WHEN salary = (select MAX(salary)
FROM worker) THEN 'Highest Salary' ELSE  'Lowest Salary' 
     END AS salary_type
FROM worker
WHERE salary = (select MAX(salary)
FROM worker) OR salary = (select MIN(salary)
FROM worker)


-- 44. Rank each host based on the number of beds they have listed. The host with the most beds should be ranked 1 and the host with the least number of beds should be ranked last. Hosts that have the same number of beds should have the same rank but there should be no gaps between ranking values. A host can also own multiple properties.
-- Output the host ID, number of beds, and rank from highest rank to lowest.
SELECT host_id, sum(n_beds),
DENSE_RANK() OVER(ORDER BY sum(n_beds) DESC)
FROM airbnb_apartments
GROUP BY host_id
ORDER BY sum(n_beds) DESC


-- 45. Meta/Facebook Messenger stores the number of messages between users in a table named 'fb_messages'. In this table 'user1' is the sender, 'user2' is the receiver, and 'msg_count' is the number of messages exchanged between them.
-- Find the top 10 most active users on Meta/Facebook Messenger by counting their total number of messages sent and received. Your solution should output usernames and the count of the total messages they sent or received
SELECT user1, SUM(cnt)
FROM (
	SELECT user1, SUM(msg_count) as cnt
	FROM fb_messages
	GROUP BY user1
	UNION 
	SELECT user2, SUM(msg_count)
	FROM fb_messages
	GROUP BY user2) tbl
GROUP BY user1
ORDER BY SUM(cnt) DESC
LIMIT 10


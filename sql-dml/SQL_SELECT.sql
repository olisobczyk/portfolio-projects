/*
Oliwier Sobczyk
EPAM COURSE Database Mentoring Programme

Last Update: 30.03.2026
	Version for the second commit before the review
	Added UPPER/LOWER in multiple places
	Fixed year condition =2015 -> >=2015 ~ line 370
	changed OUTER JOIN to INNER JOIN ~ line 510
	

IMPORTANT! - whole file can be run at once - each query is named as described below, 
therefore can be easily accessed in the results tab by its name

Each "main" task is described first with list of assumptions for it and the 
performance results for each method. These results may vary accross different
machines and current RAM occupation.
Afterwards, there is a description for each of the query type method
JOIN, CTE and Subqeries. Each method has its pros and cons list and 
a production choice - whether I would use it or not.

Each method is described with a following structure 
	Task 1 subtask 1 is described as:
		T1.1_JOIN - join method
		T1.1_CTE - CTE method
		T1.1_SUB - subquery method


Abbreviations used
	act: actor
	addr: address
	cat: category
	film_cat: film_category
	flm_act: film_actor
	invt: inventory
	pmnt: payment
	rtl: rental
	curr: current
	prev: previous
	CTE: Common Table Expression and CTE method query
	SUB: Subquery method query
	JOIN: Join method query
 */


/* 
TASK 1.1
 
The marketing team needs a list of animation movies between
2017 and 2019 to promote family-friendly content in an upcoming
season in stores. Show all animation movies released during this
period with rate more than 1, sorted alphabeticall
 
Assumptions:
	"Rate more than 1" refers to the rental_rate column, not the age rating
	"Animation movies" means the category name is 'animation'
	"Family-friendly" implies the age rating 'G'
	The result requires only the film title

Results:
 	time JOIN: 0.006s (fastest)
	time CTE: 0.039 
	time SUB: 0.04 (slowest)
*/


/* T1.1_JOIN

JOIN Types Used: LEFT OUTER JOIN is used from film to film_category to ensure starting with the core film list
INNER JOIN is used for the category table to strictly filter only those films that have a matching 'animation' category.

LEFT OUTER JOIN: 	This type of join ensures that all the records from the film table are included, 
					irrespective of whether they have a matching record in the film_category table.
					This means that if a film does not have a category assigned to it in the database, 
					the film will still be included in the final dataset, but the columns for the categories will be NULL.
					If an INNER JOIN had been used, then the film would not be included in the final dataset.

INNER JOIN: 		This type of join requires that there be a match in the film_category and the category tables.
					This means that if there is a record in the film_category table that does not have a matching 
					category_id in the category table, then the whole record will not be included in the final dataset.


Performance Impact: The INNER JOIN is a strict filter, eliminating non-matching rows as early as possible.
					This limits the amount of data stored in memory for the final filtering and sorting stages, 
					making this query execute very fast (0.006s)

Pros: 	Highly readable and logically straightforward
		Execution time is the fastest (0.006s)

Cons: 	If multiple categories were assigned to a single film, it could create duplicate rows

Production Choice: I would use this JOIN solution in production because it is the most optimized
				   and readable approach for filtering based on related tables.
 */


--NAME:T1.1_JOIN
SELECT			film.title
FROM			public.film	film
LEFT OUTER JOIN	public.film_category film_cat	ON film_cat.film_id = film.film_id
INNER JOIN		public.category	cat				ON cat.category_id 	= film_cat.category_id
WHERE			
		film.release_year 	BETWEEN 2017 AND 2019 	AND
		UPPER(film.rating::text) 	= 'G' 			AND
		film.rental_rate 			> 1 			AND
		LOWER(cat.name) 			= 'animation'
ORDER BY film.title ASC;


/* T1.1_SUB

JOIN Types Used: None. This query relies on WHERE IN conditions.

Pros: 	Isolates the filtering logic directly into the WHERE clause without altering the main FROM structure

Cons: 	Hard to read due to multiple nesting levels
		Slower execution because the database creates three separate read steps

Production Choice: I would not use this in production. It is memory inefficient and complex to maintain and considerably slower than join method.
 */

--NAME:T1.1_SUB
SELECT		film.title
FROM		public.film	film
WHERE		
		film.rental_rate 			> 1 			AND
		film.release_year 	BETWEEN 2017 AND 2019 	AND
		UPPER(film.rating::text) 	= 'G'	 	 	AND
		film.film_id 		IN (
			SELECT	film_cat.film_id
			FROM	public.film_category film_cat
			WHERE 	film_cat.category_id 	= (
						SELECT	cat.category_id
						FROM	public.category	cat
						WHERE	
							LOWER(cat.name) = 'animation'
						)	
			);

/* T1.1_CTE

EXISTS 	Checks whether a matching animation film_id exists in the CTE without returning or joining any data 
		from it. This is more efficient than IN for large CTEs as it stops on the first match found.

JOIN Types Used: INNER JOIN is used inside the CTE to strictly link film IDs to their category names

INNER JOIN (inside CTE): 	Omits any film_category rows without a valid category_id to match to the category table
							A LEFT OUTER JOIN would have preserved the film_category rows without category information, 
							effectively passing NULL category names to the final query.

Performance Impact: 	The database creates the actual intersection of the two tables in memory before processing the final query
						This takes slightly longer (0.039s) than the direct query because the query engine must process 
						the temporary result set before the final filters can be applied.

Pros: 	The CTE acts as a clear preparation step
		It is reusable in case of need for later expansion

Cons: 	Slower than the JOIN method (0.039s)
		For a single use, it occupies unnecessary space in memory
		
Production Choice: 	I would only use this in production if the report required querying multiple different categories in subsequent steps
					For this single task, it is over-engineered
					

 */

--NAME:T1.1_CTE
WITH CategoryFilmsCTE AS (
	SELECT	film_cat.film_id,
			cat.name
	FROM		public.film_category film_cat
	INNER JOIN	public.category cat 			ON cat.category_id = film_cat.category_id
)
SELECT	film.title
FROM	public.film	film
WHERE	film.release_year 	BETWEEN 2017 AND 2019 	AND
		UPPER(film.rating::text)	= 'G' 			AND
		film.rental_rate 			> 1 			AND
		EXISTS (
			SELECT	1
			FROM	CategoryFilmsCTE	CTE
			WHERE	
					CTE.film_id 	= film.film_id 	AND
					LOWER(CTE.name) = 'animation'
			)
ORDER by film.title ASC;

/* TASK 1.2

The finance department requires a report on store performance to assess profitability 
and plan resource allocation for stores after March 2017. Calculate the revenue earned by 
each rental store after March 2017 (since April) (include columns: address and address2 – 
as one column, revenue)

Assumptions:  
	"After March 2017" means any payment date greater than or equal to '2017-04-01'
	Revenue is the sum of the amount column in the payment table
	Address 1 and Address 2 should be combined with a space
	Results will be ordered by revenue DESC for their unification and to show the most "valueable" store

Results:
	time JOIN: 0.062
	time CTE: 0.072 (slowest)
	time SUB: 0.036 (fastest)
*/

/* T1.2_JOIN  

JOIN Types Used:	INNER JOIN is used across all tables (store, address, inventory, rental, payment).
					This strictly ensures it only calculates revenue for inventory items that were actually rented and paid for

INNER JOIN (multiple): 	This operation requires a strict intersection on store, address, inventory, rental, and payment.
						A store without an address, an inventory item without a rental, or a rental without a payment is entirely 
						eliminated from the result set. However, if LEFT OUTER JOINs were employed, stores with zero rentals or 
						zero payments would be included with NULL amounts.

Performance Impact: 	The use of sequential INNER JOINs on five tables requires the DB engine to calculate the intersection of 
						all transactional data prior to the application of the SUM operation. This operation increases resource 
						utilization and slows down the query (0.062s) as the transactional tables grow
						
Pros: 	Keeps all relationships visible in one block

Cons:	Thousands of rows to join before applying the SUM aggregation
		Even longer execution on massive datasets  

Production Choice:	I would not use this in a high-volume production environment due to the risk of joining large transactional tables before aggregating
 */

--NAME:T1.2_JOIN
SELECT	CONCAT(addr.address, ' ', addr.address2) 	AS address,
		SUM(pmnt.amount)							AS revenue
FROM		public.store		store
INNER JOIN	public.address		addr	ON addr.address_id	= store.address_id
INNER JOIN	public.inventory	invt	ON invt.store_id 	= store.store_id
INNER JOIN	public.rental		rtl		ON rtl.inventory_id = invt.inventory_id
INNER JOIN	public.payment		pmnt	ON pmnt.rental_id 	= rtl.rental_id
WHERE		DATE(pmnt.payment_date) >= '2017-04-01'
GROUP BY 	store.store_id,
			addr.address,
		 	addr.address2
ORDER BY	revenue DESC;

/* T1.2_SUB

JOIN Types Used: INNER JOIN is used inside the subquery to link rentals and payments, calculating revenue first before joining to inventory

INNER JOIN (inside subquery): 	Only keeps the rows from the rentals table where there is a match in the payments table.
								Rentals with unpaid status, i.e., no match in the payments table, are filtered out.

INNER JOIN (outer): 	Eliminates any rows in the inventory table where there is no match in the aggregated revenue inside the subquery.
						Those inventory items with zero revenue generated are completely filtered out.

Performance Impact: 	By aggregating the rows in the payments table before using the outer INNER JOIN, fan-out effect is avoided and 
						achieve the best performance of 0.036s
						
Pros: Very fast (0.036s) because it uses an "inside-out" strategy, aggregating the heavy transactional data first before looking up store addresses

Cons: The deep nesting makes the code harder to read

Production Choice:	I would use this in production.
					It is the most performant way to handle large transactional aggregations by isolating the heavy lifting.
 */

--NAME:T1.2_SUB
SELECT (
		SELECT	CONCAT(addr.address, ' ', addr.address2)
		FROM	public.address	addr
		WHERE	addr.address_id = (
			SELECT	store.address_id
			FROM	public.store 	store
			WHERE	store.store_id = store_revenue.store_id
			)
		) AS address,
		store_revenue.revenue
FROM (
		SELECT	invt.store_id,
				SUM(revenue.amount)	AS revenue
		FROM	public.inventory invt
		INNER JOIN	(
				SELECT	pmnt.amount,
						rtl.inventory_id
				FROM		public.rental	rtl
				INNER JOIN	public.payment	pmnt	ON pmnt.rental_id = rtl.rental_id
				WHERE		DATE(pmnt.payment_date) >= '2017-04-01'
				) revenue ON revenue.inventory_id = invt.inventory_id
		GROUP BY invt.store_id
		) 	store_revenue
ORDER BY 	store_revenue.revenue DESC;
		
/* T1.2_CTE

INNER JOIN is used within the CTE to gather all daily revenue lines linked to specific stores. The address is 
resolved separately in the main query via a correlated subquery on the address table.

INNER JOIN (Multiple, Inside CTE): 	Eliminates any store, any inventory item, and any rental transaction that does not have a fully matching 
									chain terminating in the payment table.
									
Performance Impact: 	Having the database materialize millions of rows of joined transactional data inside a CTE prior to the final 
						grouping operation forces the database to store a massive structure in memory. This is the slowest method, 
						taking 0.072s.
									
Pros:	Highly readable
		Separates the data gathering (CTE) from the data presentation (main query)

Cons: 	Slower execution (0.072s) because it scans the CTE as a temporary result set

Production Choice: 	I would use this if the team values readability and modularity over raw speed.
 */

--NAME:T1.2_CTE
WITH DailyRevenueCTE AS (
	SELECT	pmnt.amount			AS d_revenue,
			store.store_id		AS s_id,
			pmnt.payment_date,
			store.address_id	AS s_a_id
	FROM		public.store		store
	INNER JOIN	public.inventory	invt	ON invt.store_id 	= store.store_id
	INNER JOIN	public.rental		rtl		ON rtl.inventory_id = invt.inventory_id
	INNER JOIN	public.payment		pmnt	ON pmnt.rental_id 	= rtl.rental_id
)
SELECT	(
		SELECT	CONCAT(addr.address, ' ', addr.address2)
		FROM	public.address	addr
		WHERE	addr.address_id = CTE.s_a_id
		) 					AS address,
		SUM(CTE.d_revenue) 	AS revenue
FROM 	DailyRevenueCTE		CTE
WHERE 		DATE(CTE.payment_date) >= '2017-04-01'
GROUP BY 	CTE.s_id,
			address
ORDER BY 	revenue DESC;



/* TASK 1.3
 
The marketing department in our stores aims to identify the most successful actors since 2015 to boost customer
interest in their films. Show top-5 actors by number of movies (released after 2015) they took part in 
(columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)

Assumptions:  
	"Since 2015" is interpreted strictly as release year greater than 2015
	The success metric is purely the volume of films, not revenue
	In case of a tie in movie counts, sorting alphabetically by first name is applied

Results:
	time JOIN: 0.116 (slowest)
	time CTE: 0.032 (fastest)
	time SUB: 0.088
*/

/* T1.3_JOIN 
 
JOIN Types Used: 	INNER JOIN connects actors to their films.
					This filters out any actors who have not starred in any movies after 2015

INNER JOIN (multiple): 	The query will not include a row from the actor table unless there is a row from the film_actor table, and vice versa.
						The query will not include a film_actor row unless there is a row from the film table. The query will not include an 
						actor with zero films. If a LEFT OUTER JOIN had been employed, all actors would be included, with NULL values for the release year.

Performance Impact: 	The database materialises the full joined result set all matching actors and films before applying the GROUP BY clause.
						The text-intensive, unaggregated query results make this approach the slowest, taking 0.116s.
						
Pros: Simple syntax and easy to understand

Cons: 	Slowest execution (0.116s) because it joins all tables before applying the GROUP BY aggregation

Production Choice: I would avoid this in production for large databases because grouping after joining is inefficient.
 
 */

--NAME:T1.3_JOIN
SELECT	act.first_name,
		act.last_name,
		COUNT(*) AS number_of_movies
FROM		public.actor		act
INNER JOIN	public.film_actor 	flm_act	ON flm_act.actor_id = act.actor_id
INNER JOIN	public.film	 		film	ON film.film_id 	= flm_act.film_id
WHERE		film.release_year >= 2015
GROUP BY	act.actor_id
ORDER BY	number_of_movies	DESC,
			act.first_name 		ASC
LIMIT 5;

/* T1.3_CTE 
 
JOIN Types Used: 	INNER JOIN is used inside the CTE to link films to actor IDs, and then again in the main query to attach actor names

INNER JOIN (inside CTE): This eliminates the film_actor junction table rows that do not have a matching valid film row.

INNER JOIN (outer): This eliminates the rows in the actor table that do not match the pre-aggregated IDs provided by the CTE.

Performance Impact: The INNER JOIN on the text-intensive actor table is now after the aggregation to the numerical IDs, and the engine has to 
					process far fewer rows for the final step, thus optimizing the execution plan (0.032s for CTE).

Pros: 	Fastest execution time (0.032s)
		It aggregates the movie counts by ID first, then joins the actor names, saving processing power

Cons: 	Slightly longer code structure

Production Choice: 	I would definitely use this in production
					It is highly scalable and very fast
 */

--NAME:T1.3_CTE
WITH ActorMoviesCTE AS (
	SELECT	flm_act.actor_id	AS a_id,
			film.release_year	AS f_y,
			COUNT(*)			AS count_movies_p_year
	FROM		public.film_actor 	flm_act
	INNER JOIN	public.film 		film	ON film.film_id = flm_act.film_id
	GROUP BY 	flm_act.actor_id,
				film.release_year
)
SELECT	act.first_name,
		act.last_name,
		SUM(CTE.count_movies_p_year)	AS number_of_movies
FROM		ActorMoviesCTE 	 CTE
INNER JOIN	public.actor	 act	ON act.actor_id = CTE.a_id
WHERE CTE.f_y >= 2015
GROUP BY	act.actor_id,
			act.first_name,
		 	act.last_name
ORDER BY	number_of_movies 	DESC,
		 	act.first_name 		ASC
LIMIT 5;


/* T1.3_SUB

JOIN Types Used: 	INNER JOIN connects the pre-aggregated subquery (which counted the movies) to the actor table

INNER JOIN (inside subquery): This eliminates the film_actor junction table rows that do not have a matching valid film row

INNER JOIN (outer): This eliminates the rows in the actor table that do not match the pre-aggregated IDs provided by the subquery

Performance Impact:	The INNER JOIN on the text-intensive actor table is now after the aggregation to the numerical IDs, and the engine
					has to process far fewer rows for the final step, thus optimizing the execution plan (0.088s for subqury).

Pros: Follows the efficient "inside-out" strategy like the CTE

Cons: Less readable than the CTE approach due to the nested FROM clause

Production Choice: This is a solid backup, but the CTE is preferred for readability while offering similar performance.
 */

--NAME:T1.3_SUB
SELECT	act.first_name,
		act.last_name,
		SUM(actor_films.count_movies_p_year)	AS number_of_movies
FROM (
		SELECT	flm_act.actor_id	AS a_id,
				film.release_year	AS f_y,
				COUNT(*)			AS count_movies_p_year
		FROM		public.film_actor	flm_act
		INNER JOIN	public.film			film	ON film.film_id = flm_act.film_id
		GROUP BY flm_act.actor_id,
				 film.release_year
	) 		actor_films
INNER JOIN	public.actor act		ON act.actor_id = actor_films.a_id
WHERE		actor_films.f_y >= 2015
GROUP BY	act.actor_id,
			act.first_name,
			act.last_name
ORDER BY	number_of_movies 	DESC,
			act.first_name 		ASC
LIMIT 5;

/* TASK 1.4

The marketing team needs to track the production trends of Drama, Travel, and Documentary films to inform genre-specific 
marketing strategies. Show number of Drama, Travel, Documentary per year (include columns: release_year, number_of_drama_movies, 
number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)

Assumptions:  
	Data should be pivoted to show categories as columns.
	Years that might not have any films (NULL values) should be handled in these specific categories by using conditional aggregation (CASE WHEN)  
	All years should be displayed, even if they only contain NULL or 0 values for these categories
	Ordering by the realease year in descending order
 
Results:
	time JOIN: 0.052
	time CTE: 0.032 (fastest)
	time SUB: 0.056 (slowest)
*/

/* T1.4_JOIN
  

INNER JOIN (multiple): Joining categories which have any films

Performance Impact:	FULL OUTER JOINs require the database engine to perform a full table scan of both tables and keep all the non-matched 
					values in memory, which is very resource-intensive and will not scale well as the amount of data grows.
					
Pros: 	Safely captures all timeline data without dropping years

Cons: 	FULL OUTER JOIN is resource-intensive and can generate massive intermediate tables 

Production Choice: 	I would use this carefully in production
					It works well here but could be dangerous on larger datasets
 */

--NAME:T1.4_JOIN
SELECT	film.release_year,
		SUM(CASE WHEN LOWER(cat.name) = 'documentary' 	THEN 1 ELSE 0 END)	AS number_of_documentary_movies,
		SUM(CASE WHEN LOWER(cat.name) = 'travel' 		THEN 1 ELSE 0 END)	AS number_of_travel_movies,
		SUM(CASE WHEN LOWER(cat.name) = 'drama' 		THEN 1 ELSE 0 END)	AS number_of_drama_movies
FROM		public.film			film
INNER JOIN	public.film_category 	film_cat	ON film_cat.film_id = film.film_id
INNER JOIN	public.category			cat			ON cat.category_id 	= film_cat.category_id
GROUP BY	film.release_year
ORDER BY	film.release_year DESC;

/* T1.4_CTE  

JOIN Types Used: FULL OUTER JOIN is used inside the CTE to build a complete baseline of years and categories

FULLINNER JOIN (inside CTE): 	This behaves in exactly the same way as T1.4_JOIN, ensuring that include all 
								films and categories are includedc.

Performance Impact:	By using a CTE, the actual table is seperated scanning from the CASE statement logic
					This means the query can be processed slightly quicker (0.032s) than the JOIN approach

Pros: 	Fastest execution (0.032s) and cleanly separates the structural join from the pivoting logic
		Possibility for expanding main query to browse for other catgerios
		Can be also filtered by year without changing the CTE

Cons:	Code is slightly longer

Production Choice: 	I would use this in production
					t balances the safety of the FULL OUTER JOIN with better performance
 */

--NAME:T1.4_CTE
WITH FilmYearCatCTE AS (
	SELECT	film.release_year AS year,
			cat.name
	FROM		public.film			film
	INNER JOIN	public.film_category	film_cat	ON film_cat.film_id = film.film_id
	INNER JOIN	public.category			cat			ON cat.category_id 	= film_cat.category_id
)
SELECT	CTE.year													AS release_year,
		SUM(CASE WHEN LOWER(CTE.name) = 'documentary' 	THEN 1 ELSE 0 END)	AS number_of_documentary_movies,
		SUM(CASE WHEN LOWER(CTE.name) = 'travel' 		THEN 1 ELSE 0 END)	AS number_of_travel_movies,
		SUM(CASE WHEN LOWER(CTE.name) = 'drama' 		THEN 1 ELSE 0 END)	AS number_of_drama_movies
FROM	 FilmYearCatCTE CTE
GROUP BY CTE.year
ORDER BY CTE.year DESC;

/* T1.4_SUB
 
JOIN Types Used: FULL OUTER JOIN is used inside the subquery to gather the raw data before the outer query pivots it

INNER JOIN (inside subquery): 	This behaves in exactly the same way as T1.4_JOIN, ensuring that all films and categories
									are included.

Pros: 	Keeps the pivot logic separate from the join logic  

Cons: 	Harder to debug than a CTE if the raw data looks incorrect

Production Choice: I prefer the CTE over this subquery version for readability
 */

--NAME:T1.4_SUB
SELECT	FilmCatYear.release_year,
		SUM(CASE WHEN LOWER(FilmCatYear.name) = 'documentary'	THEN 1 ELSE 0 END)	AS number_of_documentary_movies,
		SUM(CASE WHEN LOWER(FilmCatYear.name) = 'travel' 		THEN 1 ELSE 0 END)	AS number_of_travel_movies,
		SUM(CASE WHEN LOWER(FilmCatYear.name) = 'drama' 		THEN 1 ELSE 0 END)	AS number_of_drama_movies
FROM	(
		SELECT	film.release_year	AS release_year,
				cat.name
		FROM		public.film				film
		INNER JOIN	public.film_category 	film_cat	ON film_cat.film_id = film.film_id
		INNER JOIN	public.category			cat			ON cat.category_id  = film_cat.category_id
		) FilmCatYear
GROUP BY FilmCatYear.release_year
ORDER BY FilmCatYear.release_year DESC;

/* TASK 2.1

The HR department aims to reward top-performing employees in 2017 with bonuses to recognize their contribution to stores revenue.
Show which three employees generated the most revenue in 2017? 

Assumptions: 
	Staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
	If staff processed the payment then he works in the same store; 
	Take into account only payment_date - only the date in 2017 from '2017-01-01' till '2017-12-31'
	The attribute store_id in staff table stores the most recent store he works in *discussion deduction
	To get the contributions to their home store then the staff.store_id should be link to inventory.store_id as itonly this 
	differs between rented from others stores and home store *discussion deduction

Results:
	time JOIN: 0.131 (fastest)
	time CTE: 0.190 (slowest)
	time SUB: 0.133 (fastest)

All methods use inner join:
INNER JOIN (multiple): 	This is a very restrictive approach in T2.1_JOIN. It only allows data to exist at the exact intersection of 
						the data in the staff table, payment table, rental table, and inventory table. This means that if a staff 
						member has made zero payments, they are excluded entirely.

Performance Impact: 	The exact intersection of un-aggregated data in the T2.1_JOIN method has a significant impact on computation 
						time. This computation time is 0.131 seconds. With T2.1_SUB, the data structure was changed to a correlated 
						subquery in the SELECT statement. While correlated subqueries examine one row at a time, the INNER JOINs 
						in the T2.1_SUB method restrict the aggregation to only those exact transactions related to a specific staff member.
 */

/* T2.1_JOIN  

JOIN Types Used: 	INNER JOIN links staff, payment, rental, and inventory.
					This ensures only completed revenue cycles aligned with the staff's home store are chosen
 
Pros:	 Directly links all necessary data points in one block

Cons: 	Prone to slowing down as transaction volume grows

Production Choice: 	I would use this only for small databases
 */

--NAME:T2.1_JOIN
SELECT	staff.first_name	AS first_name,
		staff.last_name		AS last_name,
		staff.store_id		AS last_store_id,
		SUM(pmnt.amount)	AS revenue
FROM		public.staff 		staff
INNER JOIN	public.payment		pmnt	ON pmnt.staff_id	 = staff.staff_id
INNER JOIN	public.rental	 	rtl		ON rtl.rental_id	 = pmnt.rental_id
INNER JOIN	public.inventory	invt	ON invt.inventory_id = rtl.inventory_id
WHERE		staff.store_id 							= invt.store_id AND
			EXTRACT(YEAR FROM pmnt.payment_date) 	= 2017
GROUP BY 	staff.staff_id,
			staff.first_name,
		 	staff.last_name,
		 	staff.store_id
ORDER BY	revenue DESC
LIMIT 3;

-- If the revenue counts from all stores:
SELECT	staff.first_name	AS first_name,
		staff.last_name		AS last_name,
		staff.store_id		AS last_store_id,
		SUM(pmnt.amount)	AS revenue
FROM		public.staff 		staff
INNER JOIN	public.payment		pmnt	ON pmnt.staff_id	 = staff.staff_id
WHERE		EXTRACT(YEAR FROM pmnt.payment_date) 	= 2017
GROUP BY 	staff.staff_id,
			staff.first_name,
		 	staff.last_name,
		 	staff.store_id
ORDER BY	revenue DESC
LIMIT 3;

/* T2.1_CTE

JOIN Types Used: 	INNER JOIN creates the baseline of valid transactions inside the CTE.
					An outer INNER JOIN connects the CTE back to the main staff table to retrieve 
					the text-heavy names for the final output.

Pros: 	Isolates the revenue calculation step.
		CTE isolates payment dates and amounts which could be used for later queries.
		Avoids the row-by-row execution penalty by joining the staff table normally instead of using scalar subqueries.

Cons: 	Still the slowest method (0.190s). 
		Materializing the large joined transactional dataset inside the CTE before applying the 2017 
		date filter and final GROUP BY aggregation requires more memory than the subquery method.

Production Choice:	I would use this in production if code readability and the reusability of the CTE 
					are prioritized over raw execution speed. However, for maximum performance on large 
					datasets, the subquery method remains superior.
 */

--NAME:T2.1_CTE
WITH StorePaymentCTE AS (
	SELECT	staff.staff_id	AS staff_id,
			staff.store_id	AS last_store_id,
			pmnt.amount		AS staff_revenue_home_store,
			pmnt.payment_date
	FROM		public.staff 		staff
	INNER JOIN	public.payment		pmnt	ON pmnt.staff_id 		= staff.staff_id
	INNER JOIN	public.rental		rtl		ON rtl.rental_id 		= pmnt.rental_id
	INNER JOIN	public.inventory	invt	ON invt.inventory_id	= rtl.inventory_id
	WHERE		staff.store_id = invt.store_id
)
SELECT	staff.first_name,
		staff.last_name,
		CTE.last_store_id,
		SUM(CTE.staff_revenue_home_store)	AS revenue
FROM 		StorePaymentCTE CTE
INNER JOIN 	public.staff 	staff 			ON staff.staff_id = CTE.staff_id
WHERE		EXTRACT(YEAR FROM CTE.payment_date) = 2017
GROUP BY	CTE.staff_id,
			first_name,
			last_name,
			CTE.last_store_id
ORDER BY 	revenue DESC
LIMIT 3;

-- If the revenue counts from all stores:
WITH StorePaymentCTE AS (
	SELECT	staff.staff_id	AS staff_id,
			staff.store_id	AS last_store_id,
			pmnt.amount		AS staff_revenue_home_store,
			pmnt.payment_date
	FROM		public.staff 		staff
	INNER JOIN	public.payment		pmnt	ON pmnt.staff_id 		= staff.staff_id
)
SELECT	staff.first_name,
		staff.last_name,
		CTE.last_store_id,
		SUM(CTE.staff_revenue_home_store)	AS revenue
FROM 		StorePaymentCTE CTE
INNER JOIN 	public.staff 	staff 			ON staff.staff_id = CTE.staff_id
WHERE		EXTRACT(YEAR FROM CTE.payment_date) = 2017
GROUP BY	CTE.staff_id,
			first_name,
			last_name,
			CTE.last_store_id
ORDER BY 	revenue DESC
LIMIT 3;

/* T2.1_SUB 
 
JOIN Types Used: 	No joins are used in the outer query. INNER JOINs are used exclusively within the correlated subquery 
					to tightly couple payment, rental, and inventory data before validating it against the outer staff 
					ID and store ID.

Pros: 	Very efficient
		It calculates the total revenue per staff ID
		Personal details added only after aggregation
		  
Cons: 	With correlated subquery, the database will have to process the inner block row by row for each member of the staff
		Might create severe bottlenecks if employed with a table with more employees (here only two)

Production Choice: 	I would use this in production only when the dimension table rows are very low in count 
					This is highly readable and logically correct. However, when dealing with large employee tables, 
					I would opt to use a CTE to avoid performance issues.
*/

--NAME:T2.1_SUB
SELECT	staff.first_name,
		staff.last_name,
		staff.store_id					AS last_store_id,
		(
		SELECT		SUM(pmnt.amount)
		FROM		public.payment		pmnt
		INNER JOIN	public.rental		rtl		ON rtl.rental_id = pmnt.rental_id
		INNER JOIN	public.inventory	invt	ON invt.inventory_id = rtl.inventory_id
		WHERE		pmnt.staff_id							= staff.staff_id 	AND
					EXTRACT(YEAR FROM pmnt.payment_date)	= 2017 				AND
					invt.store_id							= staff.store_id
		)			AS sum_pmnt_amount
FROM	public.staff	staff
ORDER BY	sum_pmnt_amount DESC
LIMIT 3;

-- If the revenue counts from all stores:
SELECT	staff.first_name,
		staff.last_name,
		staff.store_id					AS last_store_id,
		(
		SELECT		SUM(pmnt.amount)
		FROM		public.payment		pmnt
		WHERE		pmnt.staff_id 							= staff.staff_id AND
					EXTRACT(YEAR FROM pmnt.payment_date)	= 2017 
		)			AS sum_pmnt_amount
FROM	public.staff	staff
ORDER BY	sum_pmnt_amount DESC
LIMIT 3;



/* TASK 2.2
The management team wants to identify the most popular movies and their target audience age groups to optimize marketing efforts.
 Show which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies?

Assumptions:  
	Movie popularity is based purely on the count of rental transactions
	Age groups must be manually mapped using a CASE statement based on standard MPAA ratings (e.g., NC-17 to '18+') 
	Any similar counts will be handled by film title ordering *discussion deduction

Results:
	time JOIN: 0.078 
	time CTE: 0.078 
	time SUB: 0.027 (fastest)
*/

/* T2.2_JOIN 
 
JOIN Types Used: 	INNER JOIN links film to inventory
					RIGHT OUTER JOIN is used for the rental table to ensure every single rental transaction is counted, 
					even if the inventory record has anomalies

INNER JOIN:	Omits rows in the film table that do not have a corresponding physical copy in the inventory table.

RIGHT OUTER JOIN: 	This type of join will include all rows from the rental table, even if the corresponding inventory ID does not exist in 
					the inventory table. This forces the inclusion of all rentals; if an INNER JOIN was used instead, those rentals without a 
					corresponding inventory ID would be omitted.

Performance Impact: 	The combination of INNER and RIGHT OUTER join operations forces the optimizer to use less efficient execution plans to 
						ensure that no rows from the right tables are prematurely eliminated.

Pros: 	Very compact code
Cons: 	Mixing INNER and RIGHT OUTER joins can be confusing and lead to unexpected NULLs in the final dataset

Production Choice: I would avoid this in production because mixing join directions reduces maintainability
 */

--NAME:T2.2_JOIN 
SELECT	film.title,
		COUNT(rtl.rental_id)	AS rented,
		(CASE
			WHEN UPPER(film.rating::text) = 'NC-17' 	THEN '18+'
			WHEN UPPER(film.rating::text) = 'R' 		THEN '17+'
			WHEN UPPER(film.rating::text) = 'PG-13' 	THEN '13-18+'
			WHEN UPPER(film.rating::text) = 'PG' 		THEN '8-13+'
			ELSE 							 '0-99'
		END) AS age_group
FROM				public.film			film
INNER JOIN			public.inventory	invt	ON invt.film_id 	= film.film_id
RIGHT OUTER JOIN 	public.rental		rtl		ON rtl.inventory_id = invt.inventory_id
GROUP BY film.film_id
ORDER BY rented 	DESC,
		 film.title ASC
LIMIT 5;


/* T2.2_CTE
  
JOIN Types Used: 	INNER JOIN and RIGHT OUTER JOIN are used inside the CTE to prepare the raw rental lines

INNER JOIN:	Omits rows in the film table that do not have a corresponding physical copy in the inventory table.

RIGHT OUTER JOIN: 	This type of join will include all rows from the rental table, even if the corresponding inventory ID does not exist in 
					the inventory table. This forces the inclusion of all rentals; if an INNER JOIN was used instead, those rentals without a 
					corresponding inventory ID would be omitted.

Performance Impact: 	The combination of INNER and RIGHT OUTER join operations forces the optimizer to use less efficient execution plans to 
						ensure that no rows from the right tables are prematurely eliminated.
						
Pros: 	Reusable logic if there is a need to analyze age groups differently later

Cons: 	Still carries the risk of the RIGHT OUTER JOIN confusion

Production Choice: Better than the standard JOIN, but still requires caution
 */

--NAME:T2.2_CTE
WITH RatedRentedFilmsCTE AS (
	SELECT	film.title,
			film.film_id	AS f_id,
			(CASE
				WHEN UPPER(film.rating::text) = 'NC-17' 	THEN '18+'
				WHEN UPPER(film.rating::text) = 'R' 		THEN '17+'
				WHEN UPPER(film.rating::text) = 'PG-13' 	THEN '13-18+'
				WHEN UPPER(film.rating::text) = 'PG' 		THEN '8-13+'
				ELSE 							 '0-99'
			END)			AS age_group
	FROM		public.film			film
	INNER JOIN	public.inventory	invt	ON invt.film_id 	= film.film_id
	RIGHT OUTER JOIN public.rental	rtl		ON rtl.inventory_id = invt.inventory_id
)
SELECT	CTE.title,
		COUNT(CTE.age_group)	AS rented,
		CTE.age_group
FROM	RatedRentedFilmsCTE	CTE
GROUP BY CTE.f_id,
		 CTE.title,
		 CTE.age_group
ORDER BY rented 	DESC,
		 CTE.title 	ASC
LIMIT 5;

/* T2.2_SUB  

JOIN Types Used: INNER JOIN is used deeply within the subqueries to count rentals per inventory ID, and then sum them per film ID

INNER JOIN (outer and inner): The INNER JOIN operation eliminates any films without inventory, and any inventory without rentals.

Performance Impact: The sequential application of INNER JOINs on pre-aggregated queries (COUNT, then SUM) ensures that the engine 
					is only joining unique IDs, thus preventing row fan-out entirely, making this operation execute quickly (0.027s).

Pros: 	Most accurate math
		It builds the aggregates from the smallest unit (rental) up to the largest (film)
		
Cons: 	Deep nesting is visually complex

Production Choice: 	I would use this in production
					It guarantees accurate counts without latency and performance costly risks
 */

--NAME:T2.2_SUB
SELECT	film.title,
		times_rented.rented,
		(CASE
			WHEN UPPER(film.rating::text) = 'NC-17' 	THEN '18+'
			WHEN UPPER(film.rating::text) = 'R' 		THEN '17+'
			WHEN UPPER(film.rating::text) = 'PG-13' 	THEN '13-18+'
			WHEN UPPER(film.rating::text) = 'PG' 		THEN '8-13+'
			ELSE 							 '0-99'
		END) 		AS age_group
FROM		public.film	film
INNER JOIN	(
		SELECT		invt.film_id,
					SUM(inventory_rented.count_rtl_rental_id)	AS rented
		FROM		public.inventory invt
		INNER JOIN	(
					SELECT		rtl.inventory_id,
								COUNT(rtl.rental_id)	AS count_rtl_rental_id
					FROM		public.rental 			rtl
					GROUP BY	rtl.inventory_id
					)	inventory_rented 	ON inventory_rented.inventory_id = invt.inventory_id
		GROUP BY 	invt.film_id
		)	times_rented 			ON film.film_id = times_rented.film_id
ORDER BY times_rented.rented 	DESC,
		 film.title 								ASC
LIMIT 5;

/* TASK 3.1

The stores’ marketing team wants to analyze actors' inactivity periods to select those with notable career breaks for targeted 
promotional campaigns, highlighting their comebacks or consistent appearances to engage customers with nostalgic or reliable film stars
 
V1: gap between the latest release_year and current year per each actor
 
Assumptions:  
	Actors with no movies should be handled (returning 0)
	The results are primarly ordered by the year_between_movies (last movie till today)
	Secondary ordering is by first_name and last_name to ensure readability and repeatabilty over different methods

Results:
	time JOIN: 0.064
	time CTE: 0.074 (slowest
	time SUB: 0.063 (fastest)

T3_V1_JOIN / CTE / SUB  
JOIN Types Used: 	LEFT OUTER JOIN is used from the actor table to the film table
					This is critical to ensure that actors who have never made a movie are still included in the final report.

LEFT OUTER JOIN (multiple): Preserves all rows from the left table (actor), even if there are no matching rows in the right tables 
							(film_actor, film). Actors with exactly zero movies are included in the result set, generating NULLs for 
							the release_year columns. If an INNER JOIN were used, any actor without a film would be completely excluded from the dataset.

Performance Impact: LEFT OUTER JOINs require the database to hold the entire left table in memory while evaluating the right tables, 
					which is inherently slower than an INNER JOIN where unmatched rows are discarded immediately					 

Pros: 	Safely handles edge cases (zero movies)

Cons: 	The JOIN version requires a CASE statement to handle NULLs, while the CTE/SUB versions handle it slightly more cleanly

Production Choice: I would use the CTE version in production for its clean separation of finding the maximum year and performing the math
 */


--NAME:T3_V1_JOIN
SELECT	act.first_name,
		act.last_name,
		(CASE
			WHEN MAX(film.release_year) IS NULL THEN 0
			ELSE EXTRACT(YEAR FROM NOW()) - MAX(film.release_year)
		END) AS years_between_movies
FROM			public.actor		act
LEFT OUTER JOIN	public.film_actor	flm_act	ON flm_act.actor_id = act.actor_id
LEFT OUTER JOIN	public.film			film	ON film.film_id 	= flm_act.film_id
GROUP BY 	act.actor_id,
			act.first_name,
			act.last_name 
ORDER BY years_between_movies 	DESC,
		 act.first_name 		ASC,
		 act.last_name 			ASC;

--NAME:T3_V1_CTE
WITH ActorLatestFilmYearCTE AS (
	SELECT	act.first_name,
			act.last_name,
			MAX(film.release_year)	AS max_film_release_year
	FROM			public.actor		act
	LEFT OUTER JOIN	public.film_actor	flm_act	ON flm_act.actor_id  = act.actor_id
	LEFT OUTER JOIN	public.film			film	ON film.film_id		 = flm_act.film_id
	GROUP BY 	act.actor_id,
				act.first_name,
				act.last_name 
)
SELECT	CTE.first_name,
		CTE.last_name,
		COALESCE(EXTRACT(YEAR FROM NOW()) - CTE.max_film_release_year, 0)	AS years_between_movies
FROM	ActorLatestFilmYearCTE	CTE
ORDER BY years_between_movies 	DESC,
		 CTE.first_name 		ASC,
		 CTE.last_name 			ASC;

--NAME:T3_V1_SUB
SELECT	act.first_name,
		act.last_name,
		COALESCE(EXTRACT(YEAR FROM NOW()) - latest_film.max_film_release_year, 0) 	AS years_between_movies
FROM	public.actor 	act 
LEFT OUTER JOIN	(
		SELECT	flm_act.actor_id,
				MAX(film.release_year)	AS max_film_release_year
		FROM	public.film_actor 	flm_act
		INNER JOIN public.film film ON film.film_id = flm_act.film_id  
		GROUP BY	flm_act.actor_id
		)				latest_film	ON latest_film.actor_id = act.actor_id
ORDER BY years_between_movies 	DESC,
		 act.first_name 		ASC,
		 act.last_name			ASC;

/* TASK 3.2

The stores’ marketing team wants to analyze actors' inactivity periods to select those with notable career breaks for targeted promotional 
campaigns, highlighting their comebacks or consistent appearances to engage customers with nostalgic or reliable film stars
 
V2: gaps between sequential films per each actor;
 
Assumptions:
 	For V2, we are looking for the maximum gap between any two sequential movies in an actor's career
	An inactivity period is the mathematical difference between years without these 
	year e.g. 2019 - 2020: 0 year gap, 2019 - 2021: 1 year gap etc *discussion deduction
	Movies in consecutive years are also treated as 0 year gap *discussion deduction
	Primary ordering is by largest carreer breaks (greatest comeback) *discussion deduction
	Secondary ordering is by earliest movie (most iconic and nostalgic) *discussion deduction

JOIN Types Used: 	LEFT OUTER JOIN is used to preserve the complete list of actors and their films, while a correlated
					subquery (or a secondary LEFT OUTER JOIN on the CTE) is used to find the "previous" year

Why T3_V2_JOIN is missing:  
	I could not solve the sequential gap task using a standard JOIN approach because it violates coding standards and rules for join method.
	To find a "previous" movie using pure joins,inequality operator has to be used (e.g., film2.release_year < film1.release_year).
	According to the EPAM standards, inequalities are not allowed inside a JOIN ON clause. If inequality were to be moved to the WHERE clause to comply 
	with the standard, it acts as a post-join filter and completely destroys the LEFT OUTER JOIN logic, automatically excluding any 
	actors with only zero or one movie. Therefore, the correlated subquery and CTE approaches are the only mathematically safe and 
	standards-compliant ways to solve this problem
					
Results:
	time JOIN: -
	time CTE: 0.133 (fastest)
	time SUB: 0.992 (very slow)
 */


/* T3_V2_SUB/JOIN

JOIN Types Used: 	LEFT OUTER JOIN is used to preserve the complete list of actors and their films
					A correlated subquery in the SELECT clause is then used to find the "previous" year.

LEFT OUTER JOIN: 	Guarantees that all rows in the actor table are included despite film participation.
					The LEFT OUTER JOIN in the correlated subquery also ensures that all films are included for an actor.

Performance Impact:	Executing a correlated subquery with LEFT OUTER JOIN operations forces the engine to re-evaluate all joins and exclusions for 
					each and every single record in the query. This results in an extreme performance hit with an execution time of 0.992 seconds.
					
Pros: 	Logically sound and complies with the rule against inequalities in the JOIN ON clause
		Handles edge cases in case movies were released in the same year

Cons: 	Extremely slow execution time (0.992s).
		The correlated subquery forces the database engine to re-evaluate the maximum previous year row-by-row for every single record,
		which is mathematically heavy and scales poorly
		
Production Choice: 	I would definitely not use this in production
					The performance time lag from the correlated subquery is too severe.
 */

--NAME:T3_V2_SUB/JOIN
SELECT	act.first_name,
		act.last_name,
		film.release_year,
		COALESCE(
			(
			SELECT		
				(CASE
					WHEN film.release_year = MAX(prev.prev_year) THEN 0
					ELSE film.release_year - MAX(prev.prev_year) - 1
				END)
			FROM	(
					SELECT	act_inner.actor_id,
							film_inner.film_id		AS prev_film_id,
							film_inner.release_year	AS prev_year
					FROM			public.actor		act_inner
					LEFT OUTER JOIN	public.film_actor	flm_act_inner	ON flm_act_inner.actor_id 	= act_inner.actor_id
					LEFT OUTER JOIN	public.film			film_inner		ON film_inner.film_id 		= flm_act_inner.film_id
					)	AS prev
			WHERE	prev.actor_id 		= act.actor_id 		AND
					(prev.prev_year 	< film.release_year OR
					(prev.prev_year 	= film.release_year AND
					prev.prev_film_id 	< film.film_id))
			), 0
		)					AS sequential_gap
FROM			public.actor		act
LEFT OUTER JOIN	public.film_actor	flm_act	ON flm_act.actor_id = act.actor_id
LEFT OUTER JOIN	public.film			film	ON film.film_id 	= flm_act.film_id
ORDER BY	act.actor_id,
			film.release_year ASC;

/* T3_V2_CTE

JOIN Types Used: 	LEFT OUTER JOIN is used inside the CTE to create a safe, complete base list of all actors and their 
					film release years. In the main query, a LEFT OUTER JOIN connects the CTE to itself (curr to prev) 
					where the previous release year is older than the current release year, or where the release year 
					is the same but the previous film ID is smaller (acting as a tie-breaker in case films were released
					in the same year).

LEFT OUTER JOIN (inside CTE):	Keeps all actors and fills in NULLs for release years when there are no movies.

LEFT OUTER JOIN (CTE to CTE): 	Keeps all rows from the curr CTE, even in the case when there is no "previous" movie in the prev CTE
								This is necessary because the first movie of each actor, as well as actors with zero movies, will be lost if an 
								INNER JOIN is used in this case

Performance Impact: By evaluating the result of the LEFT OUTER JOINed table only once, in the CTE, and then doing a self-join,  
					the performance penalty of evaluating a correlated subquery is avoided, which makes the query run significantly faster (0.133s)

Pros: 	Much quicker than the previous method (0.133s)
		The database engine materializes the CTE once and then merges the blocks via the self-join, 
		completely avoiding the row-by-row penalty of the subquery method
		Handles edge cases in case movies were released in the same year

Cons: Slightly more verbose setup

Production Choice: 	I would use this CTE version in production
					It safely handles the edge cases, strictly adheres to the coding standards, and offers significantly
					faster execution times by avoiding correlated subquery bottlenecks
 */

--NAME:T3_V2_CTE
WITH FilmYearActorCTE AS (
	SELECT	act.first_name,
			act.last_name,
			act.actor_id,
			film.film_id,
			film.release_year	AS release_year
	FROM			public.actor		act
	LEFT OUTER JOIN	public.film_actor	flm_act	ON flm_act.actor_id = act.actor_id
	LEFT OUTER JOIN	public.film			film	ON film.film_id 	= flm_act.film_id
)
SELECT
		curr.first_name,
		curr.last_name,
		curr.release_year,
		GREATEST(
    		curr.release_year - COALESCE(MAX(prev.release_year), curr.release_year) - 1,
    		0
		) 					AS sequential_gap
FROM			FilmYearActorCTE		curr
LEFT OUTER JOIN	FilmYearActorCTE		prev	ON 	 prev.actor_id 		= curr.actor_id 	AND
							   						(prev.release_year 	< curr.release_year OR
							   						(prev.release_year 	= curr.release_year AND
							   						prev.film_id		< curr.film_id))
GROUP BY	curr.actor_id,
			curr.first_name,
			curr.last_name,
			curr.release_year,
			curr.film_id 
ORDER BY	sequential_gap 		DESC,
			curr.release_year 	ASC,
			curr.film_id 		ASC;
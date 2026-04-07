/*
Oliwier Sobczyk
EPAM COURSE Database Mentoring Programme

Last Update: 29.03.2026
	Version for the first commit before the review
	
List of abbreviations used accross this file:
	film 		- flm 
	actor 		- act
	film_actor 	-  fa
	inventory 	- inv
	store 		- str
	staff 		- stf
	customer 	- cust
	payment 	- pmnt
	rental		- rent
	language	- lan


My favourite films that I insert to the databse:

1. THE SHAWSHANK REDEMPTION https://www.filmweb.pl/film/Skazani+na+Shawshank-1994-1048/cast/actors
	Actors Added:
		Tim Robbins
		Morgan Freeman
	Film Attributes:
		Release Year: 1994
		Language: English
		Rental Duration: 7 weeks (or days, depending on how your database interprets the integer)
		Rental Rate: 4.99
		Length: 142 minutes

2. THE LORD OF THE RINGS: THE RETURN OF THE KING https://www.filmweb.pl/film/Władca+Pierścieni%3A+Powrót+króla-2003-11841/cast/actors
	Actors Added:
		Elijah Wood
		Sean Astin
	Film Attributes:
		Release Year: 2003
		Language: English
		Rental Duration: 14
		Rental Rate: 9.99
		Length: 201 minutes

3. BOOK OF LIFE https://www.filmweb.pl/film/Księga+życia-2014-683515
	Actors Added:
		Anthony Gonzalez
		Benjamin Bratt
	Film Attributes:
		Release Year: 2014
		Language: English
		Rental Duration: 21
		Rental Rate: 19.99
		Length: 95 minutes
 */

/*
To add the films I began by evaluating the structure of these tables
-- SELECT * FROM public.film LIMIT 5;
-- SELECT * FROM public.language LIMIT 5;
Following, I checked that film_id is a serial4 key and is automatically incremented
and these values have a default value: replacement_cost; rating public and that last_update,
description and fulltext are automatically filled with triggers.

To assure that the values will be inserted securely I made sure I have the commit set to manual to
have the possibility to rollback. Furthermore, I made sure that I am inserting each attribute has 
its value assigned. Finally, there is a possibility that one of my favourite films is already in 
the database (since there are  films), therefore I added WHERE clause with NOT EXIST to check if 
there is any record containting the same title and year - in case there is the row wont be inserted.
Usually, one could use ON CONFLICT within insert, however, this works on attributes which have either
UNIQUE constraints or are a Primary Key.
To add all films in one statement a temporary table was made with 3 film values joined with UNION ALL - 
which allows for duplicates, therefore is faster than UNION, because it doesnt compare them. 

I decided to use a CTE to forward the ID of the added films to the inventory. Otherwise The insertion 
could have been achieved using INSERT INTO ... SELECT id .. WHERE flm.title IN ['titles']. As there are
only two stores available, CROSS JOIN was used to assign each film to each store in a single INSERT INTO
statement. 
If the insert on inventory fails the film insert also rolls back. This prevents adding films which are 
nowhere in any inventory of either stores.
At this stage rollback is safe to do as there is no record of these films in other tables. 
Film_id is an auto increment PK, so it is auto assigned on insert and is forwarded back with RETURNING
*/

-- ADD THE FILMS:

WITH AddedFilms AS (
	INSERT INTO public.film (
		title,
		release_year,
		language_id,
		rental_duration,
		rental_rate,
		length,
		last_update
	)
	SELECT 
		movies.title,
		movies.release_year,
		lan.language_id,
		movies.rental_duration,
		movies.rental_rate,
		movies.length,
		CURRENT_DATE
	FROM (
		SELECT	'THE SHAWSHANK REDEMPTION'	AS title, 
				1994 						AS release_year, 
				7 							AS rental_duration, 
				4.99 						AS rental_rate, 
				142 						AS length
		UNION ALL
		SELECT 'THE LORD OF THE RINGS: THE RETURN OF THE KING', -- title
				2003, 											-- year
				14, 											-- rental duration
				9.99, 											-- rental rate
				201   											-- length
		UNION ALL
		SELECT	'BOOK OF LIFE', 								-- title
				2014, 											-- year
				21, 											-- rental duration
				19.99, 											-- rental rate
				95												-- length
	) 						AS movies
	INNER JOIN public.language lan ON LOWER(lan.name) = 'english'	-- join with the english language ID
	WHERE NOT EXISTS (
	SELECT 1
	FROM public.film flm
	WHERE 	flm.title 			= movies.title AND				-- check if title exists
			flm.release_year	= movies.release_year			-- with the release year combination
	)
	RETURNING 
		film_id													-- forward assigned film ID's to inventory
)
INSERT INTO public.inventory (
	film_id, 
	store_id, 
	last_update
)
SELECT 
	AF.film_id,
	str.store_id,
	CURRENT_DATE
	FROM AddedFilms AF
	CROSS JOIN public.store str
RETURNING
	film_id,
	store_id,
	last_update;

-- Verify before committing: confirm 3 films were inserted 

/*
THE SHAWSHANK REDEMPTION						1080	4.99	7	2026-03-28 00:00:00.000 +0100
THE LORD OF THE RINGS: THE RETURN OF THE KING	1081	9.99	14	2026-03-28 00:00:00.000 +0100
BOOK OF LIFE									1082	19.99	21	2026-03-28 00:00:00.000 +0100
 */

-- THIS QUERY SHOULD GIVE A SIMILAR RESULT TO ABOVE ^^
SELECT	flm.title,
		flm.film_id,
		flm.rental_rate, 
		flm.rental_duration,
		flm.last_update
FROM 	public.film flm
WHERE	UPPER(flm.title) IN (
			'THE SHAWSHANK REDEMPTION',
			'THE LORD OF THE RINGS: THE RETURN OF THE KING',
			'BOOK OF LIFE'
		)
ORDER BY flm.title;

-- COMMIT ADDING FILMS:
COMMIT;

/* SUBTASK 2 
Insertion of the new actors had the same issue as the films - ON CONFLICT couldnt be used as 
the firsname and lastname dont have unique constraint, therefore NOT EXIST was used and 
the inserted combinatation of name and surname was checked with the existing ones. 
The risk with this database is that their is no distinction between to people having the same
name and surname. 
The rollback can be still issued after insertion as no other table references the 
actors yet at this stage.
Again UNION ALL was used to create a temporary table and insert and check the values 
at once.
Actor_id is a self-increment primary key, hence its unique and the proper insertion is 
confirmed with RETURNING
CTE allows for a cleaner code, such that the actors are outside of the INSERT INTO statemetn
and can be easilt accessed, edited and checked for errors.
 */

-- ADD THE ACTORS:

WITH NewActors AS (
SELECT 	'ELIJAH'	AS first_name,  -- THE LORD OF THE RINGS: THE RETURN OF THE KING
		'WOOD'		AS last_name
UNION ALL
SELECT	'SEAN',                     -- THE LORD OF THE RINGS: THE RETURN OF THE KING
		'ASTIN'
UNION ALL
SELECT 	'ANTHONY' ,					-- BOOK OF LIFE
		'GONZALEZ'
UNION ALL
SELECT	'BENJAMIN' 					-- BOOK OF LIFE
		,'BRATT'
UNION ALL
SELECT 	'TIM', 						-- THE SHAWSHANK REDEMPTION
		'ROBBINS'
UNION ALL
SELECT	'MORGAN', 					-- THE SHAWSHANK REDEMPTION
		'FREEMAN'
)
INSERT INTO public.actor ( 
		first_name, 
		last_name,
		last_update
)
SELECT 	NA.first_name, 
		NA.last_name,
		CURRENT_DATE
		FROM NewActors NA
WHERE NOT EXISTS (
	SELECT 1
	FROM public.actor act
	WHERE 	UPPER(act.first_name) = NA.first_name AND			-- check if the combination of first name
			UPPER(act.last_name)  = NA.last_name				-- and last name already exists in table actor
	)
RETURNING												-- returning confirms succesful addition of rows
	actor_id,											-- with self increament actor_id
	first_name,
	last_name,
	last_update;										-- set to CURRENT_DATE

-- Verify before committing
/*
328	SEAN		ASTIN		2026-03-28 00:00:00.000 +0100
330	BENJAMIN	BRATT		2026-03-28 00:00:00.000 +0100
327	MORGAN		FREEMAN		2026-03-28 00:00:00.000 +0100
331	ANTHONY		GONZALEZ	2026-03-28 00:00:00.000 +0100
332	TIM			ROBBINS		2026-03-28 00:00:00.000 +0100
329	ELIJAH		WOOD		2026-03-28 00:00:00.000 +0100
 */

-- SELECT STATEMENT TO CONFIRM ACTORS WHERE ADDED:
SELECT	act.actor_id,
		act.first_name,
		act.last_name,
		act.last_update
FROM	public.actor act
WHERE	(UPPER(act.first_name), UPPER(act.last_name)) IN (
			('TIM',		 'ROBBINS'),
			('MORGAN',	 'FREEMAN'),
			('ELIJAH',	 'WOOD'),
			('SEAN',	 'ASTIN'),
			('ANTHONY',	 'GONZALEZ'),
			('BENJAMIN', 'BRATT')
		)
ORDER BY act.last_name;

-- COMMIT ADDING ACTORS:
COMMIT;

/* Join of films and their actors in this database is through film_actor table, which
 * accepts film_id and actor_id of related entities.
 * Previous inserts ensured that for both film and actor tables have newly inserted data.
 * 
 * Therefore, as there is no access to the ID's and the ID's shouldnt be hardcoded the 
 * ID's will be found with the title for the movies and combination for first_name and
 * last name for the actor. This ensures that the ID's are not hardcoded and possible 
 * to lookup. If the insert fails, the previously commited films and actors
 * remain safe, yet miss their relationships, which can be handled individually.
 * 
 * Initially a CTE is made to connect films with actors, which allows to insert the 
 * film_id and actor_id to film_actor table in one insert statement
 * 
 * Rollback is possible as it only affects the relationships, while film and actor
 * remain uncahnged in respective tables.
 * 
 * The insertion handles duplicates with NOT EXIST comparing the already existing 
 * film_id actor_id combinations with the ones being inserted. Additionally, film_actor table
 * has a composite key of film_id and actor_id, hence the insertion of the same combination
 * would result in an error.
 * 
 * Inner join was used to obtain the combination of actor_id and film_id for the 
 * sake of clear code, however for larger insertion and faster join subqueries should 
 * be used to filter the films and actors by titles and first and lastname respectively
 * such that join statemnetn can connect smaller tables.
 */

WITH TitlesActors AS (
SELECT 'THE SHAWSHANK REDEMPTION'		AS title, 		'TIM'	AS first_name, 	'ROBBINS'	AS last_name
UNION ALL 
SELECT 'THE SHAWSHANK REDEMPTION', 						'MORGAN', 				'FREEMAN'
UNION ALL 
SELECT 'BOOK OF LIFE', 									'ANTHONY', 				'GONZALEZ'
UNION ALL
SELECT 'BOOK OF LIFE',									'BENJAMIN', 			'BRATT'
UNION ALL
SELECT 'THE LORD OF THE RINGS: THE RETURN OF THE KING',	'ELIJAH', 				'WOOD'
UNION ALL
SELECT 'THE LORD OF THE RINGS: THE RETURN OF THE KING', 'SEAN', 				'ASTIN'
)
INSERT INTO public.film_actor ( 
	actor_id, 
	film_id,
	last_update
)
SELECT 	act.actor_id, 
		flm.film_id,
		CURRENT_DATE
FROM public.actor 		act
INNER JOIN TitlesActors TA 		ON 	TA.first_name 		= UPPER(act.first_name) AND 	-- check the combination of first_name
									TA.last_name 		= UPPER(act.last_name) 			-- and last name
INNER JOIN public.film 	flm 	ON 	UPPER(flm.title)	= TA.title
WHERE NOT EXISTS (
	SELECT 1
	FROM   public.film_actor fa
	WHERE  fa.actor_id = act.actor_id AND			-- guard against duplicate relationship rows
		   fa.film_id  = flm.film_id				-- on rerun
)
RETURNING
	actor_id, 
	film_id;

-- Verify before committing
/*
BOOK OF LIFE									BENJAMIN	BRATT		2026-03-28 16:38:06.005 +0100
BOOK OF LIFE									ANTHONY		GONZALEZ	2026-03-28 16:38:06.005 +0100
THE LORD OF THE RINGS: THE RETURN OF THE KING	SEAN		ASTIN		2026-03-28 16:38:06.005 +0100
THE LORD OF THE RINGS: THE RETURN OF THE KING	ELIJAH		WOOD		2026-03-28 16:38:06.005 +0100
THE SHAWSHANK REDEMPTION						MORGAN		FREEMAN		2026-03-28 16:38:06.005 +0100
THE SHAWSHANK REDEMPTION						TIM			ROBBINS		2026-03-28 16:38:06.005 +0100
 */

-- NAME: FilmsActors
SELECT	flm.title,
		act.first_name,
		act.last_name,
		fa.last_update
FROM		public.film_actor	fa
INNER JOIN	public.film			flm	ON	flm.film_id		= fa.film_id
INNER JOIN	public.actor		act	ON	act.actor_id	= fa.actor_id
WHERE	UPPER(flm.title) IN (
			'THE SHAWSHANK REDEMPTION',
			'THE LORD OF THE RINGS: THE RETURN OF THE KING',
			'BOOK OF LIFE'
		)
ORDER BY flm.title,
		 act.last_name;

-- COMMIT SUCCESFULL JOIN OF FILMS AND ACTORS IN FILM_ACTOR:
COMMIT;

/* Next subtask required updating the customer table with my personal information by replacing 
 * one of the current customers, which had at least 43 rentals and 43 payments (more than 42).
 * LIMIT 1 clause in the main subquery assures that only one customer is replaced.
 * Customers rentals and payments with their respective are seperately counted and filtered with
 * HAVING COUNT(pmnt.payment_id) > 42 in subqueries and joined to one table by their ID's. Using 
 * join without this filter made this query very long. 
 * 
 * The adress was chosen randomly with select statement instead of hardcoded ID and uses an 
 * address already existing in the database. LIMIT 1 ensures one address is returned.
 * 
 * The rollback can be issued if the insertion fails and the customer row is unchanged. The customer_id
 * remained untouched, therefore there is no risk of deleting on cascade any other entries.
 * The ensure everything was inserted correclty the SELECT statment below has to be run before commiting.
 * 
 * If the update is rerun the WHERE clause ensures that my new ID will be found as the rentals and payments
 * still belong to this ID - they are only deleted in the next subtask, therfore this query should not be run
 * following the next DELETE query.
 * 
 * Returning confirms the successful insertion by viewing the ID, personal details and last_update. 
 */

-- UPDATE CUSTOMER WITH MY PERSONAL DETAILS:

UPDATE public.customer cust
SET	first_name 		= 'OLIWIER',						-- set my personal data 
	last_name		= 'SOBCZYK',
	email			= 'BASNIOBOR65@GMAIL.COM',
	address_id 		= (
						SELECT	addr.address_id  			-- adress_id was set randomly
						FROM	public.address addr
						ORDER BY	addr.address_id DESC	 -- selects the most recently added address
						LIMIT 1
						),
	last_update		= CURRENT_DATE
WHERE NOT EXISTS (
	SELECT 	1
	FROM 	public.customer cust
	WHERE 	UPPER(cust.first_name) 		= 'OLIWIER'				 	AND
			UPPER(cust.last_name)		= 'SOBCZYK' 				AND
			UPPER(cust.email)			= 'BASNIOBOR65@GMAIL.COM'
) 																AND
	cust.customer_id = (
	SELECT payments.customer_id
	FROM (
		SELECT		pmnt.customer_id,
					COUNT(pmnt.payment_id) AS pmnt_count		-- count the payments
		FROM 		public.payment pmnt	
		GROUP BY 	pmnt.customer_id 				
		HAVING 		COUNT(pmnt.payment_id)	> 42				-- filter out those below 43
	) AS payments
	INNER JOIN (
		SELECT 		rent.customer_id,
					COUNT(rent.rental_id) AS rent_count			-- count the rentals
		FROM 		public.rental rent	
		GROUP BY 	rent.customer_id 
		HAVING 		COUNT(rent.rental_id)	> 42				-- filter out those below 43
	) AS rentals ON rentals.customer_id = payments.customer_id
	ORDER BY	payments.pmnt_count	DESC, 								-- find the customer with the highest
				rentals.rent_count 	DESC								-- amount of rentals and payments
	LIMIT 1														-- make sure just one ID is selected
)
RETURNING 	customer_id,										-- the replaced customer_id
			first_name,											-- with my personal_details 
			last_name,											
			email,
			address_id,
			last_update;										-- and last_update (CURRENT_DATE)

			
-- to confirm and see the customer tables execute this
/*
148	OLIWIER	SOBCZYK	BASNIOBOR65@GMAIL.COM	2026-03-28 16:50:04.236 +0100
 */
--NAME: EDITED_CUST_TAB
SELECT 	cust.customer_id,										
		cust.first_name,											 
		cust.last_name,											
		cust.email,
		cust.last_update	
FROM 	public.customer cust 
WHERE	UPPER(cust.email) = 'BASNIOBOR65@GMAIL.COM';

-- CONFRIM ADDING MY DETAILS TO THE CUSTOMER:
COMMIT;

/* Next task concerned deleting the rentals and payments of the customer that I have replaced with 
 * in the customer table. To not use hardcoded ID of me in the customer table CTE was made MyNewID
 * to retrieve the ID with the UNIQUE combination of name, surname and email ( as my mail is certainly
 * unique, this procedure was limited to search through email, however in real database, one should
 * search with combination of these three attributes as few customers might share an email)
 * 
 * Following one must understand the flow of the film rental: 
 * film_id in store inventory -> film RENTAL by CUSTOMER -> film PAYMENT by CUSTOMER
 * and the PAYMENT table is the child table with rental_id and the RENTAL is the 
 * parent table. Therefore, deleting rental first would violate the foreign key constraint
 * and the payments must be deleted prior to rentals
 * 
 * Using a one transaction CTE is used here because payment is related to rental and must 
 * be DELETED together at once. Deleting a payment and leaving rental would leave inconistency -
 * films rented without payments. Deleting payments could be returning rental_id to deleted these 
 * rentals, however this leaves edge cases, when a film was rented but not paid. As it is neccesary 
 * to delete all rentals and payments related to this customer, these are search throught customer_id 
 * instead.
 * 
 * Once commited the rerun would result in 0 deleted rows for rentals and payments without error
 * 
 * To not use hardcoded customer ID it is searched by the combination of my personal details in a 
 * SELECT statement. As it is written outside the DELETE queries it can be used for both DELETE 
 * statements without rewriting it. 
 */


/*
payments to delete	92
rentals to delete	92
 */

-- CONFRIM WITH THE RESULTS ABOVE: 

WITH MyNewID AS (
    SELECT  cust.customer_id
    FROM    public.customer cust
    WHERE   UPPER(cust.first_name) = 'OLIWIER' 
    AND     UPPER(cust.last_name)  = 'SOBCZYK' 
    AND     UPPER(cust.email)      = 'BASNIOBOR65@GMAIL.COM'
)
SELECT  'payments to delete'    AS check_type, 
        COUNT(pmnt.payment_id)  AS record_count
FROM        public.payment  pmnt
INNER JOIN  MyNewID         mid  ON mid.customer_id = pmnt.customer_id
UNION ALL
SELECT  'rentals to delete'     AS check_type, 
        COUNT(rent.rental_id)   AS record_count
FROM        public.rental   rent 
INNER JOIN  MyNewID         mid  ON mid.customer_id = rent.customer_id;

-- DELETE RECORDS OF THE PREVIOUS CUSTOMER:

WITH MyNewID AS (
	SELECT	cust.customer_id
	FROM	public.customer cust
	WHERE  	UPPER(cust.first_name) 	= 'OLIWIER' 				AND
			UPPER(cust.last_name)	= 'SOBCZYK' 				AND
			UPPER(cust.email)		= 'BASNIOBOR65@GMAIL.COM'
),
DeletedPayments AS (
	DELETE FROM public.payment pmnt
	USING 		MyNewID MID
	WHERE 		pmnt.customer_id = MID.customer_id
	RETURNING 1
),
DeletedRentals AS (
	DELETE FROM public.rental rent
	USING 		MyNewID MID
	WHERE	 	rent.customer_id = MID.customer_id
	RETURNING 1
)
SELECT 'Deleted payments' AS metric_name, -- confirm is coherent with previous result
		COUNT(*) AS cnt_payments
FROM DeletedPayments
UNION ALL
SELECT 'Deleted rentals' AS metric_name,
		COUNT(*) AS cnt_rentals
FROM DeletedRentals;		

/*
Deleted payments	92
Deleted rentals		92
 */

-- CONFRIM THAT I HAVE NO PREVIOUS PAYMENTS AND RENTALS

WITH MyNewId AS (
    SELECT  cust.customer_id
    FROM    public.customer cust
    WHERE   UPPER(cust.first_name) = 'OLIWIER' 
    AND     UPPER(cust.last_name)  = 'SOBCZYK' 
    AND     UPPER(cust.email)      = 'BASNIOBOR65@GMAIL.COM'
)
SELECT  'payments to delete'    AS check_type, 
        COUNT(pmnt.payment_id)  AS record_count
FROM        public.payment  pmnt
INNER JOIN  MyNewId         mid  ON mid.customer_id = pmnt.customer_id
UNION ALL
SELECT  'rentals to delete'     AS check_type, 
        COUNT(rent.rental_id)   AS record_count
FROM        public.rental   rent 
INNER JOIN  MyNewId         mid  ON mid.customer_id = rent.customer_id;

/*
payments to delete	0
rentals to delete	0
 */

-- COMMIT DELETING PAYMENTS AND RENTALS OF PREVIOUS CUSTOMER
COMMIT;

/* SUBTASK 6
 * 
 * Insertion of the rental and payment of the movies had to be done in the opposite 
 * order than deletion - rental is the parent table, which provides the rentail_id to 
 * the payment table, therefore insertion of rental had to be done first, followed by
 * payment insertion to avoid errors as rentail_id is a reqired foreign key.
 * 
 * MyRentalData provides the dataset to be inserted to both rental and payments in
 * subsequent transactions - customer_id, inventory_id, staff_id, store_id, film_id,
 * dates, and film rate without adding anything to dataset.
 * 
 * MyFilmRental - inserts required data into rental table adn returns rental_id
 * MyFilmPaymnet - accepts the renal_id and inserts data to payment data
 * 
 * The payment naturally follows the rental therefore, without payment the rental 
 * entry is inconsistent. If the rental insert fails, the payment will also fail 
 * ensuring no inscosistencies.
 * 
 * ID's were not hardcoded, film_id chosen by their title, staff_id by the store manager
 * As each film has a rental duration and the dates have to fallback in the first half of
 * 2017, the rental_date is set to first of may and return date is after rental_duration
 * days for each film
 */


WITH MyRentalData AS (
	SELECT	DISTINCT ON 
			(flm.film_id) 		-- multiple copies possible in one store, choose one
			cust.customer_id,
			inv.inventory_id,
			inv.store_id,
			flm.film_id,
			flm.rental_rate,
			str.manager_staff_id            			AS staff_id,
			'2017-05-01 10:00:00'::TIMESTAMP			AS rental_date,
			'2017-05-01 10:00:00'::TIMESTAMP + 
			(INTERVAL '1 day' * flm.rental_duration) 	AS return_date
	FROM		public.customer 	cust
	INNER JOIN 	public.inventory	inv	ON	inv.store_id	= cust.store_id
	INNER JOIN 	public.film			flm	ON	flm.film_id		= inv.film_id
	INNER JOIN  public.store        str ON 	str.store_id 	= inv.store_id
	WHERE	UPPER(cust.email)		= 'BASNIOBOR65@GMAIL.COM'		AND
			UPPER(cust.first_name) 	= 'OLIWIER'						AND
			UPPER(cust.last_name) 	= 'SOBCZYK'						AND
			UPPER(flm.title)		IN (
									'THE SHAWSHANK REDEMPTION',
									'THE LORD OF THE RINGS: THE RETURN OF THE KING',
									'BOOK OF LIFE'
							   )
	 ORDER BY 	flm.film_id,
             	inv.inventory_id   -- same inventory item chosen on every run
),
MyFilmRental AS (
	INSERT INTO public.rental (
		rental_date,
		inventory_id, 
		customer_id, 
		return_date, 
		staff_id,
		last_update
	)
	SELECT 	RD.rental_date,
			RD.inventory_id,
			RD.customer_id,
			RD.return_date,
			RD.staff_id,
			CURRENT_DATE
	FROM 	MyRentalData RD
	RETURNING	rental_id,
				rental_date,
				inventory_id,
				customer_id,
				staff_id,
				return_date
				
),
MyFilmPayment AS (
	INSERT INTO public.payment (
		customer_id, 
		staff_id, 
		rental_id, 
		amount, 
		payment_date
	)
	SELECT	FR.customer_id,
			FR.staff_id,
			FR.rental_id,
			RD.rental_rate,
			RD.return_date
	FROM 		MyFilmRental FR
	INNER JOIN  MyRentalData RD ON RD.inventory_id = FR.inventory_id
	RETURNING	payment_id,
				rental_id,
				amount,
				customer_id
)
SELECT	flm.title, 
		FP.payment_id,
		FP.amount,
		FP.rental_id,
		RD.rental_date,
		RD.return_date,
		RD.store_id,
		FR.staff_id
FROM 		MyFilmPayment 	FP
INNER JOIN 	MyFilmRental	FR	ON FR.rental_id		= FP.rental_id
INNER JOIN  MyRentalData    RD	ON RD.inventory_id	= FR.inventory_id 
INNER JOIN	public.film 	flm	ON flm.film_id		= RD.film_id
ORDER BY 	flm.title;	

-- CHECK IF THE LATEST RENTALS ARE INSERTED PROPERLY:
WITH MyNewId AS (
    SELECT  cust.customer_id
    FROM    public.customer cust
    WHERE   UPPER(cust.first_name) = 'OLIWIER' 
    AND     UPPER(cust.last_name)  = 'SOBCZYK' 
    AND     UPPER(cust.email)      = 'BASNIOBOR65@GMAIL.COM'
)
SELECT 	flm.title,
		rent.rental_id, 
		rent.rental_date,
		rent.inventory_id, 
		rent.customer_id, 
		rent.return_date, 
		rent.staff_id, 
		rent.last_update
FROM 		public.rental 			rent
INNER JOIN 	public.inventory 		inv 	ON inv.inventory_id = rent.inventory_id 
INNER JOIN 	public.film 			flm 	ON flm.film_id 		= inv.film_id
INNER JOIN 	MyNewId 				MID 	ON MID.customer_id 	= rent.customer_id
ORDER BY rent.last_update;


-- CHECK IF LATEST PAYMENTS INSERTED PROPERLY:
WITH MyNewId AS (
    SELECT  cust.customer_id
    FROM    public.customer cust
    WHERE   UPPER(cust.first_name) = 'OLIWIER' 
    AND     UPPER(cust.last_name)  = 'SOBCZYK' 
    AND     UPPER(cust.email)      = 'BASNIOBOR65@GMAIL.COM'
)
SELECT 	flm.title,
		payment_id, 
		pmnt.customer_id, 
		pmnt.staff_id, 
		pmnt.rental_id, 
		amount, 
		payment_date
FROM 		public.payment 	pmnt
INNER JOIN 	rental 			rent	ON rent.rental_id 	= pmnt.rental_id
INNER JOIN 	inventory 		inv 	ON inv.inventory_id = rent.inventory_id 
INNER JOIN 	film 			flm 	ON flm.film_id 		= inv.film_id
INNER JOIN 	MyNewId 		MID 	ON MID.customer_id 	= pmnt.customer_id
ORDER BY rent.last_update;

-- IF CORRECT COMMIT:
COMMIT;

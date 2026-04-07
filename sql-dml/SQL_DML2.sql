/*
Oliwier Sobczyk
EPAM COURSE Database Mentoring Programme

Last Update: 29.03.2026
	Version for the first commit before the review

*/

-- 1. Create table ‘table_to_delete’ and fill it with the following query :
-- time: 21 - 26 seconds
CREATE TABLE	table_to_delete AS
SELECT 			'veeeeeeery_long_string' || x AS col
FROM			 generate_series(1,(10^7)::int) x;	-- generate_series() creates 10^7 rows of sequential 
												 	-- numbers from 1 to 10000000 (10^7)

-- 2. Lookup how much space this table consumes with the following query:

SELECT *, pg_size_pretty(total_bytes) AS total,
          pg_size_pretty(index_bytes) AS INDEX,
          pg_size_pretty(toast_bytes) AS toast,
          pg_size_pretty(table_bytes) AS TABLE
FROM ( 
	SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
    	FROM (
        	SELECT c.oid,nspname 							AS table_schema,
                   relname 									AS TABLE_NAME,
                   c.reltuples 								AS row_estimate,
                   pg_total_relation_size(c.oid) 			AS total_bytes,
                   pg_indexes_size(c.oid) 					AS index_bytes,
                   pg_total_relation_size(reltoastrelid) 	AS toast_bytes
           FROM 		pg_class 		c
           LEFT JOIN 	pg_namespace 	n ON n.oid = c.relnamespace
           WHERE 		relkind = 'r'
        ) a
) a
WHERE table_name LIKE '%table_to_delete%';

/*
-- TABLE SIZE WHEN CREATED BEFRE DELETE VACUUM OR TRUNCATE:
	-- oid      schema   table_name      row 	     t_bytes   idx_bytes  toast_bytes table_bytes	total	index	toast		table
	-- 16950	public	table_to_delete	9999896.0	602611712	0	  		8192		602603520	575 MB	0 bytes	8192 bytes	575 MB
	
	This tables consumes a lot of space and is memory demanding. The operation to create the table takes a lot of time.
*/
-- 3. Issue the following DELETE operation on ‘table_to_delete’:

DELETE FROM table_to_delete
WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows

 /*
      a) Note how much time it takes to perform this DELETE statement: 
      		13 - 19 seconds
      		
      b) Lookup how much space this table consumes after previous DELETE: 
      		the same?;
      		
      c) Perform the following command (if you're using DBeaver, press Ctrl+Shift+O to observe server output (VACUUM results)): VACUUM FULL VERBOSE table_to_delete;
      		this took 8.95-10 seconds 6666667 nonremovable row versions in 73536 pages
      		IN Ctrl+Shift+O  "odkurzanie "public.table_to_delete""
      		
      d) Check space consumption of the table once again and make conclusions;
      	Delete just deletes the values but doesnt delete the "space" - probably the memory is still allocated thats why it holds the 
      	space - the user still can use this space or it is not free yet or organized. When Vacuum is used this space is freed and optimized.
      	
      e) Recreate ‘table_to_delete’ table;
      	-- DROP TABLE table_to_delete; 0.005s
      	and created the table again 


4. Issue the following TRUNCATE operation: TRUNCATE table_to_delete;
      a) Note how much time it takes to perform this TRUNCATE statement: 
      		0.067 way quicker almost instand.
      b) Compare with previous results and make conclusion.
      The data volume is huge for this table and DELETE is volume dependent while TRUNCATE is instanst
      For smaller volumes probably the difference is negligble but for larger data TRUNCATE makes impact
      c) Check space consumption of the table once again and make conclusions;
		total_bytes 8192byes and table 0 bytes
		
After perfomring TRUNCATE, whcih took 0.067. 
-- oid  schema   table_name      row   t_bytes  idx_bytes  toast_bytes table_bytes	total		index	toast		table
16970	public	table_to_delete	 -1.0	8192		0		8192			0		8192 bytes	0 bytes	8192 bytes	0 bytes

5. Hand over your investigation's results to your mentor. The results must include:
      a) Space consumption of ‘table_to_delete’ table before and after each operation;
      b) Compare DELETE and TRUNCATE in terms of:
      
execution time
	Execuation time is significanlty longer than for the delete. Delete allows for deletion of specific rows, so the execution
	is done row by row and requires more time (13s-20s) for a third of the table while truncate handled the whole table in just 0.067s
	In the Output there were 73536 pages, which were probably deleted with TRUNCATE instead of row by row operation
	
disk space usage
	Delete doesnt free the space after execution, the space is still allocated, while TRUNCATE frees up space immidiately. Following 
	DELETE, VACUUM should be used to free the space
	
transaction behavior
	In case of DELETE there is a possibility to access the rows by others when deleting
	During TRUNCATE this is not possbile
	
rollback possibility
	Both have the option for commit and rollback
	
c) Explain:
why DELETE does not free space immediately
	Space is still allocated after the DELETE operation - it is inaccesible by any user who woould like to acceess the data
	after the DELETE operation, a user who has been working on the data before has still access to these deleted rows. 
	Therefore, the data is still there, but new users have no pointers to them
	This works as a safety feature to make sure there are no conflicts on this matter.
	
why VACUUM FULL changes table size
	VACUUM frees up the space that was still allocated by the empty memory that was deleted with DELETE - the memory is 
	not accessible but still takes up space. 
	
why TRUNCATE behaves differently
	TRUNCAE does not scan the table as DELETE does. The operation is done globally on the whole table, hence when a table
	contains a vast amount of rows the difference between these two operations grows instantenously. TRUNCATE doesnt need 
	to compare the values also.
	
how these operations affect performance and storage
	Performance is better when using TRUNCATE, however it restricts to the whole object - when used each row is deleted.
	On the other hand, the storage is freed up immdiately and can be used straight after witout additional operations.
	DELETE is way slower as it works row by row and requires more computational power, moreover leaves the space still
	allocated, therefore additional operation with VACUUM has to be performed, which is fast but one has to remember to
	execute it.
*/

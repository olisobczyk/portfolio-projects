-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database


----------- SELECT STATEMENTS -----------

-- Find a client by it's email
SELECT * FROM "project_summary"
WHERE "ID" IN (
    SELECT "id" FROM "projects"
    WHERE "car_id" IN (
        SELECT "id" FROM "cars"
        WHERE "client_id" = (
	        SELECT "id" FROM "clients"
	        WHERE "email" = 'mike.johnson@email.com'
        )
    )
);

-- Give project details for client by its first name and last name
SELECT * FROM "project_summary"
WHERE "ID" IN (
    SELECT "id" FROM "projects"
    WHERE "car_id" IN (
        SELECT "id" FROM "cars"
        WHERE "client_id" = (
	        SELECT "id" FROM "clients"
	        WHERE "first_name" = 'Mike'
	        AND "last_name" = 'Johnson'
        )
    )
);

-- Represents the information about the worked done on a project by its name
SELECT * FROM "worked_on"
WHERE "project_id" = (
    SELECT "id" FROM "projects"
    WHERE "name" = 'Rogue Performance Pkg'
);

-- View clients details with its car which is currently available
SELECT "first_name","last_name","email","brand","model","engine"
FROM "clients"
JOIN "cars"
ON "clients"."id" = "cars"."client_id"
WHERE "cars"."status" = "available";

-- Represents each employess data, total work time, earnings
SELECT "id","first_name","last_name","hired",ROUND(COALESCE((SUM("hours") + SUM("minutes"/60)),0),2) AS "time",("salary_hour"*ROUND(COALESCE((SUM("hours") + SUM("minutes"/60)),0),2)) AS "earnings"
FROM "worked_on"
FULL JOIN "employees" ON "employees"."id" = "worked_on"."employee_id"
WHERE "worked_on"."date" BETWEEN '2023-05-01' AND '2023-07-31'
GROUP BY "employees"."id";


-- Ordered parts ordered in a certain month and their details
SELECT "parts"."name" AS "part","amount","suppliers"."name" AS "supplier", ("cost_for_client"*"amount") AS "Total Client's cost","amount"*"cost_for_client"*((100.0 - "suppliers"."discount")/100.0) AS "Total Cost"
FROM "parts"
JOIN "ordered" ON "ordered"."part_id" = "parts"."id"
JOIN "suppliers" ON "suppliers"."id" = "parts"."supplier_id"
WHERE "ordered"."date_order" BETWEEN '2025-01-01' AND '2025-04-31';

-- Parts which are currently in stock
SELECT "parts"."name" AS "part","amount","suppliers"."name" AS "supplier","cost_for_client"*((100.0 - "suppliers"."discount")/100.0) AS "Cost per Part", ("cost_for_client"*"amount"*(100.0 - "suppliers"."discount")/100.0) AS "Total Cost",("cost_for_client"*"amount") AS "Total Client's cost"
FROM "parts"
JOIN "ordered" ON "ordered"."part_id" = "parts"."id"
JOIN "suppliers" ON "suppliers"."id" = "parts"."supplier_id"
WHERE "stock" = 'ordered'
ORDER BY "supplier";

-- Employees who worked on the most worked-on project
SELECT "e"."first_name", "e"."last_name"
FROM "employees" AS "e"
WHERE "e"."id" IN (
    SELECT "employee_id"
    FROM "worked_on"
    WHERE "project_id" = (
        SELECT "project_id"
        FROM "worked_on"
        GROUP BY "project_id"
        ORDER BY (SUM("hours") + SUM("minutes"/60)) DESC
        LIMIT 1
    )
);

----------- INSERT STATEMENTS ------------

-- Clients
INSERT INTO "clients" ("first_name", "last_name", "email", "phone", "first_order")
VALUES ('Mike', 'Thompson', 'thompson2.m@yahoo.com', 5551234530, '2024-05-01');

-- Employees
INSERT INTO "employees" ("first_name", "last_name", "position", "salary_hour", "hired", "phone")
VALUES ('Maria', 'Rodriqez', 'Mechanic', 22, '2022-09-01',5559876524);

-- Cars
INSERT INTO "cars" ("brand","client_id", "model", "engine", "production_date", "status")
VALUES ('Jeep',2,'Wrangler',4.0,2020,'not_available');

-- Projects
INSERT INTO "projects" ("name", "car_id", "estimated_cost", "started", "status", "end_date")
VALUES ('Performance Tune & Cold Air',1,2500.00,'2023-01-01 08:00:00','finished','2023-02-01');

-- Suppliers
INSERT INTO "suppliers" ("name", "email", "phone","active", "discount")
VALUES ('Inter Cars','orders@intercars.com',5551113333,'yes', 5.0);

-- Parts
INSERT INTO "parts" ("name", "supplier_id", "cost_for_client", "stock")
VALUES ('Cold Air Intake',5,380.00,'in');

-- Ordered
INSERT INTO "ordered" ( "part_id", "amount", "ordered_by", "date_order", "date_delivery")
VALUES (10,2,4,'2024-08-11 11:00:00','2024-08-14');

-- Needs
INSERT INTO "needs" ( "part_id","project_id", "amount", "date")
VALUES (10,4,2,'2024-08-14');

-- Worked On
INSERT INTO "worked_on" ("employee_id", "project_id", "comment","date", "hours", "minutes")
VALUES (9,46,'Paint touch-up and final detailing','2024-08-09 10:30:00',4,30);


---------- DELETE STATEMENTS -------------

-- Delete a fired employee
DELETE FROM "active_employees"
WHERE "phone" = 5559876543;

-- Delete suppliers with whom company cooperates no more
DELETE FROM "active_suppliers"
WHERE "email" = 'info@universalauto.com';


---------- UPDATE STATEMENTS -------------

-- Update client information
UPDATE "clients"
SET  "last_name" = 'Blake', "email" = 'james.blake@email.com' , "phone" = 5551234456
WHERE "id" = (
    SELECT "id" FROM "clients"
    WHERE "email" = 'james.jackson@email.com'
);

-- Update project status and end date
UPDATE "projects"
SET "status" = "finished", "end_date" = CURRENT_TIMESTAMP
WHERE "id" = "2";

-- Update part stock status
UPDATE "parts"
SET "stock" = 'out'
WHERE "name" = 'Performance Chip'
AND "supplier_id" = (
    SELECT "id" FROM "suppliers"
    WHERE "name" = 'Engine Performance Ltd'
);

-- Update the order when delivered
UPDATE "ordered"
SET "date_delivery" = CURRENT_TIMESTAMP
WHERE "id" = 3;

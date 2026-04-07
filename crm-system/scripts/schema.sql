-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it

-- Represents clients of the company
CREATE TABLE IF NOT EXISTS  "clients" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "email" TEXT NOT NULL UNIQUE CHECK("email" LIKE '%@%.%'),
    "phone" TEXT NOT NULL UNIQUE CHECK(LENGTH("phone") >= 9),
    "first_order" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY("id")
);

-- Represents the employess of the company
CREATE TABLE IF NOT EXISTS "employees" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "position" TEXT NOT NULL,
    "salary_hour" NUMERIC NOT NULL DEFAULT 10,
    "hired" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fired" NUMERIC DEFAULT NULL,
    "phone" TEXT NOT NULL UNIQUE CHECK(LENGTH("phone") >= 9),
    PRIMARY KEY("id")
);

-- Represents cars of the clients that are in the database and if available at the company
CREATE TABLE IF NOT EXISTS "cars" (
    "id" INTEGER,
    "client_id" INTEGER,
    "brand" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "engine" NUMERIC NOT NULL,
    "production_date" NUMERIC NOT NULL,
    "status" TEXT CHECK("status" IN('not_available','available')),
    PRIMARY KEY("id"),
    FOREIGN KEY("client_id") REFERENCES "clients"("id") ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Represents the current and finalised projects of the company
CREATE TABLE IF NOT EXISTS "projects" (
    "id" INTEGER,
    "name" TEXT NOT NULL UNIQUE,
    "car_id" INTEGER,
    "estimated_cost" NUMERIC NOT NULL,
    "started" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" TEXT CHECK("status" IN('in_progress','finished','tested')),
    "end_date" NUMERIC,
    PRIMARY KEY("id"),
    FOREIGN KEY("car_id") REFERENCES "cars"("id") ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Represents the active and unactive suppliers of the company
CREATE TABLE IF NOT EXISTS "suppliers" (
    "id" INTEGER,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL UNIQUE CHECK("email" LIKE '%@%.%'),
    "phone" TEXT NOT NULL UNIQUE CHECK(LENGTH("phone") >= 9),
    "active" TEXT NOT NULL CHECK("active" IN('yes','no')) DEFAULT 'yes',
    "discount" NUMERIC NOT NULL DEFAULT 0,
    PRIMARY KEY("id")
);

-- Represents the parts from the suppliers that are available to order
CREATE TABLE IF NOT EXISTS "parts" (
    "id" INTEGER,
    "name" TEXT NOT NULL,
    "supplier_id" INTEGER,
    "cost_for_client" NUMERIC NOT NULL,
    "stock" TEXT NOT NULL CHECK("stock" IN('in','out','ordered')),
    PRIMARY KEY("id"),
    FOREIGN KEY("supplier_id") REFERENCES "suppliers"("id") ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Reprents the orders from the suppliers
CREATE TABLE IF NOT EXISTS "ordered" (
    "id" INTEGER,
    "part_id" INTEGER,
    "amount" INTEGER NOT NULL,
    "ordered_by" INTEGER,
    "date_order" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "date_delivery" NUMERIC,
    PRIMARY KEY("id"),
    FOREIGN KEY("part_id") REFERENCES "parts"("id") ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY("ordered_by") REFERENCES "employees"("id") ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Represents the amount of used parts for the projects
CREATE TABLE IF NOT EXISTS "needs" (
    "part_id" INTEGER,
    "project_id" INTEGER,
    "amount" INTEGER NOT NULL DEFAULT 1,
    "date" NUMERIC,
    FOREIGN KEY("part_id") REFERENCES "parts"("id") ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY("project_id") REFERENCES "projects"("id") ON UPDATE CASCADE ON DELETE SET NULL
);

-- Represents the work that have been done by an employee on a project
CREATE TABLE IF NOT EXISTS "worked_on" (
	"employee_id" INTEGER,
	"project_id" INTEGER,
	"date" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "comment" TEXT NOT NULL,
	"hours" INTEGER NOT NULL DEFAULT 0,
	"minutes" INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY("employee_id") REFERENCES "employees"("id") ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY("project_id") REFERENCES "projects"("id") ON UPDATE CASCADE ON DELETE RESTRICT
);

---------------------- VIEWS ------------------------

-- Represents input of each employee into each proejct
CREATE VIEW "employee_per_project" AS
    SELECT
    "project_id" AS "ID Project",
    "hours" AS "Hours",
    "minutes" AS "Minutes",
    "comment" AS "Worked on",
    "first_name" AS "Name",
    "last_name" AS "Last Name",
    "position",
    "salary_hour" AS "Salary p.H.",
    "phone"
    FROM "worked_on"
    LEFT JOIN "employees" ON "employees"."id" = "worked_on"."employee_id"
    ORDER BY "project_id";

-- Represents each part and its supplier that has been used for each project
CREATE VIEW "parts_for_project" AS
    SELECT
    "project_id" AS "ID Project",
    "amount" AS "Amount",
    "suppliers"."name" AS "Supplier",
    "parts"."name" AS "Part",
    "stock" AS "Stock"
    FROM "needs"
    LEFT JOIN "parts" ON "parts"."id" = "needs"."part_id"
    LEFT JOIN "suppliers" ON "suppliers"."id" = "parts"."supplier_id"
    ORDER BY "ID Project";

-- Represents the total cost of parts per project
CREATE VIEW "cost_parts_for_project" AS
    SELECT "project_id" AS "ID Project",
    COALESCE(SUM("cost_for_client" * "needs"."amount"),0) AS "Tot.C.P. Client",
    COALESCE(SUM("needs"."amount" * "cost_for_client" * ((100.0 - "suppliers"."discount")/100.0)),0) AS "Tot C.p.P."
    FROM "needs"
    JOIN "parts" ON "parts"."id" = "needs"."part_id"
    JOIN "suppliers" ON "suppliers"."id" = "parts"."supplier_id"
    GROUP BY "project_id"
    ORDER BY "project_id";

-- Reperesent the total cost-earnings of the employess per project
CREATE VIEW "cost_employee_per_project" AS
    SELECT "project_id" AS "ID Project",
    COALESCE(((SUM("hours") + SUM("minutes")/60)),0) AS "Time",
    ROUND(COALESCE((SUM("salary_hour"*"hours") + SUM("salary_hour"*"minutes"/60)),0),2) AS "Employee C."
    FROM "worked_on"
    LEFT JOIN "employees" ON "employees"."id" = "worked_on"."employee_id"
    GROUP BY "project_id"
    ORDER BY "project_id";

-- Represent the total summary of each project including the cost of parts, time per project, cost of employees and the profit
CREATE VIEW "project_summary" AS
    SELECT "p"."id" AS "ID",
    "p"."name" AS "Name",
    "p"."status" AS "Status",
    COALESCE("labor"."total_time", 0) AS "Tot. Time",
    "p"."estimated_cost" AS "C. Estimated",
    COALESCE("labor"."employee_cost", 0) AS "Employee C.",
    COALESCE("parts"."actual_cost", 0) AS "Tot C.p.P.",
    COALESCE("parts"."client_cost", 0) AS "Tot.C.P. Client",
    ("p"."estimated_cost" - COALESCE("labor"."employee_cost", 0) - COALESCE("parts"."actual_cost", 0)
    + COALESCE("parts"."client_cost", 0)) AS "Profit"
    FROM "projects" AS "p"
    LEFT JOIN (
        SELECT
        "wo"."project_id",
        ROUND(SUM("wo"."hours" + "wo"."minutes" / 60.0), 2) AS "total_time",
        ROUND(SUM("e"."salary_hour" * ("wo"."hours" + "wo"."minutes" / 60.0)), 2) AS "employee_cost"
        FROM "worked_on" AS "wo"
        INNER JOIN "employees" AS "e" ON "e"."id" = "wo"."employee_id"
        GROUP BY "wo"."project_id"
    ) AS "labor" ON "labor"."project_id" = "p"."id"
    LEFT JOIN (
        SELECT
        "n"."project_id",
        SUM("n"."amount" * "pt"."cost_for_client") AS "client_cost",
        SUM(n."amount" * "pt"."cost_for_client" * ((100.0 - "s"."discount") / 100.0)) AS "actual_cost"
        FROM "needs" AS "n"
        INNER JOIN "parts" AS "pt" ON "pt"."id" = "n"."part_id"
        INNER JOIN "suppliers" AS "s" ON s."id" = "pt"."supplier_id"
        GROUP BY "n"."project_id"
    ) "parts" ON "parts"."project_id" = "p"."id";

-- View all the active projects by sorted by the deadline
CREATE VIEW "active_projects" AS
    SELECT "name","first_name","last_name","email","estimated_cost","end_date"
    FROM "projects"
    JOIN "cars" ON "cars"."id" = "projects"."car_id"
    JOIN "clients" ON "clients"."id" = "cars"."client_id"
    WHERE "projects"."status" = 'in_progress'
    ORDER BY "end_date" ASC;

-- Represents currently employed employees
CREATE VIEW "active_employees" AS
    SELECT * FROM "employees"
    WHERE "fired" IS NULL
    OR "fired" = '';

-- Represents suppliers with which collaboration is active
CREATE VIEW "active_suppliers" AS
    SELECT * FROM "suppliers"
    WHERE "active" = 'yes';

-- Represents the overview of parts with their supplier and cost for the company
CREATE VIEW "parts_ov" AS
    SELECT
    "suppliers"."name" AS "Supplier",
    "parts"."name" AS "Part",
    "cost_for_client" * ((100.0 - "discount")/100.0) AS "Cost p. part",
    "cost_for_client" AS "Price for client","stock",
    (COALESCE("ordered_sum"."amount_ord",0) - COALESCE("needs_sum"."amount_need",0)) AS "Amount av."
    FROM "parts"
    LEFT JOIN "suppliers"
    ON "suppliers"."id" = "parts"."supplier_id"
    FULL JOIN (
        SELECT "part_id", SUM("amount") AS "amount_ord"
        FROM "ordered"
        WHERE (("date_delivery" IS NOT NULL) AND ("date_delivery" <> ''))
        GROUP BY "part_id"
        ) AS "ordered_sum" ON "ordered_sum"."part_id" = "parts"."id"
    FULL JOIN (
        SELECT "part_id", SUM("amount") AS "amount_need"
        FROM "needs"
        WHERE (("date" IS NOT NULL) AND ("date" <> ''))
        GROUP BY "part_id"
        ) AS "needs_sum" ON "needs_sum"."part_id" = "parts"."id"
    ORDER BY "suppliers"."name";

------------------ TRIGGERS -------------------------

-- If a part exists in a database and is ordered then its status is updated in parts table
CREATE TRIGGER "part_ordered"
AFTER INSERT ON "ordered"
FOR EACH ROW
WHEN EXISTS (SELECT 1 FROM "parts" WHERE "id" = NEW."part_id")
BEGIN
    UPDATE "parts"
    SET "stock" = 'ordered'
    WHERE "id" = NEW."part_id";
END;

-- If a part exists in a database and is delivered then its status is updated in parts table
CREATE TRIGGER "part_in"
AFTER UPDATE ON "ordered"
FOR EACH ROW
WHEN EXISTS (SELECT 1 FROM "parts" WHERE "id" = NEW."part_id")
BEGIN
    UPDATE "parts"
    SET "stock" = 'in'
    WHERE "id" = NEW."part_id";
END;

-- If an employee is fired then its soft deleted by adding the date when fired
CREATE TRIGGER "fired_employee"
INSTEAD OF DELETE ON "active_employees"
FOR EACH ROW
BEGIN
    UPDATE "employees" SET "fired" = CURRENT_TIMESTAMP WHERE "id" = OLD."id";
END;

-- If collaboration with a supplier is ended or suspended then it is soft deleted by changing it to unactive.
CREATE TRIGGER "supplier_activity"
INSTEAD OF DELETE ON "active_suppliers"
FOR EACH ROW
BEGIN
    UPDATE "suppliers" SET "active" = 'no' WHERE "id" = OLD."id";
END;

------------------- INDEXES ---------------------------------

CREATE INDEX "idx_needs_project_part" ON "needs"("project_id", "part_id");
CREATE INDEX "idx_needs_part" ON "needs"("part_id","date");
CREATE INDEX "idx_worked_on_employee_project" ON "worked_on"("employee_id", "project_id");
CREATE INDEX "idx_project_status_name" ON "projects"("name","status");
CREATE INDEX "idx_employees_fired_position" ON "employees"("fired","position");
CREATE INDEX "idx_clients_email" ON "clients"("email");
CREATE INDEX "idx_ordered_part" ON "ordered"("part_id","date_delivery");
CREATE INDEX "idx_parts_supplier_id" ON "parts"("supplier_id","name");
CREATE INDEX "idx_cars_brand_model" ON "cars"("brand","model");

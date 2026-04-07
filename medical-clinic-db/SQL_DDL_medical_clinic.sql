/*
Oliwier Sobczyk
EPAM COURSE Database Mentoring Programme

Last Update: 04.04.2026
*/


-- Create the physical database (Run this separately, then connect to it)
-- CREATE DATABASE IF NOT EXISTS medical_clinic_db;

-- Create a domain-related schema and drop the default one
CREATE 	SCHEMA IF NOT 	EXISTS clinic;
DROP 	SCHEMA IF 		EXISTS public;
/*
WHY SPECIFIC DATA TYPES WHERE USED:
VARCHAR vs TEXT:
   	VARCHAR(n) is used for all bounded strings (names, emails, statuses) to
    enforce a maximum length at the DB level, preventing oversized inputs.
    Using TEXT where VARCHAR(n) is needed allows unlimited
    input, leading to unlimited input and extensive use of storage
    However, text was introduced for clinical_notes and tests_results where 
    longer descripitions might be neccesary.
SERIAL vs INT:
    SERIAL is used for all surrogate primary keys. It auto-increments and
    prevents manual ID management errors.
    In contrary using plain INT without a sequence means inserts must
    supply an ID manually leading to duplicate key errors or gaps. INT 
    was used in all FK fields, which were related to PK SERIAL as these
    are already predefined and no errors within the data type are possible
NUMERIC(10,2) vs FLOAT/REAL:
    All monetary columns (standard_cost, standard_price, gross_amount, etc.)
    use NUMERIC(10,2) for exact decimal precision.
    In contrary FLOAT uses binary floating-point, which cannot
    represent all decimals exactly like for example 0.1 + 0.2 = 0.30000000000000004.
    This  causes rounding errors in totals, tax
    calculations and calculations in general
SMALLINT vs INT:
    Used for duration_minutes and duration_days where values will never
    exceed 32,767. Saves 2 bytes per row vs INT.
    While INT wastes storage at scale; using VARCHAR for a
    numeric field prevents arithmetic operations and comparisons
TIMESTAMP vs DATE:
    TIMESTAMP is used for event times (appointments, record creation) where
    exact time of day matters. DATE is used for dates when specific time is
    irrelevant (hire_date, issued_date).
    Storing appointment times as DATE loses the time insight, making it 
    impossible to detect scheduling conflicts or logs within
    the same day. Conversely, using TIMESTAMP for date_of_birth introduces
    unnecessary complexity without added value - storage waster
BOOLEAN vs VARCHAR/INT for flags:
    BOOLEAN (is_active, is_finalized, is_primary_role) is explicit and
    type-safe. Using INT (0/1) or VARCHAR ('Y'/'N') allows invalid values
    like 2 or 'YES' to be inserted without a constraint, which could lead 
    to anomalies.


Tables must be created in dependency order: a table with a FOREIGN KEY can
only reference a table that already exists. If the order is reversed, there 
would occur an error that a relation or a table does not exist for example 
if clinic.appointment was created before clinic.patient there would be an 
error as clinic.appointment requires FK from clinic.patient.

Hence, to ensure no errors occur the tables where created in the 
following order in this script:

Pure parent tables (no FKs to other tables):
  		patient, 
  		staff_role, 
  		treatment, 
  		diagnostic_test, 
  		medication
First-level children:
  		staff (self-ref FK), 
  		staff_role_assignment
Second-level children:
        appointment, 
        appointment_status_history
Third-level children:
        medical_record, 
        prescription, 
        bill
Junction tables (for M-M relationships):
        prescription_item
Leaf child tables:
		financial_transaction


*/
BEGIN;
    DROP TABLE IF EXISTS clinic.prescription_item         	CASCADE;
    DROP TABLE IF EXISTS clinic.financial_transaction     	CASCADE;
    DROP TABLE IF EXISTS clinic.prescription              	CASCADE;
    DROP TABLE IF EXISTS clinic.bill                      	CASCADE;
    DROP TABLE IF EXISTS clinic.medical_record            	CASCADE;
    DROP TABLE IF EXISTS clinic.appointment_status_history 	CASCADE;
    DROP TABLE IF EXISTS clinic.appointment               	CASCADE;
    DROP TABLE IF EXISTS clinic.staff_role_assignment     	CASCADE;
    DROP TABLE IF EXISTS clinic.staff                     	CASCADE;
    DROP TABLE IF EXISTS clinic.medication                	CASCADE;
    DROP TABLE IF EXISTS clinic.diagnostic_test           	CASCADE;
    DROP TABLE IF EXISTS clinic.treatment                 	CASCADE;
    DROP TABLE IF EXISTS clinic.patient                   	CASCADE;
    DROP TABLE IF EXISTS clinic.staff_role                	CASCADE;
COMMIT;

-- ==============================================================================
-- 2. PARENT TABLES
-- ==============================================================================

-- TABLE: clinic.patient

BEGIN;
	CREATE TABLE clinic.patient(
	    patient_id              SERIAL,
	    first_name              VARCHAR(100)    NOT NULL,
	    last_name               VARCHAR(100)    NOT NULL,
	    date_of_birth           DATE            NOT NULL,
	    gender                  VARCHAR(10),
	    -- Data Type Risk: Using VARCHAR instead of INT for phone numbers allows for 
	    -- leading zeros and special characters (+, -) which would be lost in numeric types.
	    phone                   VARCHAR(20)     NOT NULL,
	    email                   VARCHAR(150)    NOT NULL,
	    emergency_contact_phone VARCHAR(20)     NOT NULL,
	    registration_date       TIMESTAMP       NOT NULL DEFAULT NOW(),
	    is_active               BOOLEAN         NOT NULL DEFAULT TRUE,
	    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
	    
		/* 
	   - PK: Auto-increment surrogate key.
	   - UNIQUE: Prevents duplicate accounts by email.
	   - CHK_gender: Restricts values to ('Male', 'Female', 'Other') to prevent unrecognized data
			without it, GROUP BY gender queries would return inconsistent grouping data
	   - CHK_registration_date: Ensures no entries before 2000-01-01 (e.g.clinic opened on this day)
		*/  
	    CONSTRAINT PK_patient_patient_id 			PRIMARY KEY (patient_id),
		CONSTRAINT UQ_patient_email 				UNIQUE 		(email),
		CONSTRAINT CHK_patient_registration_date	CHECK 		(registration_date > '2000-01-01'),
		CONSTRAINT CHK_patient_gender 				CHECK 		(gender IN ('Male', 'Female', 'Other'))
	);
COMMIT;

-- TABLE: clinic.staff_role
BEGIN;
	CREATE TABLE clinic.staff_role(
	    staff_role_id           SERIAL,
	    role_name               VARCHAR(100)    NOT NULL,
	    description             VARCHAR(500),
	    
		/* 
	   - UNIQUE: Roles must be unique, otherwise multiple staff could have the same role 
	     with different task descriptions, leading to management ambiguity.
		*/
		CONSTRAINT PK_staff_role_staff_role_id 	PRIMARY KEY (staff_role_id),
		CONSTRAINT UQ_staff_role_role_name 		UNIQUE 		(role_name)
	);
COMMIT;


-- TABLE: clinic.treatment
BEGIN;
	CREATE TABLE clinic.treatment(
	    treatment_id            SERIAL,
	    treatment_name          VARCHAR(200)    NOT NULL,
	    description             VARCHAR(1000)   NOT NULL,
	    -- Data Type Risk: NUMERIC gives an exact value, which is better for financial 
	    -- applications than FLOAT, which can suffer from rounding errors in calculations.
	    standard_cost           NUMERIC(10,2),
	    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
	
		/* 
	   - CHK_cost: Cost is assumed to be positive; negative values would cause 
	     miscalculations in clinic operations reducing the cost of the patient
	   - UQ_treatment: Prevents duplicate treatment entries. Without it patients would 
			have had multiple same treatments and multiple billings instead of one
		*/
	
	    CONSTRAINT PK_treatment_treatment_id 					PRIMARY KEY (treatment_id),
	    CONSTRAINT UQ_treatment_treatment_name 					UNIQUE 		(treatment_name),
	    CONSTRAINT CHK_treatment_standard_cost_non_negative 	CHECK 		(standard_cost >= 0)
	    );
COMMIT;

-- TABLE: clinic.diagnostic_test
BEGIN;
	CREATE TABLE clinic.diagnostic_test(
	    test_id                 SERIAL,
	    test_name               VARCHAR(200)    NOT NULL,
	    description             VARCHAR(1000),
	    standard_cost           NUMERIC(10,2),
	    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
		
	    /* 
	   	- CHK_test_standard_cost_non_negative: Prevents negative cost values
   		from being entered due to a data entry error or misplaced minus sign.
    	Otherwise a value of like -60.00 would silently reduce a patient invoice
   		instead of increasing it, corrupting billing totals with no error raised.
		*/
	
		CONSTRAINT PK_diagnostic_test_test_id 			PRIMARY KEY (test_id),
		CONSTRAINT UQ_diagnostic_test_test_name 		UNIQUE (test_name),
		CONSTRAINT CHK_test_standard_cost_non_negative 	CHECK (standard_cost >= 0)   
	);
COMMIT;

-- TABLE: clinic.medication
BEGIN;
	CREATE TABLE clinic.medication(
	    medication_id           SERIAL,
	    medication_name         VARCHAR(200)    NOT NULL,
	    generic_name            VARCHAR(200)    NOT NULL,
	    manufacturer            VARCHAR(200)    NOT NULL,
	    unit                    VARCHAR(50)     NOT NULL,
	    standard_price          NUMERIC(10,2),
	    is_active               BOOLEAN         NOT NULL DEFAULT TRUE,
	    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
	
		/* 
	   	- CHK_medication_price_non_negative: Prevents negative drug prices.
    	If not implemented a negative standard_price would flow into prescription
    	billing logic, causing the system to credit patients rather than charge
    	them - an undetectable financial error at the database level.
		*/
	
	    CONSTRAINT PK_medication_medication_id			PRIMARY KEY (medication_id),
	    CONSTRAINT UQ_medication_medication_name 		UNIQUE 		(medication_name),
	    CONSTRAINT CHK_medication_price_non_negative	CHECK 		(standard_price >= 0)  
	);
COMMIT;

/*

A Foreign Key (FK) creates a referential integrity constraint between a
child table's column and a parent table's primary key.

  If an FK is absent:
  	ORPHANED RECORDS: You can insert a row in a child table referencing a
    parent ID that does not exist. For example, an appointment could reference
    patient_id = 999 even if no such patient exists, which corrupts data.

	PHANTOM DELETES: You can delete a parent row (e.g., a patient) while child
    	rows (appointments) still hold that patient_id. Queries joining the tables
     	would silently return incomplete results or crash application logic.

	NO CASCADING BEHAVIOUR: Without FK and ON DELETE/UPDATE rules, deleting or
    	renaming a parent record has no effect on its children. The database cannot
     	automatically protect referential relations.

	Example without FK on appointment.patient_id:
   		DELETE FROM clinic.patient WHERE patient_id = 1;
    	Succeeds silently and appointment rows with patient_id = 1 now reference
    	a patient whcih doesnt exists becoming a ghost record.

  All FKs in this schema use:
    ON DELETE RESTRICT  will block deletion of a parent if children exist.
    ON UPDATE CASCADE   will propagates PK changes to all FK references.
*/

-- ==============================================================================
-- 3. STAFF & ASSIGNMENTS
-- ==============================================================================

-- TABLE: clinic.staff
BEGIN;
	CREATE TABLE clinic.staff(
	    staff_id                SERIAL,
	    manager_id              INT,
	    first_name              VARCHAR(100)    NOT NULL,
	    last_name               VARCHAR(100)    NOT NULL,
	    specialty               VARCHAR(150),
	    phone                   VARCHAR(20)     NOT NULL,
	    email                   VARCHAR(150)    NOT NULL,
	    hire_date               DATE            NOT NULL,
	    is_active               BOOLEAN         NOT NULL DEFAULT TRUE,
	    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
		
	    /* 
	   	- FK: Self-referential link. Without this reference, a manager could be deleted 
	     while staff still reference their ID, causing orphaned records and hierarchy loss.
		*/
	
	    CONSTRAINT PK_staff_staff_id 	PRIMARY KEY (staff_id),
	    CONSTRAINT UQ_staff_email 		UNIQUE 		(email),
	    CONSTRAINT FK_staff_manager_id 	FOREIGN KEY (manager_id) REFERENCES clinic.staff(staff_id) ON DELETE RESTRICT ON UPDATE CASCADE
	);
COMMIT;

-- TABLE: clinic.staff_role_assignment
BEGIN;
	CREATE TABLE clinic.staff_role_assignment(
	    staff_id                INT             NOT NULL,
	    staff_role_id           INT             NOT NULL,
	    assigned_on             DATE            NOT NULL DEFAULT CURRENT_DATE,
	    is_primary_role         BOOLEAN         NOT NULL DEFAULT FALSE,
	    
	    /* 
	   	- Composite PK: Ensures a staff member cannot be assigned the same role twice.
	   	- FKs: Ensures assignments only point to valid staff and roles.
		*/
	
	    CONSTRAINT PK_staff_role_assignment_staff_id_staff_role_id 	PRIMARY KEY (staff_id, staff_role_id),
	    CONSTRAINT FK_staff_role_assignment_staff_id 				FOREIGN KEY (staff_id) 		REFERENCES clinic.staff(staff_id)			ON DELETE RESTRICT ON UPDATE CASCADE,
	    CONSTRAINT FK_staff_role_assignment_staff_role_id 			FOREIGN KEY (staff_role_id) REFERENCES clinic.staff_role(staff_role_id) ON DELETE RESTRICT ON UPDATE CASCADE
	);
COMMIT;

-- SECOND-LEVEL CHILD TABLES (Tables referencing first-level and parent tables)

-- ==============================================================================
-- 4. CLINICAL DATA
-- ==============================================================================

-- TABLE: clinic.appointment
BEGIN;
	CREATE TABLE clinic.appointment(
	    appointment_id          SERIAL,
	    patient_id              INT             NOT NULL,
	    staff_id                INT             NOT NULL,
	    appointment_datetime    TIMESTAMP       NOT NULL,
	    duration_minutes        SMALLINT        NOT NULL DEFAULT 30,
	    visit_reason            VARCHAR(500),
	    created_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
	    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
	    
	    /* 
	   - CHK_duration: Prevents zero/negative duration times which break scheduling logic
		*/
	    CONSTRAINT PK_appointment_appointment_id	PRIMARY KEY (appointment_id),
	    CONSTRAINT FK_appointment_patient_id 		FOREIGN KEY (patient_id) 	REFERENCES clinic.patient(patient_id) 	ON DELETE RESTRICT ON UPDATE CASCADE,
	    CONSTRAINT FK_appointment_staff_id 			FOREIGN KEY (staff_id) 		REFERENCES clinic.staff(staff_id) 		ON DELETE RESTRICT ON UPDATE CASCADE,
	    CONSTRAINT CHK_appointment_duration 		CHECK 		(duration_minutes > 0)
	    );
COMMIT;

-- TABLE: clinic.appointment_status_history
BEGIN;
	CREATE TABLE clinic.appointment_status_history(
	    history_id              SERIAL,
	    appointment_id          INT             NOT NULL,
	    status                  VARCHAR(50)     NOT NULL,
	    notes                   VARCHAR(500),
	    changed_by_staff_id     INT             NOT NULL,
	    effective_from          TIMESTAMP       NOT NULL DEFAULT NOW(),
	    effective_to            TIMESTAMP,
	    
		/* 
	   	- CHK_status: Restricts workflow states to predefined values to prevent data noise.
	   	- CHK_time: Ensures effective_to is not before effective_from (temporal logic).
		*/
	    CONSTRAINT PK_appointment_status_history_history_id PRIMARY KEY (history_id),
	    CONSTRAINT FK_history_appointment_id 				FOREIGN KEY (appointment_id)		REFERENCES clinic.appointment(appointment_id) 	ON DELETE RESTRICT ON UPDATE CASCADE,
	    CONSTRAINT FK_history_staff_id 						FOREIGN KEY (changed_by_staff_id) 	REFERENCES clinic.staff(staff_id) 				ON DELETE RESTRICT ON UPDATE CASCADE,
	    CONSTRAINT CHK_history_status 						CHECK 		(status IN ('SCHEDULED', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW')),
	    CONSTRAINT CHK_history_timeframe 					CHECK 		(effective_to IS NULL OR effective_to >= effective_from)
	);
COMMIT;

-- THIRD-LEVEL CHILD TABLES (Tables referencing second-level and parent tables)

-- TABLE: clinic.medical_record
BEGIN;
	CREATE TABLE clinic.medical_record(
	    record_id               SERIAL,
	    appointment_id          INT             NOT NULL,
	    staff_id                INT             NOT NULL,
	    treatment_id            INT,
	    test_id                 INT,
	    chief_complaint         VARCHAR(1000),
	    diagnosis               VARCHAR(1000)   NOT NULL,
	    clinical_notes          TEXT,
	    test_results            TEXT,
	    record_date             TIMESTAMP       NOT NULL DEFAULT NOW(),
	    is_finalized            BOOLEAN         NOT NULL DEFAULT FALSE,
	    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
	
	    /*
	   - UNIQUE: Ensures 1:1 mapping between appointment and medical record.
		*/
	    CONSTRAINT PK_medical_record_record_id 		PRIMARY KEY (record_id),
	    CONSTRAINT UQ_medical_record_appointment	UNIQUE 		(appointment_id),
	    CONSTRAINT FK_record_appointment_id 		FOREIGN KEY (appointment_id) 	REFERENCES clinic.appointment(appointment_id) 	ON DELETE RESTRICT ON UPDATE CASCADE,
	    CONSTRAINT FK_record_staff_id 				FOREIGN KEY (staff_id) 			REFERENCES clinic.staff(staff_id) 				ON DELETE RESTRICT ON UPDATE CASCADE,
	    CONSTRAINT FK_record_treatment_id 			FOREIGN KEY (treatment_id) 		REFERENCES clinic.treatment(treatment_id) 		ON DELETE RESTRICT ON UPDATE CASCADE,
	    CONSTRAINT FK_record_test_id 				FOREIGN KEY (test_id) 			REFERENCES clinic.diagnostic_test(test_id) 		ON DELETE RESTRICT ON UPDATE CASCADE
	);
COMMIT;

-- TABLE: clinic.prescription
BEGIN;
	CREATE TABLE clinic.prescription(
	    prescription_id         SERIAL,
	    appointment_id          INT             NOT NULL,
	    prescribing_staff_id    INT             NOT NULL,
	    issued_date             DATE            NOT NULL DEFAULT CURRENT_DATE,
	    valid_until             DATE            NOT NULL,
	    notes                   VARCHAR(1000),
	
	    /* 
	   	- CHK_dates: Prevents validity logic errors where expiration is before issuance.
		*/
	
	    CONSTRAINT PK_prescription_prescription_id 	PRIMARY KEY (prescription_id),
	    CONSTRAINT FK_prescription_appointment_id 	FOREIGN KEY (appointment_id) 		REFERENCES clinic.appointment(appointment_id) 	ON DELETE RESTRICT ON UPDATE CASCADE,
	    CONSTRAINT FK_prescription_staff_id 		FOREIGN KEY (prescribing_staff_id) 	REFERENCES clinic.staff(staff_id) 				ON DELETE RESTRICT ON UPDATE CASCADE,
	    CONSTRAINT CHK_prescription_validity 		CHECK 		(valid_until >= issued_date)
	    );
COMMIT;

-- ==============================================================================
-- 5. FINANCIAL DATA
-- ==============================================================================

-- TABLE: clinic.bill
BEGIN;
	CREATE TABLE clinic.bill(
	    bill_id                 SERIAL,
	    appointment_id          INT             NOT NULL,
	    gross_amount            NUMERIC(10,2)   NOT NULL,
	    discount_amount         NUMERIC(10,2)   NOT NULL DEFAULT 0,
	    tax_amount              NUMERIC(10,2)   NOT NULL DEFAULT 0,
	    issued_date             DATE            NOT NULL DEFAULT CURRENT_DATE,
	    due_date                DATE            NOT NULL,
	    notes                   VARCHAR(500),
	    updated_at              TIMESTAMP       NOT NULL DEFAULT NOW(),
	
	    /* 
	   	- CHK_amounts: Ensures sub-totals are not negative.
	   	- CHK_due_date: Ensures deadline is after issuance.
		*/
	    CONSTRAINT PK_bill_bill_id 			PRIMARY KEY (bill_id),
	    CONSTRAINT UQ_bill_appointment 		UNIQUE 		(appointment_id),
	    CONSTRAINT FK_bill_appointment_id 	FOREIGN KEY (appointment_id) REFERENCES clinic.appointment(appointment_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	    CONSTRAINT CHK_bill_amounts 		CHECK 		(gross_amount >= 0 AND discount_amount >= 0 AND tax_amount >= 0),
	    CONSTRAINT CHK_bill_due_date 		CHECK 		(due_date >= issued_date)
	    
	    );
COMMIT;


-- Leaf child table 
-- TABLE: clinic.financial_transaction
BEGIN;
	CREATE TABLE clinic.financial_transaction(
	    transaction_id      SERIAL,
	    bill_id             INT             NOT NULL,
	    transaction_type    VARCHAR(50)     NOT NULL,
	    -- ensures zero-value or negative financial ledger entries are not entered
	    amount              NUMERIC(10,2)   NOT NULL,
	    transaction_date    DATE            NOT NULL DEFAULT CURRENT_DATE,
	    reference_number    VARCHAR(100),
	    notes               VARCHAR(500),
	    
		/*
		- CHK_financial_transaction_transaction_type: Restricts entries to
    	('PAYMENT', 'WAIVER', 'DISPUTE', 'REFUND').
    	without restirction logical values like 'CASH' or 'PENDING' could be stored,
    	making filterin gor grouping unreliable and causing database to be unorganized
  		- CHK_financial_transaction_amount (> 0): Prevents zero or negative ledger entries.
    	Otheriwse a transaction of 0.00 or -59.40 could be recorded, causing the breakage
		of financial logic
		*/

	    CONSTRAINT PK_financial_transaction_transaction_id		PRIMARY KEY (transaction_id),
	    CONSTRAINT FK_financial_transaction_bill_id 			FOREIGN KEY (bill_id) REFERENCES clinic.bill(bill_id) ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT CHK_financial_transaction_transaction_type	CHECK		(transaction_type IN ('PAYMENT', 'WAIVER', 'DISPUTE', 'REFUND')),
		CONSTRAINT CHK_financial_transaction_amount				CHECK 		(amount > 0),
		CONSTRAINT UQ_financial_transaction_reference_number	UNIQUE 		(reference_number)
	);
COMMIT;

-- Junction table for M-M relationships
-- TABLE: clinic.prescription_item
BEGIN;
	CREATE TABLE clinic.prescription_item(
		prescription_id		INT,
		medication_id		INT,
		dosage				VARCHAR(100)	NOT NULL,
		frequency			VARCHAR(100)	NOT NULL,

		/*
		DEVIATION: duration_days marked NOT NULL (not in logical model)
		Reason: A prescription item without a duration is  meaningless and
		would leave dosage schedules undefined. NOT NULL is enforced to preserve
		data integrity at the physical level.	
		*/

		duration_days		SMALLINT		NOT NULL,
		quantity			SMALLINT		NOT NULL,
		instructions		VARCHAR(500),
		
		CONSTRAINT PK_prescription_item_prescription_id_medication_id 	PRIMARY KEY (prescription_id ,medication_id),
		CONSTRAINT FK_prescription_item_prescription_id					FOREIGN KEY (prescription_id) 	REFERENCES clinic.prescription(prescription_id)	ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT FK_prescription_item_medication_id					FOREIGN KEY (medication_id)		REFERENCES clinic.medication(medication_id)		ON DELETE RESTRICT ON UPDATE CASCADE,
		CONSTRAINT CHK_prescription_item_duration_days					CHECK		(duration_days 	> 0),
		CONSTRAINT CHK_prescription_item_quantity						CHECK       (quantity 		> 0)
	);
COMMIT;

/*
INSERT STRATEGY 

All INSERT operations for children are written in a CTE with correlated subquery pattern in order to 
dynamically resolve foreign key IDs during insertion based on unique business keys (e-mails, name, timestamp), 
as opposed to hardcoded integers.

This technique:
- Does not rely on any assumptions about IDs that could break due to
sequence number gaps or reordering
- Preserves referential integrity through dynamically finding the ID of the already
inserted parents
- Takes into account dependency order between parents and children in that
subqueries will always find the rows they reference.

Preventing duplicates:
- ON CONFLICT (... ) DO NOTHING where there is a reliable unique constraint
as the conflict target (e-mail address, appointment_id, composite PK).
- WHERE NOT EXISTS when no such unique constraint is available (appointment,
appointment_status_history, prescription).
This makes the script safe to re-execute multiple times

  Dependency order followed:
    1. staff_role, patient, treatment, diagnostic_test, medication (no FKs)
    2. staff - manager inserted first, subordinate references manager by email
    3. staff_role_assignment - references staff and staff_role
    4. appointment - references patient and staff
    5. appointment_status_history - references appointment and staff
    6. medical_record - references appointment, staff, treatment, diagnostic_test
    7. prescription - references appointment and staff
    8. bill - references appointment
    9. financial_transaction - references bill
   10. prescription_item - references prescription and medication
*/
BEGIN; -- transaction for parent tables
	-- CLINIC.STAFF_ROLE
	
	INSERT INTO clinic.staff_role (
			staff_role_id, 
			role_name,
			description
			) 
	VALUES
		(1, 'ADMINISTRATOR', 		'Manages clinic operations and staff'),
		(2, 'GENERAL PRACITIONER', 'Provides primary care and referrals')
	ON CONFLICT (staff_role_id) DO NOTHING;
	
	
	-- CLINIC.PATIENT
	
	INSERT INTO clinic.patient (
		patient_id,
		first_name,
		last_name,
		date_of_birth,
		gender,
		phone,
		email,
		emergency_contact_phone,
		registration_date,
		is_active,
		updated_at
	) VALUES
		(1, 'Maria', 'Wisniewska', '1985-04-12', 'Female', '+48 500 111 222', 'm.wisniewska@mail.pl', '+48 500 999 888', '2025-01-10 10:00:00', TRUE, '2025-01-15 10:00:00'),
		(2, 'Jan', 'Kowalski', '1972-11-30', 'Male', '+48 500 333 444', 'j.kowalski@mail.pl', '+48 500 777 666', '2025-02-20 14:30:00', TRUE, '2025-03-12 10:00:00')
	ON CONFLICT (patient_id) DO NOTHING;
	
	-- CLINIC.TREATMENT
	
	INSERT INTO clinic.treatment (
		treatment_id,
		treatment_name,
		description,
		standard_cost,
		updated_at
	) VALUES
		(1, 'Blood Pressure Measurement', 'Non-invasive arterial blood pressure check', 15.00, '2024-01-01 00:00:00'),
		(2, 'Wound Suturing', 'Closure of lacerations using sutures', 120.00, '2024-01-01 00:00:00')
	ON CONFLICT (treatment_id) DO NOTHING;
	
	-- CLINIC.DIAGNOSTIC_TEST
	
	INSERT INTO clinic.diagnostic_test (
		test_id,
		test_name,
		description,
		standard_cost,
		updated_at
	) VALUES
		(1, 'Complete Blood Count', 'Full CBC panel including WBC, RBC, and platelets', 40.00, '2024-01-01 00:00:00'),
		(2, 'ECG', '12-lead electrocardiogram for heart rhythm analysis', 60.00, '2024-01-01 00:00:00')
	ON CONFLICT (test_id) DO NOTHING;
	
	-- CLINIC.MEDICATION
	
	INSERT INTO clinic.medication (
		medication_id,
		medication_name,
		generic_name,
		manufacturer,
		unit,
		standard_price,
		is_active,
		updated_at
	) VALUES
		(1, 'Ibuprofen 400mg', 'Ibuprofen', 'Polpharma', 'tablet', 8.50, TRUE, '2024-01-01 00:00:00'),
		(2, 'Amoxicillin 500mg', 'Amoxicillin', 'Sandoz', 'capsule', 22.00, TRUE, '2024-01-01 00:00:00')
	ON CONFLICT (medication_id) DO NOTHING;

COMMIT; -- end of INSERT transaction for parent tables


-- ======================================================

BEGIN; -- open a new transaction for all child inserts

-- CLINIC.STAFF (MANAGERS)
-- Insert top-level staff members first so their IDs exist for subordinates to reference
WITH manager_data (first_name, last_name, specialty, phone, email, hire_date, is_active) AS (
	VALUES
		('Anna', 'Kowalska', 'General Practice', '+48 600 100 200', 'a.kowalska@clinic.pl', '2020-06-01'::DATE, TRUE)
)
INSERT INTO clinic.staff (
	manager_id,
	first_name,
	last_name,
	specialty,
	phone,
	email,
	hire_date,
	is_active,
	updated_at
)
SELECT	NULL::INT, -- Top level managers have no manager
		md.first_name,
		md.last_name,
		md.specialty,
		md.phone,
		md.email,
		md.hire_date,
		md.is_active,
		NOW()
FROM	manager_data md
ON CONFLICT (email) DO NOTHING;  -- email is UNIQUE, so conflict target is email


-- CLINIC.STAFF (SUBORDINATES)
-- Insert subordinates by dynamically looking up their manager's staff_id using the email
WITH staff_data (manager_email, first_name, last_name, specialty, phone, email, hire_date, is_active) AS (
	VALUES
		('a.kowalska@clinic.pl', 'Piotr', 'Nowak', 'Cardiology', '+48 600 300 400', 'p.nowak@clinic.pl', '2021-09-15'::DATE, TRUE)
)
INSERT INTO clinic.staff (
	manager_id,
	first_name,
	last_name,
	specialty,
	phone,
	email,
	hire_date,
	is_active,
	updated_at
)
SELECT	(SELECT mgr.staff_id FROM clinic.staff mgr WHERE mgr.email = sd.manager_email),
		sd.first_name,
		sd.last_name,
		sd.specialty,
		sd.phone,
		sd.email,
		sd.hire_date,
		sd.is_active,
		NOW()
FROM	staff_data sd
ON CONFLICT (email) DO NOTHING;

-- CLINIC.STAFF_ROLE_ASSIGNMENT
-- Uses staff email and role_name to dynamically fetch the required IDs
WITH assignment_data (staff_email, role_name, assigned_on, is_primary) AS (
	VALUES
		('a.kowalska@clinic.pl', 'ADMINISTRATOR',       '2020-01-15'::DATE, TRUE),
		('p.nowak@clinic.pl',    'GENERAL PRACITIONER', '2022-06-01'::DATE, FALSE)
)
INSERT INTO clinic.staff_role_assignment (
	staff_id,
	staff_role_id,
	assigned_on,
	is_primary_role
)
SELECT	(SELECT stf.staff_id      FROM clinic.staff      stf WHERE stf.email     = ad.staff_email),
		(SELECT rol.staff_role_id FROM clinic.staff_role rol WHERE rol.role_name = ad.role_name),
		ad.assigned_on,
		ad.is_primary
FROM	assignment_data ad
ON CONFLICT (staff_id, staff_role_id) DO NOTHING;


-- CLINIC.APPOINTMENT
-- Uses patient email and staff email to fetch IDs
WITH appointment_data (patient_email, staff_email, appt_datetime, duration, reason) AS (
	VALUES
		('m.wisniewska@mail.pl', 'a.kowalska@clinic.pl', '2026-03-15 09:00:00'::TIMESTAMP, 30, 'Routine checkup'),
		('j.kowalski@mail.pl',   'a.kowalska@clinic.pl', '2026-03-15 09:30:00'::TIMESTAMP, 45, 'Chest pain')
)
INSERT INTO clinic.appointment (
	patient_id,
	staff_id,
	appointment_datetime,
	duration_minutes,
	visit_reason,
	created_at,
	updated_at
)
SELECT	(SELECT pat.patient_id FROM clinic.patient pat WHERE pat.email = ad.patient_email),
		(SELECT stf.staff_id   FROM clinic.staff   stf WHERE stf.email = ad.staff_email),
		ad.appt_datetime,
		ad.duration,
		ad.reason,
		NOW(),
		NOW()
FROM	appointment_data ad
-- Since appointment has no UNIQUE constraint beyond PK (SERIAL), 
-- the safest approach is WHERE NOT EXISTS:
WHERE NOT EXISTS (
    SELECT 1 
	FROM 	clinic.appointment a 
	WHERE	a.appointment_datetime = ad.appt_datetime
);


-- CLINIC.APPOINTMENT_STATUS_HISTORY
-- Uses the appointment datetime and staff email to dynamically link the history log
WITH history_data (appt_datetime, status, notes, staff_email, eff_from, eff_to) AS (
	VALUES
		('2026-03-15 09:00:00'::TIMESTAMP, 'SCHEDULED', 'Initial booking confirmed', 'a.kowalska@clinic.pl', '2026-03-01 08:00:00'::TIMESTAMP, '2026-03-15 09:00:00'::TIMESTAMP),
		('2026-03-15 09:00:00'::TIMESTAMP, 'COMPLETED', 'Patient attended visit',    'a.kowalska@clinic.pl', '2026-03-15 09:00:00'::TIMESTAMP, NULL::TIMESTAMP),
		('2026-03-15 09:30:00'::TIMESTAMP, 'SCHEDULED',   'Cardiology referral booked', 'a.kowalska@clinic.pl', '2026-03-02 09:15:00'::TIMESTAMP, '2026-03-15 09:30:00'::TIMESTAMP),
		('2026-03-15 09:30:00'::TIMESTAMP, 'IN_PROGRESS',  'Patient in consultation',   'p.nowak@clinic.pl',   '2026-03-15 09:30:00'::TIMESTAMP, NULL::TIMESTAMP)
)
INSERT INTO clinic.appointment_status_history (
	appointment_id,
	status,
	notes,
	changed_by_staff_id,
	effective_from,
	effective_to
)
SELECT	(SELECT app.appointment_id FROM clinic.appointment app WHERE app.appointment_datetime = hd.appt_datetime),
		hd.status,
		hd.notes,
		(SELECT stf.staff_id       FROM clinic.staff       stf WHERE stf.email = hd.staff_email),
		hd.eff_from,
		hd.eff_to
FROM	history_data hd
WHERE NOT EXISTS (
    SELECT 1 
	FROM 	clinic.appointment_status_history ash
    WHERE 	ash.appointment_id = (SELECT appointment_id FROM clinic.appointment WHERE appointment_datetime = hd.appt_datetime)
    AND   	ash.status = hd.status
);

-- CLINIC.MEDICAL_RECORD
-- Uses the appointment datetime, staff email, and treatment/test names to link foreign keys
WITH record_data (appt_datetime, staff_email, treatment_name, test_name, complaint, diag, results, rec_date) AS (
	VALUES
		('2026-03-15 09:00:00'::TIMESTAMP, 'a.kowalska@clinic.pl', 'Blood Pressure Measurement', NULL::VARCHAR, 'Fatigue and mild fever',   'Upper respiratory infection', 'BP: 118/76 - normal', '2026-03-15 09:45:00'::TIMESTAMP),
		('2026-03-15 09:30:00'::TIMESTAMP, 'p.nowak@clinic.pl',    NULL::VARCHAR,                'ECG',         'Chest pain on exertion', 'Stable angina',               'Sinus rhythm',        '2026-03-15 10:20:00'::TIMESTAMP)
)
INSERT INTO clinic.medical_record (
	appointment_id,
	staff_id,
	treatment_id,
	test_id,
	chief_complaint,
	diagnosis,
	test_results,
	record_date,
	is_finalized,
	updated_at
)
SELECT	(SELECT app.appointment_id FROM clinic.appointment app       WHERE app.appointment_datetime = rd.appt_datetime),
		(SELECT stf.staff_id       FROM clinic.staff       stf       WHERE stf.email                = rd.staff_email),
		(SELECT trt.treatment_id   FROM clinic.treatment   trt       WHERE trt.treatment_name       = rd.treatment_name),
		(SELECT tst.test_id        FROM clinic.diagnostic_test tst   WHERE tst.test_name            = rd.test_name),
		rd.complaint,
		rd.diag,
		rd.results,
		rd.rec_date,
		TRUE,
		NOW()
FROM	record_data rd
ON CONFLICT (appointment_id) DO NOTHING;


-- CLINIC.PRESCRIPTION
-- Uses the appointment datetime and staff email to insert prescriptions
WITH prescription_data (appt_datetime, staff_email, issued, valid_until, notes) AS (
	VALUES
		('2026-03-15 09:00:00'::TIMESTAMP, 'a.kowalska@clinic.pl', '2026-03-15'::DATE, '2026-04-15'::DATE, 'Take as directed; avoid alcohol'),
		('2026-03-15 09:30:00'::TIMESTAMP, 'p.nowak@clinic.pl',    '2026-03-15'::DATE, '2026-06-15'::DATE, 'Cardiac medication; do not skip doses')
)
INSERT INTO clinic.prescription (
	appointment_id,
	prescribing_staff_id,
	issued_date,
	valid_until,
	notes
)
SELECT	(SELECT app.appointment_id FROM clinic.appointment app WHERE app.appointment_datetime = pd.appt_datetime),
		(SELECT stf.staff_id       FROM clinic.staff       stf WHERE stf.email = pd.staff_email),
		pd.issued,
		pd.valid_until,
		pd.notes
FROM	prescription_data pd
WHERE NOT EXISTS (
    SELECT 1 
	FROM 	clinic.prescription p
    WHERE	p.appointment_id = (SELECT appointment_id FROM clinic.appointment WHERE appointment_datetime = pd.appt_datetime)
);

-- CLINIC.BILL
-- Uses the appointment datetime to link the correct appointment ID dynamically
WITH bill_data (appt_datetime, gross, discount, tax, issued, due, notes) AS (
	VALUES
		('2026-03-15 09:00:00'::TIMESTAMP, 55.00, 0.00, 4.40, '2026-03-15'::DATE, '2026-03-29'::DATE, 'Standard consultation and CBC test'),
		('2026-03-15 09:30:00'::TIMESTAMP, 75.00, 5.00, 5.60, '2026-03-15'::DATE, '2026-03-29'::DATE, 'Specialist visit with ECG')
)
INSERT INTO clinic.bill (
	appointment_id,
	gross_amount,
	discount_amount,
	tax_amount,
	issued_date,
	due_date,
	notes,
	updated_at
)
SELECT	(SELECT app.appointment_id FROM clinic.appointment app WHERE app.appointment_datetime = bd.appt_datetime),
		bd.gross,
		bd.discount,
		bd.tax,
		bd.issued,
		bd.due,
		bd.notes,
		NOW()
FROM	bill_data bd
ON CONFLICT (appointment_id) DO NOTHING;


-- CLINIC.FINANCIAL_TRANSACTION
-- Uses a nested subquery. Finds the appointment_id via datetime, then finds the bill_id via appointment_id
WITH transaction_data (appt_datetime, txn_type, amount, txn_date, ref_num, notes) AS (
	VALUES
		('2026-03-15 09:00:00'::TIMESTAMP, 'PAYMENT', 59.40, '2026-03-15'::DATE, 'TXN-2026-00101', 'Full payment at checkout'),
		('2026-03-15 09:30:00'::TIMESTAMP, 'WAIVER',  4.40,  '2026-03-20'::DATE, NULL::VARCHAR,    'Goodwill tax waiver approved')
)
INSERT INTO clinic.financial_transaction (
	bill_id,
	transaction_type,
	amount,
	transaction_date,
	reference_number,
	notes
)
SELECT	(SELECT bil.bill_id FROM clinic.bill bil WHERE bil.appointment_id = (SELECT app.appointment_id FROM clinic.appointment app WHERE app.appointment_datetime = td.appt_datetime)),
		td.txn_type,
		td.amount,
		td.txn_date,
		td.ref_num,
		td.notes
FROM	transaction_data td
ON CONFLICT (reference_number) DO NOTHING;


-- CLINIC.PRESCRIPTION_ITEM 
-- Uses a nested subquery to find prescription_id via appointment_datetime, and medication_name for medication_id
WITH prescription_item_data (appt_datetime, med_name, dosage, frequency, duration, quantity, instructions) AS (
	VALUES
		('2026-03-15 09:00:00'::TIMESTAMP, 'Ibuprofen 400mg',   '400 mg', 'Three times daily', 7::SMALLINT, 21::SMALLINT, 'Take with food or milk to reduce stomach upset'),
		('2026-03-15 09:00:00'::TIMESTAMP, 'Amoxicillin 500mg', '500 mg', 'Twice daily',       7::SMALLINT, 14::SMALLINT, 'Complete full course even if symptoms improve')
)
INSERT INTO clinic.prescription_item (
	prescription_id,
	medication_id,
	dosage,
	frequency,
	duration_days,
	quantity,
	instructions
)
SELECT	(SELECT pre.prescription_id FROM clinic.prescription pre WHERE pre.appointment_id = (SELECT app.appointment_id FROM clinic.appointment app WHERE app.appointment_datetime = pid.appt_datetime)),
		(SELECT med.medication_id   FROM clinic.medication   med WHERE med.medication_name = pid.med_name),
		pid.dosage,
		pid.frequency,
		pid.duration,
		pid.quantity,
		pid.instructions
FROM	prescription_item_data pid
ON CONFLICT (prescription_id, medication_id) DO NOTHING;

COMMIT; -- commit transaction for child tables

/*
  ALTERING EACH TABLE
  
  Each table is altered by addinng a record_ts field.
  If the script aborts after adding record_ts to 8 tables, there is an inconsistent schema 
  where some tables have the column and some don't. Re-running will then error on the 8 
  previously altered tables. Having them in one transaction ensures this error does not
  happen.
*/
BEGIN;

	ALTER TABLE clinic.patient 						ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.staff_role 					ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.treatment 					ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.diagnostic_test 				ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.medication 					ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.staff 						ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.staff_role_assignment 		ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.appointment 					ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.appointment_status_history	ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.medical_record 				ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.prescription 				ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.bill 						ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.financial_transaction 		ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
	ALTER TABLE clinic.prescription_item 			ADD COLUMN record_ts DATE NOT NULL DEFAULT CURRENT_DATE;

COMMIT;


/*
  TO confirm record_ts has been populated for all existing rows every query below should return 0.
  If any table returns > 0, the DEFAULT did not apply (should not happen with
  ADD COLUMN ... DEFAULT, but this confirms it).
*/
SELECT 'patient'                    AS tbl, 	COUNT(*) AS nulls 	FROM clinic.patient                   	WHERE record_ts IS NULL
UNION ALL
SELECT 'staff_role',                         	COUNT(*) 			FROM clinic.staff_role                  WHERE record_ts IS NULL
UNION ALL
SELECT 'treatment',                          	COUNT(*) 			FROM clinic.treatment                   WHERE record_ts IS NULL
UNION ALL
SELECT 'diagnostic_test',                    	COUNT(*) 			FROM clinic.diagnostic_test             WHERE record_ts IS NULL
UNION ALL
SELECT 'medication',                         	COUNT(*) 			FROM clinic.medication                  WHERE record_ts IS NULL
UNION ALL
SELECT 'staff',                              	COUNT(*) 			FROM clinic.staff                       WHERE record_ts IS NULL
UNION ALL
SELECT 'staff_role_assignment',              	COUNT(*) 			FROM clinic.staff_role_assignment       WHERE record_ts IS NULL
UNION ALL
SELECT 'appointment',                        	COUNT(*) 			FROM clinic.appointment                 WHERE record_ts IS NULL
UNION ALL
SELECT 'appointment_status_history',         	COUNT(*) 			FROM clinic.appointment_status_history	WHERE record_ts IS NULL
UNION ALL
SELECT 'medical_record',                     	COUNT(*) 			FROM clinic.medical_record              WHERE record_ts IS NULL
UNION ALL
SELECT 'prescription',                       	COUNT(*) 			FROM clinic.prescription                WHERE record_ts IS NULL
UNION ALL
SELECT 'bill',                               	COUNT(*) 			FROM clinic.bill                        WHERE record_ts IS NULL
UNION ALL
SELECT 'financial_transaction',              	COUNT(*) 			FROM clinic.financial_transaction       WHERE record_ts IS NULL
UNION ALL
SELECT 'prescription_item',                  	COUNT(*) 			FROM clinic.prescription_item           WHERE record_ts IS NULL;

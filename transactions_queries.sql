-- =============================================================
-- LAB 10: Database Transactions (COMMIT, ROLLBACK, SAVEPOINT, AUTOCOMMIT)
-- Instructor: Fatima Gado
-- =============================================================

-- SECTION 1: Creating and Modifying a Table in a Transaction
-------------------------------------------------------------

-- Create worker table
CREATE TABLE worker (
    worker_id NUMBER PRIMARY KEY,
    worker_name VARCHAR2(50),
    salary NUMBER
);

-- Insert a record (not yet committed)
INSERT INTO worker (worker_id, worker_name, salary)
VALUES (1, 'Sohail', 5000);
-- This is a DML operation. It will not be visible to others until committed.

-- Update salary without committing
UPDATE worker SET salary = 6000 WHERE worker_id = 1;

-- Try to update the same record from another worksheet (it will be locked)
-- UPDATE worker SET salary = 7000 WHERE worker_id = 1;

-- Commit the transaction to make changes permanent
COMMIT;


-- SECTION 2: Savepoint and Rollback Example
--------------------------------------------

-- Start Transaction
SET TRANSACTION NAME 'test_transaction';

-- Insert new record and set first savepoint
INSERT INTO worker (worker_id, worker_name, salary)
VALUES (2, 'Erum', 5500);
SAVEPOINT sp1;

-- Update salary and set another savepoint
UPDATE worker SET salary = 6000 WHERE worker_name = 'Erum';
SAVEPOINT sp2;

-- Rollback to first savepoint (undo last update)
ROLLBACK TO SAVEPOINT sp1;

-- Commit the transaction
COMMIT;


-- SECTION 3: AUTOCOMMIT
------------------------

-- Enable autocommit (every DML auto commits)
SET AUTOCOMMIT ON;

-- Insert data (automatically commits)
INSERT INTO worker (worker_id, worker_name, salary)
VALUES (3, 'FAST-NU', 5000);

-- Disable autocommit again
SET AUTOCOMMIT OFF;


-- SECTION 4: Customer and Order Transaction Example
----------------------------------------------------

-- Create tables
CREATE TABLE customer (
    customer_id NUMBER PRIMARY KEY,
    customer_name VARCHAR2(50),
    balance NUMBER
);

CREATE TABLE orders (
    order_id NUMBER PRIMARY KEY,
    customer_id NUMBER REFERENCES customer(customer_id),
    order_amount NUMBER
);

-- Start a new transaction
SET TRANSACTION NAME 'customer_order_transaction';

-- Step 1: Insert new customer and set savepoint
INSERT INTO customer VALUES (1, 'Areeba', 10000);
SAVEPOINT customer_added;

-- Step 2: Insert order and update customer balance
INSERT INTO orders VALUES (101, 1, 3000);
UPDATE customer SET balance = balance - 3000 WHERE customer_id = 1;
SAVEPOINT order_added;

-- Step 3: Commit or rollback if an issue occurs
COMMIT;
-- If an issue occurs, use: ROLLBACK TO customer_added;



-- END OF LAB 10 SCRIPT
-- =============================================================

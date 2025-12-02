-- Task 1: Product inventory with savepoint
CREATE TABLE product_inventory (
    product_id NUMBER PRIMARY KEY,
    product_name VARCHAR2 (100),
    stock NUMBER,
    price NUMBER (10, 2)
);

-- Start transaction
BEGIN
    -- Insert three products
    INSERT INTO product_inventory VALUES (1, 'Laptop', 50, 999.99);
    INSERT INTO product_inventory VALUES (2, 'Mouse', 200, 25.50);
    INSERT INTO product_inventory VALUES (3, 'Keyboard', 150, 75.00);
    
    -- Reduce stock of first product
    UPDATE product_inventory 
    SET stock = stock - 10 
    WHERE product_id = 1;
    
    -- Create savepoint
    SAVEPOINT stock_update;
    
    -- You can continue with more operations or rollback to this point
    -- ROLLBACK TO stock_update;
    
    -- To make changes permanent, commit
    COMMIT;
END;
/

-- Task 2: Employee salary update with savepoints
BEGIN
    -- Add new employee
    INSERT INTO employees (employee_id, first_name, last_name, email, 
                          hire_date, job_id, salary)
    VALUES (9999, 'Test', 'Employee', 'test@company.com',
            SYSDATE, 'IT_PROG', 5000);
    
    -- Increase salary by 10%
    UPDATE employees
    SET salary = salary * 1.10
    WHERE employee_id = 9999;
    
    -- Set savepoint
    SAVEPOINT salary_increase;
    
    -- Further increase by 5%
    UPDATE employees
    SET salary = salary * 1.05
    WHERE employee_id = 9999;
    
    -- Rollback to savepoint (undo the 5% increase)
    ROLLBACK TO SAVEPOINT salary_increase;
    
    -- Commit the transaction (keeps the 10% increase)
    COMMIT;
END;
/

-- Task 3: Customer and orders transaction with rollback
BEGIN
    -- Insert new customer
    INSERT INTO customer (customer_id, customer_name, balance)
    VALUES (100, 'John Doe', 10000);
    
    -- Insert order for customer
    INSERT INTO orders (order_id, customer_id, order_amount)
    VALUES (1001, 100, 2500);
    
    -- Update customer balance
    UPDATE customer
    SET balance = balance - 2500
    WHERE customer_id = 100;
    
    -- If everything successful, commit
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        -- If any error occurs, rollback all changes
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Transaction failed: ' || SQLERRM);
END;
/

-- Task 4: AUTOCOMMIT demonstration
-- Enable autocommit
SET AUTOCOMMIT ON;

-- Create sales table if not exists
CREATE TABLE sales (
    sales_id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    amount NUMBER (10, 2),
    sale_date DATE DEFAULT SYSDATE
);

-- Insert with autocommit enabled (automatically commits)
INSERT INTO
    sales (sales_id, customer_id, amount)
VALUES (1, 100, 1500.00);

-- Check if row was committed
SELECT * FROM sales WHERE sales_id = 1;

-- Disable autocommit
SET AUTOCOMMIT OFF;

-- Task 5: Multiple savepoints with transactions
CREATE TABLE transactions (
    transaction_id NUMBER PRIMARY KEY,
    account_id NUMBER,
    transaction_type VARCHAR2 (10),
    amount NUMBER (10, 2),
    balance NUMBER (10, 2),
    transaction_date TIMESTAMP DEFAULT SYSTIMESTAMP
);

BEGIN
-- Initial balance
DECLARE v_balance NUMBER := 10000;

BEGIN
-- Credit operation
INSERT INTO
    transactions
VALUES (
        1,
        1001,
        'CREDIT',
        2000,
        v_balance + 2000,
        SYSTIMESTAMP
    );

v_balance := v_balance + 2000;

SAVEPOINT after_credit_1;

-- Debit operation
INSERT INTO
    transactions
VALUES (
        2,
        1001,
        'DEBIT',
        500,
        v_balance - 500,
        SYSTIMESTAMP
    );

v_balance := v_balance - 500;

SAVEPOINT after_debit_1;

-- Another credit
INSERT INTO
    transactions
VALUES (
        3,
        1001,
        'CREDIT',
        1500,
        v_balance + 1500,
        SYSTIMESTAMP
    );

v_balance := v_balance + 1500;

SAVEPOINT after_credit_2;

-- Another debit
INSERT INTO
    transactions
VALUES (
        4,
        1001,
        'DEBIT',
        3000,
        v_balance - 3000,
        SYSTIMESTAMP
    );

v_balance := v_balance - 3000;

SAVEPOINT after_debit_2;

-- Rollback to a specific savepoint (undo last debit)
ROLLBACK TO SAVEPOINT after_credit_2;

-- Commit remaining transactions
COMMIT;

DBMS_OUTPUT.PUT_LINE (
    'Final balance: ' || v_balance
);

END;

END;
/
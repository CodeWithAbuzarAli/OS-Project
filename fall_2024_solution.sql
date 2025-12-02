-- Q1 - (i) Retrieve the highest paid employee in each department along with their job title and salary.
SELECT d.department_name, e.first_name || ' ' || e.last_name as employee_name, j.job_title, e.salary
FROM
    employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN jobs j ON e.job_id = j.job_id
WHERE (e.department_id, e.salary) IN (
        SELECT department_id, MAX(salary)
        FROM employees
        GROUP BY
            department_id
    )
ORDER BY d.department_name;

-- Q1 - (ii) Find departments where the difference between the highest-paid and lowest-paid employee is greater than $4000.
SELECT
    d.department_name,
    MAX(e.salary) as max_salary,
    MIN(e.salary) as min_salary,
    MAX(e.salary) - MIN(e.salary) as salary_difference
FROM employees e
    JOIN departments d ON e.department_id = d.department_id
GROUP BY
    d.department_name
HAVING
    MAX(e.salary) - MIN(e.salary) > 4000
ORDER BY salary_difference DESC;

-- Q1 - (iili) Identify the year and department that hired the most empoyees.
SELECT d.department_name, SUBSTR(e.hire_date, 8, 2) as year, COUNT(*) as number_of_hires
FROM employees e
    JOIN departments d ON e.department_id = d.department_id
GROUP BY
    d.department_name,
    SUBSTR(e.hire_date, 8, 2)
ORDER BY number_of_hires DESC
LIMIT 1;

-- Q1 - (iv) Find employees whose salary has not changed since they were hired.

-- The job_history table tracks employees who had job/salary changes
-- Employees not in that table have maintained their original position and salary since being hired
SELECT
    e.first_name || ' ' || e.last_name as employee_name,
    e.hire_date,
    e.salary as current_salary,
    d.department_name
FROM employees e
    JOIN departments d ON e.department_id = d.department_id
WHERE
    e.employee_id NOT IN (
        SELECT employee_id
        FROM job_history
    )
ORDER BY e.employee_id;

-- Q1 - (v) Find employees who earn more than their direct manager.
SELECT
    e.first_name || ' ' || e.last_name as employee_name,
    m.first_name || ' ' || m.last_name as manager_name,
    e.salary as employee_salary,
    m.salary as manager_salary
FROM employees e
    JOIN employees m ON e.manager_id = m.employee_id
WHERE
    e.salary > m.salary
ORDER BY e.salary DESC;

-- ========================================================================================================================
--                                                  QUESTION 1 COMPLETED
-- ========================================================================================================================

-- ========================================================================================================================
--                                                   QUESTION 2 ONWARDS
-- ========================================================================================================================

-- a. TRIGGER
-- Create trigger named stock_threshold_check that fires BEFORE UPDATE on Products table

SET SERVEROUTPUT ON;

CREATE OR REPLACE TRIGGER stock_threshold_check
BEFORE UPDATE ON products
FOR EACH ROW
DECLARE
    v_product_name VARCHAR2(100);
BEGIN
    SELECT product_name INTO v_product_name FROM products WHERE product_id = :NEW.product_id;
    
    IF :NEW.stock < 5 THEN
        INSERT INTO stock_alert (product_id, current_stock, alert_message)
        VALUES (:NEW.product_id, :NEW.stock, 
                'Warning: Stock quantity is below threshold');
        
        DBMS_OUTPUT.PUT_LINE('Warning: ' || v_product_name || ' stock is below threshold. Current stock: ' || :NEW.stock);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Stock updated for ' || v_product_name || '. Current stock: ' || :NEW.stock);
    END IF;
END;
/

-- Driver code to test the trigger
BEGIN
    UPDATE products SET stock = 3 WHERE product_id = 1;
    UPDATE products SET stock = 2 WHERE product_id = 2;
    UPDATE products SET stock = 4 WHERE product_id = 4;
    UPDATE products SET stock = 1 WHERE product_id = 5;
    UPDATE products SET stock = 15 WHERE product_id = 3;
END;
/

-- View the alerts generated
SELECT * FROM stock_alert;

-- b. TRANSACTIONS
BEGIN
    -- Step 1: Insert a new guest
    INSERT INTO guests (guest_id, name, email) 
    VALUES (guest_seq.NEXTVAL, 'alpha', 'alpha@codewithalpha.com');
    
    INSERT INTO reservations (reservation_id, guest_id, room_id, check_in, check_out, amount)
    VALUES (reservation_seq.NEXTVAL, 1, 101, TO_DATE('2025-12-10', 'YYYY-MM-DD'), TO_DATE('2025-12-12', 'YYYY-MM-DD'), 4000.00);

    INSERT INTO payments (payment_id, reservation_id, amount)
    VALUES (payment_seq.NEXTVAL, 1, 4000.00);

    INSERT INTO reservation_log (log_id, reservation_id, action)
    VALUES (log_seq.NEXTVAL, 1, 'Reservation created and payment processed');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Transaction failed: ' || SQLERRM);
END;
/

-- View the inserted records
SELECT * FROM guests;

SELECT * FROM rooms;

SELECT * FROM reservations;

SELECT * FROM payments;

SELECT * FROM reservation_log;

-- ========================================================================================================================
--                                                  QUESTION 2 COMPLETED
-- ========================================================================================================================

-- ========================================================================================================================
--                                                   QUESTION 3 ONWARDS
-- ========================================================================================================================

-- PL/SQL

-- 1. Stored Procedure: RecordSale
-- Takes two input parameters (p_product_id and p_sale_amount)
-- Checks if product exists, validates stock quantity, and records the sale

CREATE OR REPLACE PROCEDURE RecordSale (
    p_product_id IN NUMBER,
    p_sale_amount IN NUMBER
) AS
v_product_exists NUMBER;

v_stock_quantity NUMBER;

v_product_name VARCHAR2 (100);

BEGIN
    -- Check if the product exists in the Products table
    SELECT COUNT(*) INTO v_product_exists 
    FROM products 
    WHERE product_id = p_product_id;
    
    IF v_product_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Product not found.');
        RETURN;
    END IF;
    
    -- Get product details
    SELECT stock_quantity, product_name INTO v_stock_quantity, v_product_name
    FROM products
    WHERE product_id = p_product_id;
    
    -- Check if sale amount is greater than stock quantity
    IF p_sale_amount > v_stock_quantity THEN
        DBMS_OUTPUT.PUT_LINE('Insufficient stock for the sale.');
        RETURN;
    END IF;
    
    -- If sale is possible, update stock quantity and insert sale record
    UPDATE products 
    SET stock_quantity = stock_quantity - p_sale_amount
    WHERE product_id = p_product_id;
    
    INSERT INTO sales (sale_id, product_id, sale_date, sale_amount)
    VALUES (sales_seq.NEXTVAL, p_product_id, SYSDATE, p_sale_amount);
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Sale recorded successfully for ' || v_product_name || '. Remaining stock: ' || (v_stock_quantity - p_sale_amount));
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- 2. Stored Function: GetTotalSalesAmount
-- Takes product_id as input parameter and returns total sales amount for that product

CREATE OR REPLACE FUNCTION GetTotalSalesAmount (
    p_product_id IN NUMBER -- taking product_id as input parameter
) RETURN NUMBER AS
    v_total_sales NUMBER := 0;

BEGIN
    SELECT NVL(SUM(sale_amount), 0) INTO v_total_sales
    FROM sales
    WHERE product_id = p_product_id;
    
    RETURN v_total_sales;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RETURN 0;
END;
/

-- Driver code to test the procedure and function
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Testing RecordSale Procedure ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test 1: Valid sale
    DBMS_OUTPUT.PUT_LINE('Test 1: Recording sale of 2 units for product 1 (Laptop)');
    RecordSale(1, 2);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test 2: Insufficient stock
    DBMS_OUTPUT.PUT_LINE('Test 2: Attempting to sell 20 units for product 3 (Headphones) - Should fail');
    RecordSale(3, 20);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test 3: Product not found
    DBMS_OUTPUT.PUT_LINE('Test 3: Attempting to sell product with ID 999 - Should fail');
    RecordSale(999, 5);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test 4: Another valid sale
    DBMS_OUTPUT.PUT_LINE('Test 4: Recording sale of 3 units for product 2 (Smartphone)');
    RecordSale(2, 3);
    DBMS_OUTPUT.PUT_LINE('');
END;
/

-- Driver code to test GetTotalSalesAmount function
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Testing GetTotalSalesAmount Function =====');
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('Total sales for product 1 (Laptop): ' || GetTotalSalesAmount(1));
    DBMS_OUTPUT.PUT_LINE('Total sales for product 2 (Smartphone): ' || GetTotalSalesAmount(2));
    DBMS_OUTPUT.PUT_LINE('Total sales for product 3 (Headphones): ' || GetTotalSalesAmount(3));
    DBMS_OUTPUT.PUT_LINE('Total sales for product 4 (Tablet): ' || GetTotalSalesAmount(4));
END;
/

SELECT * FROM products;

SELECT * FROM sales;
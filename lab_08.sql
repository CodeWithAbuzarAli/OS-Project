SET SERVEROUTPUT ON;

-- Task 1: Compute and print bonus amount based on employee salary
-- Accepts employee number as user input
DECLARE
    v_employee_number employees.employee_id%TYPE := &emp_num;
    v_salary          employees.salary%TYPE;
    v_bonus           NUMBER(10,2);
BEGIN
    -- Retrieve employee salary
    SELECT salary
    INTO v_salary
    FROM employees
    WHERE employee_id = v_employee_number;
    
    -- Calculate bonus based on salary ranges
    IF v_salary IS NULL THEN
        v_bonus := 0;
    ELSIF v_salary < 1000 THEN
        v_bonus := v_salary * 0.10;  -- 10% bonus
    ELSIF v_salary BETWEEN 1000 AND 1500 THEN
        v_bonus := v_salary * 0.15;  -- 15% bonus
    ELSE
        v_bonus := v_salary * 0.20;  -- 20% bonus
    END IF;
    
    -- Print the results
    DBMS_OUTPUT.PUT_LINE('Employee Number: ' || v_employee_number);
    DBMS_OUTPUT.PUT_LINE('Current Salary: $' || TO_CHAR(v_salary, '999,999.99'));
    DBMS_OUTPUT.PUT_LINE('Bonus Amount: $' || TO_CHAR(v_bonus, '999,999.99'));
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Employee number ' || v_employee_number || ' not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Task 2: Check employee commission and update salary if commission is null
DECLARE
    v_emp_id employees.employee_id%TYPE := &employee_id;
    v_commission employees.commission_pct%TYPE;
    v_salary employees.salary%TYPE;
BEGIN
    -- Get employee's commission and salary
    SELECT commission_pct, salary
    INTO v_commission, v_salary
    FROM employees
    WHERE employee_id = v_emp_id;
    
    -- If commission is null, update salary (assuming adding a default commission of 0.10)
    IF v_commission IS NULL THEN
        UPDATE employees
        SET salary = salary + (salary * 0.10)
        WHERE employee_id = v_emp_id;
        
        DBMS_OUTPUT.PUT_LINE('Employee ' || v_emp_id || ' had null commission.');
        DBMS_OUTPUT.PUT_LINE('Salary updated from ' || v_salary || ' to ' || (v_salary + v_salary * 0.10));
        COMMIT;
    ELSE
        -- Commission exists, add it to salary
        UPDATE employees
        SET salary = salary + (salary * v_commission)
        WHERE employee_id = v_emp_id;
        
        DBMS_OUTPUT.PUT_LINE('Employee ' || v_emp_id || ' commission applied.');
        DBMS_OUTPUT.PUT_LINE('Salary updated from ' || v_salary || ' to ' || (v_salary + v_salary * v_commission));
        COMMIT;
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Employee ID ' || v_emp_id || ' not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Task 3: Obtain department name for employees in deptno 30
DECLARE
    v_dept_name departments.department_name%TYPE;
BEGIN
    SELECT d.department_name
    INTO v_dept_name
    FROM departments d
    INNER JOIN employees e ON d.department_id = e.department_id
    WHERE e.department_id = 30
    AND ROWNUM = 1;  -- Get first match
    
    DBMS_OUTPUT.PUT_LINE('Department name for deptno 30: ' || v_dept_name);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No employee found in department 30');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Task 4: Find the nature of job for employee in deptno 20
DECLARE
    v_deptno employees.department_id%TYPE := &dept_no;
    v_job_title jobs.job_title%TYPE;
BEGIN
    SELECT j.job_title
    INTO v_job_title
    FROM employees e
    INNER JOIN jobs j ON e.job_id = j.job_id
    WHERE e.department_id = v_deptno
    AND ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Job nature for employee in dept ' || v_deptno || ': ' || v_job_title);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No employee found in department ' || v_deptno);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Task 5: Find salary of employee in deptno 20
DECLARE
    v_deptno employees.department_id%TYPE := &dept_no;
    v_salary employees.salary%TYPE;
    v_emp_name employees.first_name%TYPE;
BEGIN
    SELECT first_name, salary
    INTO v_emp_name, v_salary
    FROM employees
    WHERE department_id = v_deptno
    AND ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Employee: ' || v_emp_name);
    DBMS_OUTPUT.PUT_LINE('Salary in dept ' || v_deptno || ': $' || v_salary);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No employee found in department ' || v_deptno);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Task 6: Update employee salary with 10% increase
CREATE OR REPLACE PROCEDURE update_salary_10_percent(p_empno IN NUMBER)
IS
    v_old_salary employees.salary%TYPE;

v_new_salary employees.salary % TYPE;

BEGIN
    -- Get current salary
    SELECT salary INTO v_old_salary
    FROM employees
    WHERE employee_id = p_empno;
    
    -- Update salary with 10% increase
    UPDATE employees
    SET salary = salary * 1.10
    WHERE employee_id = p_empno;
    
    -- Get new salary
    SELECT salary INTO v_new_salary
    FROM employees
    WHERE employee_id = p_empno;
    
    DBMS_OUTPUT.PUT_LINE('Employee ' || p_empno || ' salary updated');
    DBMS_OUTPUT.PUT_LINE('Old Salary: $' || v_old_salary);
    DBMS_OUTPUT.PUT_LINE('New Salary: $' || v_new_salary);
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Task 7: Add Rs.1000 to employees with salary > 5000 in specific department
CREATE OR REPLACE PROCEDURE add_1000_to_high_earners(p_deptno IN NUMBER)
IS
    v_count NUMBER := 0;
BEGIN
    UPDATE employees
    SET salary = salary + 1000
    WHERE department_id = p_deptno
    AND salary > 5000;
    
    v_count := SQL%ROWCOUNT;
    
    DBMS_OUTPUT.PUT_LINE('Updated ' || v_count || ' employees in department ' || p_deptno);
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Task 8a: View to display each designation and count of employees
CREATE OR REPLACE VIEW designation_count AS
SELECT j.job_title AS designation, COUNT(e.employee_id) AS employee_count
FROM jobs j
    LEFT JOIN employees e ON j.job_id = e.job_id
GROUP BY
    j.job_title;

-- Task 8b: View to display employee details except 'King'
CREATE OR REPLACE VIEW employees_except_king AS
SELECT
    e.employee_id AS empno,
    e.first_name || ' ' || e.last_name AS empname,
    e.department_id AS deptno,
    d.department_name AS deptname
FROM employees e
    INNER JOIN departments d ON e.department_id = d.department_id
WHERE
    UPPER(e.last_name) != 'KING';

-- Task 8c: View to display employee and department details
CREATE OR REPLACE VIEW employee_department_view AS
SELECT
    e.employee_id AS empno,
    e.first_name || ' ' || e.last_name AS empname,
    e.department_id AS deptno,
    d.department_name AS deptname
FROM employees e
    INNER JOIN departments d ON e.department_id = d.department_id;

-- Task 9: Add two numbers and display sum
DECLARE
    v_num1 NUMBER := &first_number;
    v_num2 NUMBER := &second_number;
    v_sum NUMBER;
BEGIN
    v_sum := v_num1 + v_num2;
    DBMS_OUTPUT.PUT_LINE('First Number: ' || v_num1);
    DBMS_OUTPUT.PUT_LINE('Second Number: ' || v_num2);
    DBMS_OUTPUT.PUT_LINE('Sum: ' || v_sum);
END;
/

-- Task 10: Sum of all numbers between two boundaries (inclusive)
DECLARE
    v_lower NUMBER := &lower_boundary;
    v_upper NUMBER := &upper_boundary;
    v_sum NUMBER := 0;
    v_counter NUMBER;
BEGIN
    v_counter := v_lower;
    
    WHILE v_counter <= v_upper LOOP
        v_sum := v_sum + v_counter;
        v_counter := v_counter + 1;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Sum of numbers from ' || v_lower || ' to ' || v_upper || ' = ' || v_sum);
END;
/

-- Task 11: Retrieve employee name, hiredate, and department name
DECLARE
    v_emp_id employees.employee_id%TYPE := &employee_id;
    v_emp_name VARCHAR2(100);
    v_hire_date employees.hire_date%TYPE;
    v_dept_name departments.department_name%TYPE;
BEGIN
    SELECT e.first_name || ' ' || e.last_name,
           e.hire_date,
           d.department_name
    INTO v_emp_name, v_hire_date, v_dept_name
    FROM employees e
    INNER JOIN departments d ON e.department_id = d.department_id
    WHERE e.employee_id = v_emp_id;
    
    DBMS_OUTPUT.PUT_LINE('Employee Name: ' || v_emp_name);
    DBMS_OUTPUT.PUT_LINE('Hire Date: ' || v_hire_date);
    DBMS_OUTPUT.PUT_LINE('Department: ' || v_dept_name);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Task 12: Check if a number is palindrome
DECLARE
    v_number NUMBER := &input_number;
    v_original NUMBER;
    v_reverse NUMBER := 0;
    v_temp NUMBER;
    v_digit NUMBER;
BEGIN
    v_original := v_number;
    v_temp := v_number;
    
    -- Reverse the number
    WHILE v_temp > 0 LOOP
        v_digit := MOD(v_temp, 10);
        v_reverse := (v_reverse * 10) + v_digit;
        v_temp := TRUNC(v_temp / 10);
    END LOOP;
    
    -- Check if palindrome
    IF v_original = v_reverse THEN
        DBMS_OUTPUT.PUT_LINE(v_original || ' is a palindrome');
    ELSE
        DBMS_OUTPUT.PUT_LINE(v_original || ' is not a palindrome');
    END IF;
END;
/

-- Task 13: Insert data into Employee and Department tables with user input
DECLARE
    v_emp_id employees.employee_id%TYPE := &emp_id;
    v_first_name employees.first_name%TYPE := '&first_name';
    v_last_name employees.last_name%TYPE := '&last_name';
    v_email employees.email%TYPE := '&email';
    v_phone employees.phone_number%TYPE := '&phone';
    v_hire_date employees.hire_date%TYPE := TO_DATE('&hire_date', 'YYYY-MM-DD');
    v_job_id employees.job_id%TYPE := '&job_id';
    v_salary employees.salary%TYPE := &salary;
    v_dept_id employees.department_id%TYPE := &dept_id;
BEGIN
    -- Insert into employees table
    INSERT INTO employees (
        employee_id, first_name, last_name, email, phone_number,
        hire_date, job_id, salary, department_id
    ) VALUES (
        v_emp_id, v_first_name, v_last_name, v_email, v_phone,
        v_hire_date, v_job_id, v_salary, v_dept_id
    );
    
    DBMS_OUTPUT.PUT_LINE('Employee ' || v_first_name || ' ' || v_last_name || ' inserted successfully');
    COMMIT;
    
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Error: Employee ID already exists');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Task 14: Find first employee with salary > $2500 higher in chain than employee 90
DECLARE
    v_emp_id employees.employee_id%TYPE;
    v_emp_name VARCHAR2(100);
    v_salary employees.salary%TYPE;
    v_manager_id employees.manager_id%TYPE := 90;
    v_found BOOLEAN := FALSE;
BEGIN
    LOOP
        -- Get manager's manager
        SELECT manager_id INTO v_manager_id
        FROM employees
        WHERE employee_id = v_manager_id;
        
        EXIT WHEN v_manager_id IS NULL;
        
        -- Check if this employee has salary > 2500
        SELECT employee_id, first_name || ' ' || last_name, salary
        INTO v_emp_id, v_emp_name, v_salary
        FROM employees
        WHERE employee_id = v_manager_id;
        
        IF v_salary > 2500 THEN
            v_found := TRUE;
            EXIT;
        END IF;
    END LOOP;
    
    IF v_found THEN
        DBMS_OUTPUT.PUT_LINE('Found Employee: ' || v_emp_name);
        DBMS_OUTPUT.PUT_LINE('Employee ID: ' || v_emp_id);
        DBMS_OUTPUT.PUT_LINE('Salary: $' || v_salary);
    ELSE
        DBMS_OUTPUT.PUT_LINE('No employee found matching criteria');
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No such employee in chain');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Task 15: Print sum of first 100 numbers
DECLARE
    v_sum NUMBER := 0;
    v_counter NUMBER := 1;
BEGIN
    FOR v_counter IN 1..100 LOOP
        v_sum := v_sum + v_counter;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Sum of first 100 numbers: ' || v_sum);
END;
/
# PL/SQL Study Guide - Complete Beginner's Reference

## Table of Contents
1. [What is PL/SQL?](#what-is-plsql)
2. [Basic Structure](#basic-structure)
3. [Variables and Data Types](#variables-and-data-types)
4. [Control Structures](#control-structures)
5. [Cursors](#cursors)
6. [Procedures](#procedures)
7. [Functions](#functions)
8. [Views](#views)
9. [Exception Handling](#exception-handling)
10. [Practice Tips](#practice-tips)

---

## What is PL/SQL?

**PL/SQL** stands for **Procedural Language/Structured Query Language**. It's Oracle's extension to SQL that adds programming capabilities like variables, loops, and conditional statements.

### Why Use PL/SQL?
- ✅ Write complex business logic in the database
- ✅ Better performance (executes in database, reduces network traffic)
- ✅ Reusable code through procedures and functions
- ✅ Better error handling with exceptions

---

## Basic Structure

Every PL/SQL program has three sections:

```sql
DECLARE
    -- Declaration section (OPTIONAL)
    -- Declare variables, cursors, constants here
    
BEGIN
    -- Execution section (REQUIRED)
    -- Write your logic here
    
EXCEPTION
    -- Exception handling section (OPTIONAL)
    -- Handle errors here
    
END;
/
```

### Simple Example:
```sql
SET SERVEROUTPUT ON;  -- Enable output display

DECLARE
    v_name VARCHAR2(50) := 'John';
    v_age NUMBER := 25;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Name: ' || v_name);
    DBMS_OUTPUT.PUT_LINE('Age: ' || v_age);
END;
/
```

**Output:**
```
Name: John
Age: 25
```

---

## Variables and Data Types

### Declaring Variables

**Syntax:**
```sql
variable_name datatype [NOT NULL] [:= initial_value];
```

### Common Data Types:
- **VARCHAR2(size)** - Variable-length string (max 4000 bytes)
- **NUMBER(precision, scale)** - Numeric values
- **DATE** - Date and time
- **BOOLEAN** - TRUE, FALSE, or NULL (only in PL/SQL)
- **CLOB** - Large text data
- **BLOB** - Binary data

### Examples:
```sql
DECLARE
    v_student_name VARCHAR2(100);              -- No initial value
    v_age NUMBER := 20;                         -- With initial value
    v_salary NUMBER(10,2) := 5000.50;          -- 10 digits, 2 decimals
    v_hire_date DATE := SYSDATE;               -- Current date
    v_is_active BOOLEAN := TRUE;               -- Boolean
BEGIN
    v_student_name := 'Alice';
    DBMS_OUTPUT.PUT_LINE('Student: ' || v_student_name);
END;
/
```

### %TYPE Attribute

Use `%TYPE` to inherit data type from a database column:

```sql
DECLARE
    v_emp_id employees.employee_id%TYPE;
    v_emp_name employees.first_name%TYPE;
BEGIN
    SELECT employee_id, first_name
    INTO v_emp_id, v_emp_name
    FROM employees
    WHERE employee_id = 100;
    
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_emp_id);
    DBMS_OUTPUT.PUT_LINE('Name: ' || v_emp_name);
END;
/
```

**Benefits:**
- If column type changes, your code automatically adapts
- Ensures compatibility

### %ROWTYPE Attribute

Use `%ROWTYPE` to declare a record with all columns from a table:

```sql
DECLARE
    emp_record employees%ROWTYPE;
BEGIN
    SELECT * INTO emp_record
    FROM employees
    WHERE employee_id = 100;
    
    DBMS_OUTPUT.PUT_LINE('Name: ' || emp_record.first_name);
    DBMS_OUTPUT.PUT_LINE('Salary: ' || emp_record.salary);
END;
/
```

---

## Control Structures

### 1. IF-THEN-ELSIF-ELSE

**Syntax:**
```sql
IF condition1 THEN
    -- statements
ELSIF condition2 THEN
    -- statements
ELSE
    -- statements
END IF;
```

**Example: Calculate Grade**
```sql
DECLARE
    v_marks NUMBER := 85;
    v_grade CHAR(1);
BEGIN
    IF v_marks >= 90 THEN
        v_grade := 'A';
    ELSIF v_marks >= 80 THEN
        v_grade := 'B';
    ELSIF v_marks >= 70 THEN
        v_grade := 'C';
    ELSE
        v_grade := 'F';
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Grade: ' || v_grade);
END;
/
```

### 2. CASE Statement

**Syntax:**
```sql
CASE selector
    WHEN value1 THEN statement1;
    WHEN value2 THEN statement2;
    ELSE default_statement;
END CASE;
```

**Example: Day of Week**
```sql
DECLARE
    v_day NUMBER := 3;
    v_day_name VARCHAR2(20);
BEGIN
    CASE v_day
        WHEN 1 THEN v_day_name := 'Monday';
        WHEN 2 THEN v_day_name := 'Tuesday';
        WHEN 3 THEN v_day_name := 'Wednesday';
        WHEN 4 THEN v_day_name := 'Thursday';
        WHEN 5 THEN v_day_name := 'Friday';
        ELSE v_day_name := 'Weekend';
    END CASE;
    
    DBMS_OUTPUT.PUT_LINE('Day: ' || v_day_name);
END;
/
```

### 3. LOOP Statements

#### Basic LOOP
```sql
DECLARE
    v_counter NUMBER := 1;
BEGIN
    LOOP
        DBMS_OUTPUT.PUT_LINE('Counter: ' || v_counter);
        v_counter := v_counter + 1;
        
        EXIT WHEN v_counter > 5;  -- Exit condition
    END LOOP;
END;
/
```

#### WHILE LOOP
```sql
DECLARE
    v_counter NUMBER := 1;
BEGIN
    WHILE v_counter <= 5 LOOP
        DBMS_OUTPUT.PUT_LINE('Counter: ' || v_counter);
        v_counter := v_counter + 1;
    END LOOP;
END;
/
```

#### FOR LOOP
```sql
BEGIN
    FOR i IN 1..5 LOOP
        DBMS_OUTPUT.PUT_LINE('Number: ' || i);
    END LOOP;
END;
/
```

**Reverse FOR LOOP:**
```sql
BEGIN
    FOR i IN REVERSE 1..5 LOOP
        DBMS_OUTPUT.PUT_LINE('Number: ' || i);
    END LOOP;
END;
/
-- Output: 5, 4, 3, 2, 1
```

---

## Cursors

**Cursor** = A pointer to a result set of a query. It allows you to process rows one by one.

### Types of Cursors:

### 1. Implicit Cursors
Automatically created by Oracle for single-row queries.

```sql
DECLARE
    v_emp_name employees.first_name%TYPE;
BEGIN
    SELECT first_name INTO v_emp_name
    FROM employees
    WHERE employee_id = 100;
    
    DBMS_OUTPUT.PUT_LINE('Employee: ' || v_emp_name);
END;
/
```

### 2. Explicit Cursors
Manually declared for multi-row queries.

**Steps:**
1. **DECLARE** the cursor
2. **OPEN** the cursor
3. **FETCH** rows from cursor
4. **CLOSE** the cursor

**Syntax:**
```sql
DECLARE
    CURSOR cursor_name IS
        SELECT statement;
    
    variable declarations;
BEGIN
    OPEN cursor_name;
    
    LOOP
        FETCH cursor_name INTO variables;
        EXIT WHEN cursor_name%NOTFOUND;
        
        -- Process each row
    END LOOP;
    
    CLOSE cursor_name;
END;
/
```

**Example: Display All Employees**
```sql
DECLARE
    CURSOR emp_cursor IS
        SELECT employee_id, first_name, salary
        FROM employees
        ORDER BY salary DESC;
    
    v_emp_id employees.employee_id%TYPE;
    v_name employees.first_name%TYPE;
    v_salary employees.salary%TYPE;
BEGIN
    OPEN emp_cursor;
    
    LOOP
        FETCH emp_cursor INTO v_emp_id, v_name, v_salary;
        EXIT WHEN emp_cursor%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_emp_id || 
                           ', Name: ' || v_name || 
                           ', Salary: $' || v_salary);
    END LOOP;
    
    CLOSE emp_cursor;
END;
/
```

### Cursor with %ROWTYPE
```sql
DECLARE
    CURSOR emp_cursor IS
        SELECT * FROM employees;
    
    emp_record emp_cursor%ROWTYPE;
BEGIN
    OPEN emp_cursor;
    
    LOOP
        FETCH emp_cursor INTO emp_record;
        EXIT WHEN emp_cursor%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Employee: ' || emp_record.first_name);
    END LOOP;
    
    CLOSE emp_cursor;
END;
/
```

### Cursor FOR LOOP (Simplified)
```sql
BEGIN
    FOR emp_record IN (SELECT employee_id, first_name, salary 
                       FROM employees) LOOP
        DBMS_OUTPUT.PUT_LINE('Name: ' || emp_record.first_name || 
                           ', Salary: $' || emp_record.salary);
    END LOOP;
END;
/
```

**Benefits of FOR LOOP:**
- No need to OPEN, FETCH, or CLOSE
- Automatic variable declaration

### Cursor Attributes
- **%FOUND** - TRUE if last FETCH returned a row
- **%NOTFOUND** - TRUE if last FETCH did not return a row
- **%ROWCOUNT** - Number of rows fetched so far
- **%ISOPEN** - TRUE if cursor is open

```sql
DECLARE
    CURSOR emp_cursor IS SELECT * FROM employees;
    emp_rec emp_cursor%ROWTYPE;
BEGIN
    OPEN emp_cursor;
    
    LOOP
        FETCH emp_cursor INTO emp_rec;
        EXIT WHEN emp_cursor%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Row ' || emp_cursor%ROWCOUNT || 
                           ': ' || emp_rec.first_name);
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Total rows: ' || emp_cursor%ROWCOUNT);
    CLOSE emp_cursor;
END;
/
```

---

## Procedures

A **stored procedure** is a reusable PL/SQL block stored in the database.

### Creating a Procedure

**Syntax:**
```sql
CREATE OR REPLACE PROCEDURE procedure_name
    (parameter1 [IN|OUT|IN OUT] datatype,
     parameter2 [IN|OUT|IN OUT] datatype)
IS
    -- Variable declarations
BEGIN
    -- Logic
EXCEPTION
    -- Exception handling
END;
/
```

### Parameter Modes:
- **IN** (default) - Pass value to procedure (read-only)
- **OUT** - Return value from procedure
- **IN OUT** - Pass and return value

### Example 1: Simple Procedure
```sql
CREATE OR REPLACE PROCEDURE greet_user(p_name IN VARCHAR2)
IS
BEGIN
    DBMS_OUTPUT.PUT_LINE('Hello, ' || p_name || '!');
END;
/

-- Call the procedure
BEGIN
    greet_user('Alice');
END;
/
```

### Example 2: Procedure with OUT Parameter
```sql
CREATE OR REPLACE PROCEDURE get_employee_salary
    (p_emp_id IN NUMBER,
     p_salary OUT NUMBER,
     p_name OUT VARCHAR2)
IS
BEGIN
    SELECT salary, first_name
    INTO p_salary, p_name
    FROM employees
    WHERE employee_id = p_emp_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found');
END;
/

-- Call the procedure
DECLARE
    v_salary NUMBER;
    v_name VARCHAR2(50);
BEGIN
    get_employee_salary(100, v_salary, v_name);
    DBMS_OUTPUT.PUT_LINE('Employee: ' || v_name);
    DBMS_OUTPUT.PUT_LINE('Salary: $' || v_salary);
END;
/
```

### Example 3: Update Employee Salary
```sql
CREATE OR REPLACE PROCEDURE update_salary
    (p_emp_id IN NUMBER,
     p_increase_pct IN NUMBER)
IS
    v_old_salary employees.salary%TYPE;
    v_new_salary employees.salary%TYPE;
BEGIN
    -- Get old salary
    SELECT salary INTO v_old_salary
    FROM employees
    WHERE employee_id = p_emp_id;
    
    -- Update salary
    UPDATE employees
    SET salary = salary * (1 + p_increase_pct/100)
    WHERE employee_id = p_emp_id;
    
    -- Get new salary
    SELECT salary INTO v_new_salary
    FROM employees
    WHERE employee_id = p_emp_id;
    
    DBMS_OUTPUT.PUT_LINE('Old Salary: $' || v_old_salary);
    DBMS_OUTPUT.PUT_LINE('New Salary: $' || v_new_salary);
    
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- Execute
EXECUTE update_salary(100, 10);  -- 10% increase
```

---

## Functions

A **function** is similar to a procedure but MUST return a value.

### Creating a Function

**Syntax:**
```sql
CREATE OR REPLACE FUNCTION function_name
    (parameter1 datatype, parameter2 datatype)
RETURN return_datatype
IS
    -- Variable declarations
BEGIN
    -- Logic
    RETURN value;
EXCEPTION
    -- Exception handling
END;
/
```

### Example 1: Calculate Annual Salary
```sql
CREATE OR REPLACE FUNCTION calculate_annual_salary
    (p_emp_id IN NUMBER)
RETURN NUMBER
IS
    v_monthly_salary NUMBER;
    v_annual_salary NUMBER;
BEGIN
    SELECT salary INTO v_monthly_salary
    FROM employees
    WHERE employee_id = p_emp_id;
    
    v_annual_salary := v_monthly_salary * 12;
    
    RETURN v_annual_salary;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/

-- Use in SELECT
SELECT employee_id, first_name, 
       calculate_annual_salary(employee_id) AS annual_salary
FROM employees
WHERE employee_id = 100;

-- Use in PL/SQL
BEGIN
    DBMS_OUTPUT.PUT_LINE('Annual Salary: $' || 
                        calculate_annual_salary(100));
END;
/
```

### Example 2: Get Employee Count by Department
```sql
CREATE OR REPLACE FUNCTION get_dept_employee_count
    (p_dept_id IN NUMBER)
RETURN NUMBER
IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM employees
    WHERE department_id = p_dept_id;
    
    RETURN v_count;
END;
/

-- Use the function
BEGIN
    DBMS_OUTPUT.PUT_LINE('Employees in Dept 50: ' || 
                        get_dept_employee_count(50));
END;
/
```

### Difference Between Procedure and Function

| Feature         | Procedure           | Function                     |
| --------------- | ------------------- | ---------------------------- |
| Returns value   | Optional (via OUT)  | Required (RETURN)            |
| Called from SQL | ❌ No                | ✅ Yes (SELECT statements)    |
| Main purpose    | Perform action      | Calculate and return value   |
| Syntax          | `EXECUTE proc_name` | `SELECT func_name FROM dual` |

---

## Views

A **view** is a virtual table based on a SELECT query. It doesn't store data but shows data from base tables.

### Types of Views:

### 1. Simple View
Based on a single table, allows DML operations.

```sql
CREATE OR REPLACE VIEW employee_basic_view AS
SELECT employee_id, first_name, last_name, email, salary
FROM employees
WHERE department_id = 50;

-- Query the view
SELECT * FROM employee_basic_view;

-- Update through view
UPDATE employee_basic_view
SET salary = salary * 1.05
WHERE employee_id = 100;
```

### 2. Complex View
Based on multiple tables (joins), may not allow DML.

```sql
CREATE OR REPLACE VIEW employee_dept_view AS
SELECT e.employee_id,
       e.first_name,
       e.last_name,
       e.salary,
       d.department_name,
       d.location_id
FROM employees e
JOIN departments d ON e.department_id = d.department_id;

-- Query the view
SELECT * FROM employee_dept_view
WHERE department_name = 'IT';
```

### 3. Materialized View
Stores query results physically (like a table), faster but needs refresh.

```sql
CREATE MATERIALIZED VIEW emp_salary_summary AS
SELECT department_id,
       COUNT(*) AS employee_count,
       AVG(salary) AS avg_salary,
       MAX(salary) AS max_salary
FROM employees
GROUP BY department_id;

-- Query materialized view
SELECT * FROM emp_salary_summary;

-- Refresh materialized view
EXEC DBMS_MVIEW.REFRESH('emp_salary_summary');
```

### Benefits of Views:
- ✅ **Security**: Hide sensitive columns
- ✅ **Simplicity**: Simplify complex queries
- ✅ **Consistency**: Ensure users see the same data structure

---

## Exception Handling

**Exception** = Error that occurs during program execution.

### Basic Syntax:
```sql
BEGIN
    -- Normal execution
EXCEPTION
    WHEN exception_name1 THEN
        -- Handle exception1
    WHEN exception_name2 THEN
        -- Handle exception2
    WHEN OTHERS THEN
        -- Handle all other exceptions
END;
/
```

### Common Predefined Exceptions:

| Exception            | Occurs When                       |
| -------------------- | --------------------------------- |
| **NO_DATA_FOUND**    | SELECT INTO returns no rows       |
| **TOO_MANY_ROWS**    | SELECT INTO returns multiple rows |
| **DUP_VAL_ON_INDEX** | Duplicate value in unique column  |
| **ZERO_DIVIDE**      | Division by zero                  |
| **INVALID_NUMBER**   | Conversion to number fails        |
| **VALUE_ERROR**      | Arithmetic/conversion error       |

### Example 1: Handle NO_DATA_FOUND
```sql
DECLARE
    v_emp_name employees.first_name%TYPE;
BEGIN
    SELECT first_name INTO v_emp_name
    FROM employees
    WHERE employee_id = 9999;  -- Doesn't exist
    
    DBMS_OUTPUT.PUT_LINE('Employee: ' || v_emp_name);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found!');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
```

### Example 2: Handle Multiple Exceptions
```sql
DECLARE
    v_salary NUMBER;
    v_result NUMBER;
BEGIN
    SELECT salary INTO v_salary
    FROM employees
    WHERE employee_id = 100;
    
    v_result := v_salary / 0;  -- Causes ZERO_DIVIDE
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Employee not found');
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('Cannot divide by zero');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
```

### User-Defined Exceptions
```sql
DECLARE
    v_salary employees.salary%TYPE;
    salary_too_high EXCEPTION;
BEGIN
    SELECT salary INTO v_salary
    FROM employees
    WHERE employee_id = 100;
    
    IF v_salary > 50000 THEN
        RAISE salary_too_high;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Salary is acceptable: $' || v_salary);
    
EXCEPTION
    WHEN salary_too_high THEN
        DBMS_OUTPUT.PUT_LINE('Salary exceeds limit!');
END;
/
```

### RAISE_APPLICATION_ERROR
Custom error messages with error codes (-20000 to -20999):

```sql
CREATE OR REPLACE PROCEDURE insert_employee
    (p_emp_id NUMBER, p_salary NUMBER)
IS
BEGIN
    IF p_salary < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Salary cannot be negative');
    END IF;
    
    IF p_salary > 100000 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Salary exceeds maximum limit');
    END IF;
    
    INSERT INTO employees (employee_id, salary)
    VALUES (p_emp_id, p_salary);
    
    COMMIT;
END;
/
```

---

## Practice Tips

### 1. Start with Simple Examples
```sql
-- Hello World in PL/SQL
BEGIN
    DBMS_OUTPUT.PUT_LINE('Hello, World!');
END;
/
```

### 2. Use DBMS_OUTPUT for Debugging
```sql
DECLARE
    v_counter NUMBER := 0;
BEGIN
    FOR i IN 1..5 LOOP
        v_counter := v_counter + i;
        DBMS_OUTPUT.PUT_LINE('Iteration ' || i || ', Sum: ' || v_counter);
    END LOOP;
END;
/
```

### 3. Common Mistakes to Avoid
- ❌ Forgetting the `/` after END
- ❌ Not using `SET SERVEROUTPUT ON`
- ❌ Using `=` instead of `:=` for assignment
- ❌ Forgetting semicolons (`;`)
- ❌ Not handling exceptions

### 4. SQL*Plus Substitution Variables
```sql
-- Accept user input
DECLARE
    v_emp_id NUMBER := &employee_id;
BEGIN
    -- Use v_emp_id
END;
/
```

When you run this, Oracle asks: `Enter value for employee_id:`

### 5. SQL Functions in PL/SQL
You can use SQL functions in PL/SQL:

```sql
DECLARE
    v_today DATE := SYSDATE;
    v_name VARCHAR2(50) := 'john doe';
BEGIN
    DBMS_OUTPUT.PUT_LINE('Today: ' || TO_CHAR(v_today, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('Name: ' || INITCAP(v_name));  -- John Doe
    DBMS_OUTPUT.PUT_LINE('Length: ' || LENGTH(v_name));
END;
/
```

---

## Quick Reference Cheat Sheet

### Variable Declaration
```sql
variable_name datatype := value;
```

### Output
```sql
DBMS_OUTPUT.PUT_LINE('text' || variable);
```

### IF Statement
```sql
IF condition THEN
    statements;
END IF;
```

### Loop
```sql
FOR i IN 1..10 LOOP
    statements;
END LOOP;
```

### Cursor
```sql
FOR rec IN (SELECT * FROM table) LOOP
    -- process rec.column_name
END LOOP;
```

### Exception
```sql
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        statements;
END;
```

---

## Summary

**Key Concepts to Remember:**

1. **PL/SQL Block Structure**: DECLARE, BEGIN, EXCEPTION, END
2. **Variables**: Use %TYPE and %ROWTYPE for flexibility
3. **Control Structures**: IF, CASE, LOOP, WHILE, FOR
4. **Cursors**: Process multiple rows one by one
5. **Procedures**: Reusable code blocks (may not return value)
6. **Functions**: MUST return a value
7. **Views**: Virtual tables for simplified querying
8. **Exception Handling**: Handle errors gracefully

**For Your Exam:**
- Practice writing basic blocks with all sections
- Understand cursor operations (OPEN, FETCH, CLOSE)
- Know the difference between procedures and functions
- Memorize common exceptions
- Practice with employee/department schema examples

---
Remember: Practice makes perfect. Try writing each example yourself!

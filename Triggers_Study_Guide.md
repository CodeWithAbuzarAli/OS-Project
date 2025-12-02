# Database Triggers Study Guide - Complete Beginner's Reference

## Table of Contents
1. [What are Triggers?](#what-are-triggers)
2. [Why Use Triggers?](#why-use-triggers)
3. [Trigger Syntax](#trigger-syntax)
4. [DML Triggers](#dml-triggers)
5. [DDL Triggers](#ddl-triggers)
6. [System/Database Triggers](#systemdatabase-triggers)
7. [Instead Of Triggers](#instead-of-triggers)
8. [Trigger Execution Order](#trigger-execution-order)
9. [Best Practices](#best-practices)
10. [Common Use Cases](#common-use-cases)

---

## What are Triggers?

A **trigger** is a stored PL/SQL block that automatically executes (fires) when a specific event occurs in the database.

### Key Characteristics:
- ✅ Executes **automatically** (you don't call them manually)
- ✅ Associated with a specific **table, view, or database event**
- ✅ Can execute **before** or **after** an event
- ✅ Can be **row-level** (for each affected row) or **statement-level** (once per statement)

### Analogy:
Think of a trigger like an **alarm clock**:
- You set it once (create trigger)
- It automatically rings (fires) when the time comes (event occurs)
- You don't need to manually activate it

---

## Why Use Triggers?

### Common Use Cases:

1. **Auditing** - Track who changed what and when
   ```
   Example: Log all deletions from employees table
   ```

2. **Data Validation** - Enforce complex business rules
   ```
   Example: Prevent salary from exceeding $100,000
   ```

3. **Automatic Updates** - Update related data automatically
   ```
   Example: Update last_modified timestamp on every change
   ```

4. **Referential Integrity** - Maintain data consistency
   ```
   Example: Prevent deletion of department with employees
   ```

5. **Derived Values** - Calculate and store computed values
   ```
   Example: Update total_amount when order items change
   ```

---

## Trigger Syntax

### Basic Structure:
```sql
CREATE OR REPLACE TRIGGER trigger_name
{BEFORE | AFTER | INSTEAD OF}
{INSERT | UPDATE | DELETE}
ON table_name
[FOR EACH ROW]
[WHEN (condition)]
DECLARE
    -- Variables (optional)
BEGIN
    -- Trigger logic
EXCEPTION
    -- Exception handling (optional)
END;
/
```

### Components Explained:

| Component                | Description                                       |
| ------------------------ | ------------------------------------------------- |
| **BEFORE/AFTER**         | When trigger fires (before or after the event)    |
| **INSTEAD OF**           | Replace the event with trigger logic (views only) |
| **INSERT/UPDATE/DELETE** | Which DML operation triggers it                   |
| **FOR EACH ROW**         | Row-level trigger (fires for each affected row)   |
| **:NEW**                 | New values (for INSERT/UPDATE)                    |
| **:OLD**                 | Old values (for UPDATE/DELETE)                    |

---

## DML Triggers

**DML Triggers** fire when data is modified (INSERT, UPDATE, DELETE).

### Types:

### 1. BEFORE Triggers
Execute **before** the DML operation.

**Use Cases:**
- Validate data before insertion
- Modify values before saving
- Prevent invalid operations

**Example 1: Validate Salary Before Insert**
```sql
CREATE OR REPLACE TRIGGER trg_validate_salary
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
BEGIN
    -- Ensure salary is not negative
    IF :NEW.salary < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Salary cannot be negative');
    END IF;
    
    -- Ensure salary is not too high
    IF :NEW.salary > 100000 THEN
        RAISE_APPLICATION_ERROR(-20002, 
            'Salary exceeds maximum limit of $100,000');
    END IF;
END;
/

-- Test the trigger
INSERT INTO employees (employee_id, first_name, salary)
VALUES (9999, 'John', -5000);  -- ERROR: Salary cannot be negative
```

**Example 2: Auto-uppercase Email**
```sql
CREATE OR REPLACE TRIGGER trg_uppercase_email
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
BEGIN
    :NEW.email := UPPER(:NEW.email);
END;
/

-- Test
INSERT INTO employees (employee_id, email)
VALUES (9999, 'john@example.com');

-- Result: Email saved as 'JOHN@EXAMPLE.COM'
```

### 2. AFTER Triggers
Execute **after** the DML operation.

**Use Cases:**
- Audit/log changes
- Update summary tables
- Send notifications

**Example 1: Audit Employee Changes**
```sql
-- Create audit table
CREATE TABLE employee_audit (
    audit_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id NUMBER,
    operation VARCHAR2(10),
    old_salary NUMBER,
    new_salary NUMBER,
    changed_by VARCHAR2(50),
    changed_date TIMESTAMP
);

-- Create audit trigger
CREATE OR REPLACE TRIGGER trg_audit_employee
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
BEGIN
    -- Determine operation type
    IF INSERTING THEN
        v_operation := 'INSERT';
        INSERT INTO employee_audit 
        VALUES (DEFAULT, :NEW.employee_id, v_operation, NULL, 
                :NEW.salary, USER, SYSTIMESTAMP);
                
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        INSERT INTO employee_audit 
        VALUES (DEFAULT, :NEW.employee_id, v_operation, :OLD.salary, 
                :NEW.salary, USER, SYSTIMESTAMP);
                
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        INSERT INTO employee_audit 
        VALUES (DEFAULT, :OLD.employee_id, v_operation, :OLD.salary, 
                NULL, USER, SYSTIMESTAMP);
    END IF;
END;
/

-- Test
UPDATE employees SET salary = 10000 WHERE employee_id = 100;
DELETE FROM employees WHERE employee_id = 200;

-- Check audit log
SELECT * FROM employee_audit;
```

**Example 2: Auto-update Last Modified Timestamp**
```sql
-- Add column
ALTER TABLE employees ADD last_modified TIMESTAMP;

-- Create trigger
CREATE OR REPLACE TRIGGER trg_update_timestamp
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    :NEW.last_modified := SYSTIMESTAMP;
END;
/

-- Test
UPDATE employees SET salary = salary * 1.1 WHERE employee_id = 100;

-- Check timestamp
SELECT employee_id, last_modified FROM employees WHERE employee_id = 100;
```

### 3. Row-Level vs Statement-Level

**Row-Level Trigger** - Fires for EACH affected row
```sql
CREATE OR REPLACE TRIGGER trg_row_level
AFTER UPDATE ON employees
FOR EACH ROW  -- Fires for each updated row
BEGIN
    DBMS_OUTPUT.PUT_LINE('Updated employee: ' || :NEW.employee_id);
END;
/

-- Update 3 employees → Trigger fires 3 times
UPDATE employees SET salary = salary * 1.1 WHERE department_id = 50;
```

**Statement-Level Trigger** - Fires ONCE per statement
```sql
CREATE OR REPLACE TRIGGER trg_statement_level
AFTER UPDATE ON employees
-- No FOR EACH ROW → Statement-level
BEGIN
    DBMS_OUTPUT.PUT_LINE('Employee table was updated');
END;
/

-- Update 3 employees → Trigger fires ONCE
UPDATE employees SET salary = salary * 1.1 WHERE department_id = 50;
```

### 4. Using :NEW and :OLD

| Operation  | :NEW                     | :OLD                     |
| ---------- | ------------------------ | ------------------------ |
| **INSERT** | ✅ Available (new values) | ❌ NULL                   |
| **UPDATE** | ✅ Available (new values) | ✅ Available (old values) |
| **DELETE** | ❌ NULL                   | ✅ Available (old values) |

**Example: Track Salary Changes**
```sql
CREATE OR REPLACE TRIGGER trg_track_salary
AFTER UPDATE OF salary ON employees
FOR EACH ROW
BEGIN
    IF :NEW.salary != :OLD.salary THEN
        DBMS_OUTPUT.PUT_LINE('Employee ' || :NEW.employee_id);
        DBMS_OUTPUT.PUT_LINE('Old Salary: $' || :OLD.salary);
        DBMS_OUTPUT.PUT_LINE('New Salary: $' || :NEW.salary);
        DBMS_OUTPUT.PUT_LINE('Change: $' || (:NEW.salary - :OLD.salary));
    END IF;
END;
/
```

### 5. Conditional Triggers (WHEN Clause)

```sql
CREATE OR REPLACE TRIGGER trg_high_salary_alert
AFTER UPDATE OF salary ON employees
FOR EACH ROW
WHEN (NEW.salary > 50000)  -- Only fire if salary > 50000
BEGIN
    DBMS_OUTPUT.PUT_LINE('High salary alert for employee ' || :NEW.employee_id);
END;
/
```

**Note:** Use `NEW` and `OLD` (without colon) in WHEN clause.

---

## DDL Triggers

**DDL Triggers** fire when database objects are created, altered, or dropped.

### Syntax:
```sql
CREATE OR REPLACE TRIGGER trigger_name
{BEFORE | AFTER} {DDL_EVENT}
ON {SCHEMA | DATABASE}
BEGIN
    -- Trigger logic
END;
/
```

### DDL Events:
- **CREATE** - Object created
- **ALTER** - Object modified
- **DROP** - Object deleted
- **RENAME** - Object renamed
- **TRUNCATE** - Table truncated

### Example 1: Log All Schema Changes
```sql
-- Create audit table
CREATE TABLE ddl_audit_log (
    audit_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_type VARCHAR2(50),
    object_type VARCHAR2(50),
    object_name VARCHAR2(100),
    event_date TIMESTAMP,
    username VARCHAR2(50)
);

-- Create DDL trigger
CREATE OR REPLACE TRIGGER trg_ddl_audit
AFTER DDL ON SCHEMA
BEGIN
    INSERT INTO ddl_audit_log 
    VALUES (DEFAULT,
            ORA_SYSEVENT,        -- CREATE, DROP, ALTER, etc.
            ORA_DICT_OBJ_TYPE,   -- TABLE, VIEW, PROCEDURE, etc.
            ORA_DICT_OBJ_NAME,   -- Name of object
            SYSTIMESTAMP,
            USER);
END;
/

-- Test: Create a table
CREATE TABLE test_table (id NUMBER);

-- Check audit log
SELECT * FROM ddl_audit_log;
```

**Output:**
```
| EVENT_TYPE | OBJECT_TYPE | OBJECT_NAME | USERNAME |
| ---------- | ----------- | ----------- | -------- |
| CREATE     | TABLE       | TEST_TABLE  | HR       |
```

### Example 2: Prevent Dropping Critical Tables
```sql
CREATE OR REPLACE TRIGGER trg_protect_tables
BEFORE DROP ON SCHEMA
BEGIN
    -- Prevent dropping specific tables
    IF ORA_DICT_OBJ_NAME IN ('EMPLOYEES', 'DEPARTMENTS', 'CUSTOMERS') THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Cannot drop ' || ORA_DICT_OBJ_NAME || ' - table is protected');
    END IF;
END;
/

-- Test
DROP TABLE employees;  -- ERROR: Cannot drop EMPLOYEES - table is protected
```

### Example 3: Prevent Tables with Specific Naming Pattern
```sql
CREATE OR REPLACE TRIGGER trg_prevent_temp_tables
BEFORE CREATE ON SCHEMA
BEGIN
    IF ORA_DICT_OBJ_TYPE = 'TABLE' AND 
       ORA_DICT_OBJ_NAME LIKE 'TEMP_%' THEN
        RAISE_APPLICATION_ERROR(-20004,
            'Cannot create tables with TEMP_ prefix');
    END IF;
END;
/

-- Test
CREATE TABLE temp_data (id NUMBER);  -- ERROR: Cannot create tables with TEMP_ prefix
```

### Common DDL Trigger Functions:

| Function               | Returns                          |
| ---------------------- | -------------------------------- |
| **ORA_SYSEVENT**       | Event type (CREATE, DROP, ALTER) |
| **ORA_DICT_OBJ_TYPE**  | Object type (TABLE, VIEW, INDEX) |
| **ORA_DICT_OBJ_NAME**  | Object name                      |
| **ORA_DICT_OBJ_OWNER** | Object owner                     |
| **ORA_LOGIN_USER**     | Current user                     |
| **ORA_SQL_TXT**        | SQL statement text               |

---

## System/Database Triggers

**System Triggers** fire on database-level events like STARTUP, SHUTDOWN, LOGON, LOGOFF.

### Types:

### 1. LOGON Trigger
Fires when a user logs in.

**Example 1: Track User Logins**
```sql
-- Create login log table
CREATE TABLE user_login_log (
    log_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR2(50),
    login_time TIMESTAMP,
    ip_address VARCHAR2(50),
    session_id NUMBER
);

-- Create LOGON trigger
CREATE OR REPLACE TRIGGER trg_track_login
AFTER LOGON ON SCHEMA
BEGIN
    INSERT INTO user_login_log 
    VALUES (DEFAULT,
            USER,
            SYSTIMESTAMP,
            SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
            SYS_CONTEXT('USERENV', 'SESSIONID'));
    COMMIT;
END;
/

-- After login, check logs
SELECT * FROM user_login_log;
```

**Example 2: Set Session Properties on Login**
```sql
CREATE OR REPLACE TRIGGER trg_set_session
AFTER LOGON ON SCHEMA
BEGIN
    -- Set time zone
    EXECUTE IMMEDIATE 'ALTER SESSION SET TIME_ZONE = ''America/New_York''';
    
    -- Set date format
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD-MON-YYYY''';
    
    -- Set decimal separator
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ''.,''';
END;
/
```

**Example 3: Restrict Login Hours**
```sql
CREATE OR REPLACE TRIGGER trg_business_hours_only
AFTER LOGON ON SCHEMA
DECLARE
    v_hour NUMBER;
BEGIN
    v_hour := TO_NUMBER(TO_CHAR(SYSDATE, 'HH24'));
    
    -- Allow login only between 8 AM and 6 PM
    IF v_hour < 8 OR v_hour >= 18 THEN
        RAISE_APPLICATION_ERROR(-20005,
            'Login allowed only during business hours (8 AM - 6 PM)');
    END IF;
END;
/
```

### 2. LOGOFF Trigger
Fires when a user logs off.

**Example: Track Session Duration**
```sql
CREATE TABLE session_log (
    session_id NUMBER,
    username VARCHAR2(50),
    login_time TIMESTAMP,
    logoff_time TIMESTAMP,
    duration_minutes NUMBER
);

-- LOGON trigger
CREATE OR REPLACE TRIGGER trg_session_start
AFTER LOGON ON SCHEMA
BEGIN
    INSERT INTO session_log (session_id, username, login_time)
    VALUES (SYS_CONTEXT('USERENV', 'SESSIONID'), USER, SYSTIMESTAMP);
    COMMIT;
END;
/

-- LOGOFF trigger
CREATE OR REPLACE TRIGGER trg_session_end
BEFORE LOGOFF ON SCHEMA
DECLARE
    v_session_id NUMBER;
BEGIN
    v_session_id := SYS_CONTEXT('USERENV', 'SESSIONID');
    
    UPDATE session_log
    SET logoff_time = SYSTIMESTAMP,
        duration_minutes = ROUND((SYSTIMESTAMP - login_time) * 24 * 60, 2)
    WHERE session_id = v_session_id
    AND logoff_time IS NULL;
    
    COMMIT;
END;
/
```

### 3. STARTUP Trigger
Fires when database starts (requires DBA privileges).

```sql
CREATE TABLE startup_log (
    startup_time TIMESTAMP,
    server_host VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER trg_db_startup
AFTER STARTUP ON DATABASE
BEGIN
    INSERT INTO startup_log 
    VALUES (SYSTIMESTAMP, 
            SYS_CONTEXT('USERENV', 'SERVER_HOST'));
END;
/
```

### 4. SHUTDOWN Trigger
Fires when database shuts down (requires DBA privileges).

```sql
CREATE TABLE shutdown_log (
    shutdown_time TIMESTAMP,
    server_host VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER trg_db_shutdown
BEFORE SHUTDOWN ON DATABASE
BEGIN
    INSERT INTO shutdown_log 
    VALUES (SYSTIMESTAMP,
            SYS_CONTEXT('USERENV', 'SERVER_HOST'));
END;
/
```

### System Context Functions:

```sql
-- Get various session information
SELECT SYS_CONTEXT('USERENV', 'SESSION_USER') FROM dual;  -- Username
SELECT SYS_CONTEXT('USERENV', 'IP_ADDRESS') FROM dual;    -- IP address
SELECT SYS_CONTEXT('USERENV', 'HOST') FROM dual;          -- Client host
SELECT SYS_CONTEXT('USERENV', 'OS_USER') FROM dual;       -- OS username
SELECT SYS_CONTEXT('USERENV', 'SESSIONID') FROM dual;     -- Session ID
```

---

## Instead Of Triggers

**Instead Of Triggers** are defined on views (not tables) and replace the default DML operation.

### Why Use Instead Of Triggers?

Views created from multiple tables (complex views) are usually **not updatable**.

**Example Problem:**
```sql
-- Complex view with JOIN
CREATE VIEW emp_dept_view AS
SELECT e.employee_id, e.first_name, d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id;

-- This will FAIL
INSERT INTO emp_dept_view VALUES (9999, 'John', 'IT');
-- ERROR: Cannot modify a column which maps to a non key-preserved table
```

**Solution:** Use INSTEAD OF trigger!

### Example 1: Insert into Multiple Tables
```sql
-- Create view
CREATE OR REPLACE VIEW employee_dept_view AS
SELECT e.employee_id, e.first_name, e.last_name,
       d.department_id, d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;

-- Create INSTEAD OF INSERT trigger
CREATE OR REPLACE TRIGGER trg_instead_insert
INSTEAD OF INSERT ON employee_dept_view
FOR EACH ROW
DECLARE
    v_dept_id NUMBER;
BEGIN
    -- Check if department exists
    BEGIN
        SELECT department_id INTO v_dept_id
        FROM departments
        WHERE department_name = :NEW.department_name;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Create new department
            INSERT INTO departments (department_id, department_name)
            VALUES (:NEW.department_id, :NEW.department_name);
            v_dept_id := :NEW.department_id;
    END;
    
    -- Insert employee
    INSERT INTO employees (employee_id, first_name, last_name, department_id)
    VALUES (:NEW.employee_id, :NEW.first_name, :NEW.last_name, v_dept_id);
    
    DBMS_OUTPUT.PUT_LINE('Employee inserted successfully');
END;
/

-- Now this works!
INSERT INTO employee_dept_view 
VALUES (9999, 'John', 'Doe', 100, 'IT');
```

### Example 2: Update with Calculated Column
```sql
-- View with calculated annual salary
CREATE OR REPLACE VIEW employee_salary_view AS
SELECT employee_id, first_name, last_name, 
       salary AS monthly_salary,
       salary * 12 AS annual_salary
FROM employees;

-- INSTEAD OF UPDATE trigger
CREATE OR REPLACE TRIGGER trg_update_salary
INSTEAD OF UPDATE ON employee_salary_view
FOR EACH ROW
BEGIN
    -- If user updates annual_salary, calculate monthly
    IF :NEW.annual_salary != :OLD.annual_salary THEN
        UPDATE employees
        SET salary = :NEW.annual_salary / 12
        WHERE employee_id = :NEW.employee_id;
    ELSE
        -- Direct monthly salary update
        UPDATE employees
        SET salary = :NEW.monthly_salary,
            first_name = :NEW.first_name,
            last_name = :NEW.last_name
        WHERE employee_id = :NEW.employee_id;
    END IF;
END;
/

-- Update annual salary
UPDATE employee_salary_view
SET annual_salary = 120000  -- Automatically calculates monthly = 10000
WHERE employee_id = 100;
```

### Example 3: Delete from Multiple Tables
```sql
-- Create INSTEAD OF DELETE trigger
CREATE OR REPLACE TRIGGER trg_instead_delete
INSTEAD OF DELETE ON employee_dept_view
FOR EACH ROW
BEGIN
    -- Delete employee (cascading logic can be added)
    DELETE FROM employees
    WHERE employee_id = :OLD.employee_id;
    
    DBMS_OUTPUT.PUT_LINE('Employee ' || :OLD.first_name || ' deleted');
END;
/

-- Delete through view
DELETE FROM employee_dept_view WHERE employee_id = 9999;
```

---

## Trigger Execution Order

### Multiple Triggers on Same Event

If multiple triggers exist for the same event, they fire in this order:

1. **BEFORE Statement-level** triggers
2. **BEFORE Row-level** triggers (for each row)
3. **The actual DML operation**
4. **AFTER Row-level** triggers (for each row)
5. **AFTER Statement-level** triggers

### Example:
```sql
-- Statement-level BEFORE
CREATE OR REPLACE TRIGGER trg1_before_stmt
BEFORE UPDATE ON employees
BEGIN
    DBMS_OUTPUT.PUT_LINE('1. BEFORE Statement trigger');
END;
/

-- Row-level BEFORE
CREATE OR REPLACE TRIGGER trg2_before_row
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('2. BEFORE Row trigger for emp ' || :NEW.employee_id);
END;
/

-- Row-level AFTER
CREATE OR REPLACE TRIGGER trg3_after_row
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    DBMS_OUTPUT.PUT_LINE('3. AFTER Row trigger for emp ' || :NEW.employee_id);
END;
/

-- Statement-level AFTER
CREATE OR REPLACE TRIGGER trg4_after_stmt
AFTER UPDATE ON employees
BEGIN
    DBMS_OUTPUT.PUT_LINE('4. AFTER Statement trigger');
END;
/

-- Test
UPDATE employees SET salary = salary WHERE employee_id IN (100, 101);
```

**Output:**
```
1. BEFORE Statement trigger
2. BEFORE Row trigger for emp 100
3. AFTER Row trigger for emp 100
2. BEFORE Row trigger for emp 101
3. AFTER Row trigger for emp 101
4. AFTER Statement trigger
```

---

## Best Practices

### ✅ DO:

1. **Keep triggers simple**
   - Avoid complex logic
   - Don't call other procedures excessively

2. **Use meaningful names**
   ```sql
   -- Good
   CREATE TRIGGER trg_audit_employee_changes
   
   -- Bad
   CREATE TRIGGER t1
   ```

3. **Document your triggers**
   ```sql
   -- Purpose: Audit all salary changes for compliance
   -- Author: John Doe
   -- Date: 2024-01-15
   CREATE OR REPLACE TRIGGER trg_audit_salary_changes
   ```

4. **Handle exceptions**
   ```sql
   BEGIN
       -- Logic
   EXCEPTION
       WHEN OTHERS THEN
           -- Log error
           INSERT INTO error_log VALUES (SQLERRM);
   END;
   ```

5. **Use autonomous transactions for logging**
   ```sql
   PRAGMA AUTONOMOUS_TRANSACTION;
   -- Commits independently of main transaction
   ```

### ❌ DON'T:

1. **Don't create infinite loops**
   ```sql
   -- BAD: Trigger on employees updates employees
   CREATE TRIGGER trg_bad
   AFTER UPDATE ON employees
   FOR EACH ROW
   BEGIN
       UPDATE employees SET salary = salary WHERE employee_id = :NEW.employee_id;
       -- This causes infinite recursion!
   END;
   ```

2. **Don't commit/rollback in triggers** (usually)
   - Triggers are part of the calling transaction
   - Exception: Autonomous transactions

3. **Don't perform DDL in triggers** (generally avoided)

4. **Don't query the triggering table** (can cause mutating table error)

---

## Common Use Cases

### 1. Automatic Timestamp Updates
```sql
CREATE OR REPLACE TRIGGER trg_auto_timestamp
BEFORE INSERT OR UPDATE ON products
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_at := SYSTIMESTAMP;
    END IF;
    :NEW.updated_at := SYSTIMESTAMP;
END;
/
```

### 2. Enforce Business Rules
```sql
CREATE OR REPLACE TRIGGER trg_minimum_age
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
BEGIN
    IF MONTHS_BETWEEN(SYSDATE, :NEW.birth_date) / 12 < 18 THEN
        RAISE_APPLICATION_ERROR(-20006,
            'Employee must be at least 18 years old');
    END IF;
END;
/
```

### 3. Maintain Summary Tables
```sql
CREATE OR REPLACE TRIGGER trg_update_dept_count
AFTER INSERT OR DELETE ON employees
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE department_summary
        SET employee_count = employee_count + 1
        WHERE department_id = :NEW.department_id;
    ELSIF DELETING THEN
        UPDATE department_summary
        SET employee_count = employee_count - 1
        WHERE department_id = :OLD.department_id;
    END IF;
END;
/
```

### 4. Cascade Updates
```sql
CREATE OR REPLACE TRIGGER trg_cascade_dept_change
AFTER UPDATE OF department_id ON employees
FOR EACH ROW
BEGIN
    -- Update related records
    UPDATE job_history
    SET department_id = :NEW.department_id
    WHERE employee_id = :NEW.employee_id
    AND end_date IS NULL;
END;
/
```

---

## Viewing and Managing Triggers

### View All Triggers
```sql
SELECT trigger_name, trigger_type, triggering_event, table_name, status
FROM user_triggers
ORDER BY trigger_name;
```

### View Trigger Code
```sql
SELECT text
FROM user_source
WHERE name = 'TRG_AUDIT_EMPLOYEE'
ORDER BY line;
```

### Disable a Trigger
```sql
ALTER TRIGGER trg_audit_employee DISABLE;
```

### Enable a Trigger
```sql
ALTER TRIGGER trg_audit_employee ENABLE;
```

### Drop a Trigger
```sql
DROP TRIGGER trg_audit_employee;
```

### Disable All Triggers on a Table
```sql
ALTER TABLE employees DISABLE ALL TRIGGERS;
```

### Enable All Triggers on a Table
```sql
ALTER TABLE employees ENABLE ALL TRIGGERS;
```

---

## Quick Reference

### Trigger Types Summary

| Trigger Type   | Fires On             | Use Case                  |
| -------------- | -------------------- | ------------------------- |
| **DML**        | INSERT/UPDATE/DELETE | Data validation, auditing |
| **DDL**        | CREATE/ALTER/DROP    | Schema change tracking    |
| **System**     | LOGON/LOGOFF/STARTUP | Session management        |
| **Instead Of** | View operations      | Complex view updates      |

### Timing

| Timing         | When              | Use For                  |
| -------------- | ----------------- | ------------------------ |
| **BEFORE**     | Before operation  | Validation, modification |
| **AFTER**      | After operation   | Auditing, cascading      |
| **INSTEAD OF** | Replace operation | View updates             |

### Level

| Level         | Fires              | Access to     |
| ------------- | ------------------ | ------------- |
| **Row**       | Each affected row  | :NEW, :OLD    |
| **Statement** | Once per statement | No :NEW, :OLD |

---

## Summary

**Key Points for Your Exam:**

1. **Triggers execute automatically** - No manual calling
2. **Four types**: DML, DDL, System, Instead Of
3. **BEFORE vs AFTER**: Timing of execution
4. **Row vs Statement**: Frequency of execution
5. **:NEW and :OLD**: Access to values
6. **Instead Of**: For non-updatable views
7. **Use cases**: Audit, validation, automation

**Practice Questions:**
- When would you use BEFORE vs AFTER?
- What's the difference between row-level and statement-level?
- How do you access old and new values?
- What are Instead Of triggers used for?

---
Remember: Triggers are powerful but should be used wisely. Too many triggers can make debugging difficult!

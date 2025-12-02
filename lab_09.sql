-- DML TRIGGER Task 1: Log changes to a table (INSERT, UPDATE, DELETE)
CREATE TABLE change_log (
    log_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name VARCHAR2 (50),
    operation VARCHAR2 (10),
    changed_by VARCHAR2 (50),
    changed_date TIMESTAMP,
    old_value VARCHAR2 (500),
    new_value VARCHAR2 (500)
);

CREATE OR REPLACE TRIGGER trg_employee_changes
AFTER INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(10);
    v_old_value VARCHAR2(500);
    v_new_value VARCHAR2(500);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_new_value := 'ID: ' || :NEW.employee_id || ', Name: ' || :NEW.first_name;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_value := 'Salary: ' || :OLD.salary;
        v_new_value := 'Salary: ' || :NEW.salary;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_value := 'ID: ' || :OLD.employee_id || ', Name: ' || :OLD.first_name;
    END IF;
    
    INSERT INTO change_log (table_name, operation, changed_by, changed_date, old_value, new_value)
    VALUES ('EMPLOYEES', v_operation, USER, SYSTIMESTAMP, v_old_value, v_new_value);
END;
/

-- DML TRIGGER Task 2: Enforce referential integrity constraint
CREATE OR REPLACE TRIGGER trg_check_department
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
DECLARE
    v_dept_count NUMBER;
BEGIN
    -- Check if department exists
    SELECT COUNT(*)
    INTO v_dept_count
    FROM departments
    WHERE department_id = :NEW.department_id;
    
    IF v_dept_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid department ID. Department does not exist.');
    END IF;
END;
/

-- DML TRIGGER Task 3: Automatically update last_modified timestamp
-- First, add the column if it doesn't exist
ALTER TABLE employees ADD (last_modified TIMESTAMP);

CREATE OR REPLACE TRIGGER trg_update_last_modified
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    :NEW.last_modified := SYSTIMESTAMP;
END;
/

-- DDL TRIGGER Task 1: Log all schema changes
CREATE TABLE ddl_audit_log (
    audit_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_type VARCHAR2 (50),
    object_type VARCHAR2 (50),
    object_name VARCHAR2 (100),
    sql_text CLOB,
    event_date TIMESTAMP,
    event_user VARCHAR2 (50)
);

CREATE OR REPLACE TRIGGER trg_ddl_audit
AFTER DDL ON SCHEMA
BEGIN
    INSERT INTO ddl_audit_log (
        event_type, object_type, object_name, sql_text, event_date, event_user
    ) VALUES (
        ORA_SYSEVENT,
        ORA_DICT_OBJ_TYPE,
        ORA_DICT_OBJ_NAME,
        ORA_SQL_TXT(1),
        SYSTIMESTAMP,
        USER
    );
END;
/

-- DDL TRIGGER Task 2: Prohibit altering/dropping critical table
CREATE OR REPLACE TRIGGER trg_protect_critical_table
BEFORE ALTER OR DROP ON SCHEMA
BEGIN
    IF ORA_DICT_OBJ_NAME = 'EMPLOYEES' THEN
        RAISE_APPLICATION_ERROR(-20002, 
            'Cannot alter or drop EMPLOYEES table - it is protected');
    END IF;
END;
/

-- DDL TRIGGER Task 3: Prevent creation of tables with specific naming pattern
CREATE OR REPLACE TRIGGER trg_prevent_temp_tables
BEFORE CREATE ON SCHEMA
BEGIN
    IF ORA_DICT_OBJ_TYPE = 'TABLE' AND 
       ORA_DICT_OBJ_NAME LIKE 'TEMP_%' THEN
        RAISE_APPLICATION_ERROR(-20003, 
            'Cannot create tables with TEMP_ prefix');
    END IF;
END;
/

-- SYSTEM TRIGGER Task 1: Capture user login information
CREATE TABLE user_login_log (
    log_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR2 (50),
    login_time TIMESTAMP,
    ip_address VARCHAR2 (50),
    session_id NUMBER
);

CREATE OR REPLACE TRIGGER trg_capture_login
AFTER LOGON ON SCHEMA
BEGIN
    INSERT INTO user_login_log (username, login_time, ip_address, session_id)
    VALUES (
        USER,
        SYSTIMESTAMP,
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
        SYS_CONTEXT('USERENV', 'SESSIONID')
    );
    COMMIT;
END;
/

-- SYSTEM TRIGGER Task 2: Send email notification for privileged user login
-- Note: This requires UTL_MAIL package to be configured
CREATE OR REPLACE TRIGGER trg_notify_dba_login
AFTER LOGON ON SCHEMA
DECLARE
    v_user VARCHAR2(50);
    v_is_dba NUMBER;
BEGIN
    v_user := USER;
    
    -- Check if user has DBA role
    SELECT COUNT(*)
    INTO v_is_dba
    FROM session_roles
    WHERE role = 'DBA';
    
    IF v_is_dba > 0 THEN
        -- Log the privileged login
        INSERT INTO user_login_log (username, login_time, ip_address, session_id)
        VALUES (v_user || ' (DBA)', SYSTIMESTAMP, 
                SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
                SYS_CONTEXT('USERENV', 'SESSIONID'));
        COMMIT;
        
        -- In real scenario, UTL_MAIL.SEND would be used here
        DBMS_OUTPUT.PUT_LINE('Alert: DBA user ' || v_user || ' logged in');
    END IF;
END;
/

-- SYSTEM TRIGGER Task 3: Set session time zone on login
CREATE OR REPLACE TRIGGER trg_set_session_timezone
AFTER LOGON ON SCHEMA
BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET TIME_ZONE = ''America/New_York''';
END;
/

-- INSTEAD OF TRIGGER Task 1: Insert into multiple tables through view
CREATE OR REPLACE VIEW employee_dept_view AS
SELECT e.employee_id, e.first_name, e.last_name, d.department_id, d.department_name
FROM employees e
    JOIN departments d ON e.department_id = d.department_id;

CREATE OR REPLACE TRIGGER trg_instead_insert_emp_dept
INSTEAD OF INSERT ON employee_dept_view
FOR EACH ROW
DECLARE
    v_dept_exists NUMBER;
BEGIN
    -- Check if department exists
    SELECT COUNT(*) INTO v_dept_exists
    FROM departments
    WHERE department_id = :NEW.department_id;
    
    -- Create department if it doesn't exist
    IF v_dept_exists = 0 THEN
        INSERT INTO departments (department_id, department_name)
        VALUES (:NEW.department_id, :NEW.department_name);
    END IF;
    
    -- Insert employee
    INSERT INTO employees (employee_id, first_name, last_name, department_id)
    VALUES (:NEW.employee_id, :NEW.first_name, :NEW.last_name, :NEW.department_id);
END;
/

-- INSTEAD OF TRIGGER Task 2: Update with computed column
CREATE OR REPLACE VIEW employee_salary_view AS
SELECT
    employee_id,
    first_name,
    last_name,
    salary,
    salary * 12 AS annual_salary
FROM employees;

CREATE OR REPLACE TRIGGER trg_update_annual_salary
INSTEAD OF UPDATE ON employee_salary_view
FOR EACH ROW
BEGIN
    -- Calculate monthly salary from annual
    UPDATE employees
    SET salary = :NEW.annual_salary / 12,
        first_name = :NEW.first_name,
        last_name = :NEW.last_name
    WHERE employee_id = :NEW.employee_id;
END;
/

-- INSTEAD OF TRIGGER Task 3: Insert into multiple related tables
CREATE OR REPLACE VIEW complete_employee_view AS
SELECT e.employee_id, e.first_name, e.last_name, e.email, d.department_id, d.department_name, j.job_id, j.job_title
FROM
    employees e
    LEFT JOIN departments d ON e.department_id = d.department_id
    LEFT JOIN jobs j ON e.job_id = j.job_id;

CREATE OR REPLACE TRIGGER trg_insert_complete_employee
INSTEAD OF INSERT ON complete_employee_view
FOR EACH ROW
DECLARE
    v_dept_count NUMBER;
    v_job_count NUMBER;
BEGIN
    -- Ensure department exists
    SELECT COUNT(*) INTO v_dept_count
    FROM departments WHERE department_id = :NEW.department_id;
    
    IF v_dept_count = 0 THEN
        INSERT INTO departments (department_id, department_name)
        VALUES (:NEW.department_id, :NEW.department_name);
    END IF;
    
    -- Ensure job exists
    SELECT COUNT(*) INTO v_job_count
    FROM jobs WHERE job_id = :NEW.job_id;
    
    IF v_job_count = 0 THEN
        INSERT INTO jobs (job_id, job_title)
        VALUES (:NEW.job_id, :NEW.job_title);
    END IF;
    
    -- Insert employee
    INSERT INTO employees (employee_id, first_name, last_name, email, 
                          department_id, job_id)
    VALUES (:NEW.employee_id, :NEW.first_name, :NEW.last_name, :NEW.email,
            :NEW.department_id, :NEW.job_id);
END;
/
--VARIABLES AND PROCEDURES
set serveroutput on

DECLARE 
   Sec_Name varchar2(20) := 'Sec-F';
   Course_Name varchar2(20) := 'Database Systems Lab';
BEGIN 
    dbms_output.put_line('This is : '|| Sec_Name || ' and the course is ' || Course_Name); 
END; 

set serveroutput on
DECLARE 
   a integer := 10; 
   b integer := 20; 
   c integer; 
   f real; 
BEGIN 
   c := a + b; 
   dbms_output.put_line('Value of c: ' || c); 
   f := 70.0/3.0; 
   dbms_output.put_line('Value of f: ' || f); 
END; 

DECLARE 
   -- Global variables  
   num1 number := 95;  
   num2 number := 85;  
BEGIN  
   dbms_output.put_line('Outer Variable num1: ' || num1); 
   dbms_output.put_line('Outer Variable num2: ' || num2); 
   DECLARE  
      -- Local variables 
      num1 number := 195;  
      num2 number := 185;  
   BEGIN  
      dbms_output.put_line('Inner Variable num1: ' || num1); 
      dbms_output.put_line('Inner Variable num2: ' || num2); 
   END;  
END; 

--USE OF %TYPE FOR ASSIGNING DATATYPE 
DECLARE 
   e_id employees.EMPLOYEE_ID%type; 
   e_name  employees.FIRST_NAME%type; 
   e_lname employees.LAST_NAME%type; 
   d_name  DEPARTMENTS.DEPARTMENT_NAME%type; 
BEGIN 
   SELECT EMPLOYEE_ID,FIRST_NAME,LAST_NAME,DEPARTMENT_NAME
   INTO e_id, e_name, e_lname, d_name
   FROM employees inner join  DEPARTMENTS 
   on  employees.DEPARTMENT_ID = DEPARTMENTS.DEPARTMENT_ID and EMPLOYEE_ID =100 ;  
    dbms_output.put_line('EMPLOYEE ID: ' ||e_id); 
    dbms_output.put_line('EMPLOYEE First Name: ' ||e_name); 
    dbms_output.put_line('EMPLOYEE Last Name: ' ||e_lname); 
    dbms_output.put_line('DEPARTMENT Name: ' ||d_name); 
END;


--Case Conditional Statements

DECLARE 
   e_id employees.EMPLOYEE_ID%type := 100; 
   e_sal  employees.SALARY%type; 
   e_did  employees.DEPARTMENT_ID%type;
BEGIN 
   SELECT salary,DEPARTMENT_ID INTO e_sal,e_did FROM employees WHERE EMPLOYEE_ID = e_id;   
   CASE e_did  
   when  80 then  
   UPDATE employees SET salary = e_sal+100 WHERE EMPLOYEE_ID= e_id; 
   dbms_output.put_line ('Salary updated:' ||e_sal); 
   when  50 then
   UPDATE employees SET salary = e_sal+200 WHERE EMPLOYEE_ID= e_id; 
      dbms_output.put_line ('Salary updated:'||e_sal);
   when  40 then
   UPDATE employees SET salary = e_sal+300 WHERE EMPLOYEE_ID= e_id; 
      dbms_output.put_line ('Salary updated:'||e_sal);
   ELSE 
   dbms_output.put_line('No such Record'); 
   END CASE; 
END;


--LOOP
SET SERVEROUTPUT ON;
DECLARE 
  BEGIN
   FOR c IN (SELECT EMPLOYEE_ID, FIRST_NAME, SALARY  FROM employees
              WHERE DEPARTMENT_ID = 90)
   LOOP
      DBMS_OUTPUT.PUT_LINE (
         'Salary for the employee ' || c.FIRST_NAME || ' is: ' || c.SALARY);
   END LOOP;
END;

---VIEWS--

--SIMPLE VIEW--
CREATE OR REPLACE VIEW simple_employee_view AS
SELECT EMPLOYEE_ID, FIRST_NAME, LAST_NAME, EMAIL, SALARY
FROM EMPLOYEES
WHERE DEPARTMENT_ID = 80; -- Example department

SELECT * FROM simple_employee_view;

--COMPLEX VIEW
CREATE OR REPLACE VIEW complx_emp_dpt_view AS
SELECT e.EMPLOYEE_ID, e.FIRST_NAME, e.LAST_NAME, d.DEPARTMENT_NAME, e.SALARY
FROM EMPLOYEES e
JOIN DEPARTMENTS d ON e.DEPARTMENT_ID = d.DEPARTMENT_ID
WHERE e.SALARY > 5000; -- Filter for employees with a salary greater than 5000
select * from complx_emp_dpt_view;

--MATERIALIZED VIEW
CREATE MATERIALIZED VIEW employee_salary_summary AS
SELECT d.DEPARTMENT_NAME, COUNT(e.EMPLOYEE_ID) AS employee_count, AVG(e.SALARY) AS average_salary
FROM EMPLOYEES e
JOIN DEPARTMENTS d ON e.DEPARTMENT_ID = d.DEPARTMENT_ID
GROUP BY d.DEPARTMENT_NAME;
SELECT * FROM employee_salary_summary;

--FUNCTIONS

CREATE OR REPLACE FUNCTION CalculateSAL(
    DEPT_ID IN NUMBER
) RETURN NUMBER
IS
    Total_Salary NUMBER := 0;
BEGIN
    -- This query calculates the sum of salaries for the given department
    SELECT SUM(Salary)
    INTO Total_Salary
    FROM employees
    WHERE DEPARTMENT_ID = DEPT_ID;

    -- Return the calculated total salary
    RETURN Total_Salary;
END;
/

SELECT CalculateSAL(80) FROM dual;

--OBJECT TYPES AND TABLE TYPES

CREATE OR REPLACE TYPE EMP_OBJ_TYPE AS OBJECT (
  EMPLOYEE_ID NUMBER(6,0),
  FIRST_NAME VARCHAR2(30),
  LAST_NAME VARCHAR2(30),
  DEPARTMENT_ID NUMBER(4,0)
);

CREATE OR REPLACE TYPE EMP_TBL_TYPE AS TABLE OF EMP_OBJ_TYPE;

CREATE OR REPLACE FUNCTION GETALL
RETURN EMP_TBL_TYPE
IS
 EMPLOYEE_ID NUMBER(6,0);
  FIRST_NAME VARCHAR(30);
  LAST_NAME VARCHAR(30);
  DEPARTMENT_ID NUMBER(4,0);
  
  -- NESTED TABLE VARIABLE DECLARATION AND INITIALIZATION
  
    EMP_DETAILS EMP_TBL_TYPE := EMP_TBL_TYPE(); 
BEGIN
-- EXTENDING THE NESTED TABLE
EMP_DETAILS.EXTEND(); 
---- GET THE REQUIRED DATA INTO VARIABLES 
SELECT EMPLOYEE_ID,FIRST_NAME, LAST_NAME,DEPARTMENT_ID INTO EMPLOYEE_ID,FIRST_NAME,LAST_NAME,DEPARTMENT_ID FROM EMPLOYEES where EMPLOYEE_ID=100;
-- USING A OBJECT CONSTRUCTOR, TO INSERT THE DATA INTO THE NESTED TABLE
EMP_DETAILS(1) := EMP_OBJ_TYPE(EMPLOYEE_ID,FIRST_NAME,LAST_NAME,DEPARTMENT_ID);
RETURN EMP_DETAILS;
END;
/

SELECT * FROM TABLE(GETALL);

CREATE OR REPLACE FUNCTION GETALL1
RETURN EMP_TBL_TYPE
IS
 EMPLOYEE_ID NUMBER(6,0);
  FIRST_NAME VARCHAR(30);
  LAST_NAME VARCHAR(30);
  DEPARTMENT_ID NUMBER(4,0);
  -- NESTED TABLE VARIALE DECLARATION AND INITIALIZATION
  
    EMP_DETAILS EMP_TBL_TYPE := EMP_TBL_TYPE(); 
BEGIN
-- EXTENDING THE NESTED TABLE
EMP_DETAILS.EXTEND(); 
---- GET THE REQUIRED DATA INTO VARIABLES 
SELECT EMP_OBJ_TYPE( EMPLOYEE_ID,FIRST_NAME, LAST_NAME,DEPARTMENT_ID) bulk collect  INTO EMP_DETAILS FROM EMPLOYEES;
-- USING A OBJECT CONSTRUCTOR, TO INSERT THE DATA INTO THE NESTED TABLE
RETURN EMP_DETAILS;
END;
/
SELECT * FROM TABLE(GETALL1);

--Store procedures
CREATE OR REPLACE PROCEDURE all_employees
AS
BEGIN
  -- Select all records from employees table
  FOR emp_rec IN (SELECT * FROM employees) LOOP
    DBMS_OUTPUT.PUT_LINE('Employee ID: ' || emp_rec.employee_id || 
                         ', First Name: ' || emp_rec.first_name || 
                         ', Last Name: ' || emp_rec.last_name ||
                         ', Department ID: ' || emp_rec.department_id);
  END LOOP;
END;
/


execute all_employees;

---FOR INSERTING DATA STORE PROCEDURE
CREATE OR REPLACE PROCEDURE insert_unique_employee (
    p_employee_id   IN NUMBER,
    p_first_name    IN VARCHAR2,
    p_last_name     IN VARCHAR2,
    p_email         IN VARCHAR2,
    p_phone_number   IN VARCHAR2,
    p_hire_date     IN DATE,
    p_job_id        IN VARCHAR2,
    p_salary        IN NUMBER,
    p_commission_pct IN NUMBER,
    p_manager_id    IN NUMBER,
    p_department_id IN NUMBER
) AS
    v_count NUMBER;
BEGIN
    -- Check if the employee ID or email already exists
    SELECT COUNT(*)
    INTO v_count
    FROM employees
    WHERE employee_id = p_employee_id OR email = p_email;

    IF v_count = 0 THEN
        INSERT INTO employees (
            employee_id,
            first_name,
            last_name,
            email,
            phone_number,
            hire_date,
            job_id,
            salary,
            commission_pct,
            manager_id,
            department_id
        ) VALUES (
            p_employee_id,
            p_first_name,
            p_last_name,
            p_email,
            p_phone_number,
            p_hire_date,
            p_job_id,
            p_salary,
            p_commission_pct,
            p_manager_id,
            p_department_id
        );

        DBMS_OUTPUT.PUT_LINE('Employee ' || p_first_name || ' ' || p_last_name || ' inserted successfully.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Error: Employee ID or Email already exists. Insertion failed for ' || p_first_name || ' ' || p_last_name);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

BEGIN
    insert_unique_employee(
        p_employee_id   => 2005, 
        p_first_name    => 'Eva',
        p_last_name     => 'Green',
        p_email         => 'eva.green@example.com',
        p_phone_number   => '555-3698',
        p_hire_date     => TO_DATE('2024-10-24', 'YYYY-MM-DD'),
        p_job_id        => 'IT_PROG',
        p_salary        => 6200,
        p_commission_pct => 0.05,
        p_manager_id    => 102,
        p_department_id => 60
    );
END;


---Cursor--

SET SERVEROUTPUT ON;
DECLARE
  CURSOR Cursor_EMP IS
  SELECT * FROM employees ORDER BY salary DESC;
   -- record    
   row_emp Cursor_EMP%ROWTYPE;
BEGIN
  OPEN Cursor_EMP;
  LOOP
    FETCH  Cursor_EMP  INTO row_emp;
    EXIT WHEN Cursor_EMP%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE( 'EMPLOYEE id: ' ||row_emp.EMPLOYEE_ID || ' EMPLOYEE NAME: ' || row_emp.FIRST_NAME || ' EMPLOYEE CONTACT: ' || row_emp.PHONE_NUMBER || '.');
  END LOOP;
  CLOSE Cursor_EMP;
END;


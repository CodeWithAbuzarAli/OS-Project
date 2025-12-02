DECLARE
    v_employee_number employees.employeeID%TYPE := &emp_num
    v_salary          employees.salary%TYPE
    v_bonus           NUMBER(10, 2)
BEGIN
    SELECT e.salary INTO v_salary
    FROM employees e
    WHERE e.employeeID = v_employee_number;

    IF v_salary is NULL THEN
        v_bonus = 0;
    ELSIF v_salary < 1000 THEN
        v_bonus := v_salary * 0.1
    ELSIF v_salary is BETWEEN 1000 AND 1500 THEN
        v_bonus := v_salary *. 0.15
    ELSE
        v_bonus := v_salary * 0.2
    END IF;
EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE("Error Occured: " || SQLERRM)
END;
/


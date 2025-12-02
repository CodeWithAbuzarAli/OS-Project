-- LAB 09: Triggers Demonstration

SET SERVEROUTPUT ON;

-- Create the main table first
CREATE TABLE superheroes (
  sh_name VARCHAR2(30)
);

-- 1. BEFORE INSERT TRIGGER
CREATE OR REPLACE TRIGGER bi_superheroes
BEFORE INSERT ON superheroes
FOR EACH ROW
DECLARE
  v_user VARCHAR2(15);
BEGIN
  SELECT USER INTO v_user FROM dual;
  DBMS_OUTPUT.PUT_LINE('You just inserted a row, Mr. ' || v_user);
END;
/
BEGIN
INSERT INTO superheroes VALUES ('Batman');
END;
/
-- 2. BEFORE UPDATE TRIGGER
CREATE OR REPLACE TRIGGER bu_superheroes
BEFORE UPDATE ON superheroes
FOR EACH ROW
DECLARE
  v_user VARCHAR2(15);
BEGIN
  SELECT USER INTO v_user FROM dual;
  DBMS_OUTPUT.PUT_LINE('You just updated a row, Mr. ' || v_user);
END;
/

BEGIN
UPDATE superheroes SET sh_name = 'Superman' WHERE sh_name = 'Batman';
END;
/

-- 3. BEFORE DELETE TRIGGER
CREATE OR REPLACE TRIGGER bd_superheroes
BEFORE DELETE ON superheroes
FOR EACH ROW
DECLARE
  v_user VARCHAR2(15);
BEGIN
  SELECT USER INTO v_user FROM dual;
  DBMS_OUTPUT.PUT_LINE('You just deleted a row, Mr. ' || v_user);
END;
/

BEGIN
DELETE FROM superheroes WHERE sh_name = 'Superman';
END;
/
-- 4. COMBINED DML TRIGGER (INSERT, UPDATE, DELETE)
CREATE OR REPLACE TRIGGER tr_superheroes
BEFORE INSERT OR DELETE OR UPDATE ON superheroes
FOR EACH ROW
DECLARE
  v_user VARCHAR2(15);
BEGIN
  SELECT USER INTO v_user FROM dual;
  IF INSERTING THEN
    DBMS_OUTPUT.PUT_LINE('One row inserted by ' || v_user);
  ELSIF DELETING THEN
    DBMS_OUTPUT.PUT_LINE('One row deleted by ' || v_user);
  ELSIF UPDATING THEN
    DBMS_OUTPUT.PUT_LINE('One row updated by ' || v_user);
  END IF;
END;
/

-- 5. TABLE AUDITING TRIGGER
CREATE TABLE superheroes_backup AS SELECT * FROM superheroes WHERE 1=2;

CREATE TABLE sh_audit (
  new_name VARCHAR2(30),
  old_name VARCHAR2(30),
  user_name VARCHAR2(30),
  entry_date VARCHAR2(30),
  operation VARCHAR2(30)
);

CREATE OR REPLACE TRIGGER superheroes_audit
BEFORE INSERT OR DELETE OR UPDATE ON superheroes
FOR EACH ROW
DECLARE
  v_user VARCHAR2(30);
  v_date VARCHAR2(30);
BEGIN
  SELECT USER, TO_CHAR(SYSDATE, 'DD/MON/YYYY HH24:MI:SS')
  INTO v_user, v_date FROM dual;

  IF INSERTING THEN
    INSERT INTO sh_audit VALUES(:NEW.sh_name, NULL, v_user, v_date, 'Insert');
  ELSIF DELETING THEN
    INSERT INTO sh_audit VALUES(NULL, :OLD.sh_name, v_user, v_date, 'Delete');
  ELSIF UPDATING THEN
    INSERT INTO sh_audit VALUES(:NEW.sh_name, :OLD.sh_name, v_user, v_date, 'Update');
  END IF;
END;
/
--SHOW ERRORS TRIGGER sh_backup;

BEGIN
INSERT INTO superheroes VALUES ('Ironman');
INSERT INTO superheroes VALUES ('Batman');
UPDATE superheroes SET sh_name = 'Superman' WHERE sh_name = 'Batman';
DELETE FROM superheroes WHERE sh_name = 'Ironman';

END;
/
SELECT * FROM superheroes;
SELECT * FROM superheroes_backup;
SELECT * FROM SH_AUDIT;

-- 6. DDL SCHEMA AUDIT TRIGGER
CREATE TABLE schema_audit (
  ddl_date DATE,
  ddl_user VARCHAR2(15),
  object_created VARCHAR2(15),
  object_name VARCHAR2(15),
  ddl_operation VARCHAR2(15)
);

CREATE OR REPLACE TRIGGER hr_audit_tr
AFTER DDL ON SCHEMA
BEGIN
  INSERT INTO schema_audit VALUES (
    SYSDATE,
    SYS_CONTEXT('USERENV', 'CURRENT_USER'),
    ORA_DICT_OBJ_TYPE,
    ORA_DICT_OBJ_NAME,
    ORA_SYSEVENT
  );
END;
/

CREATE TABLE test_table (id NUMBER);

SELECT * FROM schema_audit;

-- 8. SYSTEM LOGON/LOGOFF TRIGGERS
CREATE TABLE hr_evnt_audit (
  event_type VARCHAR2(30),
  logon_date DATE,
  logon_time VARCHAR2(15),
  logoff_date DATE,
  logoff_time VARCHAR2(15)
);

CREATE OR REPLACE TRIGGER hr_logon_audit
AFTER LOGON ON SCHEMA
BEGIN
  INSERT INTO hr_evnt_audit VALUES(
    ORA_SYSEVENT,
    SYSDATE,
    TO_CHAR(SYSDATE, 'HH24:MI:SS'),
    NULL,
    NULL
  );
  COMMIT;
END;
/

CREATE OR REPLACE TRIGGER hr_logoff_audit
BEFORE LOGOFF ON SCHEMA
BEGIN
  INSERT INTO hr_evnt_audit VALUES(
    ORA_SYSEVENT,
    NULL,
    NULL,
    SYSDATE,
    TO_CHAR(SYSDATE, 'HH24:MI:SS')
  );
  COMMIT;
END;
/

-- 9. STARTUP AND SHUTDOWN DATABASE TRIGGERS
CREATE TABLE startup_audit (
  event_type VARCHAR2(15),
  event_date DATE,
  event_time VARCHAR2(15)
);

CREATE OR REPLACE TRIGGER startup_audit_tr
AFTER STARTUP ON DATABASE
BEGIN
  INSERT INTO startup_audit VALUES (
    ORA_SYSEVENT,
    SYSDATE,
    TO_CHAR(SYSDATE, 'HH24:MI:SS')
  );
END;
/

CREATE OR REPLACE TRIGGER shutdown_audit_tr
BEFORE SHUTDOWN ON DATABASE
BEGIN
  INSERT INTO startup_audit VALUES (
    ORA_SYSEVENT,
    SYSDATE,
    TO_CHAR(SYSDATE, 'HH24:MI:SS')
  );
END;
/

-- 10. INSTEAD OF TRIGGER ON VIEW
CREATE TABLE trainer (full_name VARCHAR2(20));
CREATE TABLE subject (subject_name VARCHAR2(15));

CREATE VIEW db_lab_09_view AS
SELECT full_name, subject_name FROM trainer, subject;

INSERT INTO trainer_subject_view VALUES ('Fatima Gado', 'Database Systems');--it will give u error bcz view is not directly updatable

CREATE OR REPLACE TRIGGER tr_io_insert
INSTEAD OF INSERT ON db_lab_09_view
FOR EACH ROW
BEGIN
  INSERT INTO trainer VALUES(:NEW.full_name);
  INSERT INTO subject VALUES(:NEW.subject_name);
END;
/

INSERT INTO trainer_subject_view VALUES ('Sohail Ahmed', 'Database Systems');


SELECT * FROM trainer;
SELECT * FROM subject;

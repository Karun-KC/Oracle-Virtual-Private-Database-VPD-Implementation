-- This script implements the roles, users, and VPD security policies.


-- 1.  Define Role Accounts 
DROP ROLE Admin_R;
DROP ROLE Doctor_R;

CREATE ROLE Admin_R;
CREATE ROLE Doctor_R;

-- 2.  Assign Permission to the Roles 

-- Admin_R: Complete access to Administrator, Clinic, Doctor tables
GRANT SELECT, INSERT, UPDATE, DELETE ON Administrator TO Admin_R;
GRANT SELECT, INSERT, UPDATE, DELETE ON Clinic TO Admin_R;
GRANT SELECT, INSERT, UPDATE, DELETE ON Doctor TO Admin_R;
-- Doctor_R: Full access to Patient, Visit, Diagnosis tables
GRANT SELECT, INSERT, UPDATE, DELETE ON Patient TO Doctor_R;
GRANT SELECT, INSERT, UPDATE, DELETE ON Visit TO Doctor_R;
GRANT SELECT, INSERT, UPDATE, DELETE ON Diagnosis TO Doctor_R;
-- Read-only access to Administrator, Clinic, and Doctor
GRANT SELECT ON Administrator TO Doctor_R;
GRANT SELECT ON Clinic TO Doctor_R;
GRANT SELECT ON Doctor TO Doctor_R;

-- 3.  Remove and Recreate Tablespace  
DROP TABLESPACE IA643Spr25TBS INCLUDING CONTENTS AND DATAFILES;
CREATE TABLESPACE IA643Spr25TBS
DATAFILE 'IA643Spr25.dat'
SIZE 500K
REUSE AUTOEXTEND ON NEXT 300K
MAXSIZE 100M;
-- 4.  Set Up User Accounts 
DROP USER AdminA CASCADE;
DROP USER AdminB CASCADE;
DROP USER RDavison CASCADE;
DROP USER SSeymour CASCADE;
DROP USER AdminS CASCADE;
DROP USER AdminT CASCADE;
DROP USER THemming CASCADE;
DROP USER KMcCain CASCADE;
DROP USER Sysadmin_ctx CASCADE; 

CREATE USER AdminA IDENTIFIED BY AdminA
DEFAULT TABLESPACE IA643Spr25TBS
TEMPORARY TABLESPACE TEMP;
CREATE USER AdminB IDENTIFIED BY AdminB
DEFAULT TABLESPACE IA643Spr25TBS
TEMPORARY TABLESPACE TEMP;

CREATE USER RDavison IDENTIFIED BY RDavison
DEFAULT TABLESPACE IA643Spr25TBS
TEMPORARY TABLESPACE TEMP;
CREATE USER SSeymour IDENTIFIED BY SSeymour
DEFAULT TABLESPACE IA643Spr25TBS
TEMPORARY TABLESPACE TEMP;

CREATE USER AdminS IDENTIFIED BY AdminS
DEFAULT TABLESPACE IA643Spr25TBS
TEMPORARY TABLESPACE TEMP;
CREATE USER AdminT IDENTIFIED BY AdminT
DEFAULT TABLESPACE IA643Spr25TBS
TEMPORARY TABLESPACE TEMP;

CREATE USER THemming IDENTIFIED BY THemming
DEFAULT TABLESPACE IA643Spr25TBS
TEMPORARY TABLESPACE TEMP;
CREATE USER KMcCain IDENTIFIED BY KMcCain
DEFAULT TABLESPACE IA643Spr25TBS
TEMPORARY TABLESPACE TEMP;
-- 5.  Grant Roles and Connect Privileges 
GRANT CONNECT, RESOURCE TO AdminA, AdminB, RDavison, SSeymour, AdminS, AdminT, THemming, KMcCain;
GRANT Admin_R TO AdminA, AdminB, AdminS, AdminT;
GRANT Doctor_R TO RDavison, SSeymour, THemming, KMcCain;
-- 6.  Create Public Synonyms 
DROP PUBLIC SYNONYM Clinic;
DROP PUBLIC SYNONYM Doctor;
DROP PUBLIC SYNONYM Administrator;
DROP PUBLIC SYNONYM Patient;
DROP PUBLIC SYNONYM Visit;
DROP PUBLIC SYNONYM Diagnosis;
DROP PUBLIC SYNONYM App_User;

CREATE PUBLIC SYNONYM Clinic FOR DBA643.Clinic;
CREATE PUBLIC SYNONYM Doctor FOR DBA643.Doctor;
CREATE PUBLIC SYNONYM Administrator FOR DBA643.Administrator;
CREATE PUBLIC SYNONYM Patient FOR DBA643.Patient;
CREATE PUBLIC SYNONYM Visit FOR DBA643.Visit;
CREATE PUBLIC SYNONYM Diagnosis FOR DBA643.Diagnosis;
CREATE PUBLIC SYNONYM App_User FOR DBA643.App_User;

-- 7.  Set Up Triggers to Track Security Info in CTL_SEC_USER 

CREATE OR REPLACE TRIGGER trg_Doctor_user
BEFORE INSERT OR UPDATE ON Doctor
FOR EACH ROW
BEGIN
  :NEW.CTL_SEC_USER := USER;
  :NEW.CTL_SEC_LEVEL := 4;
END;
/

CREATE OR REPLACE TRIGGER trg_Clinic_user
BEFORE INSERT OR UPDATE ON Clinic
FOR EACH ROW
BEGIN
  :NEW.CTL_SEC_USER := USER;
  :NEW.CTL_SEC_LEVEL := 1;
END;
/

CREATE OR REPLACE TRIGGER trg_Administrator_user
BEFORE INSERT OR UPDATE ON Administrator
FOR EACH ROW
BEGIN
  :NEW.CTL_SEC_USER := USER;
  :NEW.CTL_SEC_LEVEL := 5;
END;
/

CREATE OR REPLACE TRIGGER trg_Patient_user
BEFORE INSERT OR UPDATE ON Patient
FOR EACH ROW
BEGIN
  :NEW.CTL_SEC_USER := USER;
  :NEW.CTL_SEC_LEVEL := 4;
END;
/

CREATE OR REPLACE TRIGGER trg_Visit_user
BEFORE INSERT OR UPDATE ON Visit
FOR EACH ROW
BEGIN
  :NEW.CTL_SEC_USER := USER;
  :NEW.CTL_SEC_LEVEL := 4;
END;
/

CREATE OR REPLACE TRIGGER trg_Diagnosis_user
BEFORE INSERT OR UPDATE ON Diagnosis
FOR EACH ROW
BEGIN
  :NEW.CTL_SEC_USER := USER;
  :NEW.CTL_SEC_LEVEL := 5;
END;
/

CREATE OR REPLACE TRIGGER trg_App_user
BEFORE INSERT OR UPDATE ON App_User
FOR EACH ROW
BEGIN
  :NEW.CTL_SEC_USER := USER;
  :NEW.CTL_SEC_LEVEL := 5;
END;
/

-- 8.  Develop VPD Security Functions 

-- Access control function for admin tables: Clinic, Doctor, Administrator
CREATE OR REPLACE FUNCTION VPD_Admin_Policy(P_schema_name IN VARCHAR2, P_object_name IN VARCHAR2) RETURN VARCHAR2 IS
  V_where VARCHAR2(300);
  v_clinic_id NUMBER;
BEGIN
  v_clinic_id := SYS_CONTEXT('Clinic_Context', 'ClinicID');
  
  IF P_object_name = 'ADMINISTRATOR' THEN
    V_where := 'CTL_SEC_USER = USER'; --Only the admin's own record
  ELSIF P_object_name = 'CLINIC' THEN
    V_where := 'Clinic_ID = ' || NVL(v_clinic_id, 0);  --Only their clinic
  ELSIF P_object_name = 'DOCTOR' THEN
     V_where := 'Clinic_ID = ' || NVL(v_clinic_id, 0); -- Admins see doctors in their clinic
  ELSE
    V_where := '1=2'; -- No access to other tables
  END IF;
  RETURN V_where;
END;
/

-- Security function for doctor-specific tables: Patient, Visit, Diagnosis
CREATE OR REPLACE FUNCTION VPD_Doctor_Policy(P_schema_name IN VARCHAR2, P_object_name IN VARCHAR2) RETURN VARCHAR2 IS
  V_where VARCHAR2(300);
  v_doctor_id NUMBER;
  v_clinic_id NUMBER;
BEGIN
  v_doctor_id := SYS_CONTEXT('Clinic_Context', 'DoctorID');
  v_clinic_id := SYS_CONTEXT('Clinic_Context', 'ClinicID');
  
  IF P_object_name IN ('PATIENT', 'VISIT', 'DIAGNOSIS') THEN
    -- Doctors only see patients from their clinic (or assigned to them)
    -- This policy predicate ensures doctors only see patients assigned to them.
    V_where := 'Doctor_ID = ' || NVL(v_doctor_id, 0);
  ELSE
    V_where := '1=1';  -- Doctors see all other tables (Doctor, Admin, Clinic)
  END IF;
  RETURN V_where;
END;
/

-- 9.  Implement VPD Security Policies with DBMS_RLS 

-- Remove any previously existing policies
BEGIN
  DBMS_RLS.DROP_POLICY('DBA643', 'Clinic', 'Clinic_Admin_Sec');
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -28102 THEN RAISE; END IF;
END;
/
BEGIN
  DBMS_RLS.DROP_POLICY('DBA643', 'Doctor', 'Doctor_Admin_Sec');
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -28102 THEN RAISE; END IF;
END;
/
BEGIN
  DBMS_RLS.DROP_POLICY('DBA643', 'Administrator', 'Administrator_Admin_Sec');
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -28102 THEN RAISE; END IF;
END;
/
BEGIN
  DBMS_RLS.DROP_POLICY('DBA643', 'Patient', 'Patient_Sec');
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -28102 THEN RAISE; END IF;
END;
/
BEGIN
  DBMS_RLS.DROP_POLICY('DBA643', 'Visit', 'Visit_Sec');
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -28102 THEN RAISE; END IF;
END;
/
BEGIN
  DBMS_RLS.DROP_POLICY('DBA643', 'Diagnosis', 'Diagnosis_Sec');
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -28102 THEN RAISE; END IF;
END;
/

-- Apply VPD policies to admin-related tables
EXEC DBMS_RLS.ADD_POLICY('DBA643', 'Clinic', 'Clinic_Admin_Sec', 'DBA643', 'VPD_Admin_Policy', 'SELECT, UPDATE, DELETE, INSERT', TRUE);
EXEC DBMS_RLS.ADD_POLICY('DBA643', 'Doctor', 'Doctor_Admin_Sec', 'DBA643', 'VPD_Admin_Policy', 'SELECT, UPDATE, DELETE, INSERT', TRUE);
EXEC DBMS_RLS.ADD_POLICY('DBA643', 'Administrator', 'Administrator_Admin_Sec', 'DBA643', 'VPD_Admin_Policy', 'SELECT, UPDATE, DELETE, INSERT', TRUE);

-- Apply doctor-specific security policies to related tables
EXEC DBMS_RLS.ADD_POLICY('DBA643', 'Patient', 'Patient_Sec', 'DBA643', 'VPD_Doctor_Policy', 'SELECT, UPDATE, DELETE, INSERT', TRUE);
EXEC DBMS_RLS.ADD_POLICY('DBA643', 'Visit', 'Visit_Sec', 'DBA643', 'VPD_Doctor_Policy', 'SELECT, UPDATE, DELETE, INSERT', TRUE);
EXEC DBMS_RLS.ADD_POLICY('DBA643', 'Diagnosis', 'Diagnosis_Sec', 'DBA643', 'VPD_Doctor_Policy', 'SELECT, UPDATE, DELETE, INSERT', TRUE);


-- 10.  CSO's Code (Context and Logon Trigger)

-- This part must be run as SYSDBA
-- GRANT CREATE ANY CONTEXT to DBA643; -- or run the following as SYS
CREATE USER sysadmin_ctx IDENTIFIED BY Sysadmin643;
GRANT CREATE SESSION, CREATE ANY CONTEXT, CREATE PROCEDURE, CREATE TRIGGER, ADMINISTER DATABASE TRIGGER TO sysadmin_ctx;
GRANT EXECUTE ON DBMS_SESSION TO sysadmin_ctx;
GRANT EXECUTE ON DBMS_RLS TO sysadmin_ctx;
GRANT RESOURCE TO sysadmin_ctx; 
GRANT SELECT ON DBA643.App_User TO Sysadmin_ctx;

CONNECT sysadmin_ctx/Sysadmin643@localhost/IA643;

CREATE OR REPLACE CONTEXT Clinic_Context USING Clinic_Pkg;

CREATE OR REPLACE PACKAGE Clinic_Pkg AS
  PROCEDURE Set_Context;
END Clinic_Pkg;
/

CREATE OR REPLACE PACKAGE BODY Clinic_Pkg AS
  PROCEDURE Set_Context IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    V_user_type CHAR(1);
    v_emp_id NUMBER;
    v_clinic_id NUMBER;
    v_doctor_id NUMBER;
  BEGIN
    -- Use SYS_CONTEXT('USERENV', 'SESSION_USER') which is the logon user
    SELECT USER_TYPE, EMP_ID INTO V_user_type, v_emp_id
    FROM DBA643.App_User
    WHERE APP_USERNAME = SYS_CONTEXT('USERENV', 'SESSION_USER');

    IF V_user_type = 'A' THEN -- Administrator
      SELECT Clinic_ID INTO v_clinic_id FROM DBA643.Administrator WHERE Admin_ID = v_emp_id;
      DBMS_SESSION.SET_CONTEXT('Clinic_Context', 'UserType', 'ADMIN');
      DBMS_SESSION.SET_CONTEXT('Clinic_Context', 'ClinicID', v_clinic_id);
      DBMS_SESSION.SET_CONTEXT('Clinic_Context', 'DoctorID', NULL);  -- Clear DoctorID
    ELSIF V_user_type = 'D' THEN -- Doctor
      v_doctor_id := v_emp_id;
      SELECT Clinic_ID INTO v_clinic_id FROM DBA643.Doctor WHERE Doctor_ID = v_emp_id;
      DBMS_SESSION.SET_CONTEXT('Clinic_Context', 'UserType', 'DOCTOR');
      DBMS_SESSION.SET_CONTEXT('Clinic_Context', 'ClinicID', v_clinic_id);
      DBMS_SESSION.SET_CONTEXT('Clinic_Context', 'DoctorID', v_doctor_id);
    END IF;
    COMMIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL; -- User is not in App_User, so no context is set
  END Set_Context;
END Clinic_Pkg;
/

-- This trigger runs the Set_Context procedure every time a user logs on.
CREATE OR REPLACE TRIGGER Logon_Trg
AFTER LOGON ON DATABASE
BEGIN
  -- Only run for non-DBA users
  IF SYS_CONTEXT('USERENV', 'ISDBA') = 'FALSE' THEN
    Clinic_Pkg.Set_Context;
  END IF;
END;
/

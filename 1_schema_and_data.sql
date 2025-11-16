
-- 1_schema_and_data.sql
-- This script creates the tables and sample data for the Healthcare VPD project.


BEGIN
  FOR c IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || c.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
END;
/

-- Table for Clinics
CREATE TABLE Clinic (
    Clinic_ID NUMBER PRIMARY KEY,
    Clinic_Name VARCHAR2(100),
    Address VARCHAR2(255),
    CTL_SEC_USER VARCHAR2(100),
    CTL_SEC_LEVEL NUMBER
);

-- Table for Doctors
CREATE TABLE Doctor (
    Doctor_ID NUMBER PRIMARY KEY,
    FirstName VARCHAR2(100),
    LastName VARCHAR2(100),
    Specialty VARCHAR2(100),
    Clinic_ID NUMBER REFERENCES Clinic(Clinic_ID),
    CTL_SEC_USER VARCHAR2(100),
    CTL_SEC_LEVEL NUMBER
);

-- Table for Administrators
CREATE TABLE Administrator (
    Admin_ID NUMBER PRIMARY KEY,
    FirstName VARCHAR2(100),
    LastName VARCHAR2(100),
    Title VARCHAR2(100),
    Clinic_ID NUMBER REFERENCES Clinic(Clinic_ID),
    CTL_SEC_USER VARCHAR2(100),
    CTL_SEC_LEVEL NUMBER
);

-- Table for Patients
CREATE TABLE Patient (
    Patient_ID NUMBER PRIMARY KEY,
    FirstName VARCHAR2(100),
    LastName VARCHAR2(100),
    DOB DATE,
    Doctor_ID NUMBER REFERENCES Doctor(Doctor_ID),
    CTL_SEC_USER VARCHAR2(100),
    CTL_SEC_LEVEL NUMBER
);

-- Table for Patient Visits
CREATE TABLE Visit (
    Visit_ID NUMBER PRIMARY KEY,
    Patient_ID NUMBER REFERENCES Patient(Patient_ID),
    Visit_Date DATE,
    Reason VARCHAR2(500),
    CTL_SEC_USER VARCHAR2(100),
    CTL_SEC_LEVEL NUMBER
);

-- Table for Diagnoses
CREATE TABLE Diagnosis (
    Diagnosis_ID NUMBER PRIMARY KEY,
    Patient_ID NUMBER REFERENCES Patient(Patient_ID),
    Visit_ID NUMBER REFERENCES Visit(Visit_ID),
    Diagnosis_Code VARCHAR2(20),
    Description VARCHAR2(500),
    CTL_SEC_USER VARCHAR2(100),
    CTL_SEC_LEVEL NUMBER
);

-- Application User table to map database users to employees
CREATE TABLE App_User (
    APP_USERNAME VARCHAR2(100) PRIMARY KEY,
    USER_TYPE CHAR(1), -- 'A' for Admin, 'D' for Doctor
    EMP_ID NUMBER,     -- Corresponds to Admin_ID or Doctor_ID
    CTL_SEC_USER VARCHAR2(100),
    CTL_SEC_LEVEL NUMBER
);

-- ### INSERT SAMPLE DATA ###

-- Clinics
INSERT INTO Clinic (Clinic_ID, Clinic_Name, Address) VALUES (1, 'Northside Clinic', '123 Main St');
INSERT INTO Clinic (Clinic_ID, Clinic_Name, Address) VALUES (2, 'Southview Clinic', '456 Oak Ave');

-- Doctors
INSERT INTO Doctor (Doctor_ID, FirstName, LastName, Specialty, Clinic_ID) VALUES (101, 'Robert', 'Davison', 'Cardiology', 1);
INSERT INTO Doctor (Doctor_ID, FirstName, LastName, Specialty, Clinic_ID) VALUES (102, 'Sarah', 'Seymour', 'Pediatrics', 1);
INSERT INTO Doctor (Doctor_ID, FirstName, LastName, Specialty, Clinic_ID) VALUES (201, 'Tom', 'Hemming', 'Neurology', 2);
INSERT INTO Doctor (Doctor_ID, FirstName, LastName, Specialty, Clinic_ID) VALUES (202, 'Karen', 'McCain', 'Oncology', 2);

-- Administrators
INSERT INTO Administrator (Admin_ID, FirstName, LastName, Title, Clinic_ID) VALUES (1, 'Alice', 'Smith', 'Clinic Manager', 1);
INSERT INTO Administrator (Admin_ID, FirstName, LastName, Title, Clinic_ID) VALUES (2, 'Bob', 'Brown', 'Clinic Manager', 2);

-- Patients
-- Dr. Davison's Patients (Clinic 1)
INSERT INTO Patient (Patient_ID, FirstName, LastName, DOB, Doctor_ID) VALUES (1001, 'Pat', 'Jones', TO_DATE('1980-05-15', 'YYYY-MM-DD'), 101);
INSERT INTO Patient (Patient_ID, FirstName, LastName, DOB, Doctor_ID) VALUES (1002, 'Chris', 'Lee', TO_DATE('1992-11-01', 'YYYY-MM-DD'), 101);
-- Dr. Seymour's Patients (Clinic 1)
INSERT INTO Patient (Patient_ID, FirstName, LastName, DOB, Doctor_ID) VALUES (1003, 'Alex', 'Green', TO_DATE('2018-03-20', 'YYYY-MM-DD'), 102);
-- Dr. Hemming's Patients (Clinic 2)
INSERT INTO Patient (Patient_ID, FirstName, LastName, DOB, Doctor_ID) VALUES (2001, 'Mike', 'Davis', TO_DATE('1975-01-30', 'YYYY-MM-DD'), 201);
INSERT INTO Patient (Patient_ID, FirstName, LastName, DOB, Doctor_ID) VALUES (2002, 'Emma', 'Wilson', TO_DATE('1988-07-19', 'YYYY-MM-DD'), 201);
-- Dr. McCain's Patients (Clinic 2)
INSERT INTO Patient (Patient_ID, FirstName, LastName, DOB, Doctor_ID) VALUES (2003, 'Sam', 'Taylor', TO_DATE('1964-09-05', 'YYYY-MM-DD'), 202);


-- Map Database Users to Employees
-- Admins
INSERT INTO App_User (APP_USERNAME, USER_TYPE, EMP_ID) VALUES ('ADMINA', 'A', 1); -- Alice Smith, Clinic 1
INSERT INTO App_User (APP_USERNAME, USER_TYPE, EMP_ID) VALUES ('ADMINB', 'A', 1); -- (Assuming AdminB is also at Clinic 1 for this test)
INSERT INTO App_User (APP_USERNAME, USER_TYPE, EMP_ID) VALUES ('ADMINS', 'A', 2); -- (Assuming AdminS is at Clinic 2)
INSERT INTO App_User (APP_USERNAME, USER_TYPE, EMP_ID) VALUES ('ADMINT', 'A', 2); -- (Assuming AdminT is at Clinic 2)

-- Doctors
INSERT INTO App_User (APP_USERNAME, USER_TYPE, EMP_ID) VALUES ('RDAVISON', 'D', 101); -- Dr. Davison, Clinic 1
INSERT INTO App_User (APP_USERNAME, USER_TYPE, EMP_ID) VALUES ('SSEYMOUR', 'D', 102); -- Dr. Seymour, Clinic 1
INSERT INTO App_User (APP_USERNAME, USER_TYPE, EMP_ID) VALUES ('THEMMING', 'D', 201); -- Dr. Hemming, Clinic 2
INSERT INTO App_User (APP_USERNAME, USER_TYPE, EMP_ID) VALUES ('KMCCAIN', 'D', 202); -- Dr. McCain, Clinic 2

COMMIT;

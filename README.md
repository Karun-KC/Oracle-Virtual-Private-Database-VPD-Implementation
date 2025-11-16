# Oracle-Virtual-Private-Database-VPD-Implementation
# Oracle VPD for Healthcare (HIPAA Compliance)

This project demonstrates the design and implementation of an Oracle Virtual Private Database (VPD) to enforce Role-Based Access Control (RBAC) and the principle of least privilege in a healthcare database.

The goal is to ensure data confidentiality and integrity, aligning with security requirements like those in HIPAA.

## Core Features

* **Role-Based Access Control (RBAC):** Two primary roles are created:
    * `Admin_R`: Manages hospital administration (Doctors, Clinics).
    * `Doctor_R`: Manages patient-facing data (Patients, Visits, Diagnoses).
* **Virtual Private Database (VPD):** Row-level security is implemented using `DBMS_RLS`.
* **Application Context:** A secure context (`Clinic_Context`) is used to store session data (like `UserID`, `ClinicID`) upon user login.
* **Security Policies:**
    * **Admins** can only see and manage records associated with their *own* clinic.
    * **Doctors** can only see and manage patients assigned to them.

## Project Files

1.  **`1_schema_and_data.sql`**: The SQL script to create all necessary tables (`Clinic`, `Doctor`, `Patient`, `App_User`, etc.) and insert sample data for testing.
2.  **`2_vpd_implementation.sql`**: The main solution script. This file creates the roles, users, triggers, security functions, and VPD policies.

## How to Run

1.  **Run Schema Script:** Connect to your Oracle database as a DBA user (e.g., `SYS` or `DBA643`) and run `1_schema_and_data.sql`. This will build the database structure.
2.  **Run VPD Script:** In the same session, run `2_vpd_implementation.sql`. This will apply all the security layers.
3.  **Test the Policies:**
    * Log in as one of the new users (e.g., `CONNECT RDavison/RDavison`).
    * Run a query like `SELECT * FROM Patient;`.
    * You will only see the patients associated with Dr. Davison, not all patients in the database.

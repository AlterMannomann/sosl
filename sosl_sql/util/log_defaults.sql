-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
SET TRIMSPOOL ON
SET LINESIZE 9999
SET NEWPAGE NONE
SET PAGESIZE 9999
-- limit CLOB display to 4000 char
SET LONG 4000
SET LONGCHUNKSIZE 4000
SET NULL 'NULL'
SET SQLBLANKLINES ON
SET SERVEROUTPUT ON SIZE UNLIMITED
-- avoid that recommendation are listed as errors
ALTER SESSION SET PLSQL_WARNINGS='DISABLE:INFORMATIONAL', 'DISABLE:PERFORMANCE';
-- DO NOT use WHENEVER xxxERROR EXIT in scripts, fetch the errors instead from defined ERRORLOG table

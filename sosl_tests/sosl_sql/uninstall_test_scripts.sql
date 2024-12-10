-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
CLEAR COLUMNS
COLUMN IDENT NEW_VAL IDENT
SELECT 'sosl_uninstall' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') AS IDENT
  FROM dual;
-- error logging to default SPERRORLOG, first entry only to guarantee that SPERRORLOG is created
SET ERRORLOGGING ON
-- try again with identifier
SET ERRORLOGGING ON IDENTIFIER &IDENT
-- get executor SOSL
COLUMN SOSL_EXECUTOR_ID NEW_VAL SOSL_EXECUTOR_ID
SELECT executor_id AS SOSL_EXECUTOR_ID
  FROM sosl_executor_definition
 WHERE executor_name = 'SOSL'
;
-- delete from run_queue
DELETE FROM sosl_run_queue WHERE executor_id = &SOSL_EXECUTOR_ID;
-- delete from SOSL_IF_SCRIPT only scripts from directory /sosl_tests/sosl_sql
DELETE FROM sosl_if_script WHERE script_name LIKE '%sosl\_tests_sosl_sql%' ESCAPE '\';
-- delete from sosl_executor_definition
DELETE FROM sosl_executor_definition WHERE executor_id = &SOSL_EXECUTOR_ID;
COMMIT;
SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET HEADING OFF
-- check errors and display them, if so
COLUMN EXITCODE NEW_VAL EXITCODE
SELECT CASE
         WHEN COUNT(*) = 0
         THEN 'SUCCESS - no errors found during uninstall'
         ELSE 'ERROR - uninstall script has errors'
       END AS info
     , CASE
         WHEN COUNT(*) = 0
         THEN 0
         ELSE -1
       END AS EXITCODE
  FROM sperrorlog
 WHERE identifier = '&IDENT'
;
SELECT TO_CHAR(SUBSTR(message, 1, 2000)) AS error_messages
  FROM sperrorlog
 WHERE identifier = '&IDENT'
;

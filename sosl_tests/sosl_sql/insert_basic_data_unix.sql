-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.

-- default executor
CLEAR COLUMNS
COLUMN IDENT NEW_VAL IDENT
SELECT 'sosl_testdata' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') AS IDENT
  FROM dual;
-- error logging to default SPERRORLOG, first entry only to guarantee that SPERRORLOG is created
SET ERRORLOGGING ON
-- try again with identifier
SET ERRORLOGGING ON IDENTIFIER &IDENT
COLUMN NEW_EXECUTOR_ID NEW_VAL NEW_EXECUTOR_ID
SELECT sosl_api.create_executor( 'SOSL'
                                 , 'sosl'
                                 , 'sosl_if.has_scripts'
                                 , 'sosl_if.get_next_script'
                                 , 'sosl_if.set_script_status'
                                 , '../sosl_templates/sosl_login.cfg'
                                 , 1
                                 , 'sosl_if.send_mail'
                                 , 'Internal SOSL executor for testing and demonstration purposes. Only a simple set of ordered scripts supported.'
                                 ) AS NEW_EXECUTOR_ID
  FROM dual
;

SELECT sosl_api.activate_executor(&NEW_EXECUTOR_ID) FROM dual;
SELECT sosl_api.set_executor_reviewed(&NEW_EXECUTOR_ID) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_hello_world.sql', &NEW_EXECUTOR_ID, 1, 1) FROM dual;
-- first group, 10 1 minute scripts, probably reaching max parallel
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1minute.sql', &NEW_EXECUTOR_ID, 2, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1minute.sql', &NEW_EXECUTOR_ID, 2, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1minute.sql', &NEW_EXECUTOR_ID, 2, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1minute.sql', &NEW_EXECUTOR_ID, 2, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1minute.sql', &NEW_EXECUTOR_ID, 2, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1minute.sql', &NEW_EXECUTOR_ID, 2, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1minute.sql', &NEW_EXECUTOR_ID, 2, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1minute.sql', &NEW_EXECUTOR_ID, 2, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1minute.sql', &NEW_EXECUTOR_ID, 2, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1minute.sql', &NEW_EXECUTOR_ID, 2, 1) FROM dual;
-- second group, 10 10 minute scripts, should reach max parallel
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_10minutes.sql', &NEW_EXECUTOR_ID, 3, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_10minutes.sql', &NEW_EXECUTOR_ID, 3, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_10minutes.sql', &NEW_EXECUTOR_ID, 3, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_10minutes.sql', &NEW_EXECUTOR_ID, 3, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_10minutes.sql', &NEW_EXECUTOR_ID, 3, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_10minutes.sql', &NEW_EXECUTOR_ID, 3, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_10minutes.sql', &NEW_EXECUTOR_ID, 3, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_10minutes.sql', &NEW_EXECUTOR_ID, 3, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_10minutes.sql', &NEW_EXECUTOR_ID, 3, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_10minutes.sql', &NEW_EXECUTOR_ID, 3, 1) FROM dual;
-- test the 1 hour script
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1hour.sql', &NEW_EXECUTOR_ID, 4, 1) FROM dual;
-- test the error script
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_error.sql', &NEW_EXECUTOR_ID, 5, 1) FROM dual;
-- add some scripts after the error
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_1minute.sql', &NEW_EXECUTOR_ID, 6, 1) FROM dual;
SELECT sosl_api.add_script('../sosl_tests/sosl_sql/sosl_test_10minutes.sql', &NEW_EXECUTOR_ID, 6, 1) FROM dual;
SET ECHO OFF
SET VERIFY OFF
SET FEEDBACK OFF
SET HEADING OFF
-- check errors and display them, if so
COLUMN EXITCODE NEW_VAL EXITCODE
SELECT CASE
         WHEN COUNT(*) = 0
         THEN 'SUCCESS - no errors found during install of test data'
         ELSE 'ERROR - test data install script has errors'
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

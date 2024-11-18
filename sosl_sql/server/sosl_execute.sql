-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Executes a given script with the given login configuration from the executor. As we do not know the user
-- executing this script, all sosl calls must be fully qualified.??? If sosl user is not named SOSL???
-- parameter 1: The run id of the script file to execute
-- parameter 2: A unique identifier for the error logging
-- parameter 3: The OS timestamp as it may differ from the database timestamp
-- parameter 4: The name and (relative) path of the logfile to write to
-- parameter 5: GUID of the process
-- parameter 6: SOSL schema to prefix sosl packages and functions
-- return: EXITCODE 0 on success, -1 on errors
SET ECHO OFF
CLEAR COLUMNS
SET ERRORLOGGING ON TABLE sosl.soslerrorlog IDENTIFIER &2
-- get basic data by RUN_ID, set parameter fallbacks and set script to running
@@..\sosl_sql\util\log_silent.sql
-- define variables with names for the given parameters
COLUMN SET_RUNNING_RESULT NEW_VAL SET_RUNNING_RESULT
COLUMN SCRIPT_FILE NEW_VAL SCRIPT_FILE
COLUMN SCRIPT_SCHEMA NEW_VAL SCRIPT_SCHEMA
COLUMN SOSL_SCHEMA NEW_VAL SOSL_SCHEMA
COLUMN OS_TIME NEW_VAL OS_TIME
COLUMN SOSL_LOG NEW_VAL SOSL_LOG
COLUMN GUID NEW_VAL GUID
COLUMN RUN_ID NEW_VAL RUN_ID
COLUMN SOSL_ID NEW_VAL SOSL_ID
SELECT TRIM(TO_CHAR(NVL(&6..sosl_server.set_script_running(&1), -1))) AS SET_RUNNING_RESULT
     , TRIM(&6..sosl_server.get_script_file(&1))                      AS SCRIPT_FILE
     , TRIM(&6..sosl_server.get_script_schema(&1))                    AS SCRIPT_SCHEMA
     , TRIM('&6')                                                     AS SOSL_SCHEMA
     , TRIM('&3')                                                     AS OS_TIME
     , TRIM('&4')                                                     AS SOSL_LOG
     , TRIM('&5')                                                     AS GUID
     , TRIM(TO_CHAR(NVL(&1, -1)))                                     AS RUN_ID
     , TRIM('&2')                                                     AS SOSL_ID
  FROM dual;
-- check for errors
COLUMN PARAM_ERROR NEW_VAL PARAM_ERROR
SELECT CASE
         WHEN COUNT(*) > 0
           OR NVL(&SET_RUNNING_RESULT, -1) = -1
           OR NVL(&RUN_ID, -1) = -1
         THEN -1
         ELSE 0
       END AS PARAM_ERROR
  FROM &SOSL_SCHEMA..soslerrorlog
 WHERE identifier = '&SOSL_ID';
-- log current result
SPOOL &4 APPEND
SELECT CASE
         WHEN &PARAM_ERROR = -1
         THEN '&OS_TIME. ' ||
              &6..sosl_server.error_log( p_srv_caller => '../sosl_sql/server/sosl_execute.sql'
                                       , p_srv_message => 'Error fetching parameters and setting RUNNING state for &SCRIPT_FILE. and run id &RUN_ID.'
                                       , p_identifier => '&SOSL_ID'
                                       , p_local_log => '&SOSL_LOG'
                                       , p_srv_guid => '&GUID'
                                       )
         ELSE '&OS_TIME. ' ||
              &6..sosl_server.success_log( p_srv_caller => '../sosl_sql/server/sosl_execute.sql'
                                         , p_srv_message => 'Successfully fetched parameters and set RUNNING state for &SCRIPT_FILE. and run id &RUN_ID.'
                                         , p_identifier => '&SOSL_ID'
                                         , p_local_log => '&SOSL_LOG'
                                         , p_srv_guid => '&GUID'
                                         )
         END AS info
  FROM dual;
SPOOL OFF
-- define logging details, show everything for unknown scripts
@@..\sosl_sql\util\log_visible.sql
-- set current session to defined schema
ALTER SESSION SET CURRENT_SCHEMA=&SCRIPT_SCHEMA;
-- execute given script
@@&SCRIPT_FILE
-- check for errors and log the result
COLUMN EXITCODE NEW_VAL EXITCODE
SELECT CASE
         WHEN COUNT(*) > 0
         THEN -1
         ELSE 0
       END AS EXITCODE
  FROM &SOSL_SCHEMA..soslerrorlog
 WHERE identifier = '&SOSL_ID';
-- update script state
@@..\sosl_sql\util\log_silent.sql
SELECT CASE
         WHEN &EXITCODE = -1
         THEN &SOSL_SCHEMA..sosl_server.set_script_error(&RUN_ID)
         ELSE &SOSL_SCHEMA..sosl_server.set_script_finished(&RUN_ID)
       END AS info
  FROM dual;
-- write log
SPOOL &4 APPEND
SELECT CASE
         WHEN &EXITCODE = -1
         THEN '&OS_TIME. ' ||
              &SCRIPT_SCHEMA..sosl_server.error_log( p_srv_caller => '../sosl_sql/server/sosl_execute.sql'
                                                   , p_srv_message => 'Error calling script &SCRIPT_FILE.'
                                                   , p_identifier => '&SOSL_ID'
                                                   , p_local_log => '&SOSL_LOG'
                                                   , p_srv_guid => '&GUID'
                                                   )
         ELSE '&OS_TIME. ' ||
              &SCRIPT_SCHEMA..sosl_server.success_log( p_srv_caller => '../sosl_sql/server/sosl_execute.sql'
                                                     , p_srv_message => 'Successfully executed: &SCRIPT_FILE.'
                                                     , p_identifier => '&SOSL_ID'
                                                     , p_local_log => '&SOSL_LOG'
                                                     , p_srv_guid => '&GUID'
                                                     )
       END AS info
  FROM dual;
SPOOL OFF
EXIT &EXITCODE

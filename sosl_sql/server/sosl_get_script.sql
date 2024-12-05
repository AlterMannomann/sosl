-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Gets the script filename associated to the run id
-- parameter 1: A unique identifier for the error logging
-- parameter 2: The OS timestamp as it may differ from the database timestamp
-- parameter 3: The RUN_ID for the script
-- parameter 4: The name and (relative) path of the temporary file to write to
-- parameter 5: The name and (relative) path of the logfile to write to
-- parameter 6: GUID of the process
-- return: EXITCODE > 0 (equals sosl_server.get_next_script return value) on success, -1 on errors
SET ECHO OFF
-- define logging details, calling util relative to run directory
@@../sosl_sql/util/log_silent.sql
SET ERRORLOGGING ON TABLE soslerrorlog IDENTIFIER &1
CLEAR COLUMNS
COLUMN SCRIPT_FILE NEW_VAL SCRIPT_FILE
SPOOL &4
SELECT TRIM(sosl_server.get_script_file(&3)) AS SCRIPT_FILE
  FROM dual
;
SPOOL OFF
-- write log file
SPOOL &5 APPEND
SELECT CASE
         WHEN '&SCRIPT_FILE' = '-1'
         THEN '&2. ' ||
              sosl_server.error_log( p_srv_caller => '../sosl_sql/server/sosl_get_script.sql'
                                   , p_srv_message => 'Error calling sosl_server.get_script_file with run id &3.'
                                   , p_identifier => '&1'
                                   , p_local_log => '&5'
                                   , p_srv_guid => '&6'
                                   )
         ELSE '&2. ' ||
              sosl_server.success_log( p_srv_caller => '../sosl_sql/server/sosl_get_script.sql'
                                     , p_srv_message => 'Fetched sosl_server.get_script_file: &SCRIPT_FILE. with run id &3.'
                                     , p_identifier => '&1'
                                     , p_local_log => '&5'
                                     , p_srv_guid => '&6'
                                     )
       END AS info
  FROM dual;
SPOOL OFF
COLUMN EXITCODE NEW_VAL EXITCODE
SELECT CASE
         WHEN COUNT(*) > 0
           OR '&SCRIPT_FILE' = '-1'
         THEN -1
         ELSE 0
       END AS EXITCODE
  FROM soslerrorlog
 WHERE identifier = '&1';
EXIT &EXITCODE

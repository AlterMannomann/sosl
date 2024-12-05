-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Fetches a new run id and sets the script for that run id to STARTED
-- parameter 1: A unique identifier for the error logging
-- parameter 2: The OS timestamp as it may differ from the database timestamp
-- parameter 3: The name and (relative) path of the temporary file to write to
-- parameter 4: The name and (relative) path of the logfile to write to
-- parameter 5: GUID of the process
-- return: EXITCODE > 0 (equals sosl_server.get_next_script return value) on success, -1 on errors
SET ECHO OFF
-- define logging details, calling util relative to run directory
@@../sosl_sql/util/log_silent.sql
SET ERRORLOGGING ON TABLE soslerrorlog IDENTIFIER &1
CLEAR COLUMNS
COLUMN RUN_ID NEW_VAL RUN_ID
-- numeric values have to be prepared as trimmed char to be saved without leading spaces if reading from a written temporary file
SPOOL &3
SELECT TRIM(TO_CHAR(sosl_server.get_next_script)) AS RUN_ID
  FROM dual
;
SPOOL OFF
-- set process started
COLUMN SCRIPT_STARTED NEW_VAL SCRIPT_STARTED
SELECT TRIM(TO_CHAR(sosl_server.set_script_started(&RUN_ID))) AS SCRIPT_STARTED
  FROM dual;
-- write log file
SPOOL &4 APPEND
SELECT CASE
         WHEN &RUN_ID = -1
           OR &SCRIPT_STARTED = -1
         THEN '&2. ' ||
              sosl_server.error_log( p_srv_caller => '../sosl_sql/server/sosl_get_next_run_id.sql'
                                   , p_srv_message => 'Error calling sosl_server.get_next_script run id: &RUN_ID. or sosl_server.set_script_started: &SCRIPT_STARTED.'
                                   , p_identifier => '&1'
                                   , p_local_log => '&4'
                                   , p_srv_guid => '&5'
                                   )
         ELSE '&2. ' ||
              sosl_server.success_log( p_srv_caller => '../sosl_sql/server/sosl_get_next_run_id.sql'
                                     , p_srv_message => 'Fetched sosl_server.get_next_script run id: &RUN_ID. and set script to STARTED'
                                     , p_identifier => '&1'
                                     , p_local_log => '&4'
                                     , p_srv_guid => '&5'
                                     )
       END AS info
  FROM dual;
SPOOL OFF
COLUMN EXITCODE NEW_VAL EXITCODE
SELECT CASE
         WHEN COUNT(*) > 0
           OR &RUN_ID = -1
           OR &SCRIPT_STARTED = -1
         THEN -1
         ELSE 0
       END AS EXITCODE
  FROM soslerrorlog
 WHERE identifier = '&1';
EXIT &EXITCODE
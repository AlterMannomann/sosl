-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- parameter 1: A unique identifier for the error logging
-- parameter 2: The OS timestamp as it may differ from the database timestamp
-- parameter 3: The name and (relative) path of the temporary file to write to
-- parameter 4: The name and (relative) path of the logfile to write to
-- parameter 5: GUID of the process
-- return: EXITCODE >= 0 (equals sosl_server.has_scripts return value) on success, -1 on errors
SET ECHO OFF
-- define logging details, calling util relative to run directory
@@..\sosl_sql\util\log_silent.sql
SET ERRORLOGGING ON TABLE soslerrorlog IDENTIFIER &1
CLEAR COLUMNS
COLUMN SCRIPT_COUNT NEW_VAL SCRIPT_COUNT
-- numeric values have to be prepared as trimmed char to be saved without leading spaces if reading from a written temporary file
SPOOL &3
SELECT TRIM(TO_CHAR(sosl_server.has_scripts)) AS SCRIPT_COUNT
  FROM dual
;
SPOOL OFF
-- write log file
SPOOL &4 APPEND
SELECT CASE
         WHEN &SCRIPT_COUNT < 0
         THEN '&2. ' ||
              sosl_server.error_log( p_srv_caller => '../sosl_sql/server/sosl_has_scripts.sql'
                                   , p_srv_message => 'Error calling sosl_server.has_scripts: &SCRIPT_COUNT.'
                                   , p_identifier => '&1'
                                   , p_local_log => '&4'
                                   , p_srv_guid => '&5'
                                   )
         ELSE '&2. ' ||
              sosl_server.success_log( p_srv_caller => '../sosl_sql/server/sosl_has_scripts.sql'
                                     , p_srv_message => 'Fetched sosl_server.has_scripts: &SCRIPT_COUNT.'
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
           OR &SCRIPT_COUNT < 0
         THEN -1
         ELSE 0
       END AS EXITCODE
  FROM soslerrorlog
 WHERE identifier = '&1';
EXIT &EXITCODE
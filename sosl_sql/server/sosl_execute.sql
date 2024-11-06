-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Executes a given script with the given login configuration from the executor
-- parameter 1: The script file name including relative or absolute path to execute
-- parameter 2: The db schema to set as current schema for the script
-- parameter 3: A unique identifier for the error logging
-- parameter 4: The OS timestamp as it may differ from the database timestamp
-- parameter 5: The name and (relative) path of the logfile to write to
-- parameter 6: GUID of the process
-- return: EXITCODE 0 on success, -1 on errors
SET ECHO OFF
CLEAR COLUMNS
-- define logging details, show everything for unknown scripts
@@..\sosl_sql\util\log_visible.sql
SET ERRORLOGGING ON TABLE soslerrorlog IDENTIFIER &3
-- set current session to defined schema
ALTER SESSION SET CURRENT_SCHEMA=&2;
-- execute given script
@@&1
-- check for errors and log the result
COLUMN EXITCODE NEW_VAL EXITCODE
SELECT CASE
         WHEN COUNT(*) > 0
         THEN -1
         ELSE 0
       END AS EXITCODE
  FROM soslerrorlog
 WHERE identifier = '&3';
-- write log
@@..\sosl_sql\util\log_silent.sql
SPOOL &5 APPEND
SELECT CASE
         WHEN &EXITCODE = -1
         THEN '&4. ' ||
              sosl_server.error_log( p_srv_caller => '../sosl_sql/server/sosl_execute.sql'
                                   , p_srv_message => 'Error calling script &1.'
                                   , p_identifier => '&3'
                                   , p_local_log => '&5'
                                   , p_srv_guid => '&6'
                                   )
         ELSE '&4. ' ||
              sosl_server.info_log( p_srv_caller => '../sosl_sql/server/sosl_execute.sql'
                                  , p_srv_message => 'Successfully executed: &1.'
                                  , p_identifier => '&3'
                                  , p_local_log => '&5'
                                  , p_srv_guid => '&6'
                                  )
       END AS info
  FROM dual;
SPOOL OFF
EXIT &EXITCODE

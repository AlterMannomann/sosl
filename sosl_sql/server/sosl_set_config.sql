-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- parameter 1: A unique identifier for the error logging
-- parameter 2: The OS timestamp as it may differ from the database timestamp
-- parameter 3: The name of the configuration parameter
-- parameter 4: The configuration value to write for given parameter
-- parameter 5: The name and (relative) path of the logfile to write to
-- parameter 6: GUID of the process
-- return: EXITCODE 0 on success, -1 on errors
SET ECHO OFF
-- define logging details, calling util relative to run directory
@@..\sosl_sql\util\log_silent.sql
SET ERRORLOGGING ON TABLE soslerrorlog IDENTIFIER &1
CLEAR COLUMNS
COLUMN SET_SUCCESS NEW_VAL SET_SUCCESS
SELECT sosl_server.set_config('&3', '&4') AS SET_SUCCESS
  FROM dual
;
-- write log file
SPOOL &5 APPEND
SELECT CASE
         WHEN &SET_SUCCESS = 0
         THEN '&2. ' ||
              sosl_server.success_log( p_srv_caller => '../sosl_sql/server/sosl_set_config.sql'
                                     , p_srv_message => 'Set parameter &3. to value: &4.'
                                     , p_identifier => '&1'
                                     , p_local_log => '&5'
                                     , p_srv_guid => '&6'
                                     )
         ELSE '&2. ' ||
              sosl_server.error_log( p_srv_caller => '../sosl_sql/server/sosl_set_config.sql'
                                   , p_srv_message => 'Error Set parameter &3. to value: &4.'
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
           OR &SET_SUCCESS != 0
         THEN -1
         ELSE 0
       END AS EXITCODE
  FROM soslerrorlog
 WHERE identifier = '&1';
EXIT &EXITCODE
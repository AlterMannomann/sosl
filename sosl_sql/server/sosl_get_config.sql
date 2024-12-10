-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- parameter 1: A unique identifier for the error logging
-- parameter 2: The OS timestamp as it may differ from the database timestamp
-- parameter 3: The name of the configuration parameter
-- parameter 4: The name and (relative) path of the temporary file to write to
-- parameter 5: The name and (relative) path of the logfile to write to
-- parameter 6: GUID of the process
-- return: Temporary file containing the result of the get operation
-- return: EXITCODE 0 on success, -1 on errors
SET ECHO OFF
-- define logging details, calling util relative to run directory
@@../sosl_sql/util/log_silent.sql
SET ERRORLOGGING ON TABLE soslerrorlog IDENTIFIER &1
CLEAR COLUMNS
COLUMN CONF_VAL NEW_VAL CONF_VAL
SPOOL &4
-- write result to temporary file
SELECT sosl_server.get_config('&3') AS CONF_VAL
  FROM dual
;
SPOOL OFF
-- write log file
SPOOL &5 APPEND
SELECT CASE
         WHEN '&CONF_VAL' = '-1'
          AND '&3' NOT IN ('SOSL_START_JOBS', 'SOSL_STOP_JOBS') -- -1 is valid for disabling the timeframe
         THEN '&2. ' ||
              sosl_server.error_log( p_srv_caller => '../sosl_sql/server/sosl_set_config.sql'
                                   , p_srv_message => 'Error parameter &3. with value: &CONF_VAL.'
                                   , p_identifier => '&1'
                                   , p_local_log => '&5'
                                   , p_srv_guid => '&6'
                                   )
         ELSE '&2. ' ||
              sosl_server.success_log( p_srv_caller => '../sosl_sql/server/sosl_get_config.sql'
                                     , p_srv_message => 'Get parameter &3. with value: &CONF_VAL.'
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
         THEN -1
         ELSE 0
       END AS EXITCODE
  FROM soslerrorlog
 WHERE identifier = '&1';
EXIT &EXITCODE
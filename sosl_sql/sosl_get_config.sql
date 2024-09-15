-- parameter 1: A unique identifier for the error logging
-- parameter 2: The OS timestamp as it may differ from the database timestamp
-- parameter 3: The name of the configuration parameter
-- parameter 4: The name and (relative) path of the temporary file to write to
-- parameter 5: The name and (relative) path of the logfile to write to
SET ECHO OFF
-- define logging details, calling util relative to run directory
@@..\sosl_sql\util\log_silent.sql
SET ERRORLOGGING ON TABLE soslerrorlog IDENTIFIER &1
CLEAR COLUMNS
COLUMN CONF_VAL NEW_VAL CONF_VAL
SPOOL &4
-- write result to temporary file
SELECT config_value AS CONF_VAL
  FROM sosl_config
 WHERE config_name = '&3'
;
SPOOL OFF
-- write log file
SPOOL &5 APPEND
SELECT '&2. Get parameter &3. with value: &CONF_VAL.' AS info
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
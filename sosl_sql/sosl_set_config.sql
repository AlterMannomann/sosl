-- parameter 1: A unique identifier for the error logging
-- parameter 2: The OS timestamp as it may differ from the database timestamp
-- parameter 3: The name of the configuration parameter
-- parameter 4: The configuration value to write for given parameter
-- parameter 5: The name and (relative) path of the logfile to write to
SET ECHO OFF
-- define logging details, calling util relative to run directory
@@..\sosl_sql\util\log_silent.sql
SET ERRORLOGGING ON TABLE soslerrorlog IDENTIFIER &1
UPDATE sosl_config
   SET config_value = '&4'
 WHERE config_name = '&3'
;
COMMIT;
-- write log file
SPOOL &5 APPEND
SELECT '&2. Set parameter &3. to value: &4.' AS info
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
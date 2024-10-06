-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- parameter 1: A unique identifier for the error logging
-- parameter 2: The OS timestamp as it may differ from the database timestamp
-- parameter 3: The name and (relative) path of the logfile to write to
SET ECHO OFF
-- define logging details, calling util relative to run directory
@@..\sosl_sql\util\log_silent.sql
SET ERRORLOGGING ON TABLE soslerrorlog IDENTIFIER &1
SPOOL &3 APPEND
-- format output in log style, date format limited to possible OS format
SELECT '&2. Simple Oracle Script Loader server started' ||
       ' db name: ' || TRIM(SYS_CONTEXT('USERENV', 'DB_NAME')) ||
       ' OS user: ' || TRIM(SYS_CONTEXT('USERENV', 'OS_USER')) ||
       ' DB user: ' || TRIM(SYS_CONTEXT('USERENV', 'CURRENT_USER')) ||
       ' schema: ' || TRIM(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')) AS info
  FROM dual
;
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
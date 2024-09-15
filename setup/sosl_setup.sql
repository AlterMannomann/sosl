-- setup the SOSL environment
@@../sosl_sql/util/log_visible.sql
CLEAR COLUMNS
COLUMN IDENT NEW_VAL IDENT
SELECT 'sosl_setup' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') AS IDENT
  FROM dual;
-- error logging to default SPERRORLOG, first entry only to guarantee that SPERRORLOG is created
SET ERRORLOGGING ON
-- try again with identifier
SET ERRORLOGGING ON IDENTIFIER &IDENT
SPOOL logs/sosl_setup.log
@@../sosl_ddl/tables/soslerrorlog.sql
@@../sosl_ddl/tables/sosl_config.sql
@@../sosl_ddl/tables/sosl_scripts.sql
@@../sosl_sql/util/log_silent.sql
-- check errors and display them, if so
COLUMN EXITCODE NEW_VAL EXITCODE
SELECT CASE
         WHEN COUNT(*) = 0
         THEN 'SUCCESS - no errors found during setup'
         ELSE 'ERROR - script has errors'
       END AS info
     , CASE
         WHEN COUNT(*) = 0
         THEN 0
         ELSE -1
       END AS EXITCODE
  FROM sperrorlog
 WHERE identifier = '&IDENT'
;
SELECT TO_CHAR(SUBSTR(message, 1, 2000)) AS error_messages
  FROM sperrorlog
 WHERE identifier = '&IDENT'
;
SPOOL OFF
-- uncomment in SQL Developer to keep the session, otherwise the session is closed
EXIT &EXITCODE
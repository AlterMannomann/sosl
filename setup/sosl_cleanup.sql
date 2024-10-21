-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- no checks if table exists, cleanup SOSL objects
@@../sosl_sql/util/log_visible.sql
CLEAR COLUMNS
COLUMN IDENT NEW_VAL IDENT
SELECT 'sosl_cleanup' || TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') AS IDENT
  FROM dual;
-- error logging to default SPERRORLOG, first entry only to guarantee that SPERRORLOG is created
SET ERRORLOGGING ON
-- try again with identifier
SET ERRORLOGGING ON IDENTIFIER &IDENT
-- ==============UNINSTALL start==============
SPOOL logs/sosl_cleanup.log
-- packages and functions
@@../sosl_ddl/functions/drop/drop_has_scripts.sql
@@../sosl_ddl/packages/drop/drop_sosl_pkb.sql
@@../sosl_ddl/packages/drop/drop_sosl_pks.sql
@@../sosl_ddl/packages/drop/drop_sosl_api_pkb.sql
@@../sosl_ddl/packages/drop/drop_sosl_api_pks.sql
@@../sosl_ddl/packages/drop/drop_sosl_log_pkb.sql
@@../sosl_ddl/packages/drop/drop_sosl_log_pks.sql
@@../sosl_ddl/packages/drop/drop_sosl_sys_pkb.sql
@@../sosl_ddl/packages/drop/drop_sosl_sys_pks.sql
-- view objects
-- table objects
@@../sosl_ddl/tables/drop/drop_sosl_script.sql
@@../sosl_ddl/tables/drop/drop_sosl_executor.sql
@@../sosl_ddl/tables/drop/drop_sosl_config.sql
@@../sosl_ddl/tables/drop/drop_sosl_server_log.sql
@@../sosl_ddl/tables/drop/drop_soslerrorlog.sql
-- queues
@@../sosl_ddl/queues/drop/drop_sosl_script_queue.sql
-- ==============UNINSTALL done==============
@@../sosl_sql/util/log_silent.sql
-- check errors and display them, if so
COLUMN EXITCODE NEW_VAL EXITCODE
SELECT CASE
         WHEN COUNT(*) = 0
         THEN 'SUCCESS - no errors found during cleanup'
         ELSE 'ERROR - cleanup script has errors'
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
SELECT 'SPERRORLOG is not deleted, as we do not know if schema is exclusive. You may drop it manually with: DROP TABLE sperrorlog PURGE;' AS info FROM dual;
SPOOL OFF
-- uncomment in SQL Developer to keep the session, otherwise the session is closed
EXIT &EXITCODE
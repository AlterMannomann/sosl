-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
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
-- ==============INSTALL start==============
SPOOL logs/sosl_setup.log
-- roles
@@../sosl_ddl/roles/create_roles.sql
-- types
@@../sosl_ddl/types/sosl_payload.sql
-- SQLPlus error logging table
@@../sosl_ddl/tables/soslerrorlog.sql
-- logging table
@@../sosl_ddl/tables/sosl_server_log.sql
-- SOSL objects basic objects
@@../sosl_ddl/tables/sosl_config.sql
@@../sosl_ddl/tables/sosl_executor.sql
@@../sosl_ddl/tables/sosl_run_queue.sql
-- internal interface objects using the API
@@../sosl_ddl/tables/sosl_if_script.sql
-- package with no dependency on SOSL objects
@@../sosl_ddl/packages/sosl_constants.pks
@@../sosl_ddl/packages/sosl_constants.pkb
-- logging package
@@../sosl_ddl/packages/sosl_log.pks
@@../sosl_ddl/packages/sosl_log.pkb
-- util package
@@../sosl_ddl/packages/sosl_util.pks
@@../sosl_ddl/packages/sosl_util.pkb
-- packages depending on SOSL objects
@@../sosl_ddl/packages/sosl_sys.pks
@@../sosl_ddl/packages/sosl_sys.pkb
@@../sosl_ddl/packages/sosl_api.pks
@@../sosl_ddl/packages/sosl_api.pkb
@@../sosl_ddl/packages/sosl_if.pks
@@../sosl_ddl/packages/sosl_if.pkb
-- table trigger using packages and tables defined
@@../sosl_ddl/trigger/sosl_server_log_trg.sql
@@../sosl_ddl/trigger/sosl_config_trg.sql
@@../sosl_ddl/trigger/sosl_executor_trg.sql
@@../sosl_ddl/trigger/sosl_run_queue_trg.sql
@@../sosl_ddl/trigger/sosl_if_script_trg.sql
-- wrapper functions
@@../sosl_ddl/functions/has_scripts.sql
-- ==============INSTALL done==============
@@../sosl_sql/util/log_silent.sql
-- check errors and display them, if so
COLUMN EXITCODE NEW_VAL EXITCODE
SELECT CASE
         WHEN COUNT(*) = 0
         THEN 'SUCCESS - no errors found during setup'
         ELSE 'ERROR - setup script has errors'
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
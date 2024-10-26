-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Use this if you want to create a specific SOSL schema in your database.
-- tested with SQLPlus and SQL Developer (execute as script)
-- you may want to adjust tablespace
@@../sosl_sql/util/log_silent.sql
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
WHENEVER OSERROR EXIT FAILURE ROLLBACK
CLEAR COLUMNS
SPOOL logs/sosl_dba_setup.log
ACCEPT SOSL_PASS CHAR PROMPT 'Password for SOSL: ' HIDE
COLUMN SOSL_MSG NEW_VAL SOSL_MSG
SET TERMOUT OFF
SELECT 'Create user/schema SOSL with a password of length ' || LENGTH('&SOSL_PASS') || '? The tablespace SOSL_TABLESPACE with 100M, data sosl.dbf is created in the default directory. Use Ctrl-C to stop the script in sqlplus, Enter to continue.' AS SOSL_MSG
  FROM dual;
SET TERMOUT ON
PAUSE &SOSL_MSG
-- define LINE_FEED by identified system
SET ECHO OFF
COLUMN LINE_FEED NEW_VAL LINE_FEED
SELECT CASE
         WHEN INSTR(process, ':') > 0
         THEN 'Running under WINDOWS'
         ELSE 'Running under UNIX'
       END AS os_info
     , CASE
         WHEN INSTR(process, ':') > 0
         THEN CHR(13) || CHR(10)
         ELSE CHR(10)
       END AS LINE_FEED
  FROM v$session
 WHERE sid    = SYS_CONTEXT('USERENV', 'SID')
   AND ROWNUM = 1
;
-- set only echo on to display statement, but not password replacement
SET ECHO ON
-- tablespace
CREATE TABLESPACE sosl_tablespace
  DATAFILE 'sosl.dbf'
    SIZE 100M
    AUTOEXTEND ON
;
-- user creation
CREATE USER sosl IDENTIFIED BY &SOSL_PASS;
-- assign tablespace
ALTER USER sosl
  DEFAULT TABLESPACE sosl_tablespace
  ACCOUNT UNLOCK;
-- quotas
ALTER USER sosl QUOTA UNLIMITED ON sosl_tablespace;
-- basic grants
GRANT CONNECT TO sosl;
GRANT RESOURCE TO sosl;
GRANT GATHER_SYSTEM_STATISTICS TO sosl;
GRANT CREATE VIEW TO sosl;
GRANT CREATE JOB TO sosl;
GRANT CREATE ROLE TO sosl;
GRANT SELECT ON v_$session TO sosl;
GRANT SELECT ON dba_role_privs TO sosl;
SET ECHO OFF
SELECT 'Creating sosl_login.cfg with current values and @soslinstance in template folder ...' AS info
  FROM dual;
SPOOL OFF
-- create a cfg file in template folder
SET ECHO OFF
SET VERIFY OFF
SET TIMING OFF
SET HEADING OFF
SET TERMOUT OFF
SET TRIMSPOOL ON
SET TRIMOUT ON
SET NEWPAGE NONE
SET RECSEP OFF
SPOOL ../sosl_templates/sosl_login.cfg
SELECT 'sosl/&SOSL_PASS.@soslinstance&LINE_FEED.' ||
       '--/--&LINE_FEED.' ||
       '--/--'
  FROM dual;
SPOOL OFF
SET TERMOUT ON
SPOOL logs/sosl_dba_setup.log APPEND
SELECT 'Executed: ' || TO_CHAR(SYSTIMESTAMP) || CHR(13) || CHR(10) ||
       'Created user SOSL with unlimited quota on' || CHR(13) || CHR(10) ||
       'tablespace SOSL_TABLESPACE, 100 MB, data file sosl.dbf' || CHR(13) || CHR(10) ||
       'Granted CREATE VIEW, CREATE JOB, CREATE ROLE, CONNECT, RESSOURCE, GATHER_SYSTEM_STATISTICS, SELECT for V$SESSION and DBA_ROLE_PRIVS' || CHR(13) || CHR(10) ||
       'by ' || SYS_CONTEXT('USERENV', 'OS_USER') || CHR(13) || CHR(10) ||
       'using ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || CHR(13) || CHR(10) ||
       'on database ' || SYS_CONTEXT('USERENV', 'DB_NAME') || CHR(13) || CHR(10) ||
       'from terminal ' || SYS_CONTEXT('USERENV', 'TERMINAL') || CHR(13) || CHR(10) ||
       'Created sosl_login.cfg with current values and @soslinstance in template folder.' || CHR(13) || CHR(10) ||
       'Map name soslinstance with TNS and move the file to the desired cfg directory.' AS info
  FROM dual;
SPOOL OFF
-- uncomment in SQL Developer to keep the session, otherwise the session is closed
EXIT



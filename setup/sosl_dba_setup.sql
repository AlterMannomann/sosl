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
GRANT CREATE VIEW TO sosl;
GRANT GATHER_SYSTEM_STATISTICS TO sosl;
GRANT CONNECT TO sosl;
GRANT RESOURCE TO sosl;
GRANT SELECT ON v_$session TO sosl;
SET ECHO OFF
SELECT 'Executed: ' || TO_CHAR(SYSTIMESTAMP) || CHR(13) || CHR(10) ||
       'Created user SOSL with unlimited quota on' || CHR(13) || CHR(10) ||
       'tablespace SOSL_TABLESPACE, 100 MB, data file sosl.dbf' || CHR(13) || CHR(10) ||
       'Granted CREATE VIEW, CONNECT, RESSOURCE, GATHER_SYSTEM_STATISTICS, V$SESSION' || CHR(13) || CHR(10) ||
       'by ' || SYS_CONTEXT ('USERENV', 'OS_USER') || CHR(13) || CHR(10) ||
       'using ' || SYS_CONTEXT ('USERENV', 'SESSION_USER') || CHR(13) || CHR(10) ||
       'on database ' || SYS_CONTEXT ('USERENV', 'DB_NAME') || CHR(13) || CHR(10) ||
       'from terminal ' || SYS_CONTEXT ('USERENV', 'TERMINAL') AS info
  FROM dual;
SPOOL OFF
-- uncomment in SQL Developer to keep the session, otherwise the session is closed
EXIT



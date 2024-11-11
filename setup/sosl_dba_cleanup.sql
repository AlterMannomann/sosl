-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- simple drop script, not checking if the objects exist
@@../sosl_sql/util/log_silent.sql
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
WHENEVER OSERROR EXIT FAILURE ROLLBACK
CLEAR COLUMNS
SPOOL logs/sosl_dba_cleanup.log
COLUMN SOSL_MSG NEW_VAL SOSL_MSG
SET TERMOUT OFF
SELECT 'Drop user/schema SOSL including tablespace SOSL_TABLESPACE and datafile? Use Ctrl-C to stop the script in sqlplus, Enter to continue.' AS SOSL_MSG
  FROM dual;
SET TERMOUT ON
PAUSE &SOSL_MSG
SET ECHO ON
DROP USER sosl CASCADE;
DROP TABLESPACE sosl_tablespace DROP QUOTA INCLUDING CONTENTS AND DATAFILES;
DROP VIEW sosl_role_privs;
DROP VIEW sosl_sessions;
-- drop SOSL roles if they still exist dynamically
SET ECHO OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
BEGIN
  FOR rec IN (SELECT 'DROP ROLE ' || role AS exec_cmd FROM dba_roles WHERE role LIKE 'SOSL%')
  LOOP
    DBMS_OUTPUT.PUT_LINE(rec.exec_cmd || ';');
    EXECUTE IMMEDIATE rec.exec_cmd;
  END LOOP;
END;
/
SELECT 'Executed: ' || TO_CHAR(SYSTIMESTAMP) || CHR(13) || CHR(10) ||
       'User SOSL dropped' || CHR(13) || CHR(10) ||
       'Tablespace SOSL_TABLESPACE and datafile dropped' || CHR(13) || CHR(10) ||
       'View SOSL_ROLE_PRIVS and SOSL_SESSIONS dropped' || CHR(13) || CHR(10) ||
       'by ' || SYS_CONTEXT('USERENV', 'OS_USER') || CHR(13) || CHR(10) ||
       'using ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || CHR(13) || CHR(10) ||
       'on database ' || SYS_CONTEXT('USERENV', 'DB_NAME') || CHR(13) || CHR(10) ||
       'from terminal ' || SYS_CONTEXT('USERENV', 'TERMINAL') AS info
  FROM dual;
SPOOL OFF
-- uncomment in SQL Developer to keep the session, otherwise the session is closed
EXIT
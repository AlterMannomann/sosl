-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
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
-- drop sosl roles
DROP ROLE sosl_admin;
DROP ROLE sosl_executor;
DROP ROLE sosl_reviewer;
DROP ROLE sosl_user;
DROP ROLE sosl_guest;
SET ECHO OFF
SELECT 'Executed: ' || TO_CHAR(SYSTIMESTAMP) || CHR(13) || CHR(10) ||
       'User SOSL dropped' || CHR(13) || CHR(10) ||
       'SOSL roles dropped' || CHR(13) || CHR(10) ||
       'Tablespace SOSL_TABLESPACE and datafile dropped' || CHR(13) || CHR(10) ||
       'by ' || SYS_CONTEXT('USERENV', 'OS_USER') || CHR(13) || CHR(10) ||
       'using ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || CHR(13) || CHR(10) ||
       'on database ' || SYS_CONTEXT('USERENV', 'DB_NAME') || CHR(13) || CHR(10) ||
       'from terminal ' || SYS_CONTEXT('USERENV', 'TERMINAL') AS info
  FROM dual;
SPOOL OFF
-- uncomment in SQL Developer to keep the session, otherwise the session is closed
EXIT
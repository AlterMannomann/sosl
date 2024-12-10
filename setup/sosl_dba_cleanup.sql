-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- Drop script to handle multiple SOSL users, will ignore drops if other users still are active on the object.
-- SOSL db user name to drop (default SOSL) - must be a user that exists
-- SOSL tablespace name to drop (default SOSL_TABLESPACE) - only dropped if noone else uses this tablespace
-- SOSL drop tablespace indicator N (no) or Y (yes), default is N - only dropped if noone else uses this tablespace
-- SOSL drop roles and views indicator N (no) or Y (yes), default is N - only dropped if noone else uses the roles and views
@@../sosl_sql/util/log_silent.sql
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
WHENEVER OSERROR EXIT FAILURE ROLLBACK
CLEAR COLUMNS
SPOOL logs/sosl_dba_cleanup.log
ACCEPT SOSL_USER CHAR DEFAULT 'SOSL' PROMPT 'SOSL DB user name to drop (default is SOSL if no value is given): '
ACCEPT SOSL_TS CHAR DEFAULT 'SOSL_TABLESPACE' PROMPT 'SOSL table space name to drop (default is SOSL_TABLESPACE if no value is given): '
ACCEPT SOSL_DROP_TS CHAR DEFAULT 'N' PROMPT 'Drop the tablespace &SOSL_TS.: Y (yes) or N (no) (default is N): '
ACCEPT SOSL_DROP_ROLES CHAR DEFAULT 'N' PROMPT 'Drop the SYS roles and views: Y (yes) or N (no) (default is N): '
COLUMN SOSL_MSG NEW_VAL SOSL_MSG
SET TERMOUT OFF
SELECT 'Drop user/schema &SOSL_USER.? Drop tablespace set to &SOSL_DROP_TS. for &SOSL_TS.. Drop SYS roles and views set to &SOSL_DROP_ROLES.. Use Ctrl-C to stop the script in sqlplus, Enter to continue.' AS SOSL_MSG
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
SET ECHO OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
-- drop objects ddepending on demand
DECLARE
  l_statement VARCHAR2(256);
  l_count     NUMBER;
BEGIN
  -- check user
  SELECT COUNT(*) INTO l_count FROM dba_users WHERE username = '&SOSL_USER';
  IF l_count = 1
  THEN
    l_statement := 'DROP USER &SOSL_USER CASCADE';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('User &SOSL_USER. does not exist');
  END IF;
  IF UPPER('&SOSL_DROP_TS') = 'Y'
  THEN
    -- does tablespace exist
    SELECT COUNT(*) INTO l_count FROM dba_tablespaces WHERE tablespace_name = '&SOSL_TS';
    IF l_count = 1
    THEN
      -- check if more than one user uses tablespace defined
      SELECT COUNT(*) INTO l_count FROM dba_users WHERE default_tablespace = '&SOSL_TS';
      IF l_count = 0
      THEN
        l_statement := 'DROP TABLESPACE &SOSL_TS. DROP QUOTA INCLUDING CONTENTS AND DATAFILES';
        DBMS_OUTPUT.PUT_LINE(l_statement || ';');
        EXECUTE IMMEDIATE l_statement;
      ELSE
        DBMS_OUTPUT.PUT_LINE('Tablespace &SOSL_TS. is assigned to other users');
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('Tablespace &SOSL_TS. does not exist');
    END IF;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Leave tablespace &SOSL_TS. untouched');
  END IF;
  IF UPPER('&SOSL_DROP_ROLES') = 'Y'
  THEN
    -- revoke grants if they exist
    SELECT COUNT(*) INTO l_count FROM dba_tab_privs WHERE grantee = '&SOSL_USER' AND table_name = 'DBA_ROLE_PRIVS';
    IF l_count = 1
    THEN
      l_statement := 'REVOKE SELECT ON dba_role_privs FROM &SOSL_USER';
      DBMS_OUTPUT.PUT_LINE(l_statement || ';');
      EXECUTE IMMEDIATE l_statement;
    ELSE
      DBMS_OUTPUT.PUT_LINE('SELECT grant on DBA_ROLE_PRIVS for &SOSL_USER. does not exist');
    END IF;
    SELECT COUNT(*) INTO l_count FROM dba_tab_privs WHERE grantee = '&SOSL_USER' AND table_name = 'GV_$SESSION';
    IF l_count = 1
    THEN
      l_statement := 'REVOKE SELECT ON gv_$session FROM &SOSL_USER';
      DBMS_OUTPUT.PUT_LINE(l_statement || ';');
      EXECUTE IMMEDIATE l_statement;
    ELSE
      DBMS_OUTPUT.PUT_LINE('SELECT grant on GV$SESSION for &SOSL_USER. does not exist');
    END IF;
    SELECT COUNT(*) INTO l_count FROM dba_tab_privs WHERE grantee = '&SOSL_USER' AND table_name = 'GV_$SQL';
    IF l_count = 1
    THEN
      l_statement := 'REVOKE SELECT ON gv_$sql FROM &SOSL_USER';
      DBMS_OUTPUT.PUT_LINE(l_statement || ';');
      EXECUTE IMMEDIATE l_statement;
    ELSE
      DBMS_OUTPUT.PUT_LINE('SELECT grant on GV$SQL for &SOSL_USER. does not exist');
    END IF;
    -- check if the SOSL roles exist
    SELECT COUNT(*) INTO l_count FROM dba_roles WHERE role LIKE 'SOSL%';
    IF l_count > 0
    THEN
      -- check if other users have this role
      SELECT COUNT(*) INTO l_count FROM dba_role_privs WHERE granted_role LIKE 'SOSL%' AND grantee != 'SYS' AND grantee NOT LIKE 'SOSL\_%' ESCAPE '\';
      IF l_count = 0
      THEN
        FOR rec IN (SELECT 'DROP ROLE ' || role AS exec_cmd FROM dba_roles WHERE role LIKE 'SOSL%')
        LOOP
          DBMS_OUTPUT.PUT_LINE(rec.exec_cmd || ';');
          EXECUTE IMMEDIATE rec.exec_cmd;
        END LOOP;
      ELSE
        DBMS_OUTPUT.PUT_LINE('SOSL roles still in use by other users, do nothing');
      END IF;
    ELSE
      DBMS_OUTPUT.PUT_LINE('No SOSL roles found');
    END IF;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Leave SYS roles and views for SOSL untouched');
  END IF;
END;
/
  WITH usr AS
       (SELECT CASE
                 WHEN COUNT(*) = 0
                 THEN 'User &SOSL_USER. dropped or does not exist'
                 ELSE 'ERROR User &SOSL_USER. still exists'
               END AS user_state
          FROM dba_users
         WHERE username = '&SOSL_USER'
       )
     , tbs AS
       (SELECT CASE
                 WHEN COUNT(*) = 0
                 THEN 'Tablespace &SOSL_TS. dropped or does not exist'
                 ELSE 'Tablespace &SOSL_TS. still in use by other users'
               END AS tbs_state
          FROM dba_tablespaces
         WHERE tablespace_name = '&SOSL_TS'
       )
     , rle AS
       (SELECT CASE
                 WHEN COUNT(*) = 0
                 THEN 'Grants on dba views revoked or do not exist'
                 ELSE 'ERROR still dba view grants for &SOSL_USER. exist'
               END AS dba_view_grants
          FROM dba_tab_privs
         WHERE grantee     = '&SOSL_USER'
           AND table_name IN ('GV_$SESSION', 'GV_$SQL', 'DBA_ROLE_PRIVS')
       )
     , srl AS
       (SELECT CASE
                 WHEN COUNT(*) = 0
                 THEN 'SOSL roles dropped or do not exist'
                 ELSE 'SOSL roles still in use by other users'
               END AS has_roles
          FROM dba_roles
         WHERE role LIKE 'SOSL%'
       )
SELECT 'Executed: ' || TO_CHAR(SYSTIMESTAMP) || '&LINE_FEED' ||
       'Status USER: ' || usr.user_state || '&LINE_FEED' ||
       'Status TABLESPACE: ' || tbs.tbs_state || '&LINE_FEED' ||
       'Status DBA view grants: ' || rle.dba_view_grants || '&LINE_FEED' ||
       'Status ROLES: ' || srl.has_roles || '&LINE_FEED' ||
       'by ' || SYS_CONTEXT('USERENV', 'OS_USER') || '&LINE_FEED' ||
       'using ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || '&LINE_FEED' ||
       'on database ' || SYS_CONTEXT('USERENV', 'DB_NAME') || '&LINE_FEED' ||
       'from terminal ' || SYS_CONTEXT('USERENV', 'TERMINAL') AS info
  FROM usr
 CROSS JOIN tbs
 CROSS JOIN rle
 CROSS JOIN srl
;
SPOOL OFF
-- uncomment in SQL Developer to keep the session, otherwise the session is closed
EXIT
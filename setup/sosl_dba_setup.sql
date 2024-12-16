-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- SOSL create script to handle multiple SOSL users. Creates a specific SOSL schema in your database with own definitions.
-- Tested with SQLPlus and SQL Developer. Script must be called/opened from the git directory where this script resides.
-- The tablespace data file given is ignored, if the tablespace already exists.
-- Requires:
-- SOSL db user name (default SOSL) - must be a user that does not exist yet
-- SOSL db user password - mandatory
-- SOSL tablespace name (default SOSL_TABLESPACE)
-- SOSL tablespace data file name (sosl.dbf without any path, if path is given must match Oracle paths for data files)
-- SOSL login file (default ../sosl_templates/sosl_login.cfg) - local path must exist
-- SOSL server or tns name (default SOSLINSTANCE) - must be a valid server or tns name
@@../sosl_sql/util/log_silent.sql
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
WHENEVER OSERROR EXIT FAILURE ROLLBACK
CLEAR COLUMNS
SPOOL logs/sosl_dba_setup.log
-- define LINE_FEED by identified system
COLUMN LINE_FEED NEW_VAL LINE_FEED
SELECT CASE
         WHEN INSTR(process, ':') > 0
         THEN 'Running under WINDOWS'
         ELSE 'Running under UNIX'
       END AS os_info
     , CHR(10) AS LINE_FEED
  FROM v$session
 WHERE sid    = SYS_CONTEXT('USERENV', 'SID')
   AND ROWNUM = 1
;
ACCEPT SOSL_USER CHAR DEFAULT 'SOSL' PROMPT 'DB user name for SOSL (default is SOSL if no value is given): '
ACCEPT SOSL_PASS CHAR PROMPT 'Mandatory db password for &SOSL_USER.: ' HIDE
ACCEPT SOSL_TS CHAR DEFAULT 'SOSL_TABLESPACE' PROMPT 'Table space name for SOSL (default is SOSL_TABLESPACE if no value is given): '
ACCEPT SOSL_DBF CHAR DEFAULT 'sosl.dbf' PROMPT 'Table space data file name for SOSL (default is sosl.dbf if no value is given): '
ACCEPT SOSL_CFG CHAR DEFAULT '../sosl_templates/sosl_login.cfg' PROMPT 'Path and filename for the SOSL schema login (default ../sosl_templates/sosl_login.cfg): '
ACCEPT SOSL_SRV CHAR DEFAULT 'SOSLINSTANCE' PROMPT 'SOSL db server or tnsname (default is SOSLINSTANCE if no value is given): '
SPOOL OFF
SET TERMOUT OFF
COLUMN SOSL_MSG NEW_VAL SOSL_MSG
SELECT '==== SOSL DBA setup ====' || '&LINE_FEED' ||
       'Create user/schema &SOSL_USER. with a password of length ' || LENGTH('&SOSL_PASS') || '? ' || '&LINE_FEED' ||
       '  Tablespace &SOSL_TS., if not exists, will be created' || '&LINE_FEED' ||
       '  with 100M and data file &SOSL_DBF..' || '&LINE_FEED' ||
       '  Instance name: &SOSL_SRV' || '&LINE_FEED' ||
       'Not allowed to be used as AI training material without explicite permission.' || CHR(10) ||
       'Use Ctrl-C to stop the script in sqlplus, Enter to continue.' AS SOSL_MSG
  FROM dual;
SET TERMOUT ON
SPOOL logs/sosl_dba_setup.log APPEND
PAUSE &SOSL_MSG
SELECT 'Started ...' AS info FROM dual;
COLUMN SOSL_LOGIN NEW_VAL SOSL_LOGIN
SELECT CASE
         WHEN COUNT(*) = 0
         THEN '&SOSL_CFG'
         ELSE '../sosl_templates/illegal_login_overwrite.cfg'
       END AS SOSL_LOGIN
     , CASE
         WHEN COUNT(*) = 0
         THEN 'Create login config OK'
         ELSE 'ERROR User exists, overwrite of login config is not allowed'
       END AS info
  FROM dba_users
 WHERE username = UPPER('&SOSL_USER')
;
-- do most of the things dynamically, as we may have more than one SOSL user
DECLARE
  l_statement VARCHAR2(32000);
  l_count     NUMBER;
BEGIN
  -- tablespace
  SELECT COUNT(*) INTO l_count FROM dba_tablespaces WHERE tablespace_name = UPPER('&SOSL_TS');
  IF l_count = 0
  THEN
    l_statement := 'CREATE TABLESPACE &SOSL_TS. DATAFILE ''&SOSL_DBF'' SIZE 100M AUTOEXTEND ON';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Tablespace &SOSL_TS. already exists, do nothing');
  END IF;
  -- SOSL roles
  SELECT COUNT(*) INTO l_count FROM dba_roles WHERE role = 'SOSL_USER';
  IF l_count = 0
  THEN
    l_statement := 'CREATE ROLE sosl_user';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role SOSL_USER already exists, do nothing');
  END IF;
  SELECT COUNT(*) INTO l_count FROM dba_roles WHERE role = 'SOSL_REVIEWER';
  IF l_count = 0
  THEN
    l_statement := 'CREATE ROLE sosl_reviewer';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role SOSL_REVIEWER already exists, do nothing');
  END IF;
  SELECT COUNT(*) INTO l_count FROM dba_roles WHERE role = 'SOSL_EXECUTOR';
  IF l_count = 0
  THEN
    l_statement := 'CREATE ROLE sosl_executor';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role SOSL_EXECUTOR already exists, do nothing');
  END IF;
  SELECT COUNT(*) INTO l_count FROM dba_roles WHERE role = 'SOSL_ADMIN';
  IF l_count = 0
  THEN
    l_statement := 'CREATE ROLE sosl_admin';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role SOSL_ADMIN already exists, do nothing');
  END IF;
  -- now grant hierarchical roles
  SELECT COUNT(*) INTO l_count FROM dba_role_privs WHERE grantee = 'SOSL_REVIEWER' AND granted_role = 'SOSL_USER';
  IF l_count = 0
  THEN
    l_statement := 'GRANT sosl_user TO sosl_reviewer';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role SOSL_USER already granted to SOSL_REVIEWER, do nothing');
  END IF;
  SELECT COUNT(*) INTO l_count FROM dba_role_privs WHERE grantee = 'SOSL_EXECUTOR' AND granted_role = 'SOSL_REVIEWER';
  IF l_count = 0
  THEN
    l_statement := 'GRANT sosl_reviewer TO sosl_executor';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role SOSL_REVIEWER already granted to SOSL_EXECUTOR, do nothing');
  END IF;
  SELECT COUNT(*) INTO l_count FROM dba_role_privs WHERE grantee = 'SOSL_ADMIN' AND granted_role = 'SOSL_EXECUTOR';
  IF l_count = 0
  THEN
    l_statement := 'GRANT sosl_executor TO sosl_admin';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Role SOSL_EXECUTOR already granted to SOSL_ADMIN, do nothing');
  END IF;
  -- SOSL user
  SELECT COUNT(*) INTO l_count FROM dba_users WHERE username = '&SOSL_USER';
  IF l_count = 0
  THEN
    l_statement := 'CREATE USER &SOSL_USER. IDENTIFIED BY &SOSL_PASS.';
    EXECUTE IMMEDIATE l_statement;
    DBMS_OUTPUT.PUT_LINE('User &SOSL_USER. created with defined password');
    l_statement := 'ALTER USER &SOSL_USER. DEFAULT TABLESPACE &SOSL_TS. ACCOUNT UNLOCK';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
    l_statement := 'ALTER USER &SOSL_USER. QUOTA UNLIMITED ON &SOSL_TS.';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
    -- basic grants
    l_statement := 'GRANT CONNECT TO &SOSL_USER';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
    l_statement := 'GRANT RESOURCE TO &SOSL_USER';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
    l_statement := 'GRANT GATHER_SYSTEM_STATISTICS TO &SOSL_USER';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
    l_statement := 'GRANT CREATE VIEW TO &SOSL_USER';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
    -- grant roles with admin option
    l_statement := 'GRANT sosl_admin TO &SOSL_USER WITH ADMIN OPTION';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
    l_statement := 'GRANT sosl_executor TO &SOSL_USER WITH ADMIN OPTION';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
    l_statement := 'GRANT sosl_reviewer TO &SOSL_USER WITH ADMIN OPTION';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
    l_statement := 'GRANT sosl_user TO &SOSL_USER WITH ADMIN OPTION';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
    -- only if we create a new user, we create the static view
    l_statement := q'[CREATE OR REPLACE VIEW &SOSL_USER..sosl_install_v
AS
  SELECT '&SOSL_USER' AS sosl_schema
       , SYS_CONTEXT('USERENV', 'HOST') AS sosl_machine
       , '&SOSL_TS' AS sosl_tablespace
       , '&SOSL_DBF' AS sosl_data_file
       , '&SOSL_CFG' AS sosl_config_file
       , '&SOSL_SRV' AS sosl_db_connection
    FROM dual]'
    ;
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('User &SOSL_USER. already exists, do nothing');
  END IF;
  -- dba view grants
  l_statement := 'GRANT SELECT ON dba_role_privs TO &SOSL_USER WITH GRANT OPTION';
  DBMS_OUTPUT.PUT_LINE(l_statement || ';');
  EXECUTE IMMEDIATE l_statement;
  l_statement := 'GRANT SELECT ON gv_$session TO &SOSL_USER WITH GRANT OPTION';
  DBMS_OUTPUT.PUT_LINE(l_statement || ';');
  EXECUTE IMMEDIATE l_statement;
  l_statement := 'GRANT SELECT ON gv_$sql TO &SOSL_USER WITH GRANT OPTION';
  DBMS_OUTPUT.PUT_LINE(l_statement || ';');
  EXECUTE IMMEDIATE l_statement;
END;
/
SET ECHO OFF
SET FEEDBACK OFF
SELECT 'Creating &SOSL_LOGIN. with current values and @&SOSL_SRV. ...' AS info
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
SPOOL &SOSL_LOGIN
SELECT '&SOSL_USER./&SOSL_PASS.@&SOSL_SRV.&LINE_FEED.' ||
       '--/--&LINE_FEED.' ||
       '--/--'
  FROM dual;
SPOOL OFF
SET TERMOUT ON
SPOOL logs/sosl_dba_setup.log APPEND
  WITH usr AS
       (SELECT CASE
                 WHEN COUNT(*) = 0
                 THEN 'ERROR &SOSL_USER. does not exist'
                 ELSE '&SOSL_USER. exists'
               END AS user_state
          FROM dba_users
         WHERE username = UPPER('&SOSL_USER')
       )
     , tbs AS
       (SELECT CASE
                 WHEN cnt_datafiles > 0
                  AND has_datafile > 0
                 THEN '&SOSL_TS. with &SOSL_DBF. exists'
                 WHEN cnt_datafiles > 0
                  AND has_datafile  = 0
                 THEN '&SOSL_TS. exists'
                 ELSE 'ERROR &SOSL_TS. does not exist'
               END AS tbs_state
          FROM (SELECT COUNT(*) AS cnt_datafiles
                     , COUNT(CASE WHEN UPPER(file_name) LIKE UPPER('%&SOSL_DBF.') THEN 1 ELSE 0 END) AS has_datafile
                     , SUM(bytes)/1024/1024 AS tablespace_size
                  FROM dba_data_files
                 WHERE tablespace_name = UPPER('&SOSL_TS')
               )
       )
     , rle AS
       (SELECT CASE
                 WHEN COUNT(*) = 3
                 THEN 'GV$SESSION, GV$SQL and DBA_ROLE_PRIVS granted with ADMIN option'
                 ELSE 'ERROR granting sys views, found ' || COUNT(*) || ' grants'
               END AS dba_view_grants
          FROM dba_tab_privs
         WHERE grantee     = UPPER('&SOSL_USER')
           AND table_name IN ('GV_$SESSION', 'GV_$SQL', 'DBA_ROLE_PRIVS')
       )
     , gra AS
       (SELECT CASE
                 WHEN SUM(cnt_grants) = 4
                 THEN 'CREATE VIEW, CONNECT, RESSOURCE, GATHER_SYSTEM_STATISTICS granted'
                 ELSE 'Missing sys grants, found ' || SUM(cnt_grants) || ' grants'
               END AS sys_grants
          FROM (SELECT COUNT(*) AS cnt_grants FROM dba_sys_privs WHERE grantee = UPPER('&SOSL_USER')
                 UNION ALL
                SELECT COUNT(*) AS cnt_grants FROM dba_role_privs WHERE grantee = UPPER('&SOSL_USER') AND granted_role NOT LIKE 'SOSL\_%' ESCAPE '\'
               )
       )
     , srl AS
       (SELECT CASE
                 WHEN COUNT(*) = 4
                 THEN 'SOSL_USER, SOSL_REVIEWER, SOSL_EXECUTOR, SOSL_ADMIN granted'
                 ELSE 'ERROR SOSL roles missing, found ' || COUNT(*) || ' roles'
               END AS has_roles
          FROM dba_role_privs
         WHERE grantee       = UPPER('&SOSL_USER')
           AND granted_role IN ('SOSL_USER', 'SOSL_REVIEWER', 'SOSL_EXECUTOR', 'SOSL_ADMIN')
           AND admin_option  = 'YES'
       )
SELECT '==== SOSL DBA setup ====' || '&LINE_FEED' ||
       'Executed: ' || TO_CHAR(SYSTIMESTAMP) || '&LINE_FEED' ||
       'Status USER: ' || usr.user_state || '&LINE_FEED' ||
       'Status TABLESPACE: ' || tbs.tbs_state || '&LINE_FEED' ||
       'Status SYS GRANTS: ' || gra.sys_grants || '&LINE_FEED' ||
       'Status SYS VIEWS: ' || rle.dba_view_grants || '&LINE_FEED' ||
       'Status ROLES: ' || srl.has_roles || '&LINE_FEED' ||
       'Created &SOSL_LOGIN. with current values and server/tnsname @&SOSL_SRV..' || '&LINE_FEED' ||
       'Check log for unexpected issues like user already exists' || '&LINE_FEED' ||
       'by ' || SYS_CONTEXT('USERENV', 'OS_USER') || '&LINE_FEED' ||
       'using ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || '&LINE_FEED' ||
       'on database ' || SYS_CONTEXT('USERENV', 'DB_NAME') || '&LINE_FEED' ||
       'from terminal ' || SYS_CONTEXT('USERENV', 'TERMINAL') AS info
  FROM usr
 CROSS JOIN tbs
 CROSS JOIN rle
 CROSS JOIN srl
 CROSS JOIN gra
;
SELECT '(C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1' || '&LINE_FEED' ||
       'Not allowed to be used as AI training material without explicite permission.' AS disclaimer
  FROM dual;
SPOOL OFF
-- uncomment in SQL Developer to keep the session, otherwise the session is closed
EXIT

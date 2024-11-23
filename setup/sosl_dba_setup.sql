-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
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
ACCEPT SOSL_USER CHAR DEFAULT 'SOSL' PROMPT 'DB user name for SOSL (default is SOSL if no value is given): '
ACCEPT SOSL_PASS CHAR PROMPT 'Mandatory db password for &SOSL_USER.: ' HIDE
ACCEPT SOSL_TS CHAR DEFAULT 'SOSL_TABLESPACE' PROMPT 'Table space name for SOSL (default is SOSL_TABLESPACE if no value is given): '
ACCEPT SOSL_DBF CHAR DEFAULT 'sosl.dbf' PROMPT 'Table space data file name for SOSL (default is sosl.dbf if no value is given): '
ACCEPT SOSL_CFG CHAR DEFAULT '../sosl_templates/sosl_login.cfg' PROMPT 'Path and filename for the SOSL schema login (default ../sosl_templates/sosl_login.cfg): '
ACCEPT SOSL_SRV CHAR DEFAULT 'SOSLINSTANCE' PROMPT 'SOSL db server or tnsname (default is SOSLINSTANCE if no value is given): '
COLUMN SOSL_MSG NEW_VAL SOSL_MSG
SET TERMOUT OFF
SELECT 'Create user/schema &SOSL_USER. with a password of length ' || LENGTH('&SOSL_PASS') || '? The tablespace &SOSL_TS. with 100M, data &SOSL_DBF. will be created. Use Ctrl-C to stop the script in sqlplus, Enter to continue.' AS SOSL_MSG
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
 WHERE username = '&SOSL_USER'
;
-- do most of the things dynamically, as we may have more than one SOSL user
SET ECHO OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
DECLARE
  l_statement VARCHAR2(32000);
  l_count     NUMBER;
BEGIN
  -- tablespace
  SELECT COUNT(*) INTO l_count FROM dba_tablespaces WHERE tablespace_name = '&SOSL_TS';
  IF l_count = 0
  THEN
    l_statement := 'CREATE TABLESPACE &SOSL_TS. DATAFILE ''&SOSL_DBF'' SIZE 100M AUTOEXTEND ON';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('Tablespace &SOSL_TS. already exists, do nothing');
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
    -- only if we create a new user, we create the static view
    l_statement := q'[CREATE OR REPLACE VIEW &SOSL_USER..sosl_install_v
AS
  SELECT ''&SOSL_USER''                     AS sosl_schema
       , SYS_CONTEXT(''USERENV'', ''HOST'') AS sosl_machine
       , ''&SOSL_TS''                       AS sosl_tablespace
       , ''&SOSL_DBF''                      AS sosl_data_file
       , ''&SOSL_CFG''                      AS sosl_config_file
       , ''&SOSL_SRV''                      AS sosl_db_server
    FROM dual]'
    ;
  ELSE
    DBMS_OUTPUT.PUT_LINE('User &SOSL_USER. already exists, do nothing');
  END IF;
  -- views
  SELECT COUNT(*) INTO l_count FROM dba_objects WHERE object_name = 'SOSL_ROLE_PRIVS' AND owner = 'SYS' AND object_type = 'VIEW';
  IF l_count = 0
  THEN
    l_statement := 'CREATE OR REPLACE VIEW SYS.sosl_role_privs AS SELECT * FROM dba_role_privs WHERE granted_role LIKE ''SOSL%''';
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('View SYS.SOSL_ROLE_PRIVS already exists, do nothing');
  END IF;
  SELECT COUNT(*) INTO l_count FROM dba_objects WHERE object_name = 'SOSL_SESSIONS' AND owner = 'SYS' AND object_type = 'VIEW';
  IF l_count = 0
  THEN
    l_statement := q'[CREATE OR REPLACE VIEW SYS.sosl_sessions
AS
  SELECT gses.inst_id
       , gses.saddr
       , gses.sid
       , gses.serial#
       , gses.audsid
       , gses.paddr
       , gses.user#
       , gses.username
       , gses.command
       , gses.ownerid
       , gses.taddr
       , gses.lockwait
       , gses.status
       , gses.server
       , gses.schema#
       , gses.schemaname
       , gses.osuser
       , gses.process
       , gses.machine
       , gses.port
       , gses.terminal
       , gses.program
       , gses.type
       , gses.sql_address
       , gses.sql_hash_value
       , gses.sql_id
       , gses.sql_child_number
       , gses.sql_exec_start
       , gses.sql_exec_id
       , gses.prev_sql_addr
       , gses.prev_hash_value
       , gses.prev_sql_id
       , gses.prev_child_number
       , gses.prev_exec_start
       , gses.prev_exec_id
       , gses.plsql_entry_object_id
       , gses.plsql_entry_subprogram_id
       , gses.plsql_object_id
       , gses.plsql_subprogram_id
       , gses.module
       , gses.module_hash
       , gses.action
       , gses.action_hash
       , gses.client_info
       , gses.fixed_table_sequence
       , gses.row_wait_obj#
       , gses.row_wait_file#
       , gses.row_wait_block#
       , gses.row_wait_row#
       , gses.top_level_call#
       , gses.logon_time
       , gses.last_call_et
       , gses.pdml_enabled
       , gses.failover_type
       , gses.failover_method
       , gses.failed_over
       , gses.resource_consumer_group
       , gses.pdml_status
       , gses.pddl_status
       , gses.pq_status
       , gses.current_queue_duration
       , gses.client_identifier
       , gses.blocking_session_status
       , gses.blocking_instance
       , gses.blocking_session
       , gses.final_blocking_session_status
       , gses.final_blocking_instance
       , gses.final_blocking_session
       , gses.seq#
       , gses.event#
       , gses.event
       , gses.p1text
       , gses.p1
       , gses.p1raw
       , gses.p2text
       , gses.p2
       , gses.p2raw
       , gses.p3text
       , gses.p3
       , gses.p3raw
       , gses.wait_class_id
       , gses.wait_class#
       , gses.wait_class
       , gses.wait_time
       , gses.seconds_in_wait
       , gses.state
       , gses.wait_time_micro
       , gses.time_remaining_micro
       , gses.total_time_waited_micro
       , gses.heur_time_waited_micro
       , gses.time_since_last_wait_micro
       , gses.service_name
       , gses.sql_trace
       , gses.sql_trace_waits
       , gses.sql_trace_binds
       , gses.sql_trace_plan_stats
       , gses.session_edition_id
       , gses.creator_addr
       , gses.creator_serial#
       , gses.ecid
       , gses.sql_translation_profile_id
       , gses.pga_tunable_mem
       , gses.shard_ddl_status
       , gses.con_id
       , gses.external_name
       , gses.plsql_debugger_connected
       , gses.drain_status
       , gses.drain_deadline
       , gses.drain_origin
       , gsql.sql_text
       , gsql.sql_fulltext
       , gsql.sharable_mem
       , gsql.persistent_mem
       , gsql.runtime_mem
       , gsql.sorts
       , gsql.loaded_versions
       , gsql.open_versions
       , gsql.users_opening
       , gsql.fetches
       , gsql.executions
       , gsql.px_servers_executions
       , gsql.end_of_fetch_count
       , gsql.users_executing
       , gsql.loads
       , gsql.first_load_time
       , gsql.invalidations
       , gsql.parse_calls
       , gsql.disk_reads
       , gsql.direct_writes
       , gsql.direct_reads
       , gsql.buffer_gets
       , gsql.application_wait_time
       , gsql.concurrency_wait_time
       , gsql.cluster_wait_time
       , gsql.user_io_wait_time
       , gsql.plsql_exec_time
       , gsql.java_exec_time
       , gsql.rows_processed
       , gsql.command_type
       , gsql.optimizer_mode
       , gsql.optimizer_cost
       , gsql.optimizer_env
       , gsql.optimizer_env_hash_value
       , gsql.parsing_user_id
       , gsql.parsing_schema_id
       , gsql.parsing_schema_name
       , gsql.kept_versions
       , gsql.address
       , gsql.type_chk_heap
       , gsql.hash_value
       , gsql.old_hash_value
       , gsql.plan_hash_value
       , gsql.full_plan_hash_value
       , gsql.child_number
       , gsql.service
       , gsql.service_hash
       , gsql.module_hash AS module_hash_sql
       , gsql.action_hash AS action_hash_sql
       , gsql.serializable_aborts
       , gsql.outline_category
       , gsql.cpu_time
       , gsql.elapsed_time
       , gsql.outline_sid
       , gsql.child_address
       , gsql.sqltype
       , gsql.remote
       , gsql.object_status
       , gsql.literal_hash_value
       , gsql.last_load_time
       , gsql.is_obsolete
       , gsql.is_bind_sensitive
       , gsql.is_bind_aware
       , gsql.is_shareable
       , gsql.child_latch
       , gsql.sql_profile
       , gsql.sql_patch
       , gsql.sql_plan_baseline
       , gsql.program_id
       , gsql.program_line#
       , gsql.exact_matching_signature
       , gsql.force_matching_signature
       , gsql.last_active_time
       , gsql.bind_data
       , gsql.typecheck_mem
       , gsql.io_cell_offload_eligible_bytes
       , gsql.io_interconnect_bytes
       , gsql.physical_read_requests
       , gsql.physical_read_bytes
       , gsql.physical_write_requests
       , gsql.physical_write_bytes
       , gsql.optimized_phy_read_requests
       , gsql.locked_total
       , gsql.pinned_total
       , gsql.io_cell_uncompressed_bytes
       , gsql.io_cell_offload_returned_bytes
       , gsql.is_reoptimizable
       , gsql.is_resolved_adaptive_plan
       , gsql.im_scans
       , gsql.im_scan_bytes_uncompressed
       , gsql.im_scan_bytes_inmemory
       , gsql.ddl_no_invalidate
       , gsql.is_rolling_invalid
       , gsql.is_rolling_refresh_invalid
       , gsql.result_cache
       , gsql.sql_quarantine
       , gsql.avoided_executions
       , gsql.heap0_load_time
       , gsql.heap6_load_time
       , gsql.result_cache_executions
       , gsql.result_cache_rejection_reason
    FROM gv$session gses
    LEFT OUTER JOIN gv$sql gsql
      ON gses.sql_id  = gsql.sql_id
     AND gses.inst_id = gsql.inst_id
     AND gses.con_id  = gsql.con_id
     AND gses.module  = gsql.module
     AND gses.action  = gsql.action]'
    ;
    DBMS_OUTPUT.PUT_LINE(l_statement || ';');
    EXECUTE IMMEDIATE l_statement;
  ELSE
    DBMS_OUTPUT.PUT_LINE('View SYS.SOSL_SESSIONS already exists, do nothing');
  END IF;
END;
/
SET FEEDBACK ON
-- set only echo on to display statement, but not password replacement
SET ECHO ON
-- basic grants
GRANT CONNECT TO &SOSL_USER;
GRANT RESOURCE TO &SOSL_USER;
GRANT GATHER_SYSTEM_STATISTICS TO &SOSL_USER;
GRANT CREATE VIEW TO &SOSL_USER;
GRANT CREATE JOB TO &SOSL_USER;
GRANT CREATE ROLE TO &SOSL_USER;
GRANT SELECT ON SYS.sosl_sessions TO &SOSL_USER;
GRANT SELECT ON SYS.sosl_role_privs TO &SOSL_USER;
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
SELECT 'Executed: ' || TO_CHAR(SYSTIMESTAMP) || '&LINE_FEED' ||
       'Created user &SOSL_USER. if not exists with unlimited quota on' || '&LINE_FEED' ||
       'tablespace &SOSL_TS., 100 MB, data file &SOSL_DBF.' || '&LINE_FEED' ||
       'Granted CREATE VIEW, CREATE JOB, CREATE ROLE, CONNECT, RESSOURCE, GATHER_SYSTEM_STATISTICS' || '&LINE_FEED' ||
       'Granted SELECT for SYS.SOSL_SESSIONS and SYS.SOSL_ROLE_PRIVS' || '&LINE_FEED' ||
       'Created installation view &SOSL_USER..SOSL_INSTALL_V' || '&LINE_FEED' ||
       'Created &SOSL_LOGIN. with current values and server/tnsname @&SOSL_SRV..' || '&LINE_FEED' ||
       'Check log for unexpected issues like user already exists' || '&LINE_FEED' ||
       'by ' || SYS_CONTEXT('USERENV', 'OS_USER') || '&LINE_FEED' ||
       'using ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || '&LINE_FEED' ||
       'on database ' || SYS_CONTEXT('USERENV', 'DB_NAME') || '&LINE_FEED' ||
       'from terminal ' || SYS_CONTEXT('USERENV', 'TERMINAL') AS info
  FROM dual;
SPOOL OFF
-- uncomment in SQL Developer to keep the session, otherwise the session is closed
EXIT

-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Use this if you want to create a specific SOSL schema in your database.
-- tested with SQLPlus and SQL Developer (execute as script)
-- you may want to adjust tablespace (line 47) and schema (starting with line 44)
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
-- create a special version of dba_role_privs limited to SOSL roles
CREATE OR REPLACE VIEW sosl_role_privs AS SELECT * FROM dba_role_privs WHERE granted_role LIKE 'SOSL%';
-- create a special version of gv$session limited to the machine SOSL is running on
-- as other users may execute scripts we cannot limit it to the sosl user
-- you may limit the columns that SOSL can see and the users that are shown
CREATE OR REPLACE VIEW sosl_sessions
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
     AND gses.action  = gsql.action
   WHERE gses.machine = SYS_CONTEXT('USERENV', 'HOST')
;
-- basic grants
GRANT CONNECT TO sosl;
GRANT RESOURCE TO sosl;
GRANT GATHER_SYSTEM_STATISTICS TO sosl;
GRANT CREATE VIEW TO sosl;
GRANT CREATE JOB TO sosl;
GRANT CREATE ROLE TO sosl;
GRANT SELECT ON sosl_sessions TO sosl;
GRANT SELECT ON sosl_role_privs TO sosl;
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
       'Granted CREATE VIEW, CREATE JOB, CREATE ROLE, CONNECT, RESSOURCE, GATHER_SYSTEM_STATISTICS, SELECT for SOSL_SESSIONS and SOSL_ROLE_PRIVS' || CHR(13) || CHR(10) ||
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



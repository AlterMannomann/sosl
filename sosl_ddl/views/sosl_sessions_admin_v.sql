-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- Admin content providing full GV$SESSION content
CREATE OR REPLACE VIEW sosl_sessions_admin_v
AS
  SELECT inst_id
       , saddr
       , sid
       , serial#
       , audsid
       , paddr
       , user#
       , username
       , command
       , ownerid
       , taddr
       , lockwait
       , status
       , server
       , schema#
       , schemaname
       , osuser
       , process
       , machine
       , port
       , terminal
       , program
       , type
       , sql_address
       , sql_hash_value
       , sql_id
       , sql_child_number
       , sql_exec_start
       , sql_exec_id
       , prev_sql_addr
       , prev_hash_value
       , prev_sql_id
       , prev_child_number
       , prev_exec_start
       , prev_exec_id
       , plsql_entry_object_id
       , plsql_entry_subprogram_id
       , plsql_object_id
       , plsql_subprogram_id
       , module
       , module_hash
       , action
       , action_hash
       , client_info
       , fixed_table_sequence
       , row_wait_obj#
       , row_wait_file#
       , row_wait_block#
       , row_wait_row#
       , top_level_call#
       , logon_time
       , last_call_et
       , pdml_enabled
       , failover_type
       , failover_method
       , failed_over
       , resource_consumer_group
       , pdml_status
       , pddl_status
       , pq_status
       , current_queue_duration
       , client_identifier
       , blocking_session_status
       , blocking_instance
       , blocking_session
       , final_blocking_session_status
       , final_blocking_instance
       , final_blocking_session
       , seq#
       , event#
       , event
       , p1text
       , p1
       , p1raw
       , p2text
       , p2
       , p2raw
       , p3text
       , p3
       , p3raw
       , wait_class_id
       , wait_class#
       , wait_class
       , wait_time
       , seconds_in_wait
       , state
       , wait_time_micro
       , time_remaining_micro
       , total_time_waited_micro
       , heur_time_waited_micro
       , time_since_last_wait_micro
       , service_name
       , sql_trace
       , sql_trace_waits
       , sql_trace_binds
       , sql_trace_plan_stats
       , session_edition_id
       , creator_addr
       , creator_serial#
       , ecid
       , sql_translation_profile_id
       , pga_tunable_mem
       , shard_ddl_status
       , con_id
       , external_name
       , plsql_debugger_connected
       , drain_status
       , drain_deadline
       , drain_origin
    FROM gv$session gses
;
GRANT SELECT ON sosl_sessions_admin_v TO sosl_admin;

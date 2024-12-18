-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- short version of GV$SESSION for SOSL user, machine/terminal and function owners
-- including a basic join on GV$SQL
CREATE OR REPLACE VIEW sosl_sessions_v
AS
  SELECT gsn.schemaname
       , gsn.username
       , gsn.osuser
       , gsn.logon_time
       , gsn.sid
       , gsn.serial#
       , gsn.status
       , gsn.blocking_session_status
       , gsn.state AS wait_status
       , CASE
           WHEN gsq.sql_text IS NOT NULL
                  -- reduce formatting space chars
           THEN SUBSTR(REGEXP_REPLACE(gsq.sql_text, '\s{2,}', ' '), 1, 80) || '...'
           ELSE NULL
         END AS short_sql
       , gsn.sql_exec_start
       , gsn.event
       , gsn.machine
       , gsn.module
       , gsn.action
       , gsn.terminal
       , gsn.program
       , gsn.server
       , gsn.wait_time
       , gsn.seconds_in_wait
       , gsn.process
       , gsn.sql_id
       , gsn.inst_id
       , gsn.con_id
       , gsn.action_hash
       , gsn.module_hash
       , gsn.lockwait
       , gsn.blocking_instance
       , gsn.blocking_session
       , gsn.final_blocking_session_status
       , gsn.final_blocking_instance
       , gsn.final_blocking_session
       , gsn.wait_class_id
       , gsn.wait_class#
       , gsn.wait_class
       , gsn.wait_time_micro
       , gsn.time_remaining_micro
       , gsn.total_time_waited_micro
       , gsn.heur_time_waited_micro
       , gsn.time_since_last_wait_micro
    FROM gv$session gsn
    LEFT OUTER JOIN gv$sql gsq
      ON gsn.sql_id = gsq.sql_id
   WHERE gsn.username IS NOT NULL -- exclude oracle system
     AND (   gsn.username          = (SELECT sosl_schema FROM sosl_install_v)
          OR gsn.schemaname        = (SELECT sosl_schema FROM sosl_install_v)
          OR UPPER(gsn.terminal)   = (SELECT UPPER(sosl_machine) FROM sosl_install_v)
          OR gsn.username         IN (SELECT function_owner FROM sosl_executor_definition WHERE executor_active = 1 AND executor_reviewed = 1)
          OR gsn.schemaname       IN (SELECT function_owner FROM sosl_executor_definition WHERE executor_active = 1 AND executor_reviewed = 1)
          OR UPPER(gsn.machine) LIKE (SELECT '%' || UPPER(sosl_machine) || '%' FROM sosl_install_v)
         )
;
GRANT SELECT ON sosl_sessions_v TO sosl_user;

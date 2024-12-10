-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE VIEW sosl_server_log_v
AS
SELECT TO_CHAR(exec_timestamp, 'YYYY-MM-DD HH24:MI:SS.FF9') AS exec_time
     , log_type
     , log_category
     , message
     , run_id
     , executor_id
     , guid
     , sosl_identifier
     , caller
     , ext_script_id
     , script_file
     , created_by
     , created_by_os
     , full_message
     , exec_timestamp
  FROM sosl_server_log
 ORDER BY exec_timestamp DESC
;
GRANT SELECT ON sosl_server_log_v TO sosl_user;

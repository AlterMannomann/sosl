-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE VIEW sosl_executors_v
AS
  SELECT executor_name
       , function_owner
       , sosl_util.yes_no(use_mail) AS use_mail
       , sosl_util.yes_no(executor_active) AS executor_active
       , sosl_util.yes_no(executor_reviewed) AS executor_reviewed
       , fn_has_scripts
       , fn_get_next_script
       , fn_set_script_status
       , fn_send_db_mail
       , script_schema
       , CASE
           WHEN sosl_util.has_role(SYS_CONTEXT('USERENV', 'SESSION_USER'), 'SOSL_REVIEWER')
           THEN cfg_file
           ELSE '***'
         END AS cfg_file
       , executor_description
       , executor_id
       , TO_CHAR(created, 'YYYY-MM-DD HH24:MI:SS')            AS created
       , created_by
       , created_by_os
       , TO_CHAR(updated, 'YYYY-MM-DD HH24:MI:SS')            AS updated
       , updated_by
       , updated_by_os
    FROM sosl_executor_definition
;
GRANT SELECT ON sosl_executors_v TO sosl_user;

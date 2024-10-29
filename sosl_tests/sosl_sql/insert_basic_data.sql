-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.

-- default executor
INSERT INTO sosl_executor_definition
  ( executor_name
  , db_user
  , function_owner
  , fn_has_scripts
  , fn_get_next_script
  , fn_set_script_status
  , cfg_file
  , use_mail
  , executor_description
  )
  VALUES ( 'SOSL'
         , 'sosl'
         , 'sosl'
         , 'sosl_if.has_scripts'
         , 'sosl_if.get_next_script'
         , 'sosl_if.set_script_status'
         , '..\sosl_templates\sosl_login.cfg'
         , 0
         , 'Internal SOSL executor for testing and demonstration purposes. Only a simple set of ordered scripts supported.'
         )
;
COMMIT;
INSERT INTO sosl_if_script
  ( script_name
  , script_active
  , executor_id
  )
  SELECT '..\sosl_tests\sosl_sql\sosl_hello_world.sql' AS script_name
       , 1 AS script_active
       , executor_id
    FROM sosl_executor_definition
   WHERE executor_name = 'SOSL'
;
COMMIT;

UPDATE sosl_executor_definition
   SET fn_send_db_mail = 'sosl_if.send_mail'
 WHERE executor_name = 'SOSL'
;
COMMIT;
UPDATE sosl_executor_definition
   SET executor_active = 1
     , executor_reviewed = 1
     , use_mail = 1
 WHERE executor_name = 'SOSL'
;
COMMIT;

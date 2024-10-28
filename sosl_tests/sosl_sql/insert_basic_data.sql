-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.

-- default executor
INSERT INTO sosl_executor
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
         , 'sosl.has_scripts'
         , 'sosl.get_next_script'
         , 'sosl.set_script_status'
         , '..\sosl_templates\sosl_login.cfg'
         , 0
         , 'Internal SOSL executor for testing and demonstration purposes. Only a simple set of ordered scripts supported.'
         )
;
COMMIT;
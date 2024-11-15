-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.

-- default executor
SELECT sosl_api.create_executor( 'SOSL'
                                 , 'sosl'
                                 , 'sosl_if.has_scripts'
                                 , 'sosl_if.get_next_script'
                                 , 'sosl_if.set_script_status'
                                 , '..\sosl_templates\sosl_login.cfg'
                                 , 1
                                 , 'sosl_if.send_mail'
                                 , 'Internal SOSL executor for testing and demonstration purposes. Only a simple set of ordered scripts supported.'
                                 ) AS new_executor_id
  FROM dual
;

SELECT sosl_api.activate_executor(1) FROM dual;
SELECT sosl_api.set_executor_reviewed(1) FROM dual;

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

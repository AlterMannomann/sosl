-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.

-- default executor
CLEAR COLUMNS
COLUMN NEW_EXECUTOR_ID NEW_VAL NEW_EXECUTOR_ID
SELECT sosl_api.create_executor( 'SOSL'
                                 , 'sosl'
                                 , 'sosl_if.has_scripts'
                                 , 'sosl_if.get_next_script'
                                 , 'sosl_if.set_script_status'
                                 , '..\sosl_templates\sosl_login.cfg'
                                 , 1
                                 , 'sosl_if.send_mail'
                                 , 'Internal SOSL executor for testing and demonstration purposes. Only a simple set of ordered scripts supported.'
                                 ) AS NEW_EXECUTOR_ID
  FROM dual
;

SELECT sosl_api.activate_executor(1) FROM dual;
SELECT sosl_api.set_executor_reviewed(1) FROM dual;
SELECT sosl_api.add_script('..\sosl_tests\sosl_sql\sosl_hello_world.sql', &NEW_EXECUTOR_ID, 1, 1) FROM dual;

-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- simulate a script with errors
SELECT 'SOSL: Test script for error in script' AS info FROM dual;
BEGIN
  sosl_log.minimal_info_log('sosl_test_error.sql', 'SOSL TEST', 'Test script will create an error after logging');
END;
/
-- provoke an error
SELECT 1/0 AS impossible FROM dual;
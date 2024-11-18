-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- just write a hello world log entry
SELECT 'SOSL: Hello World' AS info FROM dual;
BEGIN
  sosl_log.minimal_info_log('sosl_hello_world.sql', 'SOSL TEST', 'Hello World');
END;
/
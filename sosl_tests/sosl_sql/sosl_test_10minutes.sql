-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- simulate a script with 10 minute runtime
SELECT 'SOSL: Test script 10 minutes runtime' AS info FROM dual;
BEGIN
  sosl_log.minimal_info_log('sosl_test_10minutes.sql', 'SOSL TEST', 'Test script 10 minutes runtime');
  -- add a wait time of ten minutes
  DBMS_SESSION.SLEEP(600);
END;
/
-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- simulate a script with 1 minute runtime
SELECT 'SOSL: Test script 1 minute runtime' AS info FROM dual;
BEGIN
  sosl_log.minimal_info_log('sosl_test_1minute.sql', 'SOSL TEST', 'Test script 1 minute runtime');
  -- add a wait time of one minute
  DBMS_SESSION.SLEEP(60);
END;
/
-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
DECLARE
  l_test SOSL_PAYLOAD;
BEGIN
  l_test := (1, 'MY ID', 'myscriptfile.sql');
  DBMS_OUTPUT.PUT_LINE(l_test.script_file);
END;
/
-- test function and SQL access
CREATE OR REPLACE FUNCTION get_next_id
  RETURN sosl_payload
IS
  l_payload SOSL_PAYLOAD;
BEGIN
  l_payload := sosl_payload(1, 'MY ID', 'myscriptfile.sql');
  RETURN l_payload;
END;
/
-- to be used by the sosl_server for fetching current data
  WITH base AS
       -- single call only one fetch of the function
       (SELECT /*+MATERIALIZE*/ sosl_payload(1, 'MY ID', 'myscriptfile.sql') AS res FROM dual)
SELECT TREAT(res AS sosl_payload).executor_id
     , TREAT(res AS sosl_payload).ext_script_id
     , TREAT(res AS sosl_payload).script_file
  FROM base
;

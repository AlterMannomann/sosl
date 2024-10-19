DECLARE
  l_test SOSL_PAYLOAD;
BEGIN
  l_test := (1, 'MY ID', 'myscriptfile.sql');
  DBMS_OUTPUT.PUT_LINE(l_test.script_file);
END;
/
-- test enqueue
SET SERVEROUTPUT ON SIZE UNLIMITED
DECLARE
  l_msg_id RAW(32);
  l_enq_opt DBMS_AQ.ENQUEUE_OPTIONS_T;
  l_deq_opt DBMS_AQ.DEQUEUE_OPTIONS_T;
  l_msg_opt DBMS_AQ.MESSAGE_PROPERTIES_T;
  l_message SOSL_PAYLOAD;
BEGIN
  -- default mode on commit, so commit is crucial on enqueue and dequeue, otherwise messages remain in the queue table
  DBMS_AQ.ENQUEUE('SOSL_SCRIPT_ID_QUEUE', l_enq_opt, l_msg_opt, sosl_payload(1, 'MY ID', 'myscriptfile.sql'), l_msg_id);
  COMMIT;
  DBMS_AQ.DEQUEUE('SOSL_SCRIPT_ID_QUEUE', l_deq_opt, l_msg_opt, l_message, l_msg_id);
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Enqueued and dequeued message with ext_script_id ' || l_message.ext_script_id || ', executor_id ' || l_message.executor_id || ' and script_file ' || l_message.script_file);
END;
/
-- get content from queue table for existing entries
SELECT TREAT(user_data AS sosl_payload).executor_id AS executor_id
     , TREAT(user_data AS sosl_payload).ext_script_id AS ext_script_id
     , TREAT(user_data AS sosl_payload).script_file AS script_file
  FROM sosl_script_id_queue;
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
       (SELECT /*+MATERIALIZE*/ get_next_id AS res FROM dual)
SELECT TREAT(res AS sosl_payload).executor_id
     , TREAT(res AS sosl_payload).ext_script_id
     , TREAT(res AS sosl_payload).script_file
  FROM base
;

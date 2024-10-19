-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE OR REPLACE FUNCTION get_next_id
  RETURN SOSL_PAYLOAD
IS
  /* Wrapper function for defined executor get_next_id functions.
  * Fetches every has_ids and get_next_id function from all active and reviewed executors. If executors
  * share the same functions, their functions must take care of correct timing for processing.
  * Queues all found ids into SOSL_SCRIPT_ID_QUEUE and returns the first queue entry.
  *
  * @return The first external script id in the queue.
  */

  -- variables
  l_payload   SOSL_PAYLOAD;
  l_return    SOSL_PAYLOAD;
  l_msg_id    RAW(16);
  l_enq_opt   DBMS_AQ.ENQUEUE_OPTIONS_T;
  l_deq_opt   DBMS_AQ.DEQUEUE_OPTIONS_T;
  l_msg_opt   DBMS_AQ.MESSAGE_PROPERTIES_T;
  l_queue     VARCHAR2(20) := 'SOSL_SCRIPT_ID_QUEUE';
  -- cursors
  CURSOR cur_executors
  IS
    SELECT fn_has_ids
         , fn_get_next_id
         , executor_id
      FROM sosl_executor
     WHERE executor_active   = 1
       AND executor_reviewed = 1
  ;
BEGIN
  -- explicitely define setable options and properties
  -- enqueue
  l_enq_opt.visibility          := DBMS_AQ.ON_COMMIT;
  l_enq_opt.relative_msgid      := NULL;
  l_enq_opt.sequence_deviation  := NULL;
  l_enq_opt.transformation      := NULL;
  l_enq_opt.delivery_mode       := DBMS_AQ.PERSISTENT;
  -- dequeue
  l_deq_opt.consumer_name       := NULL;
  l_deq_opt.dequeue_mode        := DBMS_AQ.REMOVE;
  l_deq_opt.navigation          := DBMS_AQ.NEXT_MESSAGE;
  l_deq_opt.visibility          := DBMS_AQ.ON_COMMIT;
  l_deq_opt.wait                := DBMS_AQ.FOREVER;
  l_deq_opt.msgid               := NULL;
  l_deq_opt.correlation         := NULL;
  l_deq_opt.deq_condition       := NULL;
  l_deq_opt.signature           := NULL;
  l_deq_opt.transformation      := NULL;
  l_deq_opt.delivery_mode       := DBMS_AQ.PERSISTENT;
  -- message
  l_msg_opt.priority            := 1;
  l_msg_opt.delay               := DBMS_AQ.NO_DELAY;
  l_msg_opt.expiration          := DBMS_AQ.NEVER;
  l_msg_opt.correlation         := NULL;
  l_msg_opt.exception_queue     := NULL;
  l_msg_opt.sender_id           := NULL;
  l_msg_opt.original_msgid      := NULL;
  l_msg_opt.signature           := NULL;
  l_msg_opt.transaction_group   := NULL;
  l_msg_opt.user_property       := NULL;
  l_msg_opt.delivery_mode       := DBMS_AQ.PERSISTENT;
  -- first check if there are more ids available and queue them
  FOR rec IN cur_executors
  LOOP
    NULL;
  END LOOP;
  -- now retrieve the first item in the queue and return it
  BEGIN
    -- check for content if possible
    DBMS_AQ.DEQUEUE(l_queue, l_deq_opt, l_msg_opt, l_return, l_msg_id);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END;

  RETURN l_return;
END;
/
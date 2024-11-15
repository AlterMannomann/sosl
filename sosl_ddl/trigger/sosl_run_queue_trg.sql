-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- requires login with the correct schema, either SOSL or your own SOSL schema
-- requires table to have been created before, as well as used packages
CREATE OR REPLACE TRIGGER sosl_run_queue_ins_trg
  BEFORE INSERT ON sosl_run_queue
  FOR EACH ROW
DECLARE
  l_executor_valid    NUMBER;
  l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_RUN_QUEUE';
  l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_run_queue_ins_trg';
BEGIN
  -- check executor, if not accepted and reviewed, set run state to error, else waiting
  IF sosl_sys.is_executor_valid(:NEW.executor_id)
  THEN
    :NEW.run_state      := sosl_constants.RUN_STATE_WAITING;
    :NEW.waiting        := SYSTIMESTAMP;
    :NEW.waiting_by     := SYS_CONTEXT('USERENV', 'SESSION_USER');
    :NEW.waiting_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
    :NEW.finished       := NULL;
    :NEW.finished_by    := NULL;
    :NEW.finished_by_os := NULL;
  ELSE
    -- log error
    sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Given executor id ' || :NEW.executor_id || ' is not active and reviewed. Script execution not allowed.');
    :NEW.run_state      := sosl_constants.RUN_STATE_ERROR;
    :NEW.waiting        := NULL;
    :NEW.waiting_by     := NULL;
    :NEW.waiting_by_os  := NULL;
    :NEW.finished       := SYSTIMESTAMP;
    :NEW.finished_by    := SYS_CONTEXT('USERENV', 'SESSION_USER');
    :NEW.finished_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
  END IF;
  -- set basic timestamps
  :NEW.created        := SYSTIMESTAMP;
  :NEW.created_by     := SYS_CONTEXT('USERENV', 'SESSION_USER');
  :NEW.created_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  -- overwrite any other injected dates and user on insert
  :NEW.enqueued       := NULL;
  :NEW.enqueued_by    := NULL;
  :NEW.enqueued_by_os := NULL;
  :NEW.started        := NULL;
  :NEW.started_by     := NULL;
  :NEW.started_by_os  := NULL;
  :NEW.running_since  := NULL;
  :NEW.running_by     := NULL;
  :NEW.running_by_os  := NULL;
  -- log the insert
  sosl_log.minimal_info_log( l_self_caller
                           , l_self_log_category
                           , 'A new script with run id ' || :NEW.run_id || ' is prepared to be added to the run queue created by OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                           )
  ;
EXCEPTION
  WHEN OTHERS THEN
    sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
    -- raise all errors
    RAISE;
END;
/
CREATE OR REPLACE TRIGGER sosl_run_queue_upd_trg
  BEFORE UPDATE ON sosl_run_queue
  FOR EACH ROW
DECLARE
  l_executor_valid    NUMBER;
  l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_RUN_QUEUE';
  l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_run_queue_upd_trg';
BEGIN
  -- make sure created and basics are not changed
  sosl_log.log_column_change(:NEW.created, :OLD.created, 'SOSL_RUN_QUEUE.CREATED', l_self_caller);
  :NEW.created        := :OLD.created;
  sosl_log.log_column_change(:NEW.created_by, :OLD.created_by, 'SOSL_RUN_QUEUE.CREATED_BY', l_self_caller);
  :NEW.created_by     := :OLD.created_by;
  sosl_log.log_column_change(:NEW.created_by_os, :OLD.created_by_os, 'SOSL_RUN_QUEUE.CREATED_BY_OS', l_self_caller);
  :NEW.created_by_os  := :OLD.created_by_os;
  sosl_log.log_column_change(:NEW.executor_id, :OLD.executor_id, 'SOSL_RUN_QUEUE.EXECUTOR_ID', l_self_caller);
  :NEW.executor_id    := :OLD.executor_id;
  sosl_log.log_column_change(:NEW.ext_script_id, :OLD.ext_script_id, 'SOSL_RUN_QUEUE.EXT_SCRIPT_ID', l_self_caller);
  :NEW.ext_script_id  := :OLD.ext_script_id;
  sosl_log.log_column_change(:NEW.script_file, :OLD.script_file, 'SOSL_RUN_QUEUE.SCRIPT_FILE', l_self_caller);
  :NEW.script_file    := :OLD.script_file;
  -- check run state order, error can always be set
  IF :NEW.run_state != sosl_constants.RUN_STATE_ERROR
  THEN
    -- only if run state has changed
    IF :NEW.run_state != :OLD.run_state
    THEN
      -- normal transitions, organized as ordered sequence numbers 0 to 4
      -- WAITING -> ENQUEUED, ENQUEUED -> STARTED, STARTED -> RUNNING, RUNNING -> FINISHED, FINSHED -> WAITING
      IF     (   :OLD.run_state = sosl_constants.RUN_STATE_ERROR
              OR :OLD.run_state = sosl_constants.RUN_STATE_FINISHED
             )
         AND :NEW.run_state != sosl_constants.RUN_STATE_WAITING
      THEN
        -- log it
        sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Wrong state transition: ' || sosl_constants.run_state_text(:OLD.run_state) || ' not allowed to change to ' || sosl_constants.run_state_text(:NEW.run_state) || '. State set to ERROR.');
        -- ignore invalid run state, set state to error
        :NEW.run_state := sosl_constants.RUN_STATE_ERROR;
      ELSE
        -- next state must be exactly old run state +1
        IF :NEW.run_state != (:OLD.run_state + 1)
        THEN
          -- log it
          sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Wrong state transition: ' || sosl_constants.run_state_text(:OLD.run_state) || ' not allowed to change to ' || sosl_constants.run_state_text(:NEW.run_state) || '. State set to ERROR.');
          -- ignore invalid run state, set state to error
          :NEW.run_state := sosl_constants.RUN_STATE_ERROR;
        END IF;
      END IF;
    END IF;
  END IF;
  -- check executor and prevent updates on run state if not valid, set run state to error if executor not valid
  IF sosl_sys.is_executor_valid(:NEW.executor_id)
  THEN
   -- update dates and user by run state
    CASE :NEW.run_state
      WHEN sosl_constants.RUN_STATE_WAITING THEN
        :NEW.waiting        := SYSTIMESTAMP;
        :NEW.waiting_by     := SYS_CONTEXT('USERENV', 'SESSION_USER');
        :NEW.waiting_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
      WHEN sosl_constants.RUN_STATE_ENQUEUED THEN
        :NEW.enqueued       := SYSTIMESTAMP;
        :NEW.enqueued_by    := SYS_CONTEXT('USERENV', 'SESSION_USER');
        :NEW.enqueued_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
      WHEN sosl_constants.RUN_STATE_STARTED THEN
        :NEW.started        := SYSTIMESTAMP;
        :NEW.started_by     := SYS_CONTEXT('USERENV', 'SESSION_USER');
        :NEW.started_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
      WHEN sosl_constants.RUN_STATE_RUNNING THEN
        :NEW.running_since  := SYSTIMESTAMP;
        :NEW.running_by     := SYS_CONTEXT('USERENV', 'SESSION_USER');
        :NEW.running_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
      WHEN sosl_constants.RUN_STATE_FINISHED THEN
        :NEW.finished       := SYSTIMESTAMP;
        :NEW.finished_by    := SYS_CONTEXT('USERENV', 'SESSION_USER');
        :NEW.finished_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
      ELSE
        -- any other state is an error state
        :NEW.finished       := SYSTIMESTAMP;
        :NEW.finished_by    := SYS_CONTEXT('USERENV', 'SESSION_USER');
        :NEW.finished_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
        :NEW.run_state      := sosl_constants.RUN_STATE_ERROR;
    END CASE;
  ELSE
    -- log error
    sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Current executor id ' || :NEW.executor_id || ' is not longer active and reviewed. Script execution not allowed.');
    -- set run state to error in any case
    :NEW.run_state      := sosl_constants.RUN_STATE_ERROR;
    :NEW.enqueued       := :OLD.enqueued;
    :NEW.enqueued_by    := :OLD.enqueued_by;
    :NEW.enqueued_by_os := :OLD.enqueued_by_os;
    :NEW.started        := :OLD.started;
    :NEW.started_by     := :OLD.started_by;
    :NEW.started_by_os  := :OLD.started_by_os;
    :NEW.running_since  := :OLD.running_since;
    :NEW.running_by     := :OLD.running_by;
    :NEW.running_by_os  := :OLD.running_by_os;
    :NEW.finished       := :OLD.finished;
    :NEW.finished_by    := :OLD.finished_by;
    :NEW.finished_by_os := :OLD.finished_by_os;
  END IF;
  -- log the update
  sosl_log.minimal_info_log( l_self_caller
                           , l_self_log_category
                           , 'Prepared the update for run id ' || :OLD.run_id || ' by OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                           )
  ;
EXCEPTION
  WHEN OTHERS THEN
    sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
    -- raise all errors
    RAISE;
END;
/
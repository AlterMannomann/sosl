-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE PACKAGE BODY sosl_sys
AS
  -- for description see header file
  FUNCTION get_valid_executor_cnt
    RETURN NUMBER
  IS
    l_return NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO l_return
      FROM sosl_executor
     WHERE executor_active   = sosl_constants.NUM_YES
       AND executor_reviewed = sosl_constants.NUM_YES
    ;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_sys.get_valid_executor_cnt', 'SOSL_SYS', SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN -1;
  END get_valid_executor_cnt;

  FUNCTION get_waiting_cnt
    RETURN NUMBER
  IS
    l_return NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO l_return
      FROM sosl_run_queue
     WHERE run_state = sosl_constants.RUN_STATE_WAITING
    ;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_sys.get_waiting_cnt', 'SOSL_SYS', SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN -1;
  END get_waiting_cnt;

  FUNCTION get_waiting_cnt(p_executor_id IN NUMBER)
    RETURN NUMBER
  IS
    l_return NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO l_return
      FROM sosl_run_queue
     WHERE run_state   = sosl_constants.RUN_STATE_WAITING
       AND executor_id = p_executor_id
    ;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_sys.get_waiting_cnt executor', 'SOSL_SYS', SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN -1;
  END get_waiting_cnt;

  FUNCTION deactivate_by_fn_has_scripts( p_function_owner IN VARCHAR2
                                       , p_fn_has_scripts IN VARCHAR2
                                       , p_log_reason     IN VARCHAR2
                                       )
    RETURN BOOLEAN
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.deactivate_by_fn_has_scripts';
    CURSOR cur_deactivate( cp_function_owner IN VARCHAR2
                         , cp_function_name  IN VARCHAR2
                         )
    IS
      SELECT executor_id
           , function_owner
        FROM sosl_executor
       WHERE function_owner = cp_function_owner
         AND fn_has_scripts = cp_function_name
    ;
  BEGIN
    l_return := TRUE;
    sosl_log.minimal_warning_log(l_self_caller, l_self_log_category, p_log_reason);
    FOR rec IN cur_deactivate(p_function_owner, p_fn_has_scripts)
    LOOP
      -- disable executor
      UPDATE sosl_executor
         SET executor_active    = sosl_constants.NUM_NO
           , executor_reviewed  = sosl_constants.NUM_NO
       WHERE executor_id = rec.executor_id
      ;
      COMMIT;
      -- revoke grants for function owner
      IF NOT sosl_util.revoke_role(rec.function_owner, 'SOSL_EXECUTOR')
      THEN
        sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Unable to revoke grant SOSL_EXECUTOR from ' || rec.function_owner);
        -- if one fails, it all is in error
        l_return := FALSE;
      END IF;
    END LOOP;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END deactivate_by_fn_has_scripts;

  FUNCTION deactivate_by_fn_get_next_script( p_function_owner     IN VARCHAR2
                                           , p_fn_get_next_script IN VARCHAR2
                                           , p_log_reason         IN VARCHAR2
                                           )
    RETURN BOOLEAN
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.deactivate_by_fn_get_next_script';
    CURSOR cur_deactivate( cp_function_owner IN VARCHAR2
                         , cp_function_name  IN VARCHAR2
                         )
    IS
      SELECT executor_id
           , function_owner
        FROM sosl_executor
       WHERE function_owner     = cp_function_owner
         AND fn_get_next_script = cp_function_name
    ;
  BEGIN
    l_return := TRUE;
    sosl_log.minimal_warning_log(l_self_caller, l_self_log_category, p_log_reason);
    FOR rec IN cur_deactivate(p_function_owner, p_fn_get_next_script)
    LOOP
      -- disable executor
      UPDATE sosl_executor
         SET executor_active    = sosl_constants.NUM_NO
           , executor_reviewed  = sosl_constants.NUM_NO
       WHERE executor_id = rec.executor_id
      ;
      COMMIT;
      -- revoke grants for function owner
      IF NOT sosl_util.revoke_role(rec.function_owner, 'SOSL_EXECUTOR')
      THEN
        sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Unable to revoke grant SOSL_EXECUTOR from ' || rec.function_owner);
        -- if one fails, it all is in error
        l_return := FALSE;
      END IF;
    END LOOP;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END deactivate_by_fn_get_next_script;

  FUNCTION deactivate_by_fn_set_script_status( p_function_owner       IN VARCHAR2
                                             , p_fn_set_script_status IN VARCHAR2
                                             , p_log_reason           IN VARCHAR2
                                             )
    RETURN BOOLEAN
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.deactivate_by_fn_set_script_status';
    CURSOR cur_deactivate( cp_function_owner IN VARCHAR2
                         , cp_function_name  IN VARCHAR2
                         )
    IS
      SELECT executor_id
           , function_owner
        FROM sosl_executor
       WHERE function_owner       = cp_function_owner
         AND fn_set_script_status = cp_function_name
    ;
  BEGIN
    l_return := TRUE;
    sosl_log.minimal_warning_log(l_self_caller, l_self_log_category, p_log_reason);
    FOR rec IN cur_deactivate(p_function_owner, p_fn_set_script_status)
    LOOP
      -- disable executor
      UPDATE sosl_executor
         SET executor_active    = sosl_constants.NUM_NO
           , executor_reviewed  = sosl_constants.NUM_NO
       WHERE executor_id = rec.executor_id
      ;
      COMMIT;
      -- revoke grants for function owner
      IF NOT sosl_util.revoke_role(rec.function_owner, 'SOSL_EXECUTOR')
      THEN
        sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Unable to revoke grant SOSL_EXECUTOR from ' || rec.function_owner);
        -- if one fails, it all is in error
        l_return := FALSE;
      END IF;
    END LOOP;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END deactivate_by_fn_set_script_status;

  FUNCTION deactivate_by_fn_send_db_mail( p_function_owner  IN VARCHAR2
                                        , p_fn_send_db_mail IN VARCHAR2
                                        , p_log_reason      IN VARCHAR2
                                        )
    RETURN BOOLEAN
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.deactivate_by_fn_send_db_mail';
    CURSOR cur_deactivate( cp_function_owner IN VARCHAR2
                         , cp_function_name  IN VARCHAR2
                         )
    IS
      SELECT executor_id
           , function_owner
        FROM sosl_executor
       WHERE function_owner  = cp_function_owner
         AND fn_send_db_mail = cp_function_name
    ;
  BEGIN
    l_return := TRUE;
    sosl_log.minimal_warning_log(l_self_caller, l_self_log_category, p_log_reason);
    FOR rec IN cur_deactivate(p_function_owner, p_fn_send_db_mail)
    LOOP
      -- disable executor
      UPDATE sosl_executor
         SET executor_active    = sosl_constants.NUM_NO
           , executor_reviewed  = sosl_constants.NUM_NO
       WHERE executor_id = rec.executor_id
      ;
      COMMIT;
      -- revoke grants for function owner
      IF NOT sosl_util.revoke_role(rec.function_owner, 'SOSL_EXECUTOR')
      THEN
        sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Unable to revoke grant SOSL_EXECUTOR from ' || rec.function_owner);
        -- if one fails, it all is in error
        l_return := FALSE;
      END IF;
    END LOOP;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END deactivate_by_fn_send_db_mail;

  FUNCTION build_script_call( p_function_owner  IN VARCHAR2
                            , p_function_name   IN VARCHAR2
                            )
    RETURN VARCHAR2
  IS
    l_statement VARCHAR2(1024);
  BEGIN
    IF p_function_owner IS NOT NULL
    THEN
      l_statement := 'SELECT ' || p_function_owner || '.' || p_function_name || ' FROM dual';
    ELSE
      l_statement := 'SELECT ' || p_function_name || ' FROM dual';
    END IF;
    RETURN l_statement;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_sys.build_script_call', 'SOSL_SYS', SQLERRM);
      RETURN 'SELECT -1 FROM dual';
  END build_script_call;

  FUNCTION build_signal_call( p_function_owner  IN VARCHAR2
                            , p_function_name   IN VARCHAR2
                            , p_run_id          IN NUMBER
                            , p_status          IN NUMBER
                            )
    RETURN VARCHAR2
  IS
    l_statement VARCHAR2(4000);
  BEGIN
    IF p_function_owner IS NOT NULL
    THEN
      l_statement := 'SELECT ' || p_function_owner || '.' || p_function_name || '(' ||
                     TRIM(TO_CHAR(p_run_id)) || ', ' || TRIM(TO_CHAR(p_status)) || ')' ||
                     ' FROM dual'
      ;
    ELSE
      l_statement := 'SELECT ' || p_function_name || '(' ||
                     TRIM(TO_CHAR(p_run_id)) || ', ' || TRIM(TO_CHAR(p_status)) || ')' ||
                     ' FROM dual';
    END IF;
    RETURN l_statement;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_sys.build_signal_call', 'SOSL_SYS', SQLERRM);
      RETURN 'SELECT -1 FROM dual';
  END build_signal_call;


  FUNCTION get_has_script_cnt
    RETURN NUMBER
  IS
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.get_has_script_cnt';
    l_total             NUMBER;
    l_count             NUMBER;
    l_success           BOOLEAN;
    l_statement         VARCHAR2(1024);
    CURSOR cur_fn_has_scripts
    IS
      SELECT function_owner
           , fn_has_scripts
        FROM sosl_executor
       WHERE executor_active   = sosl_constants.NUM_YES
         AND executor_reviewed = sosl_constants.NUM_YES
       GROUP BY function_owner
              , fn_has_scripts
    ;
  BEGIN
    -- flag to determine if at least one execution was successful
    l_success := FALSE;
    l_total   := 0;
    l_count   := 0;
    -- loop through functions
    FOR rec IN cur_fn_has_scripts
    LOOP
      l_statement := sosl_sys.build_script_call(rec.function_owner, rec.fn_has_scripts);
      BEGIN
        EXECUTE IMMEDIATE l_statement INTO l_count;
      EXCEPTION
        WHEN OTHERS THEN
          sosl_log.exception_log(l_self_caller, l_self_log_category, l_statement || ': ' || SQLERRM);
          l_count := -1;
      END;
      IF l_count < 0
      THEN
        -- we have errors with this function disable executors using this function
        IF NOT sosl_sys.deactivate_by_fn_has_scripts(rec.function_owner, rec.fn_has_scripts, 'Function returns exceptions or values below zero. Executors deactivated. Fix function issue before.')
        THEN
          -- error situation
          sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Could not deactivate executors for function ' || rec.fn_has_scripts || ' function owner ' || rec.function_owner);
        END IF;
      ELSE
        l_success := TRUE;
        l_total   := l_total + l_count;
      END IF;
    END LOOP;
    -- now check if we have at least one function executed with success
    IF NOT l_success
    THEN
      -- we should report the error situation
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'No defined has_scripts function is working. Disabled executors.');
      l_total := -1;
    END IF;
    RETURN l_total;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN -1;
  END get_has_script_cnt;

  FUNCTION is_executor_valid(p_executor_id IN NUMBER)
    RETURN BOOLEAN
  IS
    l_valid_count NUMBER;
    l_return      BOOLEAN;
  BEGIN
    l_return := FALSE;
    SELECT COUNT(*)
      INTO l_valid_count
      FROM sosl_executor
     WHERE executor_id        = p_executor_id
       AND executor_active    = sosl_constants.NUM_YES
       AND executor_reviewed  = sosl_constants.NUM_YES
    ;
    l_return := (l_valid_count != 0);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      sosl_log.exception_log('sosl_sys.is_executor_valid', 'SOSL_SYS', SQLERRM);
      RETURN FALSE;
  END is_executor_valid;

  FUNCTION is_executor(p_executor_id IN NUMBER)
    RETURN BOOLEAN
  IS
    l_valid_count NUMBER;
    l_return      BOOLEAN;
  BEGIN
    l_return := FALSE;
    SELECT COUNT(*)
      INTO l_valid_count
      FROM sosl_executor
     WHERE executor_id        = p_executor_id
    ;
    l_return := (l_valid_count != 0);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      sosl_log.exception_log('sosl_sys.is_executor', 'SOSL_SYS', SQLERRM);
      RETURN FALSE;
  END is_executor;

  FUNCTION has_valid_executors
    RETURN BOOLEAN
  IS
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.has_valid_executors';
  BEGIN
    l_return := (sosl_sys.get_valid_executor_cnt > 0);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END has_valid_executors;

  FUNCTION has_scripts
    RETURN NUMBER
  IS
    l_return            NUMBER;
    l_waiting           NUMBER;
    l_defined           NUMBER;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.has_scripts';
  BEGIN
    l_return      := -1;
    IF sosl_sys.has_valid_executors
    THEN
      -- initialize the total count
      l_return := 0;
      -- get count of waiting scripts
      l_waiting := sosl_sys.get_waiting_cnt;
      l_defined := sosl_sys.get_has_script_cnt;
      IF      l_waiting >= 0
         AND  l_defined >= 0
      THEN
        -- build total
        l_return := l_waiting + l_defined;
      ELSE
        -- report error
        sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Defined functions or run queue in error. Fix problems before expecting valid results');
        l_return := -1;
      END IF;
    ELSE
      -- log no valid executors
      sosl_log.minimal_warning_log(l_self_caller, l_self_log_category, 'Nothing to do, no valid executors. Return 0 scripts available');
      l_return := 0;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END has_scripts;

  FUNCTION has_run_id(p_run_id IN NUMBER)
    RETURN BOOLEAN
  IS
    l_return  BOOLEAN;
    l_count   NUMBER;
  BEGIN
    l_return := FALSE;
    SELECT COUNT(*)
      INTO l_count
      FROM sosl_run_queue
     WHERE run_id = p_run_id
    ;
    l_return := (l_count = 1);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_sys.has_run_id', 'SOSL_SYS', SQLERRM);
      RETURN FALSE;
  END has_run_id;

  FUNCTION get_run_state(p_run_id IN NUMBER)
    RETURN NUMBER
  IS
    l_run_state NUMBER;
  BEGIN
    IF sosl_sys.has_run_id(p_run_id)
    THEN
      SELECT run_state
        INTO l_run_state
        FROM sosl_run_queue
       WHERE run_id = p_run_id
      ;
    ELSE
      l_run_state := sosl_constants.RUN_STATE_ERROR;
    END IF;
    RETURN l_run_state;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_sys.get_run_state', 'SOSL_SYS', SQLERRM);
      RETURN -1;
  END get_run_state;

  FUNCTION get_payload(p_run_id IN NUMBER)
    RETURN SOSL_PAYLOAD
  IS
    l_payload           SOSL_PAYLOAD;
    l_executor_id       sosl_run_queue.executor_id%TYPE;
    l_ext_script_id     sosl_run_queue.ext_script_id%TYPE;
    l_script_file       sosl_run_queue.script_file%TYPE;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.get_payload';
  BEGIN
    l_payload := NULL;
    IF sosl_sys.has_run_id(p_run_id)
    THEN
      SELECT executor_id
           , ext_script_id
           , script_file
        INTO l_executor_id
           , l_ext_script_id
           , l_script_file
        FROM sosl_run_queue
       WHERE run_id = p_run_id
      ;
      l_payload := SOSL_PAYLOAD(l_executor_id, l_ext_script_id, l_script_file);
    ELSE
      l_payload := NULL;
      -- log error
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Invalid run id ' || p_run_id);
    END IF;
    RETURN l_payload;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN NULL;
  END get_payload;

  FUNCTION signal_status_change( p_run_id IN NUMBER
                               , p_status IN NUMBER
                               )
    RETURN BOOLEAN
  IS
    l_return                BOOLEAN;
    l_num_result            NUMBER;
    l_function_owner        sosl_executor.function_owner%TYPE;
    l_fn_set_script_status  sosl_executor.fn_set_script_status%TYPE;
    l_fn_send_db_mail       sosl_executor.fn_send_db_mail%TYPE;
    l_use_mail              sosl_executor.use_mail%TYPE;
    l_statement             VARCHAR2(4000);
    l_self_log_category     sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller           sosl_server_log.caller%TYPE       := 'sosl_sys.signal_status_change';
  BEGIN
    l_return := FALSE;
    IF sosl_sys.has_run_id(p_run_id)
    THEN
      -- get the defined function to signal the status change
      SELECT sexe.function_owner
           , sexe.fn_set_script_status
           , sexe.fn_send_db_mail
           , sexe.use_mail
        INTO l_function_owner
           , l_fn_set_script_status
           , l_fn_send_db_mail
           , l_use_mail
        FROM sosl_run_queue srqu
       INNER JOIN sosl_executor sexe
          ON srqu.executor_id = sexe.executor_id
       WHERE srqu.run_id = p_run_id
      ;
      l_statement := sosl_sys.build_signal_call(l_function_owner, l_fn_set_script_status, p_run_id, p_status);
      BEGIN
        EXECUTE IMMEDIATE l_statement INTO l_num_result;
        IF l_num_result = sosl_constants.NUM_SUCCESS
        THEN
          l_return := TRUE;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          sosl_log.exception_log(l_self_caller, l_self_log_category, l_statement || ': ' || SQLERRM);
      END;
      IF l_return
      THEN
        -- if mail activated execute also the defined mail function
        IF l_use_mail = sosl_constants.NUM_YES
        THEN
          l_statement := sosl_sys.build_signal_call(l_function_owner, l_fn_send_db_mail, p_run_id, p_status);
          BEGIN
            EXECUTE IMMEDIATE l_statement INTO l_num_result;
          EXCEPTION
            WHEN OTHERS THEN
              sosl_log.exception_log(l_self_caller, l_self_log_category, l_statement || ': ' || SQLERRM);
              l_num_result := sosl_constants.NUM_ERROR;
          END;
          IF l_num_result = sosl_constants.NUM_ERROR
          THEN
            IF NOT sosl_sys.deactivate_by_fn_send_db_mail(l_function_owner, l_fn_send_db_mail, 'Function returns exceptions or values below zero. Executors deactivated. Fix function issue before.')
            THEN
              sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Could not deactivate executors for function ' || l_fn_send_db_mail || ' function owner ' || l_function_owner);
            END IF;
          END IF;
        END IF;
      ELSE
        -- deactivate executors using the set_script_status function
        IF NOT sosl_sys.deactivate_by_fn_set_script_status(l_function_owner, l_fn_set_script_status, 'Function returns exceptions or values below zero. Executors deactivated. Fix function issue before.')
        THEN
          sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Could not deactivate executors for function ' || l_fn_set_script_status || ' function owner ' || l_function_owner);
        END IF;
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END signal_status_change;

  FUNCTION set_run_state( p_run_id IN NUMBER
                        , p_status IN NUMBER
                        )
    RETURN BOOLEAN
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            BOOLEAN;
    l_run_state         INTEGER;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.set_script_status';
  BEGIN
    l_return := FALSE;
    l_run_state := sosl_util.get_valid_run_state(p_status);
    IF sosl_sys.has_run_id(p_run_id)
    THEN
      UPDATE sosl_run_queue
         SET run_state = l_run_state
       WHERE run_id = p_run_id
      ;
      COMMIT;
      -- check that state was set successfully
      l_return := (l_run_state = sosl_sys.get_run_state(p_run_id));
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END set_run_state;

  FUNCTION set_script_status( p_run_id IN NUMBER
                            , p_status IN NUMBER
                            )
    RETURN NUMBER
  IS
    l_return            NUMBER;
    l_run_state         INTEGER;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.set_script_status';
  BEGIN
    l_return := -1;
    -- check status
    l_run_state := sosl_util.get_valid_run_state(p_status);
    -- check run id
    IF sosl_sys.has_run_id(p_run_id)
    THEN
      -- first set own status, then signal changes
      IF     sosl_sys.set_run_state(p_run_id, p_status)
         AND sosl_sys.signal_status_change(p_run_id, p_status)
      THEN
        l_return := 0;
      ELSE
        sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Could not set the run state to ' || p_status || ' for run id ' || p_run_id);
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END set_script_status;

  FUNCTION register_next_script( p_function_name  IN VARCHAR2
                               , p_function_owner IN VARCHAR2
                               )
    RETURN BOOLEAN
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            BOOLEAN;
    l_payload           SOSL_PAYLOAD;
    l_statement         VARCHAR2(1024);
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.register_next_script';
  BEGIN
    l_return := FALSE;
    l_statement := sosl_sys.build_script_call(p_function_owner, p_function_name);
    BEGIN
      EXECUTE IMMEDIATE l_statement INTO l_payload;
      IF      sosl_sys.is_executor_valid(l_payload.executor_id)
         AND  l_payload.ext_script_id IS NOT NULL
         AND  l_payload.script_file   IS NOT NULL
      THEN
        -- valid payload
        INSERT INTO sosl_run_queue
          (executor_id, ext_script_id, script_file)
          VALUES
          (l_payload.executor_id, l_payload.ext_script_id, l_payload.script_file)
        ;
        COMMIT;
        l_return := TRUE;
      ELSE
        -- invalid payload, check if usable and save with error state if possible
        IF     sosl_sys.is_executor(l_payload.executor_id)
           AND l_payload.ext_script_id IS NOT NULL
           AND l_payload.script_file   IS NOT NULL
        THEN
          -- insert the record with error state
          INSERT INTO sosl_run_queue
            (executor_id, ext_script_id, script_file, run_state)
            VALUES
            (l_payload.executor_id, l_payload.ext_script_id, l_payload.script_file, sosl_constants.RUN_STATE_ERROR)
          ;
          COMMIT;
        END IF;
        -- log the error
        sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'SOSL_PAYLOAD has invalid content, either the executor "' || l_payload.executor_id || '" is not valid or payload fields are NULL. External script id "' || l_payload.ext_script_id || '" script file "' || l_payload.script_file || '".');
        l_return := FALSE;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        sosl_log.exception_log(l_self_caller, l_self_log_category, l_statement || ': ' || SQLERRM);
        l_return := FALSE;
    END;
    -- if we have still FALSE return value, deactivate the executors for the given function
    IF NOT l_return
    THEN
      IF NOT sosl_sys.deactivate_by_fn_get_next_script(p_function_owner, p_function_name, 'Function returns exceptions or values below zero. Executors deactivated. Fix function issue before.')
      THEN
        -- log error
        sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Could not deactivate executors for function ' || p_function_name || ' function owner ' || p_function_owner);
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END register_next_script;

  FUNCTION register_waiting
    RETURN BOOLEAN
  IS
    l_return            BOOLEAN;
    l_success           BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.register_waiting';
    CURSOR cur_fn_get_next_script
    IS
      SELECT function_owner
           , fn_get_next_script
        FROM sosl_executor
       WHERE executor_active   = sosl_constants.NUM_YES
         AND executor_reviewed = sosl_constants.NUM_YES
       GROUP BY function_owner
              , fn_get_next_script
    ;
  BEGIN
    l_return  := FALSE;
    l_success := FALSE;
    FOR rec IN cur_fn_get_next_script
    LOOP
      IF sosl_sys.register_next_script(rec.fn_get_next_script, rec.function_owner)
      THEN
        l_success := TRUE;
      END IF;
    END LOOP;
    -- if at least one script was registered successfully, errors may be seen in the logs of register_next_script
    IF l_success
    THEN
      l_return := TRUE;
    ELSE
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Error fetching get_next_script functions. No defined function works correctly.');
      l_return := FALSE;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END register_waiting;

  FUNCTION fetch_next_run_id
    RETURN NUMBER
  IS
    l_run_id            NUMBER;
    l_count             NUMBER;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.fetch_next_run_id';
    -- get waiting run id, oldest first
    CURSOR cur_run_id
    IS
      SELECT run_id
        FROM sosl_run_queue
       WHERE run_state = sosl_constants.RUN_STATE_WAITING
       ORDER BY created
    ;
  BEGIN
    l_run_id := -1;
    SELECT COUNT(*) INTO l_count FROM sosl_run_queue WHERE run_state = sosl_constants.RUN_STATE_WAITING;
    IF l_count > 0
    THEN
      OPEN cur_run_id;
      FETCH cur_run_id INTO l_run_id;
      CLOSE cur_run_id;
    END IF;
    RETURN l_run_id;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END fetch_next_run_id;

  FUNCTION get_next_script
    RETURN NUMBER
  IS
    l_run_id            NUMBER;
    l_state_result      NUMBER;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.get_next_script';
  BEGIN
    l_run_id := -1;
    -- if we have scripts
    IF sosl_sys.has_scripts > 0
    THEN
      -- select all valid executors and get their results, store results in SOSL_RUN_QUEUE.
      IF NOT sosl_sys.register_waiting
      THEN
        -- probably an error with defined functions, log the error
        sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Defined functions in error, not registered any new script.');
      END IF;
      -- as we should have scripts, the run queue still may have scripts even if register failed
      l_run_id := sosl_sys.fetch_next_run_id;
      IF l_run_id = sosl_constants.NUM_ERROR
      THEN
        -- log the error
        sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Unable to fetch next run id.');
      ELSE
        -- mark run id as enqueued
        l_state_result := sosl_sys.set_script_status(l_run_id, sosl_constants.RUN_STATE_ENQUEUED);
        IF l_state_result = sosl_constants.NUM_ERROR
        THEN
          sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Could not update run state to ENQUEUED for run id: ' || l_run_id);
        END IF;
      END IF;
    END IF;
    RETURN l_run_id;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END get_next_script;

END;
/

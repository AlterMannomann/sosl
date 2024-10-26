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
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SYS';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_sys.deactivate_by_fn_has_scripts';
  BEGIN
    sosl_log.minimal_warning_log(l_self_caller, l_self_log_category, p_log_reason);
    UPDATE sosl_executor
       SET executor_active    = sosl_constants.NUM_NO
         , executor_reviewed  = sosl_constants.NUM_NO
     WHERE function_owner = p_function_owner
       AND fn_has_scripts = p_fn_has_scripts
    ;
    COMMIT;
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END deactivate_by_fn_has_scripts;

  FUNCTION build_script_call( p_function_name   IN VARCHAR2
                            , p_function_owner  IN VARCHAR2 DEFAULT NULL
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
      l_statement := sosl_sys.build_script_call(rec.fn_has_scripts, rec.function_owner);
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

  FUNCTION has_valid_executors
    RETURN BOOLEAN
  IS
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE := 'HAS_SCRIPTS';
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
    l_self_log_category sosl_server_log.log_category%TYPE := 'HAS_SCRIPTS';
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

  FUNCTION get_next_script
    RETURN NUMBER
  IS
  BEGIN
    RETURN NULL;
  END get_next_script;

  FUNCTION set_config( p_config_name  IN VARCHAR2
                     , p_config_value IN VARCHAR2
                     )
    RETURN NUMBER
  IS
  BEGIN
    RETURN NULL;
  END set_config;

  FUNCTION get_config(p_config_name IN VARCHAR2)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END get_config;

  FUNCTION base_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END base_path;

  FUNCTION cfg_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END cfg_path;

  FUNCTION tmp_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END tmp_path;

  FUNCTION log_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END log_path;

END;
/

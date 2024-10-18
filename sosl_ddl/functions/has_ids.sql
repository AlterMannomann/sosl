-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE OR REPLACE FUNCTION has_ids
  RETURN NUMBER
IS
  /* Wrapper function for defined executor has_ids functions.
  * Collects and sums the output of all defined executor has_ids functions of active and reviewed executors that
  * return a number greater 0. Will log all functions in error.
  *
  * @return The amount of scripts waiting for all valid executor has_ids functions or -1 if all functions have errors.
  */
  -- variables
  l_cnt_valid   NUMBER;
  l_id_cnt      NUMBER;
  l_tmp_cnt     NUMBER;
  l_success_cnt NUMBER;
  l_category    VARCHAR2(256) := 'HAS_IDS';
  l_caller      VARCHAR2(256) := 'has_ids';
  -- cursors
  CURSOR cur_fn_call
  IS
    SELECT DISTINCT fn_has_ids AS fn_call
      FROM sosl_executor
     WHERE executor_active   = 1
       AND executor_reviewed = 1
  ;
BEGIN
  l_id_cnt      := -1;
  l_success_cnt := 0;
  -- log the call
  sosl_log.full_log( p_message => 'HAS_IDS called by OS user ' || SYS_CONTEXT('USERENV', 'OS_USER')
                   , p_log_type => sosl_sys.INFO_TYPE
                   , p_log_category => l_category
                   , p_caller => l_caller
                   )
  ;
  SELECT COUNT(*) INTO l_cnt_valid FROM sosl_executor WHERE executor_active = 1 AND executor_reviewed = 1;
  IF l_cnt_valid > 0
  THEN
    -- get the results and sum them up
    FOR rec IN cur_fn_call
    LOOP
      l_tmp_cnt := -1;
      BEGIN
        EXECUTE IMMEDIATE rec.fn_call INTO l_tmp_cnt;
        l_success_cnt := l_success_cnt +1;
      EXCEPTION
        WHEN OTHERS THEN
          -- log the error
          sosl_log.full_log( p_message => 'Exception for defined function ' || rec.fn_call || ': ' || SQLERRM
                           , p_log_type => sosl_sys.ERROR_TYPE
                           , p_log_category => l_category
                           , p_caller => rec.fn_call
                           )
          ;
      END;
      IF l_tmp_cnt >= 0
      THEN
        l_id_cnt := l_id_cnt + l_tmp_cnt;
      ELSE
        -- log error functions including those returning -1 without throwing exceptions
        sosl_log.full_log( p_message => 'Error using defined function ' || rec.fn_call || ' either an exception occured (separately logged) or the function returned -1'
                         , p_log_type => sosl_sys.ERROR_TYPE
                         , p_log_category => l_category
                         , p_caller => rec.fn_call
                         )
        ;
      END IF;
    END LOOP;
    IF l_success_cnt = 0
    THEN
      sosl_log.full_log( p_message => 'HAS_IDS did not find any valid executor has_ids functions'
                       , p_log_type => sosl_sys.ERROR_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
      l_id_cnt := -1;
    END IF;
  ELSE
    -- log no valid executors
    sosl_log.full_log( p_message => 'HAS_IDS called without valid executors defined'
                     , p_log_type => sosl_sys.WARNING_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    l_id_cnt := 0;
  END IF;
  RETURN l_id_cnt;
EXCEPTION
  WHEN OTHERS THEN
    -- log the error
    sosl_log.full_log( p_message => 'Unhandled exception in HAS_IDS wrapper function: ' || SQLERRM
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RETURN -1;
END;
/
-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE OR REPLACE PACKAGE BODY sosl_api
AS
  -- for description see header file
  FUNCTION has_scripts
    RETURN NUMBER
  IS
    l_return      NUMBER;
    l_success_cnt NUMBER;
    l_cnt_valid   NUMBER;
    l_tmp_cnt     NUMBER;
    l_queue_table VARCHAR2(128)                     := 'SOSL_SCRIPT_QUEUE';
    l_category    sosl_server_log.log_category%TYPE := 'HAS_SCRIPTS';
    l_caller      sosl_server_log.caller%TYPE       := 'sosl_api.has_scripts queue and executor';
    CURSOR cur_executors
    IS
      SELECT UPPER(fn_has_scripts) AS fn_has_scripts
        FROM sosl_executor
       WHERE executor_active       = 1
         AND executor_reviewed     = 1
       GROUP BY UPPER(fn_has_scripts)
    ;
  BEGIN
    l_return      := -1;
    l_success_cnt := 0;
    sosl_log.full_log( p_message => 'sosl_api.has_scripts called'
                     , p_log_type => sosl_sys.INFO_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    SELECT COUNT(*) INTO l_cnt_valid FROM sosl_executor WHERE executor_active = 1 AND executor_reviewed = 1;
    IF l_cnt_valid > 0
    THEN
      l_return := 0;
      -- loop through unique defined functions
      FOR rec IN cur_executors
      LOOP
        l_tmp_cnt := sosl_api.has_scripts_for_fn(rec.fn_has_scripts);
        IF l_tmp_cnt > 0
        THEN
          l_success_cnt := l_success_cnt +1;
          l_return      := l_return + l_tmp_cnt;
        END IF;
      END LOOP;
      -- now check queue for waiting message, overrule failed functions calls if messages waiting
      l_tmp_cnt := sosl_api.has_scripts(l_queue_table);
      IF l_tmp_cnt > 0
      THEN
        l_success_cnt := l_success_cnt +1;
        l_return      := l_return + l_tmp_cnt;
      END IF;
      -- if not at least one successful executed
      IF l_success_cnt <= 0
      THEN
        sosl_log.full_log( p_message => 'sosl_api.has_scripts did not find any valid executor has_scripts functions and messages in the queue. Return 0 scripts waiting.'
                         , p_log_type => sosl_sys.ERROR_TYPE
                         , p_log_category => l_category
                         , p_caller => l_caller
                         )
        ;
        l_return := 0;
      END IF;
    ELSE
      -- log no valid executors
      sosl_log.full_log( p_message => 'sosl_api.has_scripts called without valid executors defined. Return 0 scripts waiting.'
                       , p_log_type => sosl_sys.WARNING_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
      l_return := 0;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.full_log( p_message => 'Unhandled exception in sosl_api.has_scripts function: ' || SQLERRM
                       , p_log_type => sosl_sys.FATAL_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
      RETURN -1;
  END has_scripts;

  FUNCTION has_scripts(p_identifier IN NUMBER)
    RETURN NUMBER
  IS
    l_has_executor  NUMBER;
    l_return        NUMBER;
    l_fn_call       sosl_executor.fn_has_scripts%TYPE;
    l_category      sosl_server_log.log_category%TYPE   := 'HAS_SCRIPTS';
    l_caller        sosl_server_log.caller%TYPE         := 'sosl_api.has_scripts executor';
  BEGIN
    l_return := -1;
    sosl_log.full_log( p_message => 'sosl_api.has_scripts executer check p_identifier: ' || p_identifier
                     , p_log_type => sosl_sys.INFO_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    SELECT COUNT(*)
      INTO l_has_executor
      FROM sosl_executor
     WHERE executor_active   = 1
       AND executor_reviewed = 1
    ;
    IF l_has_executor = 0
    THEN
      sosl_log.full_log( p_message => 'The given executor id does not exist or is not active and reviewed: "' || p_identifier || '". Return 0 scripts waiting.'
                       , p_log_type => sosl_sys.ERROR_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
      l_return := 0;
    ELSE
      SELECT fn_has_scripts INTO l_fn_call FROM sosl_executor WHERE executor_id = p_identifier;
      l_return := sosl_api.has_scripts_for_fn(l_fn_call);
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.full_log( p_message => 'Unhandled exception in sosl_api.has_scripts for executor function: ' || SQLERRM
                       , p_log_type => sosl_sys.FATAL_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
      RETURN -1;
  END has_scripts;

  FUNCTION has_scripts(p_identifier IN VARCHAR2)
    RETURN NUMBER
  IS
    l_has_queue   NUMBER;
    l_return      NUMBER;
    l_category    sosl_server_log.log_category%TYPE := 'HAS_SCRIPTS';
    l_caller      sosl_server_log.caller%TYPE       := 'sosl_api.has_scripts queue';
  BEGIN
    l_return := -1;
    sosl_log.full_log( p_message => 'sosl_api.has_scripts queue check p_identifier: ' || p_identifier
                     , p_log_type => sosl_sys.INFO_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    SELECT COUNT(*)
      INTO l_has_queue
      FROM user_objects
     WHERE object_name = UPPER(p_identifier)
       AND object_type = 'TABLE'
    ;
    IF l_has_queue = 0
    THEN
      sosl_log.full_log( p_message => 'The given queue table name does not exist in the current user schema: "' || UPPER(p_identifier) || '". Return 0 scripts waiting.'
                       , p_log_type => sosl_sys.ERROR_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
      l_return := 0;
    ELSE
      BEGIN
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || p_identifier INTO l_return;
      EXCEPTION
        WHEN OTHERS THEN
          sosl_log.full_log( p_message => 'Unhandled exception in sosl_api.has_scripts for queue function checking queue table: ' || SQLERRM
                           , p_log_type => sosl_sys.FATAL_TYPE
                           , p_log_category => l_category
                           , p_caller => l_caller
                           )
          ;
          l_return := -1;
      END;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.full_log( p_message => 'Unhandled exception in sosl_api.has_scripts for queue function: ' || SQLERRM
                       , p_log_type => sosl_sys.FATAL_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
      RETURN -1;
  END has_scripts;

  FUNCTION has_scripts_for_fn(p_fn_has_scripts IN VARCHAR2)
    RETURN NUMBER
  IS
    l_has_function  NUMBER;
    l_return        NUMBER;
    l_fn_valid      BOOLEAN;
    l_fn_call       sosl_executor.fn_has_scripts%TYPE;
    l_category      sosl_server_log.log_category%TYPE   := 'HAS_SCRIPTS';
    l_caller        sosl_server_log.caller%TYPE         := 'sosl_api.has_scripts_for_fn';
    CURSOR cur_fn_owner(cp_fn_name IN VARCHAR2)
    IS
      SELECT function_owner
        FROM sosl_executor
       WHERE UPPER(fn_has_scripts) = UPPER(cp_fn_name)
         AND executor_active       = 1
         AND executor_reviewed     = 1
       GROUP BY function_owner
    ;
  BEGIN
    l_return  := -1;
    sosl_log.full_log( p_message => 'sosl_api.has_scripts_for_fn defined function check p_fn_has_scripts: ' || p_fn_has_scripts
                     , p_log_type => sosl_sys.INFO_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    SELECT COUNT(*)
      INTO l_has_function
      FROM sosl_executor
     WHERE UPPER(fn_has_scripts) = UPPER(p_fn_has_scripts)
       AND executor_active       = 1
       AND executor_reviewed     = 1
    ;
    IF l_has_function = 0
    THEN
      sosl_log.full_log( p_message => 'The given function name does not have an active and reviewed executor: "' || UPPER(p_fn_has_scripts) || '". Return 0 scripts waiting.'
                       , p_log_type => sosl_sys.ERROR_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
      l_return := 0;
    ELSE
      -- check function owner, to verify function exists
      l_fn_valid := FALSE;
      FOR rec IN cur_fn_owner(p_fn_has_scripts)
      LOOP
        IF sosl_sys.has_function(rec.function_owner, UPPER(p_fn_has_scripts), 'NUMBER')
        THEN
          l_fn_valid := TRUE;
          EXIT;
        END IF;
      END LOOP;
      IF l_fn_valid
      THEN
        BEGIN
          EXECUTE IMMEDIATE p_fn_has_scripts INTO l_return;
        EXCEPTION
          WHEN OTHERS THEN
            sosl_log.full_log( p_message => 'Unhandled exception in sosl_api.has_scripts_for_fn for calling defined function: ' || p_fn_has_scripts || ' Error: ' || SQLERRM
                             , p_log_type => sosl_sys.FATAL_TYPE
                             , p_log_category => l_category
                             , p_caller => l_caller
                             )
            ;
            l_return := -1;
        END;
      ELSE
        sosl_log.full_log( p_message => 'The given function ' || p_fn_has_scripts || ' is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has not return datatype NUMBER or is not granted with EXECUTE rights to SOSL. Return 0 scripts waiting.'
                         , p_log_type => sosl_sys.ERROR_TYPE
                         , p_log_category => l_category
                         , p_caller => l_caller
                         )
        ;
        l_return := 0;
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.full_log( p_message => 'Unhandled exception in sosl_api.has_scripts_for_fn function: ' || SQLERRM
                       , p_log_type => sosl_sys.FATAL_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
      RETURN -1;
  END has_scripts_for_fn;

  FUNCTION get_next_script
    RETURN SOSL_PAYLOAD
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

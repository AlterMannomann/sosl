-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE PACKAGE BODY sosl_api
AS
  -- for description see header file
  FUNCTION get_config(p_config_name IN VARCHAR2)
    RETURN VARCHAR2
  IS
    l_return        VARCHAR2(4000);
    l_user          VARCHAR2(128);
    l_log_category  sosl_server_log.log_category%TYPE := 'SOSL_API';
    l_caller        sosl_server_log.caller%TYPE       := 'sosl_api.get_config';
  BEGIN
    l_user   := SYS_CONTEXT('USERENV', 'SESSION_USER');
    l_return := sosl_server.get_config(p_config_name);
    IF NOT sosl_util.has_role(l_user, 'SOSL_REVIEWER')
    THEN
      IF p_config_name = 'SOSL_PATH_CFG'
      THEN
        sosl_log.minimal_warning_log(l_caller, l_log_category, 'User ' || l_user || ' requested SOSL_PATH_CFG without sufficient role rights.');
        l_return := '*** at least SOSL_REVIEWER role needed to see this value';
      END IF;
    END IF;
    IF l_return = '-1'
    THEN
      l_return := 'ERROR executing SOSL_SERVER.GET_CONFIG see SOSL_SERVER_LOG for details';
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN 'ERROR executing SOSL_API.GET_CONFIG see SOSL_SERVER_LOG for details';
  END get_config;

  FUNCTION set_runmode(p_runmode IN VARCHAR2 DEFAULT 'RUN')
    RETURN VARCHAR2
  IS
    l_return        VARCHAR2(4000);
    l_result        NUMBER;
    l_user          VARCHAR2(128);
    l_log_category  sosl_server_log.log_category%TYPE := 'SOSL_API';
    l_caller        sosl_server_log.caller%TYPE       := 'sosl_api.set_runmode';
  BEGIN
    l_user   := SYS_CONTEXT('USERENV', 'SESSION_USER');
    IF sosl_util.has_role(l_user, 'SOSL_EXECUTOR')
    THEN
      l_result := sosl_server.set_runmode(p_runmode);
      IF l_result = -1
      THEN
        l_return := 'ERROR executing SOSL_SERVER.SET_RUNMODE with ' || p_runmode || ' see SOSL_SERVER_LOG for details';
      ELSE
        l_return := 'SUCCESS set runmode to ' || p_runmode;
      END IF;
    ELSE
      sosl_log.minimal_warning_log(l_caller, l_log_category, 'User ' || l_user || ' wanted to set runmode to ' || p_runmode || ' without sufficient role rights.');
      l_return := 'ERROR insufficient privileges. Needs at least role SOSL_EXECUTOR.';
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN 'ERROR executing SOSL_API.SET_RUNMODE see SOSL_SERVER_LOG for details';
  END set_runmode;

  FUNCTION set_timeframe( p_from IN VARCHAR2 DEFAULT '07:55'
                        , p_to   IN VARCHAR2 DEFAULT '18:00'
                        )
    RETURN VARCHAR2
  IS
    l_return        VARCHAR2(4000);
    l_user          VARCHAR2(128);
    l_from_result   NUMBER;
    l_to_result     NUMBER;
    l_log_category  sosl_server_log.log_category%TYPE := 'SOSL_API';
    l_caller        sosl_server_log.caller%TYPE       := 'sosl_api.set_timeframe';
  BEGIN
    l_user   := SYS_CONTEXT('USERENV', 'SESSION_USER');
    IF sosl_util.has_role(l_user, 'SOSL_EXECUTOR')
    THEN
      l_from_result := sosl_server.set_config('SOSL_START_JOBS', p_from);
      l_to_result   := sosl_server.set_config('SOSL_STOP_JOBS', p_to);
      IF    l_from_result = -1
         OR l_to_result   = -1
      THEN
        -- logging should be done by called function
        l_return := 'ERROR executing sosl_server.set_config';
        IF l_from_result = -1
        THEN
          l_return := l_return || ' SOSL_START_JOBS: ' || p_from;
        END IF;
        IF l_to_result = -1
        THEN
          l_return := l_return || ' SOSL_STOP_JOBS ' || p_to;
        END IF;
        l_return := l_return || ' see SOSL_SERVER_LOG for details';
      ELSE
        IF p_from = '-1' OR p_to = '-1'
        THEN
          l_return := 'SUCCESS disabled server timeframe with -1';
        ELSE
          l_return := 'SUCCESS set server timeframe to ' || p_from || ' - ' || p_to;
        END IF;
      END IF;
    ELSE
      sosl_log.minimal_warning_log(l_caller, l_log_category, 'User ' || l_user || ' wanted to set server timeframe to ' || p_from || ' - ' || p_to || ' without sufficient role rights.');
      l_return := 'ERROR insufficient privileges. Needs at least role SOSL_EXECUTOR.';
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN 'ERROR executing SOSL_API.SET_TIMEFRAME see SOSL_SERVER_LOG for details';
  END set_timeframe;

  FUNCTION create_executor( p_executor_name         IN VARCHAR2
                          , p_function_owner        IN VARCHAR2
                          , p_fn_has_scripts        IN VARCHAR2
                          , p_fn_get_next_script    IN VARCHAR2
                          , p_fn_set_script_status  IN VARCHAR2
                          , p_cfg_file              IN VARCHAR2
                          , p_use_mail              IN NUMBER     DEFAULT 0
                          , p_fn_send_db_mail       IN VARCHAR2   DEFAULT NULL
                          , p_executor_description  IN VARCHAR2   DEFAULT NULL
                          )
    RETURN NUMBER
  IS
    l_return        NUMBER;
    l_user          VARCHAR2(128);
    l_log_category  sosl_server_log.log_category%TYPE := 'SOSL_API';
    l_caller        sosl_server_log.caller%TYPE       := 'sosl_api.create_executor';
  BEGIN
    l_user   := SYS_CONTEXT('USERENV', 'SESSION_USER');
    IF sosl_util.has_role(l_user, 'SOSL_EXECUTOR')
    THEN
      l_return := sosl_util.create_executor( p_executor_name
                                           , l_user
                                           , p_function_owner
                                           , p_fn_has_scripts
                                           , p_fn_get_next_script
                                           , p_fn_set_script_status
                                           , p_cfg_file
                                           , p_use_mail
                                           , p_fn_send_db_mail
                                           , p_executor_description
                                           )
      ;
    ELSE
      sosl_log.minimal_warning_log(l_caller, l_log_category, 'User ' || l_user || ' wanted to create an executor named ' || p_executor_name || ' using function owner ' || p_function_owner || ' without sufficient role rights.');
      l_return := -1;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN -1;
  END create_executor;

  FUNCTION activate_executor(p_executor_id IN NUMBER)
    RETURN VARCHAR2
  IS
    l_return        VARCHAR2(4000);
    l_user          VARCHAR2(128);
    l_result        NUMBER;
    l_log_category  sosl_server_log.log_category%TYPE := 'SOSL_API';
    l_caller        sosl_server_log.caller%TYPE       := 'sosl_api.activate_executor';
  BEGIN
    l_user   := SYS_CONTEXT('USERENV', 'SESSION_USER');
    IF sosl_util.has_role(l_user, 'SOSL_EXECUTOR')
    THEN
      l_result := sosl_util.active_state_executor(p_executor_id, sosl_constants.NUM_YES);
      IF l_result = -1
      THEN
        l_return := 'ERROR activating executor with id ' || p_executor_id || ' see SOSL_SERVER_LOG for details';
      ELSE
        l_return := 'SUCCESS Activated executor with id ' || p_executor_id;
      END IF;
    ELSE
      sosl_log.minimal_warning_log(l_caller, l_log_category, 'User ' || l_user || ' wanted to activate executor with id ' || p_executor_id || ' without sufficient role rights.');
      l_return := 'ERROR insufficient privileges. Needs at least role SOSL_EXECUTOR.';
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN 'ERROR executing SOSL_API.ACTIVATE_EXECUTOR see SOSL_SERVER_LOG for details';
  END activate_executor;

  FUNCTION deactivate_executor(p_executor_id IN NUMBER)
    RETURN VARCHAR2
  IS
    l_return        VARCHAR2(4000);
    l_user          VARCHAR2(128);
    l_result        NUMBER;
    l_log_category  sosl_server_log.log_category%TYPE := 'SOSL_API';
    l_caller        sosl_server_log.caller%TYPE       := 'sosl_api.deactivate_executor';
  BEGIN
    l_user   := SYS_CONTEXT('USERENV', 'SESSION_USER');
    IF sosl_util.has_role(l_user, 'SOSL_EXECUTOR')
    THEN
      l_result := sosl_util.active_state_executor(p_executor_id, sosl_constants.NUM_NO);
      IF l_result = -1
      THEN
        l_return := 'ERROR deactivating executor with id ' || p_executor_id || ' see SOSL_SERVER_LOG for details';
      ELSE
        l_return := 'SUCCESS Deactivated executor with id ' || p_executor_id;
      END IF;
    ELSE
      sosl_log.minimal_warning_log(l_caller, l_log_category, 'User ' || l_user || ' wanted to deactivate executor with id ' || p_executor_id || ' without sufficient role rights.');
      l_return := 'ERROR insufficient privileges. Needs at least role SOSL_EXECUTOR.';
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN 'ERROR executing SOSL_API.DEACTIVATE_EXECUTOR see SOSL_SERVER_LOG for details';
  END deactivate_executor;

  FUNCTION set_executor_reviewed(p_executor_id IN NUMBER)
    RETURN VARCHAR2
  IS
    l_return        VARCHAR2(4000);
    l_user          VARCHAR2(128);
    l_result        NUMBER;
    l_log_category  sosl_server_log.log_category%TYPE := 'SOSL_API';
    l_caller        sosl_server_log.caller%TYPE       := 'sosl_api.set_executor_reviewed';
  BEGIN
    l_user   := SYS_CONTEXT('USERENV', 'SESSION_USER');
    IF sosl_util.has_role(l_user, 'SOSL_REVIEWER')
    THEN
      l_result := sosl_util.review_state_executor(p_executor_id, sosl_constants.NUM_YES);
      IF l_result = -1
      THEN
        l_return := 'ERROR set executor with id ' || p_executor_id || ' to reviewed see SOSL_SERVER_LOG for details';
      ELSE
        l_return := 'SUCCESS Set executor with id ' || p_executor_id || ' to reviewed';
      END IF;
    ELSE
      sosl_log.minimal_warning_log(l_caller, l_log_category, 'User ' || l_user || ' wanted to set executor with id ' || p_executor_id || ' to reviewed without sufficient role rights.');
      l_return := 'ERROR insufficient privileges. Needs at least role SOSL_REVIEWER.';
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN 'ERROR executing SOSL_API.SET_EXECUTOR_REVIEWED see SOSL_SERVER_LOG for details';
  END set_executor_reviewed;

  FUNCTION revoke_executor_reviewed(p_executor_id IN NUMBER)
    RETURN VARCHAR2
  IS
    l_return        VARCHAR2(4000);
    l_user          VARCHAR2(128);
    l_result        NUMBER;
    l_log_category  sosl_server_log.log_category%TYPE := 'SOSL_API';
    l_caller        sosl_server_log.caller%TYPE       := 'sosl_api.revoke_executor_reviewed';
  BEGIN
    l_user   := SYS_CONTEXT('USERENV', 'SESSION_USER');
    IF sosl_util.has_role(l_user, 'SOSL_REVIEWER')
    THEN
      l_result := sosl_util.review_state_executor(p_executor_id, sosl_constants.NUM_NO);
      IF l_result = -1
      THEN
        l_return := 'ERROR set executor with id ' || p_executor_id || ' to not reviewed see SOSL_SERVER_LOG for details';
      ELSE
        l_return := 'SUCCESS Set executor with id ' || p_executor_id || ' to not reviewed';
      END IF;
    ELSE
      sosl_log.minimal_warning_log(l_caller, l_log_category, 'User ' || l_user || ' wanted to set executor with id ' || p_executor_id || ' to not reviewed without sufficient role rights.');
      l_return := 'ERROR insufficient privileges. Needs at least role SOSL_REVIEWER.';
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN 'ERROR executing SOSL_API.REVOKE_EXECUTOR_REVIEWED see SOSL_SERVER_LOG for details';
  END revoke_executor_reviewed;

  FUNCTION add_script( p_script_name    IN VARCHAR2
                     , p_executor_id    IN NUMBER
                     , p_run_order      IN NUMBER   DEFAULT 1
                     , p_script_active  IN NUMBER   DEFAULT 0
                     )
    RETURN NUMBER
  IS
    l_return        NUMBER;
    l_log_category  sosl_server_log.log_category%TYPE := 'SOSL_API';
    l_caller        sosl_server_log.caller%TYPE       := 'sosl_api.add_script';
  BEGIN
    l_return := sosl_if.add_script(p_script_name, p_executor_id, p_run_order, p_script_active);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN -1;
  END add_script;

END;
/

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

END;
/

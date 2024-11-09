-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE PACKAGE BODY sosl_server
AS
  -- for description see header file
  /*====================================== start internal functions made visible for testing ======================================*/
  FUNCTION has_config_name(p_config_name IN VARCHAR2)
    RETURN BOOLEAN
  IS
    l_return            BOOLEAN;
    l_count             NUMBER;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SERVER';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_server.has_config_name';
  BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM sosl_config
     WHERE config_name = p_config_name
    ;
    l_return := (l_count = 1);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.has_config_name', 'SOSL_SERVER', SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN FALSE;
  END has_config_name;


  FUNCTION set_guid( p_run_id IN NUMBER
                   , p_guid   IN VARCHAR2
                   )
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            NUMBER;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SERVER';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_server.set_guid';
  BEGIN
    l_return := -1;
    IF sosl_sys.has_run_id(p_run_id)
    THEN
      UPDATE sosl_run_queue
         SET script_guid = p_guid
       WHERE run_id = p_run_id
      ;
      COMMIT;
      l_return := 0;
    ELSE
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Requested run id ' || p_run_id || ' does not exist.');
      l_return := -1;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END set_guid;

  FUNCTION set_identifier( p_run_id     IN NUMBER
                         , p_identifier IN VARCHAR2
                         )
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            NUMBER;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SERVER';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_server.set_identifier';
  BEGIN
    l_return := -1;
    IF sosl_sys.has_run_id(p_run_id)
    THEN
      UPDATE sosl_run_queue
         SET sosl_identifier = p_identifier
       WHERE run_id = p_run_id
      ;
      COMMIT;
      l_return := 0;
    ELSE
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Requested run id ' || p_run_id || ' does not exist.');
      l_return := -1;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END set_identifier;
  /*====================================== end internal functions made visible for testing ======================================*/

  FUNCTION set_config( p_config_name  IN VARCHAR2
                     , p_config_value IN VARCHAR2
                     )
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            NUMBER;
    l_set_value         BOOLEAN;
    l_config_value      sosl_config.config_value%TYPE;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SERVER';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_server.set_config';
  BEGIN
    l_return := -1;
    IF sosl_server.has_config_name(p_config_name)
    THEN
      l_set_value    := TRUE;
      l_config_value := TRIM(p_config_value);
      -- do some extra checks on config name SOSL_RUNMODE and SOSL_SERVER_STATE
      IF p_config_name IN ('SOSL_RUNMODE', 'SOSL_SERVER_STATE')
      THEN
        -- make commands uppercase
        l_config_value := UPPER(l_config_value);
        IF     p_config_name      = 'SOSL_RUNMODE'
           AND l_config_value NOT IN ('RUN', 'WAIT', 'STOP')
        THEN
          -- log the error and do not change the config value
          sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Invalid run mode: ' || l_config_value || '. Configuration not changed');
          l_set_value := FALSE;
        END IF;
        IF      p_config_name = 'SOSL_SERVER_STATE'
           AND  l_config_value NOT IN ('ACTIVE', 'INACTIVE', 'PAUSE')
        THEN
          -- log the error and do not change the config value
          sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Invalid server state: ' || l_config_value || '. Configuration not changed');
          l_set_value := FALSE;
        END IF;
      END IF;
      IF l_set_value
      THEN
        UPDATE sosl_config
           SET config_value = p_config_value
         WHERE config_name = p_config_name
        ;
        COMMIT;
        l_return := 0;
      END IF;
    ELSE
      -- log error wrong config name
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Requested config name "' || p_config_name || '" does not exist.');
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END set_config;

  FUNCTION get_config(p_config_name IN VARCHAR2)
    RETURN VARCHAR2
  IS
    l_config_value      sosl_config.config_value%TYPE;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SERVER';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_server.get_config';
  BEGIN
    l_config_value := '-1';
    IF sosl_server.has_config_name(p_config_name)
    THEN
      SELECT config_value
        INTO l_config_value
        FROM sosl_config
       WHERE config_name = p_config_name
      ;
    ELSE
      -- log error wrong config name
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Requested config name "' || p_config_name || '" does not exist.');
      l_config_value := '-1';
    END IF;
    RETURN l_config_value;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN '-1';
  END get_config;

  FUNCTION set_server_state(p_server_state IN VARCHAR2)
    RETURN NUMBER
  IS
    l_return  NUMBER;
  BEGIN
    l_return := sosl_server.set_config('SOSL_SERVER_STATE', p_server_state);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.set_server_state', 'SOSL_SERVER', SQLERRM);
      RETURN -1;
  END set_server_state;

  FUNCTION set_runmode(p_runmode IN VARCHAR2)
    RETURN NUMBER
  IS
    l_return  NUMBER;
  BEGIN
    l_return := sosl_server.set_config('SOSL_RUNMODE', p_runmode);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.set_runmode', 'SOSL_SERVER', SQLERRM);
      RETURN -1;
  END set_runmode;

  FUNCTION get_executor_cfg(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
    l_executor_cfg      sosl_executor_definition.cfg_file%TYPE;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SERVER';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_server.get_executor_cfg';
  BEGIN
    l_executor_cfg := '-1';
    IF sosl_sys.has_run_id(p_run_id)
    THEN
      SELECT sed.cfg_file
        INTO l_executor_cfg
        FROM sosl_run_queue srq
        LEFT OUTER JOIN sosl_executor_definition sed
          ON srq.executor_id = sed.executor_id
       WHERE srq.run_id = p_run_id
      ;
    ELSE
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Requested run id ' || p_run_id || ' does not exist.');
      l_executor_cfg := '-1';
    END IF;
    RETURN l_executor_cfg;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN '-1';
  END get_executor_cfg;

  FUNCTION get_script_file(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
    l_script_file       sosl_run_queue.script_file%TYPE;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SERVER';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_server.get_script_file';
  BEGIN
    l_script_file := '-1';
    IF sosl_sys.has_run_id(p_run_id)
    THEN
      SELECT script_file
        INTO l_script_file
        FROM sosl_run_queue
       WHERE run_id = p_run_id
      ;
    ELSE
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Requested run id ' || p_run_id || ' does not exist.');
      l_script_file := '-1';
    END IF;
    RETURN l_script_file;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN '-1';
  END get_script_file;

  FUNCTION get_script_schema(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
    l_script_schema     sosl_executor_definition.function_owner%TYPE;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_SERVER';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_server.get_script_schema';
  BEGIN
    l_script_schema := TRIM(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'));
    IF sosl_sys.has_run_id(p_run_id)
    THEN
      SELECT sed.function_owner
        INTO l_script_schema
        FROM sosl_run_queue srq
        LEFT OUTER JOIN sosl_executor_definition sed
          ON srq.executor_id = sed.executor_id
       WHERE srq.run_id = p_run_id
      ;
    ELSE
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'Requested run id ' || p_run_id || ' does not exist.');
      l_script_schema := TRIM(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'));
    END IF;
    RETURN l_script_schema;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN TRIM(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'));
  END get_script_schema;

  FUNCTION get_sosl_schema
    RETURN VARCHAR2
  IS
    l_sosl_schema       VARCHAR2(128);
  BEGIN
    SELECT config_value
      INTO l_sosl_schema
      FROM sosl_config
     WHERE config_name = 'SOSL_SCHEMA'
    ;
    RETURN l_sosl_schema;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.get_sosl_schema', 'SOSL_SERVER', SQLERRM);
      -- return PUBLIC to guarantee errors if used as schema prefix. Issues must be fixed before.
      RETURN 'PUBLIC';
  END get_sosl_schema;

  FUNCTION set_script_started(p_run_id IN NUMBER)
    RETURN NUMBER
  IS
    l_return            NUMBER;
  BEGIN
    l_return := sosl_sys.set_script_status(p_run_id, sosl_constants.RUN_STATE_STARTED);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.set_script_started', 'SOSL_SERVER', SQLERRM);
      RETURN -1;
  END set_script_started;

  FUNCTION set_script_running(p_run_id IN NUMBER)
    RETURN NUMBER
  IS
    l_return            NUMBER;
  BEGIN
    l_return := sosl_sys.set_script_status(p_run_id, sosl_constants.RUN_STATE_RUNNING);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.set_script_running', 'SOSL_SERVER', SQLERRM);
      RETURN -1;
  END set_script_running;

  FUNCTION set_script_finished(p_run_id IN NUMBER)
    RETURN NUMBER
  IS
    l_return            NUMBER;
  BEGIN
    l_return := sosl_sys.set_script_status(p_run_id, sosl_constants.RUN_STATE_FINISHED);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.set_script_finished', 'SOSL_SERVER', SQLERRM);
      RETURN -1;
  END set_script_finished;

  FUNCTION set_script_error(p_run_id IN NUMBER)
    RETURN NUMBER
  IS
    l_return            NUMBER;
  BEGIN
    l_return := sosl_sys.set_script_status(p_run_id, sosl_constants.RUN_STATE_ERROR);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.set_script_error', 'SOSL_SERVER', SQLERRM);
      RETURN -1;
  END set_script_error;

  FUNCTION info_log( p_srv_caller   IN VARCHAR2
                   , p_srv_message  IN VARCHAR2
                   , p_identifier   IN VARCHAR2 DEFAULT NULL
                   , p_local_log    IN VARCHAR2 DEFAULT NULL
                   , p_srv_run_id   IN NUMBER   DEFAULT NULL
                   , p_srv_guid     IN VARCHAR2 DEFAULT NULL
                   )
    RETURN VARCHAR2
  IS
    l_message   VARCHAR2(32767);
    l_payload   SOSL_PAYLOAD;
  BEGIN
    IF p_local_log IS NOT NULL
    THEN
      l_message := p_srv_message || ' local log file: ' || p_local_log;
    ELSE
      l_message := p_srv_message;
    END IF;
    IF p_srv_run_id IS NOT NULL
    THEN
      l_payload := sosl_sys.get_payload(p_srv_run_id);
    ELSE
      l_payload := SOSL_PAYLOAD(NULL, NULL, NULL);
    END IF;
    sosl_log.full_log( p_message => l_message
                     , p_log_type => sosl_constants.LOG_INFO_TYPE
                     , p_log_category => 'SOSL_SERVER'
                     , p_caller => p_srv_caller
                     , p_guid => p_srv_guid
                     , p_sosl_identifier => p_identifier
                     , p_executor_id => l_payload.executor_id
                     , p_ext_script_id => l_payload.ext_script_id
                     , p_script_file => l_payload.script_file
                     , p_run_id => p_srv_run_id
                     )
    ;
    RETURN p_srv_message;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.info_log', 'SOSL_SERVER', SQLERRM);
      RETURN SUBSTR(SQLERRM, 1, 4000);
  END info_log;

  FUNCTION warning_log( p_srv_caller   IN VARCHAR2
                      , p_srv_message  IN VARCHAR2
                      , p_identifier   IN VARCHAR2 DEFAULT NULL
                      , p_local_log    IN VARCHAR2 DEFAULT NULL
                      , p_srv_run_id   IN NUMBER   DEFAULT NULL
                      , p_srv_guid     IN VARCHAR2 DEFAULT NULL
                      )
    RETURN VARCHAR2
  IS
    l_message   VARCHAR2(32767);
    l_payload   SOSL_PAYLOAD;
  BEGIN
    IF p_local_log IS NOT NULL
    THEN
      l_message := p_srv_message || ' local log file: ' || p_local_log;
    ELSE
      l_message := p_srv_message;
    END IF;
    IF p_srv_run_id IS NOT NULL
    THEN
      l_payload := sosl_sys.get_payload(p_srv_run_id);
    ELSE
      l_payload := SOSL_PAYLOAD(NULL, NULL, NULL);
    END IF;
    sosl_log.full_log( p_message => l_message
                     , p_log_type => sosl_constants.LOG_WARNING_TYPE
                     , p_log_category => 'SOSL_SERVER'
                     , p_caller => p_srv_caller
                     , p_guid => p_srv_guid
                     , p_sosl_identifier => p_identifier
                     , p_executor_id => l_payload.executor_id
                     , p_ext_script_id => l_payload.ext_script_id
                     , p_script_file => l_payload.script_file
                     , p_run_id => p_srv_run_id
                     )
    ;
    RETURN p_srv_message;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.warning_log', 'SOSL_SERVER', SQLERRM);
      RETURN SUBSTR(SQLERRM, 1, 4000);
  END warning_log;

  FUNCTION error_log( p_srv_caller   IN VARCHAR2
                    , p_srv_message  IN VARCHAR2
                    , p_identifier   IN VARCHAR2 DEFAULT NULL
                    , p_local_log    IN VARCHAR2 DEFAULT NULL
                    , p_srv_run_id   IN NUMBER   DEFAULT NULL
                    , p_srv_guid     IN VARCHAR2 DEFAULT NULL
                    )
    RETURN VARCHAR2
  IS
    l_message   VARCHAR2(32767);
    l_payload   SOSL_PAYLOAD;
  BEGIN
    IF p_local_log IS NOT NULL
    THEN
      l_message := p_srv_message || ' local log file: ' || p_local_log;
    ELSE
      l_message := p_srv_message;
    END IF;
    IF p_srv_run_id IS NOT NULL
    THEN
      l_payload := sosl_sys.get_payload(p_srv_run_id);
    ELSE
      l_payload := SOSL_PAYLOAD(NULL, NULL, NULL);
    END IF;
    sosl_log.full_log( p_message => l_message
                     , p_log_type => sosl_constants.LOG_ERROR_TYPE
                     , p_log_category => 'SOSL_SERVER'
                     , p_caller => p_srv_caller
                     , p_guid => p_srv_guid
                     , p_sosl_identifier => p_identifier
                     , p_executor_id => l_payload.executor_id
                     , p_ext_script_id => l_payload.ext_script_id
                     , p_script_file => l_payload.script_file
                     , p_run_id => p_srv_run_id
                     )
    ;
    RETURN p_srv_message;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.error_log', 'SOSL_SERVER', SQLERRM);
      RETURN SUBSTR(SQLERRM, 1, 4000);
  END error_log;

  FUNCTION has_scripts
    RETURN NUMBER
  IS
    l_return NUMBER;
  BEGIN
    l_return := sosl_sys.has_scripts;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.has_scripts', 'SOSL_SERVER', SQLERRM);
      RETURN -1;
  END has_scripts;

  FUNCTION get_next_script
    RETURN NUMBER
  IS
    l_return NUMBER;
  BEGIN
    l_return := sosl_sys.get_next_script;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.get_next_script', 'SOSL_SERVER', SQLERRM);
      RETURN -1;
  END get_next_script;

  FUNCTION update_run_id( p_run_id      IN NUMBER
                        , p_identifier  IN VARCHAR2
                        , p_guid        IN VARCHAR2 DEFAULT NULL
                        )
    RETURN NUMBER
  IS
    l_return  NUMBER;
    l_result  NUMBER;
  BEGIN
    l_return := -1;
    l_result := sosl_server.set_identifier(p_run_id, p_identifier);
    IF l_result = 0
    THEN
      l_return := 0;
    END IF;
    IF p_guid IS NOT NULL
    THEN
      l_result := sosl_server.set_guid(p_run_id, p_guid);
      IF l_result != 0
      THEN
        l_return := -1;
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_server.update_run_id', 'SOSL_SERVER', SQLERRM);
      RETURN -1;
  END update_run_id;

END;
/
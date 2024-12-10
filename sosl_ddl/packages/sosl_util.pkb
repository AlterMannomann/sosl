-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE PACKAGE BODY sosl_util
AS
  -- for description see header file
  PROCEDURE split_function_name( p_function_name IN  VARCHAR2
                               , p_package       OUT VARCHAR2
                               , p_function      OUT VARCHAR2
                               )
  IS
    l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_util.split_function_name';
  BEGIN
    IF INSTR(p_function_name, '.') > 0
    THEN
      p_package   := TRIM(SUBSTR(p_function_name, 1, INSTR(p_function_name, '.') -1));
      p_function  := TRIM(SUBSTR(p_function_name, INSTR(p_function_name, '.') +1));
    ELSE
      p_package   := NULL;
      p_function  := TRIM(p_function_name);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event and raise
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RAISE;
  END split_function_name;

  FUNCTION has_db_user(p_username IN VARCHAR2)
    RETURN BOOLEAN
  IS
    l_has_user          NUMBER;
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_util.has_db_user';
  BEGIN
    l_return := FALSE;
    SELECT COUNT(*) INTO l_has_user FROM all_users WHERE username = p_username;
    IF l_has_user != 0
    THEN
      l_return := TRUE;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END has_db_user;

  FUNCTION has_function( p_owner          IN VARCHAR2
                       , p_function_name  IN VARCHAR2
                       , p_datatype       IN VARCHAR2
                       )
    RETURN BOOLEAN
  IS
    l_has_function      NUMBER;
    l_package           VARCHAR2(128);
    l_function          VARCHAR2(128);
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_util.has_function';
  BEGIN
    l_return := FALSE;
    split_function_name(p_function_name, l_package, l_function);
    SELECT COUNT(*)
      INTO l_has_function
      FROM all_arguments
     WHERE position                   = 0                               -- only functions
       AND argument_name              IS NULL                           -- only functions
       AND data_type                  = p_datatype
       AND owner                      = UPPER(p_owner)
       AND NVL(package_name, 'N/A')   = NVL(UPPER(l_package), 'N/A')    -- may not contain a package name
       AND object_name                = UPPER(l_function)
       AND package_name               NOT IN ( 'SOSL_SYS'               -- exclude internal packages that should never be referenced
                                             , 'SOSL_UTIL'
                                             , 'SOSL_LOG'
                                             , 'SOSL_CONSTANTS'
                                             , 'SOSL_API'
                                             )
    ;
    IF l_has_function != 0
    THEN
      l_return := TRUE;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END has_function;

  FUNCTION get_col_length( p_table  IN VARCHAR2
                         , p_column IN VARCHAR2
                         )
    RETURN INTEGER
  IS
    l_return            INTEGER;
    l_has_column        INTEGER;
    l_data_type         user_tab_columns.data_type%TYPE;
    l_data_length       user_tab_columns.data_length%TYPE;
    l_data_precision    user_tab_columns.data_precision%TYPE;
    l_data_scale        user_tab_columns.data_scale%TYPE;
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_util.get_col_length';
  BEGIN
    l_return := -1;
    SELECT COUNT(*) INTO l_has_column FROM user_tab_columns WHERE table_name = UPPER(p_table) AND column_name = UPPER(p_column);
    IF l_has_column = 1
    THEN
      -- column match calculate length
      SELECT data_type
           , data_length
           , data_precision
           , data_scale
        INTO l_data_type
           , l_data_length
           , l_data_precision
           , l_data_scale
        FROM user_tab_columns
       WHERE table_name  = UPPER(p_table)
         AND column_name = UPPER(p_column)
      ;
      IF l_data_type = 'NUMBER'
      THEN
        IF l_data_scale != 0
        THEN
          -- consider delimiter
          l_return := l_data_precision + l_data_scale;
        ELSE
          l_return := l_data_precision;
        END IF;
      ELSIF l_data_type = 'CLOB'
      THEN
        l_return := 32767;
      ELSE
        l_return := l_data_length;
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN sosl_constants.NUM_ERROR;
  END get_col_length;

  FUNCTION get_col_type( p_table  IN VARCHAR2
                       , p_column IN VARCHAR2
                       )
    RETURN VARCHAR2
  IS
    l_return            VARCHAR2(128);
    l_has_column        INTEGER;
    l_data_type         user_tab_columns.data_type%TYPE;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_util.get_col_type';
  BEGIN
    l_return := sosl_constants.GEN_NA_TYPE;
    SELECT COUNT(*) INTO l_has_column FROM user_tab_columns WHERE table_name = UPPER(p_table) AND column_name = UPPER(p_column);
    IF l_has_column = 1
    THEN
      -- column match get data type
      SELECT data_type
        INTO l_return
        FROM user_tab_columns
       WHERE table_name  = UPPER(p_table)
         AND column_name = UPPER(p_column)
      ;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN sosl_constants.GEN_NA_TYPE;
  END get_col_type;

  FUNCTION check_col( p_table  IN VARCHAR2
                    , p_column IN VARCHAR2
                    , p_value  IN VARCHAR2
                    )
    RETURN BOOLEAN
  IS
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_util.check_col VARCHAR';
  BEGIN
    l_return := FALSE;
    IF sosl_util.get_col_type(p_table, p_column) IN ('VARCHAR2', 'CHAR')
    THEN
      IF NVL(LENGTH(p_value), 0) <= sosl_util.get_col_length(p_table, p_column)
      THEN
        l_return := TRUE;
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END check_col; -- VARCHAR2 variant

  FUNCTION check_col( p_table  IN VARCHAR2
                    , p_column IN VARCHAR2
                    , p_value  IN NUMBER
                    )
    RETURN BOOLEAN
  IS
    l_return            BOOLEAN;
    l_number            VARCHAR2(128);
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_util.check_col NUMBER';
  BEGIN
    l_return := FALSE;
    IF sosl_util.get_col_type(p_table, p_column) = 'NUMBER'
    THEN
      l_number := REGEXP_REPLACE(TO_CHAR(p_value), '[^0-9]', '');
      IF NVL(LENGTH(l_number), 0) <= sosl_util.get_col_length(p_table, p_column)
      THEN
        l_return := TRUE;
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END check_col; -- NUMBER variant

  FUNCTION has_role( p_db_user IN VARCHAR2
                   , p_role    IN VARCHAR2
                   )
    RETURN BOOLEAN
  IS
    l_count             NUMBER;
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_util.has_role';
  BEGIN
    l_return := FALSE;
    -- identify implicite roles first
      WITH rol AS
           (SELECT DISTINCT granted_role
              FROM sosl_role_privs_v
             START WITH grantee = UPPER(p_db_user)
           CONNECT BY PRIOR granted_role = grantee
           )
    SELECT COUNT(*)
      INTO l_count
      FROM rol
     WHERE granted_role = UPPER(p_role)
    ;
    l_return := (l_count != 0);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END has_role;

  FUNCTION grant_role( p_db_user IN VARCHAR2
                     , p_role    IN VARCHAR2
                     )
    RETURN BOOLEAN
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            BOOLEAN;
    l_statement         VARCHAR2(1024);
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_util.grant_role';
  BEGIN
    l_return := FALSE;
    IF has_role(p_db_user, p_role)
    THEN
      -- has grant everything is okay
      l_return := TRUE;
    ELSE
      -- give grant
      l_statement := 'GRANT ' || p_role || ' TO ' || p_db_user;
      BEGIN
        EXECUTE IMMEDIATE l_statement;
        l_return := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          -- log error
          sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM || ' - Could not execute: ' || l_statement);
          l_return := FALSE;
      END;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END grant_role;

  FUNCTION revoke_role( p_db_user IN VARCHAR2
                      , p_role    IN VARCHAR2
                      )
    RETURN BOOLEAN
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            BOOLEAN;
    l_has_admin         NUMBER;
    l_schema            VARCHAR2(128);
    l_statement         VARCHAR2(1024);
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_util.revoke_role';
  BEGIN
    l_return := FALSE;
    SELECT config_value INTO l_schema FROM sosl_config WHERE config_name = 'SOSL_SCHEMA';
    SELECT COUNT(*) INTO l_has_admin FROM user_role_privs WHERE granted_role = p_role AND admin_option = 'YES';
    IF NOT has_role(p_db_user, p_role)
        OR p_db_user   = l_schema
        OR l_has_admin = 1
    THEN
      -- SOSL user, role admin or role not given
      IF   p_db_user   = l_schema
        OR l_has_admin = 1
      THEN
        sosl_log.minimal_warning_log(l_self_caller, l_self_log_category, 'Roles will never be revoked from role admins and SOSL schema - user '|| p_db_user || ' role ' || p_role);
      ELSE
        sosl_log.minimal_info_log(l_self_caller, l_self_log_category, 'Role cannot be revoked, user '|| p_db_user || ' has no role ' || p_role);
      END IF;
      l_return := TRUE;
    ELSE
      -- give grant
      l_statement := 'REVOKE ' || p_role || ' FROM ' || p_db_user;
      BEGIN
        EXECUTE IMMEDIATE l_statement;
        l_return := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          -- log error
          sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM || ' - Could not execute: ' || l_statement);
          l_return := FALSE;
      END;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END revoke_role;

  FUNCTION utc_mail_date
    RETURN VARCHAR2
  IS
    l_date VARCHAR2(500);
  BEGIN
    l_date := TO_CHAR(SYSTIMESTAMP AT TIME ZONE SESSIONTIMEZONE, 'Dy, DD Mon YYYY HH24:MI:SS TZHTZM');
    RETURN l_date;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log('sosl_util.utc_mail_date', 'SOSL_UTIL', SQLERRM);
      RETURN NULL;
  END utc_mail_date;

  FUNCTION format_mail( p_sender      IN VARCHAR2
                      , p_recipients  IN VARCHAR2
                      , p_subject     IN VARCHAR2
                      , p_message     IN VARCHAR2
                      )
    RETURN VARCHAR2
  IS
    l_crlf          VARCHAR2(2)       := CHR(13) || CHR(10);
    l_mail_message  VARCHAR2(32767);
  BEGIN
    l_mail_message := 'From: ' || p_sender || l_crlf ||
                      'To: ' || p_recipients || l_crlf ||
                      'Date: ' || sosl_util.utc_mail_date || l_crlf ||
                      'Subject: ' || p_subject || l_crlf ||
                      p_message
    ;
    RETURN l_mail_message;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log('sosl_util.format_mail', 'SOSL_UTIL', SQLERRM);
      RETURN NULL;
  END format_mail;

  FUNCTION check_mail_address_format(p_mail_address IN VARCHAR2)
    RETURN BOOLEAN
  IS
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE       := 'sosl_util.check_mail_address_format';
  BEGIN
    l_return := FALSE;
    IF      LENGTH(p_mail_address) > 5
       AND  INSTR(p_mail_address, '@') > 0
       AND  INSTR(p_mail_address, '.') > 0
    THEN
      l_return := TRUE;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log event instead of raise
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END check_mail_address_format;

  FUNCTION dummy_mail( p_sender      IN VARCHAR2
                     , p_recipients  IN VARCHAR2
                     , p_subject     IN VARCHAR2
                     , p_message     IN VARCHAR2
                     )
    RETURN NUMBER
  IS
    l_message           VARCHAR2(32767);
    l_self_log_category sosl_server_log.log_category%TYPE   := 'MAIL DUMMY';
    l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_util.dummy_mail';
  BEGIN
    l_message := sosl_util.format_mail(p_sender, p_recipients, p_subject, p_message);
    sosl_log.minimal_info_log(l_self_caller, l_self_log_category, 'Fake mail with subject "' || p_subject || '" created in full_message. Check the results.', l_message);
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END dummy_mail;

  FUNCTION txt_boolean( p_bool   IN BOOLEAN
                      , p_true   IN VARCHAR2 DEFAULT 'TRUE'
                      , p_false  IN VARCHAR2 DEFAULT 'FALSE'
                      )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    IF p_bool
    THEN
      RETURN TRIM(SUBSTR(NVL(p_true, 'TRUE'), 1, 10));
    ELSE
      RETURN TRIM(SUBSTR(NVL(p_false, 'FALSE'), 1, 10));
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      sosl_log.exception_log('sosl_util.txt_boolean BOOLEAN', 'SOSL_UTIL', SQLERRM);
      RETURN sosl_constants.GEN_NA_TYPE;
  END txt_boolean; -- boolean input

  FUNCTION txt_boolean( p_bool   IN NUMBER
                      , p_true   IN VARCHAR2 DEFAULT 'TRUE'
                      , p_false  IN VARCHAR2 DEFAULT 'FALSE'
                      )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_util.txt_boolean((p_bool = 1), p_true, p_false);
  EXCEPTION
    WHEN OTHERS THEN
      sosl_log.exception_log('sosl_util.txt_boolean NUMBER', 'SOSL_UTIL', SQLERRM);
      RETURN sosl_constants.GEN_NA_TYPE;
  END txt_boolean; -- number input

  FUNCTION yes_no( p_bool   IN BOOLEAN
                 , p_true   IN VARCHAR2 DEFAULT 'YES'
                 , p_false  IN VARCHAR2 DEFAULT 'NO'
                 )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_util.txt_boolean(p_bool, p_true, p_false);
  EXCEPTION
    WHEN OTHERS THEN
      sosl_log.exception_log('sosl_util.yes_no BOOLEAN', 'SOSL_UTIL', SQLERRM);
      RETURN sosl_constants.GEN_NA_TYPE;
  END yes_no;

  FUNCTION yes_no( p_bool   IN NUMBER
                 , p_true   IN VARCHAR2 DEFAULT 'YES'
                 , p_false  IN VARCHAR2 DEFAULT 'NO'
                 )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_util.txt_boolean((p_bool = 1), p_true, p_false);
  EXCEPTION
    WHEN OTHERS THEN
      sosl_log.exception_log('sosl_util.yes_no NUMBER', 'SOSL_UTIL', SQLERRM);
      RETURN sosl_constants.GEN_NA_TYPE;
  END yes_no;

  FUNCTION object_date( p_object_name IN VARCHAR2
                      , p_object_type IN VARCHAR2
                      )
    RETURN DATE
  IS
    l_has_object  NUMBER;
    l_return      DATE;
  BEGIN
    l_return := sosl_constants.GEN_NA_DATE_TYPE;
    SELECT COUNT(*)
      INTO l_has_object
      FROM user_objects
     WHERE object_name = TRIM(UPPER(p_object_name))
       AND object_type = TRIM(UPPER(p_object_type))
    ;
    -- only if we have exactly one object
    IF l_has_object = 1
    THEN
      SELECT last_ddl_time
        INTO l_return
        FROM user_objects
       WHERE object_name = TRIM(UPPER(p_object_name))
         AND object_type = TRIM(UPPER(p_object_type))
      ;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      sosl_log.exception_log('sosl_util.object_date', 'SOSL_UTIL', SQLERRM);
      RETURN sosl_constants.GEN_NA_DATE_TYPE;
  END object_date;

  FUNCTION get_valid_run_state(p_run_state IN NUMBER)
    RETURN NUMBER
  IS
  BEGIN
    IF p_run_state IN ( sosl_constants.RUN_STATE_WAITING
                      , sosl_constants.RUN_STATE_ENQUEUED
                      , sosl_constants.RUN_STATE_STARTED
                      , sosl_constants.RUN_STATE_RUNNING
                      , sosl_constants.RUN_STATE_FINISHED
                      , sosl_constants.RUN_STATE_ERROR
                      )
    THEN
      RETURN p_run_state;
    ELSE
      sosl_log.minimal_error_log('sosl_util.get_valid_run_state', 'SOSL_UTIL', 'Run state ' || p_run_state || ' not supported.');
      RETURN sosl_constants.RUN_STATE_ERROR;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      sosl_log.exception_log('sosl_util.get_valid_run_state', 'SOSL_UTIL', SQLERRM);
      RETURN -1;
  END get_valid_run_state;

  FUNCTION create_executor( p_executor_name         IN VARCHAR2
                          , p_db_user               IN VARCHAR2
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
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return            NUMBER;
    l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_util.create_executor';
  BEGIN
    l_return := -1;
    -- leave error checking to trigger
    INSERT INTO sosl_executor_definition
      ( executor_name
      , db_user
      , function_owner
      , fn_has_scripts
      , fn_get_next_script
      , fn_set_script_status
      , cfg_file
      , use_mail
      , fn_send_db_mail
      , executor_description
      )
      VALUES ( p_executor_name
             , p_db_user
             , p_function_owner
             , p_fn_has_scripts
             , p_fn_get_next_script
             , p_fn_set_script_status
             , p_cfg_file
             , p_use_mail
             , p_fn_send_db_mail
             , p_executor_description
             )
      RETURNING executor_id INTO l_return
    ;
    COMMIT;
    sosl_log.minimal_info_log(l_self_caller, l_self_log_category, 'Created new executor: ' || p_executor_name || ' with ID: ' || l_return);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END create_executor;

  FUNCTION active_state_executor( p_executor_id   IN NUMBER
                                , p_active_state  IN NUMBER DEFAULT 0
                                )
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_util.active_state_executor';
  BEGIN
    -- leave error checking to trigger
    UPDATE sosl_executor_definition
       SET executor_active = p_active_state
     WHERE executor_id = p_executor_id
    ;
    COMMIT;
    sosl_log.minimal_info_log(l_self_caller, l_self_log_category, 'Active state changed for executor id: ' || p_executor_id || ' to: ' || p_active_state);
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END active_state_executor;

  FUNCTION review_state_executor( p_executor_id   IN NUMBER
                                , p_review_state  IN NUMBER DEFAULT 0
                                )
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_util.review_state_executor';
  BEGIN
    -- leave error checking to trigger
    UPDATE sosl_executor_definition
       SET executor_reviewed = p_review_state
     WHERE executor_id = p_executor_id
    ;
    COMMIT;
    sosl_log.minimal_info_log(l_self_caller, l_self_log_category, 'Review state changed for executor id: ' || p_executor_id || ' to: ' || p_review_state);
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END review_state_executor;

  FUNCTION db_in_time
    RETURN BOOLEAN
  IS
    l_return            BOOLEAN;
    l_time_from_cfg     VARCHAR2(4000);
    l_time_to_cfg       VARCHAR2(4000);
    l_time_from         DATE;
    l_time_to           DATE;
    l_time_current      DATE;
    l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_UTIL';
    l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_util.db_in_time';
  BEGIN
    l_return := FALSE;
    -- get configured times
    SELECT config_value INTO l_time_from_cfg FROM sosl_config WHERE config_name = 'SOSL_START_JOBS';
    SELECT config_value INTO l_time_to_cfg FROM sosl_config WHERE config_name = 'SOSL_STOP_JOBS';
    l_time_from     := TO_DATE(l_time_from_cfg, 'HH24:MI');
    l_time_to       := TO_DATE(l_time_to_cfg, 'HH24:MI');
    l_time_current  := TO_DATE(TO_CHAR(SYSDATE, 'HH24:MI'), 'HH24:MI');
    IF l_time_from > l_time_to
    THEN
      -- add a day if daybreak
      l_time_to := l_time_to + 1;
      -- check current, if lower than from add a day
      IF l_time_current < l_time_from
      THEN
        l_time_current := l_time_current +1;
      END IF;
    END IF;
    IF     l_time_current >= l_time_from
       AND l_time_current <= l_time_to
    THEN
      l_return := TRUE;
    ELSE
      l_return := FALSE;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN FALSE;
  END db_in_time;

  FUNCTION cleanup_logs(p_older_than IN NUMBER DEFAULT 7)
    RETURN NUMBER
  IS
  BEGIN
    RETURN -1;
  END cleanup_logs;

  FUNCTION cleanup_queue(p_older_than IN NUMBER DEFAULT 7)
    RETURN NUMBER
  IS
  BEGIN
    RETURN -1;
  END cleanup_queue;

END;
/
-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- requires login with the correct schema, either SOSL or your own SOSL schema
-- requires table to have been created before, as well as used packages
CREATE OR REPLACE TRIGGER sosl_config_ins_trg
  BEFORE INSERT ON sosl_config
  FOR EACH ROW
DECLARE
  l_ok                BOOLEAN;
  l_date              DATE;
  l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_CONFIG';
  l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_config_ins_trg';
BEGIN
  -- remove any leading and trailing blanks from config_value
  :NEW.config_value   := TRIM(:NEW.config_value);
  :NEW.created        := SYSDATE;
  :NEW.created_by     := SYS_CONTEXT('USERENV', 'SESSION_USER');
  :NEW.created_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  -- check max length if defined
  IF :NEW.config_type = 'CHAR'
  THEN
    IF :NEW.config_max_length > 0
    THEN
      IF LENGTH(:NEW.config_value) > :NEW.config_max_length
      THEN
        sosl_log.minimal_error_log( l_self_caller
                                  , l_self_log_category
                                  , '-20010 The config_value exceeds the defined config_max_length. Current length: ' || LENGTH(:NEW.config_value)
                                  , 'Wrong length of config value for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                  )
        ;
        RAISE_APPLICATION_ERROR(-20010, 'The config_value exceeds the defined config_max_length. Current length: ' || LENGTH(:NEW.config_value));
      END IF;
    END IF;
  END IF;
  -- check number type
  IF :NEW.config_type = 'NUMBER'
  THEN
    l_ok := TRUE;
    -- compare TO_NUMBER with implicite conversion, if it fails the config_value cannot be interpreted correctly
    BEGIN
      l_ok := (TO_NUMBER(:NEW.config_value) = :NEW.config_value);
    EXCEPTION
      WHEN OTHERS THEN
        sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
        l_ok := FALSE;
    END;
    IF NOT l_ok
    THEN
      sosl_log.minimal_error_log( l_self_caller
                                , l_self_log_category
                                , '-20011 The given config_value "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" could not be converted successfully to a number.'
                                , 'Wrong type of config value for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                )
      ;
      RAISE_APPLICATION_ERROR(-20011, 'The given config_value "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" could not be converted successfully to a number.');
    END IF;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER sosl_config_upd_trg
  BEFORE UPDATE ON sosl_config
  FOR EACH ROW
DECLARE
  l_ok                BOOLEAN;
  l_date              DATE;
  l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_CONFIG';
  l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_config_upd_trg';
BEGIN
  -- remove any leading and trailing blanks from config_value
  :NEW.config_value   := TRIM(:NEW.config_value);
  -- report intended changes on columns not allowed to change and reset values to OLD
  sosl_log.log_column_change(:OLD.created, :NEW.created, 'SOSL_CONFIG.CREATED', l_self_caller, TRUE);
  :NEW.created        := :OLD.created;
  sosl_log.log_column_change(:OLD.created_by, :NEW.created_by, 'SOSL_CONFIG.CREATED_BY', l_self_caller, TRUE);
  :NEW.created_by     := :OLD.created_by;
  sosl_log.log_column_change(:OLD.created_by_os, :NEW.created_by_os, 'SOSL_CONFIG.CREATED_BY_OS', l_self_caller, TRUE);
  :NEW.created_by_os  := :OLD.created_by_os;
  -- check changes on config_name for protected values
  IF     :OLD.config_name != :NEW.config_name
     AND :OLD.config_name IN ( 'SOSL_PATH_CFG'
                             , 'SOSL_PATH_TMP'
                             , 'SOSL_PATH_LOG'
                             , 'SOSL_START_LOG'
                             , 'SOSL_BASE_LOG'
                             , 'SOSL_EXT_LOG'
                             , 'SOSL_EXT_TMP'
                             , 'SOSL_EXT_LOCK'
                             , 'SOSL_EXT_ERROR'
                             , 'SOSL_MAX_PARALLEL'
                             , 'SOSL_RUNMODE'
                             , 'SOSL_DEFAULT_WAIT'
                             , 'SOSL_NOJOB_WAIT'
                             , 'SOSL_PAUSE_WAIT'
                             , 'SOSL_SERVER_STATE'
                             , 'SOSL_START_JOBS'
                             , 'SOSL_STOP_JOBS'
                             , 'SOSL_SCHEMA'
                             )
  THEN
    sosl_log.log_column_change(:OLD.config_name, :NEW.config_name, 'SOSL_CONFIG.CONFIG_NAME', l_self_caller, TRUE);
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20012 The given system config_name ' || :OLD.config_name || ' cannot be changed.'
                              , 'Tried to change a system config name for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20012, 'The given system config_name ' || :OLD.config_name || ' cannot be changed.');
  END IF;
  IF      :OLD.config_name   = 'SOSL_SCHEMA'
     AND  :OLD.config_value != :NEW.config_value
  THEN
    sosl_log.log_column_change(:OLD.config_value, :NEW.config_value, 'SOSL_CONFIG.CONFIG_VALUE', l_self_caller, TRUE);
    sosl_log.minimal_error_log( l_self_caller
                              , l_self_log_category
                              , '-20014 The SOSL_SCHEMA value ' || :OLD.config_value || ' cannot be changed.'
                              , 'Tried to change SOSL_SCHEMA in SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20014, 'The SOSL_SCHEMA value ' || :OLD.config_value || ' cannot be changed.');
  END IF;
  -- report value changes allowed
  sosl_log.log_column_change(:OLD.config_value, :NEW.config_value, :OLD.config_name, l_self_caller, FALSE);
  -- set updated
  :NEW.updated        := SYSDATE;
  :NEW.updated_by     := SYS_CONTEXT('USERENV', 'SESSION_USER');
  :NEW.updated_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  -- check max length if defined
  IF :NEW.config_type = 'CHAR'
  THEN
    IF :NEW.config_max_length > 0
    THEN
      IF LENGTH(:NEW.config_value) > :NEW.config_max_length
      THEN
        sosl_log.minimal_error_log( l_self_caller
                                  , l_self_log_category
                                  , '-20010 The config_value exceeds the defined config_max_length. Current length: ' || LENGTH(:NEW.config_value)
                                  , 'Wrong length of config value for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                  )
        ;
        RAISE_APPLICATION_ERROR(-20010, 'The config_value exceeds the defined config_max_length. Current length: ' || LENGTH(:NEW.config_value));
      END IF;
    END IF;
  END IF;
  -- check number type
  IF :NEW.config_type = 'NUMBER'
  THEN
    l_ok := TRUE;
    -- compare TO_NUMBER with implicite conversion, if it fails the config_value cannot be interpreted correctly
    BEGIN
      l_ok := (TO_NUMBER(:NEW.config_value) = :NEW.config_value);
    EXCEPTION
      WHEN OTHERS THEN
        sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
        l_ok := FALSE;
    END;
    IF NOT l_ok
    THEN
      sosl_log.minimal_error_log( l_self_caller
                                , l_self_log_category
                                , '-20011 The given config_value "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" could not be converted successfully to a number.'
                                , 'Wrong type of config value for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                )
      ;
      RAISE_APPLICATION_ERROR(-20011, 'The given config_value "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" could not be converted successfully to a number.');
    END IF;
  END IF;
  -- check run mode
  IF     :OLD.config_name       = 'SOSL_RUNMODE'
     AND :OLD.config_value     != :NEW.config_value
     AND :NEW.config_value NOT IN (sosl_constants.SERVER_RUN_MODE, sosl_constants.SERVER_PAUSE_MODE, sosl_constants.SERVER_STOP_MODE)
  THEN
      sosl_log.minimal_error_log( l_self_caller
                                , l_self_log_category
                                , '-20015 The given runmode "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" is not supported, only RUN, PAUSE or STOP accepted.'
                                , 'Wrong type of config value for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                )
      ;
    RAISE_APPLICATION_ERROR(-20015, 'The given runmode "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" is not supported, only RUN, PAUSE or STOP accepted.');
  END IF;
  -- check server state
  IF     :OLD.config_name       = 'SOSL_SERVER_STATE'
     AND :OLD.config_value     != :NEW.config_value
     AND :NEW.config_value NOT IN ('ACTIVE', 'INACTIVE')
  THEN
      sosl_log.minimal_error_log( l_self_caller
                                , l_self_log_category
                                , '-20016 The given server state "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" is not supported, only ACTIVE or INACTIVE accepted.'
                                , 'Wrong type of config value for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                )
      ;
    RAISE_APPLICATION_ERROR(-20016, 'The given server state "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" is not supported, only ACTIVE or INACTIVE accepted.');
  END IF;
  -- check start and stop times
  IF     :OLD.config_name      IN ('SOSL_START_JOBS', 'SOSL_STOP_JOBS')
     AND :OLD.config_value     != :NEW.config_value
  THEN
    IF    SUBSTR(:NEW.config_value, 3, 1) != ':'
       OR NOT REGEXP_LIKE(SUBSTR(:NEW.config_value, 1, 2), '^[0-9][0-9]')
       OR NOT REGEXP_LIKE(SUBSTR(:NEW.config_value, 4, 5), '^[0-9][0-9]')
    THEN
      sosl_log.minimal_error_log( l_self_caller
                                , l_self_log_category
                                , '-20017 The given time frame "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" for start and stop times is not supported. Format is HH24:MI with leading zeros, e.g. 05:04 and must be a valid time.'
                                , 'Wrong type of config value for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                )
      ;
      RAISE_APPLICATION_ERROR(-20017, 'The given time frame "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" for start and stop times is not supported. Format is HH24:MI with leading zeros, e.g. 05:04 and must be a valid time.');
    END IF;
    -- check times
    IF    TO_NUMBER(SUBSTR(:NEW.config_value, 1, 2)) > 23
       OR TO_NUMBER(SUBSTR(:NEW.config_value, 4, 5)) > 59
    THEN
      sosl_log.minimal_error_log( l_self_caller
                                , l_self_log_category
                                , '-20017 The given time frame "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" for start and stop times is not supported. Format is HH24:MI with leading zeros, e.g. 05:04 and must be a valid time.'
                                , 'Wrong type of config value for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                )
      ;
      RAISE_APPLICATION_ERROR(-20017, 'The given time frame "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" for start and stop times is not supported. Format is HH24:MI with leading zeros, e.g. 05:04 and must be a valid time.');
    END IF;
  END IF;
END;
/
CREATE OR REPLACE TRIGGER sosl_config_del_trg
  BEFORE DELETE ON sosl_config
  FOR EACH ROW
BEGIN
  -- protect system parameters from delete
  IF :OLD.config_name IN ( 'SOSL_PATH_CFG'
                         , 'SOSL_PATH_TMP'
                         , 'SOSL_PATH_LOG'
                         , 'SOSL_START_LOG'
                         , 'SOSL_BASE_LOG'
                         , 'SOSL_EXT_LOG'
                         , 'SOSL_EXT_TMP'
                         , 'SOSL_EXT_LOCK'
                         , 'SOSL_EXT_ERROR'
                         , 'SOSL_MAX_PARALLEL'
                         , 'SOSL_RUNMODE'
                         , 'SOSL_DEFAULT_WAIT'
                         , 'SOSL_NOJOB_WAIT'
                         , 'SOSL_PAUSE_WAIT'
                         , 'SOSL_SERVER_STATE'
                         , 'SOSL_START_JOBS'
                         , 'SOSL_STOP_JOBS'
                         , 'SOSL_SCHEMA'
                         )
  THEN
    sosl_log.minimal_error_log( 'sosl_config_del_trg'
                              , 'SOSL_CONFIG'
                              , '-20013 The given system config_name "' || :OLD.config_name || '" cannot be deleted.'
                              , 'Forbidden delete of config name for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'SESSION_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20013, 'The given system config_name "' || :OLD.config_name || '" cannot be deleted.');
  END IF;
END;
/


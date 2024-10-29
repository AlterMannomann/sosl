-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- requires login with the correct schema, either SOSL or your own SOSL schema
-- requires table to have been created before, as well as used packages
CREATE OR REPLACE TRIGGER sosl_config_ins_upd_trg
  BEFORE INSERT OR UPDATE ON sosl_config
  FOR EACH ROW
DECLARE
  l_ok                BOOLEAN;
  l_date              DATE;
  l_self_log_category sosl_server_log.log_category%TYPE   := 'SOSL_CONFIG';
  l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_config_ins_upd_trg';
BEGIN
  -- remove any leading and trailing blanks from config_value
  :NEW.config_value   := TRIM(:NEW.config_value);
  IF UPDATING
  THEN
    :NEW.created        := :OLD.created;
    :NEW.created_by     := :OLD.created_by;
    :NEW.created_by_os  := :OLD.created_by_os;
  ELSE
    :NEW.created        := SYSDATE;
    :NEW.created_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
    :NEW.created_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  END IF;
  :NEW.updated        := SYSDATE;
  :NEW.updated_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
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
                                  , '-20002 The config_value exceeds the defined config_max_length. Current length: ' || LENGTH(:NEW.config_value)
                                  , 'Wrong length of config value for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                  )
        ;
        RAISE_APPLICATION_ERROR(-20002, 'The config_value exceeds the defined config_max_length. Current length: ' || LENGTH(:NEW.config_value));
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
                                , '-20003 The given config_value "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" could not be converted successfully to a number.'
                                , 'Wrong type of config value for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                )
      ;
      RAISE_APPLICATION_ERROR(-20003, 'The given config_value "' || NVL(:NEW.config_value, sosl_constants.GEN_NULL_TEXT) || '" could not be converted successfully to a number.');
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
                         )
  THEN
    sosl_log.minimal_error_log( 'sosl_config_del_trg'
                              , 'SOSL_CONFIG'
                              , '-20004 The given system config_name "' || :OLD.config_name || '" cannot be deleted.'
                              , 'Forbidden delete of config name for SOSL_CONFIG table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                              )
    ;
    RAISE_APPLICATION_ERROR(-20004, 'The given system config_name "' || :OLD.config_name || '" cannot be deleted.');
  END IF;
END;
/


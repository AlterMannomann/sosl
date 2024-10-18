-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- requires login with the correct schema, either SOSL or your on schema
-- table is NOT qualified and created in the schema active at execution, columns ordered by access and then space consumption
CREATE TABLE sosl_config
  ( config_name         VARCHAR2(128)                                             NOT NULL
  , config_value        VARCHAR2(4000)                                            NOT NULL
  , config_max_length   NUMBER          DEFAULT -1                                NOT NULL
  , config_type         VARCHAR2(6)     DEFAULT 'CHAR'                            NOT NULL
  , created             DATE            DEFAULT SYSDATE                           NOT NULL
  , updated             DATE            DEFAULT SYSDATE                           NOT NULL
  , created_by          VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , created_by_os       VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , updated_by          VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , updated_by_os       VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , config_description  VARCHAR2(4000)
  )
;
-- description
COMMENT ON TABLE sosl_config IS 'Holds the configuration used by SOSL. Will use the alias scfg.';
COMMENT ON COLUMN sosl_config.config_name IS 'The unique case sensitive name of the SOSL configuration object.';
COMMENT ON COLUMN sosl_config.config_value IS 'The configuration value always as VARCHAR2. Type handling and conversion must be done by the caller.';
COMMENT ON COLUMN sosl_config.config_type IS 'Defines how the config value has to be interpreted. Currently supports CHAR and NUMBER.';
COMMENT ON COLUMN sosl_config.config_max_length IS 'Defines a maximum length for CHAR type config values if set to a number > 0. Default is -1, do not not check length.';
COMMENT ON COLUMN sosl_config.config_description IS 'Optional description of the SOSL config object.';
COMMENT ON COLUMN sosl_config.created IS 'Date created, managed by default and trigger.';
COMMENT ON COLUMN sosl_config.updated IS 'Date updated, managed by default and trigger.';
COMMENT ON COLUMN sosl_config.created_by IS 'DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_config.created_by_os IS 'OS user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_config.updated_by IS 'DB user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_config.updated_by_os IS 'OS user who updated the record, managed by default and trigger.';

-- primary key
ALTER TABLE sosl_config
  ADD CONSTRAINT sosl_config_pk
  PRIMARY KEY (config_name)
  ENABLE
;
-- constraints
ALTER TABLE sosl_config
  ADD CONSTRAINT sosl_config_chk_type
  CHECK (config_type IN ('CHAR', 'NUMBER'))
;
ALTER TABLE sosl_config
  ADD CONSTRAINT sosl_config_chk_max_length
  CHECK (config_max_length = -1 OR config_max_length > 0)
;
-- trigger
CREATE OR REPLACE TRIGGER sosl_config_ins_upd_trg
  BEFORE INSERT OR UPDATE ON sosl_config
  FOR EACH ROW
DECLARE
  l_ok    BOOLEAN;
  l_date  DATE;
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
        sosl_log.full_log( p_message => 'The config_value exceeds the defined config_max_length. Current length: ' || LENGTH(:NEW.config_value)
                         , p_log_type => sosl_sys.FATAL_TYPE
                         , p_log_category => 'SOSL_CONFIG/sosl_config_ins_upd_trg'
                         , p_caller => 'sosl_config_ins_upd_trg'
                         )
        ;
        RAISE_APPLICATION_ERROR(-20000, 'The config_value exceeds the defined config_max_length. Current length: ' || LENGTH(:NEW.config_value));
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
        l_ok := FALSE;
    END;
    IF NOT l_ok
    THEN
        sosl_log.full_log( p_message => 'The given config_value "' || :NEW.config_value || '" could not be converted successfully to a number.'
                         , p_log_type => sosl_sys.FATAL_TYPE
                         , p_log_category => 'SOSL_CONFIG/sosl_config_ins_upd_trg'
                         , p_caller => 'sosl_config_ins_upd_trg'
                         )
        ;
      RAISE_APPLICATION_ERROR(-20001, 'The given config_value "' || :NEW.config_value || '" could not be converted successfully to a number.');
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
                         )
  THEN
    RAISE_APPLICATION_ERROR(-20002, 'The given system config_name "' || :OLD.config_name || '" cannot be deleted.');
  END IF;
END;
/
-- load default values that can be configured in the database
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_PATH_CFG', '..\..\sosl_cfg\', 'Relative path with delimiter at path end to configuration files the SOSL server uses. Set by SOSL server. As configuration files contain credentials and secrets the path should be in a safe space with controlled user rights.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_max_length, config_description)
  VALUES
  ('SOSL_PATH_TMP', '..\..\sosl_tmp\', 239, 'Relative path with delimiter at path end to temporary files the SOSL server uses. Set by SOSL server. Parameter for sql files, limited to 239 chars.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_max_length, config_description)
  VALUES
  ('SOSL_PATH_LOG', '..\..\sosl_log\', 239, 'Relative path with delimiter at path end to log files the SOSL server creates. Set by SOSL server. Parameter for sql files, limited to 239 chars.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_START_LOG', 'sosl_server', 'Log filename for start and end of SOSL server CMD. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_BASE_LOG', 'sosl_job_', 'Base log filename for single job runs. Will be extended by GUID. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_EXT_LOG', 'log', 'Log file extension to use. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_EXT_TMP', 'tmp', 'Log file extension for temporary logs to use. On error those file extension will be renamed to SOSL_EXT_ERROR extension. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_EXT_LOCK', 'lock', 'Default process lock file extension. Lock files will always get deleted either on service start or after a run. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_EXT_ERROR', 'err', 'Default process error file extension. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_type, config_description)
  VALUES
  ('SOSL_MAX_PARALLEL', '8', 'NUMBER', 'The maximum of parallel started scripts. Read by the SOSL server. After this amount if scripts is started, next scripts are only loaded, if the run count is below this value.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_type, config_description)
  VALUES
  ('SOSL_RUNMODE', 'RUN', 'CHAR', 'Determines if the server should RUN, WAIT or STOP. Read by the SOSL server. RUN will cause the SOSL server, if started to run as long as it does not get a STOP signal from the database. Set it to STOP to stop the SOSL server. Set to WAIT if the server should not call any script apart the check for the run mode. Can be locally overwritten.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_type, config_description)
  VALUES
  ('SOSL_DEFAULT_WAIT', '1', 'NUMBER', 'Determines the normal sleep time in seconds the sosl server has between calls if scripts are available for processing.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_type, config_description)
  VALUES
  ('SOSL_NOJOB_WAIT', '120', 'NUMBER', 'Determines the sleep time in seconds the sosl server has between calls if no scripts are available for processing.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_type, config_description)
  VALUES
  ('SOSL_PAUSE_WAIT', '3600', 'NUMBER', 'Determines the sleep time in seconds the sosl server has between calls if run mode is set to wait.')
;
COMMIT;
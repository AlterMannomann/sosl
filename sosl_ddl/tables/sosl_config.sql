CREATE TABLE sosl_config
  ( config_name         VARCHAR2(128)                   NOT NULL
  , config_value        VARCHAR2(4000)                  NOT NULL
  , config_type         VARCHAR2(6)     DEFAULT 'CHAR'  NOT NULL
  , config_max_length   NUMBER          DEFAULT -1      NOT NULL
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
CREATE OR REPLACE TRIGGER sosl_config_ins_trg
  BEFORE INSERT ON sosl_config
  FOR EACH ROW
DECLARE
  l_ok    BOOLEAN;
  l_date  DATE;
BEGIN
  -- remove any leading and trailing blanks from config_value
  :NEW.config_value := TRIM(:NEW.config_value);
  -- check max length if defined
  IF :NEW.config_type = 'CHAR'
  THEN
    IF :NEW.config_max_length > 0
    THEN
      IF LENGTH(:NEW.config_value) > :NEW.config_max_length
      THEN
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
                         , 'SOSL_EXT_LOG'
                         , 'SOSL_EXT_LOCK'
                         , 'SOSL_START_LOG'
                         , 'SOSL_BASE_LOG'
                         , 'SOSL_MAX_PARALLEL'
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
  ('SOSL_PATH_CFG', '..\..\cfg\', 'Path to configuration files the SOSL server uses. As configuration files contain credentials and secrets the path should be in a safe space with controlled user rights.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_max_length, config_description)
  VALUES
  ('SOSL_PATH_TMP', '..\..\tmp\', 239, 'Path to temporary files the SOSL server uses. Parameter for sql files, limited to 239 chars.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_max_length, config_description)
  VALUES
  ('SOSL_PATH_LOG', '..\..\log\', 239, 'Path to log files the SOSL server creates. Parameter for sql files, limited to 239 chars.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_EXT_LOG', 'log', 'Log file extension to use.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_EXT_LOCK', 'lock', 'Default process lock file extension.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_START_LOG', 'sosl_server', 'Log filename for start and end of SOSL server CMD.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_BASE_LOG', 'sosl_job_', 'Base log filename for single job runs. Will be extended by GUID.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_type, config_description)
  VALUES
  ('SOSL_MAX_PARALLEL', '8', 'NUMBER', 'The maximum of parallel started scripts. After this amount if scripts is started, next scripts are only loaded, if the run count is below this value.')
;
COMMIT;
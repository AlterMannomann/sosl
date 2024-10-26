-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- requires login with the correct schema, either SOSL or your SOSL schema
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
-- Grants, inherited by others, no guest and user access on tables
GRANT SELECT ON sosl_config TO sosl_reviewer;
GRANT UPDATE ON sosl_config TO sosl_admin;
-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- load default values that can be configured in the database (mandatory)
-- basic configuration
INSERT INTO sosl_config
  (config_name, config_value, config_type, config_max_length, config_description)
  VALUES
  ('SOSL_RUNMODE', 'RUN', 'CHAR', 5, 'Determines if the server should RUN, PAUSE or STOP. Read by the SOSL server. RUN will cause the SOSL server, if started to run as long as it does not get a STOP signal from the database. Set it to STOP to stop the SOSL server. Set to PAUSE if the server should not call any script apart the check for the run mode. Can be locally overwritten.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_type, config_description)
  VALUES
  ('SOSL_MAX_PARALLEL', '8', 'NUMBER', 'The maximum of parallel started scripts. Read by the SOSL server. After this amount if scripts is started, next scripts are only loaded, if the run count is below this value.')
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
  ('SOSL_PAUSE_WAIT', '3600', 'NUMBER', 'Determines the sleep time in seconds the sosl server has between calls if run mode is set to wait. This wait time is also used, if the server detects that it is running out of the given timeframe.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_SERVER_STATE', 'INACTIVE', 'Information only. SOSL server sets this flag to ACTIVE if started, INACTIVE if stopped and PAUSE if waiting. If server is broken, the state is probably not reflecting the real server state.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_max_length, config_description)
  VALUES
  ('SOSL_START_JOBS', '07:55', 5, 'Defines the hour:minutes (24 hour format with leading zeros) where SOSL should start running scripts. If set to -1 this parameter is ignored and SOSL server runs until stopped. Otherwise the server will not start to request scripts before this hour. Either both hours are given for start and stop or -1 on one value deactivates the time frame.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_max_length, config_description)
  VALUES
  ('SOSL_STOP_JOBS', '18:00', 5, 'Defines the hour:minutes (24 hour format with leading zeros) where SOSL should stop running scripts. If set to -1 this parameter is ignored and SOSL server runs until stopped. Otherwise the server will stop to request scripts after this hour. Either both hours are given for start and stop or -1 on one value deactivates the time frame.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_max_length, config_description)
  VALUES
  ('SOSL_PATH_CFG', '..\..\sosl_cfg\', 4000, 'Information only. The relative path with delimiter at path end to configuration files the SOSL server uses for SOSL logins. Set by SOSL server. As configuration files contain credentials and secrets the path should be in a safe space with controlled user rights.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_max_length, config_description)
  VALUES
  ('SOSL_PATH_TMP', '..\..\sosl_tmp\', 239, 'Information only. The relative path with delimiter at path end to temporary files the SOSL server uses. Set by SOSL server. Parameter for sql files, limited to 239 chars.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_max_length, config_description)
  VALUES
  ('SOSL_PATH_LOG', '..\..\sosl_log\', 239, 'Information only. The relative path with delimiter at path end to log files the SOSL server creates. Set by SOSL server. Parameter for sql files, limited to 239 chars.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_START_LOG', 'sosl_server', 'Information only. The log filename for start and end of SOSL server CMD. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_BASE_LOG', 'sosl_job_', 'Information only. The base log filename for single job runs. Will be extended by GUID. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_EXT_LOG', 'log', 'Information only. The log file extension to use. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_EXT_TMP', 'tmp', 'Information only. The log file extension for temporary logs to use. On error those file extension will be renamed to SOSL_EXT_ERROR extension. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_EXT_LOCK', 'lock', 'Information only. The default process lock file extension. Lock files will always get deleted either on service start or after a run. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_description)
  VALUES
  ('SOSL_EXT_ERROR', 'err', 'Information only. The default process error file extension. Set by SOSL server.')
;
INSERT INTO sosl_config
  (config_name, config_value, config_max_length, config_description)
  VALUES
  ('SOSL_SCHEMA', TRIM(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')), 128, 'Information only. The schema SOSL uses. Defined on setup. No update or delete allowed.')
;
COMMIT;

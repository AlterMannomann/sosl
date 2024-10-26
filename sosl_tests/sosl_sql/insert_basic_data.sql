-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- load default values that can be configured in the database
-- basic configuration
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
-- default executor
INSERT INTO sosl_executor
  ( executor_name
  , db_user
  , function_owner
  , fn_has_scripts
  , fn_get_next_script
  , fn_set_script_status
  , cfg_file
  , use_mail
  , executor_description
  )
  VALUES ( 'SOSL'
         , 'sosl'
         , 'sosl'
         , 'sosl.has_scripts'
         , 'sosl.get_next_script'
         , 'sosl.set_script_status'
         , '..\sosl_templates\sosl_login.cfg'
         , 0
         , 'Internal SOSL executor for testing and demonstration purposes. Only a simple set of ordered scripts supported.'
         )
;
COMMIT;
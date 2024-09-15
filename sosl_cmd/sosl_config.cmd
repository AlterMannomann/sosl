REM Use this file to redefine the default values of variables, remove or put comment for sections to be
REM adjusted. By default the configuration is read from the database.
REM Set global variables valid in the script.
SET IDENTIFIER=%SOSL_GUID%_load_cfg
SET TMP_FILE=%SOSL_PATH_TMP%conf.tmp
REM *****************************************************************************************************
REM Path to log files the SOSL server creates. Parameter for sql files, limited to 239 chars.
REM SET SOSL_PATH_LOG=../../log/
CALL sosl_timestamp.cmd
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_PATH_LOG" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.cmd with SOSL_PATH_LOG
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_PATH_LOG=%%c
REM Now we can start logging
CALL sosl_timestamp.cmd
CALL sosl_sql.cmd "@@..\sosl_sql\sosl_whoami.sql" "%SOSL_GUID%_whoami" "%SOSL_DATETIME%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_whoami.cmd
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Path to configuration files the SOSL server uses. As configuration files contain credentials and
REM secrets the path should be in a safe space with controlled user rights. Must be correct configured if
REM security is important.
REM SET SOSL_PATH_CFG=../../cfg/
CALL sosl_timestamp.cmd
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_PATH_CFG" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.cmd with SOSL_PATH_CFG
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_PATH_CFG=%%c
REM *****************************************************************************************************
REM Path to temporary files the SOSL server uses. Parameter for sql files, limited to 239 chars.
REM SET SOSL_PATH_TMP=../../tmp/
REM *****************************************************************************************************
REM Log file extension to use.
REM SET SOSL_EXT_LOG=log
REM *****************************************************************************************************
REM Default process lock file extension.
REM SET SOSL_EXT_LOCK=lock
REM *****************************************************************************************************
REM Log filename for start and end of SOSL server CMD.
REM SET SOSL_START_LOG=sosl_server
REM *****************************************************************************************************
REM Base log filename for single job runs. Will be extended by GUID.
REM SET SOSL_BASE_LOG=sosl_job_
REM *****************************************************************************************************
REM The maximum of parallel started scripts. After this amount if scripts is started, next scripts are
REM only loaded, if the run count is below this value.
REM SET SOSL_MAX_PARALLEL=8
REM *****************************************************************************************************

REM skip error handling
GOTO :SOSL_CFG_END
:SOSL_CFG_ERROR
REM log to whatever definition of log file we have, on errors use the default
CALL sosl_log.cmd "%SOSL_ERRMSG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
EXIT /B -1
:SOSL_CFG_END
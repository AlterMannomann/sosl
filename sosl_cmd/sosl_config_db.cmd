REM Read configuration from database. Edit table SOSL_CONFIG in the database to change the values.
REM Set global variables valid in the script.
SET TMP_FILE=%SOSL_PATH_TMP%conf.tmp
REM *****************************************************************************************************
REM Now we can start logging
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql.cmd "@@..\sosl_sql\sosl_whoami.sql" "%SOSL_GUID%_whoami" "%SOSL_DATETIME%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_whoami.cmd
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM The maximum of parallel started scripts. After this amount of scripts is started, next scripts are
REM only loaded, if the run count is below this value.
REM Fetch SOSL_MAX_PARALLEL
SET IDENTIFIER=%SOSL_GUID%_load_cfg1
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_MAX_PARALLEL" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.cmd with SOSL_MAX_PARALLEL
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_MAX_PARALLEL=%%c
REM *****************************************************************************************************
REM Defines if SOSL server should run or stop.
REM Fetch SOSL_RUNMODE
SET IDENTIFIER=%SOSL_GUID%_load_cfg2
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_RUNMODE" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.cmd with SOSL_RUNMODE
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_RUNMODE=%%c
REM make sure we have either RUN or STOP
IF NOT %SOSL_RUNMODE%==RUN SET SOSL_RUNMODE=STOP
REM *****************************************************************************************************
REM Now update the database with the current settings we are running.
REM Set SOSL_PATH_CFG
SET IDENTIFIER=%SOSL_GUID%_set_cfg1
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_PATH_CFG" "%SOSL_PATH_CFG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_PATH_CFG
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_PATH_TMP
SET IDENTIFIER=%SOSL_GUID%_set_cfg2
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_PATH_TMP" "%SOSL_PATH_TMP%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_PATH_TMP
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_PATH_LOG
SET IDENTIFIER=%SOSL_GUID%_set_cfg3
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_PATH_LOG" "%SOSL_PATH_LOG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_PATH_LOG
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_EXT_LOG
SET IDENTIFIER=%SOSL_GUID%_set_cfg4
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_EXT_LOG" "%SOSL_EXT_LOG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_EXT_LOG
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_EXT_LOCK
SET IDENTIFIER=%SOSL_GUID%_set_cfg5
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_EXT_LOCK" "%SOSL_EXT_LOCK%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_EXT_LOCK
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_START_LOG
SET IDENTIFIER=%SOSL_GUID%_set_cfg6
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_START_LOG" "%SOSL_START_LOG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_START_LOG
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_BASE_LOG
SET IDENTIFIER=%SOSL_GUID%_set_cfg6
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_BASE_LOG" "%SOSL_BASE_LOG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_BASE_LOG
  GOTO :SOSL_CFG_ERROR
)

REM skip error handling
GOTO :SOSL_CFG_END
:SOSL_CFG_ERROR
REM log to whatever definition of log file we have, on errors use the default
CALL sosl_log.cmd "%SOSL_ERRMSG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
REM Delete temporary file if it exists
IF EXIST %TMP_FILE% DEL %TMP_FILE%
EXIT /B -1
:SOSL_CFG_END
REM Delete temporary file if it exists
IF EXIST %TMP_FILE% DEL %TMP_FILE%
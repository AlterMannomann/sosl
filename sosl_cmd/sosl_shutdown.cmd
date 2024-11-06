REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Read configuration from database. Edit table SOSL_CONFIG in the database to change the values.
REM Set global variables valid in the script.
SET TMP_FILE=%SOSL_PATH_TMP%shutdown.tmp
REM *****************************************************************************************************
REM Now we can start logging
REM Set server state to inactive and inform about the basics used
SET IDENTIFIER=%SOSL_GUID%_set_inactive
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_SERVER_STATE" "INACTIVE" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.sql with SOSL_SERVER_STATE
  GOTO :SOSL_CFG_ERROR
)
SET IDENTIFIER=%SOSL_GUID%_stop
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql.cmd "@@..\sosl_sql\server\sosl_stop.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_stop.sql
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
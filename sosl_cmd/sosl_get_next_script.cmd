REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Reads the needed data and details for script execution and executes the script.
REM Set global variables valid in the script.
SET CUR_SOSL_LOGIN=%SOSL_PATH_CFG%%SOSL_LOGIN%
SET TMP_FILE_RUN=%SOSL_PATH_TMP%%SOSL_GUID%_run_id.tmp
SET TMP_FILE_CFG=%SOSL_PATH_TMP%%SOSL_GUID%_cfg_file.tmp
SET LOCAL_RUN_ID=-1
SET LOCAL_CFG=INVALID
REM *****************************************************************************************************
REM Now we can get current script details
REM *****************************************************************************************************
REM Get the run id of the waiting script
SET IDENTIFIER=%SOSL_GUID%_get_run_id
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_RUN_ERROR
)
CALL sosl_sql_tmp.cmd "@@..\sosl_sql\server\sosl_get_next_run_id.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "%TMP_FILE_RUN%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_next_run_id.sql
  GOTO :SOSL_RUN_ERROR
)
FOR /F %%c IN (%TMP_FILE_RUN%) DO SET LOCAL_RUN_ID=%%c
IF %LOCAL_RUN_ID% LEQ 0 (
  SET SOSL_ERRMSG=Error invalid run id %LOCAL_RUN_ID%
  GOTO :SOSL_RUN_ERROR
)
REM get config file to use for script
SET IDENTIFIER=%SOSL_GUID%_get_cfg
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_RUN_ERROR
)
CALL sosl_sql_par.cmd "@@..\sosl_sql\server\sosl_get_cfg.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "%LOCAL_RUN_ID%" "%TMP_FILE_CFG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_cfg.sql
  GOTO :SOSL_RUN_ERROR
)
FOR /F %%c IN (%TMP_FILE_CFG%) DO SET LOCAL_CFG=%%c
IF NOT EXIST %LOCAL_CFG% (
  SET SOSL_ERRMSG=Error login config file %LOCAL_CFG% does not exist or is not reachable for SOSL
  GOTO :SOSL_RUN_ERROR
)
REM *****************************************************************************************************
REM All details successfully gathered, start the CMD that will run the script as an independent session
REM *****************************************************************************************************
START sosl_execute_script.cmd "%LOCAL_CFG%" "%LOCAL_RUN_ID%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%" "%SOSL_SCHEMA%"
GOTO :SOSL_RUN_END
:SOSL_RUN_ERROR
REM log to whatever definition of log file we have, on errors use the default
CALL sosl_log.cmd "%SOSL_ERRMSG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
REM On errors do not delete the temporary file
EXIT /B -1
:SOSL_RUN_END
REM Delete temporary file if it exists
IF EXIST %TMP_FILE_RUN% DEL %TMP_FILE_RUN%
IF EXIST %TMP_FILE_CFG% DEL %TMP_FILE_CFG%

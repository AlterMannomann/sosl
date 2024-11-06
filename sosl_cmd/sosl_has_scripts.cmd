ECHO ON
REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Check if SOSL has scripts waiting. Set wait time according to result.
REM Set global variables valid in the script.
SET TMP_FILE=%SOSL_PATH_TMP%%SOSL_GUID%_has_script.tmp
SET CUR_SOSL_LOGIN=%SOSL_PATH_CFG%%SOSL_LOGIN%
REM *****************************************************************************************************
REM Fetch SOSL_SERVER.HAS_SCRIPTS
SET IDENTIFIER=%SOSL_GUID%_has_scripts
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_tmp.cmd "@@..\sosl_sql\server\sosl_has_scripts.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF %SOSL_EXITCODE%==-1 (
  SET SOSL_ERRMSG=Error executing sosl_has_scripts.sql
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET CUR_HAS_SCRIPTS=%%c
IF [%CUR_HAS_SCRIPTS%]==[] GOTO :SOSL_CFG_ERROR
IF %CUR_HAS_SCRIPTS%==-1 GOTO :SOSL_CFG_ERROR
IF %CUR_HAS_SCRIPTS%==0 (
  SET CUR_WAIT_TIME=%SOSL_NOJOB_WAIT%
) ELSE (
  SET CUR_WAIT_TIME=%SOSL_DEFAULT_WAIT%
)
REM skip error handling
GOTO :SOSL_CFG_END
:SOSL_CFG_ERROR
REM log to whatever definition of log file we have, on errors use the default
CALL sosl_log.cmd "%SOSL_ERRMSG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
REM On errors do not delete the temporary file
EXIT /B -1
:SOSL_CFG_END
REM Delete temporary file if it exists
IF EXIST %TMP_FILE% DEL %TMP_FILE%

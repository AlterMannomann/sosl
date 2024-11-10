REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM This script should be started in an extra CMD session using START.
REM This means, it may read the variables of the caller session but they are only reliable
REM if this variables are stable for the whole time.
REM Expects the following parameter, all parameter are expected to be enclosed in ".
REM Parameter 1: login config filename including relative or absolute path used for login
REM Parameter 2: the run id associated with the script to run
REM Parameter 3: log file and relative path
REM Parameter 4: GUID of the process
REM Parameter 5: SOSL schema to use for SOSL packages and functions
REM Build own parameter set
SET SESSION_LOGIN=%~1
SET SESSION_RUN_ID=%~2
SET SESSION_LOG=%~3
SET SESSION_GUID=%~4
SET SESSION_SOSL_SCHEMA=%~5
SET SESSION_TMP_FILE=%SOSL_PATH_TMP%%SESSION_GUID%_execute.tmp
SET SESSION_IDENTIFIER=%SESSION_GUID%_execute
REM Build a run lock file
SET SESSION_LOCK=%SOSL_PATH_TMP%%SESSION_GUID%_run.%SOSL_EXT_LOCK%
ECHO Script %SESSION_SCRIPT% execution with guid %SESSION_GUID% > %SESSION_LOCK%
REM Get a valid date - do not use function to not interfere with the server
FOR /f %%a IN ('WMIC OS GET LocalDateTime ^| FIND "."') DO (
  SET DTS=%%a
)
REM format string
SET SESSION_DATETIME=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2% %DTS:~8,2%:%DTS:~10,2%:%DTS:~12,2%.%DTS:~15,6%
SET SESSION_DATETIME=%SESSION_DATETIME% -
CALL sosl_sql_execute.cmd "%SESSION_LOGIN%" "@@..\sosl_sql\server\sosl_execute.sql" "%SESSION_RUN_ID%" "%SESSION_IDENTIFIER%" "%SESSION_DATETIME%" "%SESSION_LOG%" "%SESSION_GUID%" "%SESSION_SOSL_SCHEMA%" > %SESSION_TMP_FILE% 2>&1
SET SESSION_EXITCODE=%ERRORLEVEL%
IF NOT %SESSION_EXITCODE%==0 (
  SET SESSION_ERRMSG=Error executing sosl_execute.sql with run id %SESSION_RUN_ID%
  GOTO :SESSION_ERROR
)
GOTO :SESSION_END

:SESSION_ERROR
REM Get a valid date - do not use function to not interfere with the server
FOR /f %%a IN ('WMIC OS GET LocalDateTime ^| FIND "."') DO (
  SET DTS=%%a
)
REM format string
SET SESSION_DATETIME=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2% %DTS:~8,2%:%DTS:~10,2%:%DTS:~12,2%.%DTS:~15,6%
SET SESSION_DATETIME=%SESSION_DATETIME% -
ECHO %SESSION_DATETIME% %SESSION_ERRMSG% >> %SESSION_LOG%
GOTO :SESSION_EXIT

:SESSION_END
REM Delete tmp file only if no errors occured
IF EXIST %SESSION_TMP_FILE% DEL %SESSION_TMP_FILE%

:SESSION_EXIT
REM Always delete lock file before ending the script
IF EXIST %SESSION_LOCK% DEL %SESSION_LOCK%
REM As we run independent no one will get our exit code
EXIT
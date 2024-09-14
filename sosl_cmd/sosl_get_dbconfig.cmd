REM Fetches configuration values from the database and provides them to the calling CMD. On errors variables will not be set.
REM Requires two parameter
REM Parameter 1: The name of the configuration variable to load.
REM Parameter 2: The SQL script name fetching the variable.
REM Check parameters
IF [%1]==[] GOTO PARAMETER_MISSING
IF [%2]==[] GOTO PARAMETER_MISSING
SET TMPFILE=%SOSL_PATH_TMP%/conf_value.tmp
SET TMP_CONTENT=undefined
START /WAIT /D ../sosl_sql/

REM get content of temporary file
FOR /F %%c IN (%TMPFILE%) DO SET TMP_CONTENT=%%c
REM jump to end if successfully finished
GOTO DBCONFIG_END
:PARAMETER_MISSING
REM log the error and exit afterwards

:DBCONFIG_END

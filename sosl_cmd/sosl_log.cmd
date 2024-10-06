REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CALL sosl_timestamp.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_LOG_ERROR
)
ECHO  %SOSL_DATETIME% %~1 >> %~2
GOTO :SOSL_LOG_EXIT
:SOSL_LOG_ERROR
EXIT /B -1
:SOSL_LOG_EXIT
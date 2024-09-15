REM Expects the following parameter, all parameter are expected to be enclosed in ".
REM Parameter 1: scriptname and relative path
REM Parameter 2: identifier for error log
REM Parameter 3: OS timestamp
REM Parameter 4: config name
REM Parameter 5: temporary content file and relative path
REM Parameter 6: log file and relative path
REM Add an extra line echo if last empty line is missing, errors must be handled by the caller
(TYPE %SOSL_PATH_CFG%sosl_login.cfg && ECHO. && ECHO %~1 %2 %3 %4 %5 %6) | sqlplus
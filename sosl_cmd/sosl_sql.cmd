REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Expects the following parameter, all parameter are expected to be enclosed in ".
REM Parameter 1: scriptname and relative path
REM Parameter 2: identifier for error log
REM Parameter 3: OS timestamp
REM Parameter 4: log file and relative path
REM Add an extra line echo if last empty line is missing, errors must be handled by the caller
(TYPE %SOSL_PATH_CFG%%SOSL_LOGIN% && ECHO. && ECHO %~1 %2 %3 %4) | sqlplus
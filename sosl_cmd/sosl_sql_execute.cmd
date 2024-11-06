REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Used for executing waiting scripts from SOSL.
REM Expects the following parameter, all parameter are expected to be enclosed in ".
REM Parameter 1: wrapper scriptname and relative path
REM Parameter 2: login config file
REM Parameter 3: waiting script file to execute
REM Parameter 4: db schema to use for the script
REM Parameter 5: identifier for error log
REM Parameter 6: OS timestamp
REM Parameter 7: log file and relative path
REM Parameter 8: GUID of the process
REM Add an extra line echo if last empty line is missing, errors must be handled by the caller
(TYPE %2 && ECHO. && ECHO %~1 %3 %4 %5 %6 %7 %8) | sqlplus
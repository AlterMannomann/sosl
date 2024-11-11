REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Default sql call with 4 SQL parameters (2-5). No return value apart from script execution
REM EXITCODE expected. Used mostly for logging purposes.
REM Expects the following parameter, all parameter are expected to be enclosed in ".
REM Parameter 1: scriptname and relative path
REM Parameter 2: identifier for error log
REM Parameter 3: OS timestamp
REM Parameter 4: log file and relative path
REM Parameter 5: GUID of the process
REM Add an extra line echo if last empty line is missing, errors must be handled by the caller
CHCP 65001 && (TYPE %CUR_SOSL_LOGIN% && ECHO. && ECHO %~1 %2 %3 %4 %5) | sqlplus
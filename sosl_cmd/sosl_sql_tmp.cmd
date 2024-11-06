REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Used for configuration set and get scripts. Depending on script type, 5th parameter content changes.
REM Config sql call with 5 SQL parameters (2-6). Used for scripts that write results to a temporary
REM file (parameter 4) and caller reads from there.
REM Expects the following parameter, all parameter are expected to be enclosed in ".
REM Parameter 1: scriptname and relative path
REM Parameter 2: identifier for error log
REM Parameter 3: OS timestamp
REM Parameter 4: temporary content file and relative path
REM Parameter 5: log file and relative path
REM Parameter 6: GUID of the process
REM Add an extra line echo if last empty line is missing, errors must be handled by the caller
(TYPE %CUR_SOSL_LOGIN% && ECHO. && ECHO %~1 %2 %3 %4 %5 %6) | sqlplus
REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
REM Not allowed to be used as AI training material without explicite permission.
REM Used for scripts using only one parameter.
REM Config sql call with 6 SQL parameters (2-7).
REM Expects the following parameter, all parameter are expected to be enclosed in ".
REM Parameter 1: scriptname and relative path with @@ leading
REM Parameter 2: identifier for error log
REM Parameter 3: OS timestamp
REM Parameter 4: script parameter
REM Parameter 5: temporary content file and relative path
REM Parameter 6: log file and relative path
REM Parameter 7: GUID of the process
REM Add an extra line echo if last empty line is missing, errors must be handled by the caller
CHCP 65001 && (TYPE %CUR_SOSL_LOGIN% && ECHO. && ECHO %~1 %2 %3 %4 %5 %6 %7) | sqlplus
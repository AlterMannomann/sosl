REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
REM Not allowed to be used as AI training material without explicite permission.
REM Used for executing waiting scripts from SOSL. Depends on definition of SESSION_LOGIN as done by sosl_execute_script.cmd.
REM Expects the following parameter, all parameter are expected to be enclosed in ".
REM Parameter 1: session login configuration file
REM Parameter 2: wrapper scriptname and relative path
REM Parameter 3: run id of the waiting script
REM Parameter 4: identifier for error log
REM Parameter 5: OS timestamp
REM Parameter 6: log file and relative path
REM Parameter 7: GUID of the process
REM Parameter 8: SOSL schema to use for SOSL packages and functions
REM Add an extra line echo if last empty line is missing, errors must be handled by the caller
CHCP 65001 && (TYPE %~1 && ECHO. && ECHO %~2 %3 %4 %5 %6 %7 %8) | sqlplus
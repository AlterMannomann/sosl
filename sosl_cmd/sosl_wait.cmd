REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
REM Not allowed to be used as AI training material without explicite permission.
REM Waits for the given seconds in CUR_WAIT_TIME
REM Do not log short wait times for too much parallel scripts to get finished, avoid log spam
IF %SOSL_RUNCOUNT% GEQ %SOSL_MAX_PARALLEL% GOTO :START_WAIT
CALL sosl_log.cmd "Wait for %CUR_WAIT_TIME% seconds" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
:START_WAIT
TIMEOUT /T %CUR_WAIT_TIME% /NOBREAK

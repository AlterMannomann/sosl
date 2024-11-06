REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Waits for the given seconds in CUR_WAIT_TIME
CALL sosl_log.cmd "Wait for %CUR_WAIT_TIME% seconds" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
TIMEOUT /T %CUR_WAIT_TIME% /NOBREAK

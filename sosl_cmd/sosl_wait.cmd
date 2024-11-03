REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Waits for the fiven seconds in parameter
CALL sosl_log.cmd "Not within timeframe between %SOSL_START_JOBS% and %SOSL_STOP_JOBS%. Wait for %1 seconds" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
TIMEOUT /T %1 /NOBREAK

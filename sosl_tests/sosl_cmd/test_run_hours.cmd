REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM FOR /f %%a IN ('WMIC OS GET LocalDateTime ^| FIND "."') DO (
REM   SET DTS=%%a
REM )
REM if start time greater (GTR) stop time we have a day break at 00:00
REM if start time equal (EQU) stop time not valid, ignore
REM if start time less (LSS) stop time, we are within a current day time frame
REM SET CUR_TIME=%DTS:~8,2%:%DTS:~10,2%
REM Suppose everything is okay and set then error states
REM SET CUR_RUNTIME_OK=0
REM Check for invalid settings or settings ignoring time frame
IF %SOSL_START_JOBS% EQU %SOSL_STOP_JOBS% GOTO :INVALID_SETTINGS
IF %SOSL_START_JOBS%==-1 GOTO :INVALID_SETTINGS
IF %SOSL_STOP_JOBS%==-1 GOTO :INVALID_SETTINGS
REM Check for valid settings
IF %SOSL_START_JOBS% GTR %SOSL_STOP_JOBS% GOTO :DAYBREAK
IF %SOSL_START_JOBS% LSS %SOSL_STOP_JOBS% GOTO :TIMEFRAME
REM If we land here we have a logic error
GOTO :INVALID_SETTINGS
:DAYBREAK
IF %CUR_TIME% GTR %SOSL_STOP_JOBS% (
  IF %CUR_TIME% LSS %SOSL_START_JOBS% SET CUR_RUNTIME_OK=-1
)
GOTO :TIMEFRAME_EXIT
:TIMEFRAME
IF %CUR_TIME% LSS %SOSL_START_JOBS% SET CUR_RUNTIME_OK=-1
IF %CUR_TIME% GTR %SOSL_STOP_JOBS% SET CUR_RUNTIME_OK=-1
GOTO :TIMEFRAME_EXIT
:INVALID_SETTINGS
REM Error situation, set runtime not ok always
ECHO Invalid settings
SET CUR_RUNTIME_OK=-1
:TIMEFRAME_EXIT


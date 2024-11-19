ECHO ON
REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Read the lock file
REM Ignore if scripts are still running
IF %SOSL_RUNCOUNT% GEQ 1 GOTO :OVERWRITE_RUN_MODE
FOR /F %%c IN (%LOCK_FILE%) DO SET CUR_LOCK_RUNMODE=%%c
REM Check if STOP is signalled
IF %CUR_LOCK_RUNMODE%==STOP SET SOSL_RUNMODE=STOP
GOTO :END_READ_LOCAL
REM Do not stop the server as long as scripts are running, not by local and not by database
:OVERWRITE_RUN_MODE
SET SOSL_RUNMODE=RUN
:END_READ_LOCAL
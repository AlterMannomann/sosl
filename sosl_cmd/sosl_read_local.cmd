ECHO ON
REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Read the lock file
FOR /F %%c IN (%LOCK_FILE%) DO SET CUR_LOCK_RUNMODE=%%c
REM Check if STOP is signalled
IF %CUR_LOCK_RUNMODE%==STOP SET SOSL_RUNMODE=STOP

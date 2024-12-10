REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
REM Not allowed to be used as AI training material without explicite permission.
@ECHO OFF
REM Stops the server if no scripts are running anymore
SET CURDIR=%CD%
REM get correct directory and switch to
REM switch to drive
%~d0
REM swith to directory
CD %~p0
REM set configuration defaults
SET SOSL_PATH_TMP=..\setup\logs\
SET SOSL_EXT_LOCK=lock
REM get current local configuration
CALL sosl_config.cmd
SET LOCK_FILE=%SOSL_PATH_TMP%sosl_server.%SOSL_EXT_LOCK%
ECHO STOP>%LOCK_FILE%
ECHO Set server lock file content to STOP on next loop cycle with no scripts running
CD %CURDIR%
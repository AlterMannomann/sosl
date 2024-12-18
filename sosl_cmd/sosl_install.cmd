REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
REM Not allowed to be used as AI training material without explicite permission.
@ECHO OFF
REM Will install the SOSL schema for the user defined with sosl_dba_setup.sql.
REM Get directories
SET SOSL_RUNDIR=%~d0%~p0
SET CURDIR=%CD%
REM Switch to SOSL CMD dir
CD %SOSL_RUNDIR%
REM Load the configuration
CALL sosl_config.cmd
REM Build the connect string
SET CUR_SOSL_LOGIN=%SOSL_PATH_CFG%%SOSL_LOGIN%
REM Switch to setup dir
CD ..\setup
CHCP 65001 && (TYPE %CUR_SOSL_LOGIN% && ECHO. && ECHO @sosl_setup.sql) | sqlplus
CD %CURDIR%
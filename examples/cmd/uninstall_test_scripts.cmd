REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
REM Not allowed to be used as AI training material without explicite permission.
@ECHO OFF
REM Will install an executor named SOSL and configure 25 test scripts with different runtime as well as one script
REM that will cause an error.
REM After installing start the SOSL CMD server
REM Get directories
SET SOSL_EXAMPLEDIR=%~d0%~p0
SET CURDIR=%CD%
CD %SOSL_EXAMPLEDIR%
REM Switch to SOSL CMD dir
CD ..\..\sosl_cmd
REM Load the configuration
CALL sosl_config.cmd
REM Build the connect string
SET CUR_SOSL_LOGIN=%SOSL_PATH_CFG%%SOSL_LOGIN%
CHCP 65001 && (TYPE %CUR_SOSL_LOGIN% && ECHO. && ECHO @..\sosl_tests\sosl_sql\uninstall_test_scripts.sql) | sqlplus
CD %CURDIR%
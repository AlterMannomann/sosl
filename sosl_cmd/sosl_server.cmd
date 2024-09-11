REM @ECHO OFF - disabled during testing
REM basically define variable defaults on highest level to be accessible for all called CMD files
REM you may change this variables using sosl_config.cmd, no need to touch this file. See also for
REM description of used variables.
SET SOSL_PATH_TMP=..\..\tmp
SET SOSL_PATH_LOG=..\..\log
REM This is a fallback using the repository directory, if path is not configured. Must be configured in sosl_config.cmd.
SET SOSL_PATH_CFG=..\sosl_templates
REM Fetch configured variables and overwrite definition if needed
CALL sosl_config.cmd

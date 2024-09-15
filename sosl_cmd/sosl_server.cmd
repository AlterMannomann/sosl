REM @ECHO OFF - disabled during testing
REM CMD must be called in this directory to make relative paths work. You may use START /D or task
REM scheduler to set the correct path the CMD is running in.
REM Basically define variable defaults on highest level to be accessible for all called CMD files
REM you may change this variables using sosl_config.cmd, no need to touch this file. See also for
REM description of used variables.
REM *****************************************************************************************************
REM Variables that can be manipulated by sosl_config.cmd or loaded from database.
REM This is a fallback using the repository directory, if path is not configured. SHOULD be configured in
REM sosl_config.cmd or the database.
SET SOSL_PATH_CFG=..\sosl_templates\
REM Default path to temporary files of SOSL.
SET SOSL_PATH_TMP=..\..\tmp\
REM Default path to logging files of SOSL.
SET SOSL_PATH_LOG=..\..\log\
REM Default log file extension.
SET SOSL_EXT_LOG=log
REM Default process lock file extension.
SET SOSL_EXT_LOCK=lock
REM Default log filename for start and end of SOSL server CMD.
SET SOSL_START_LOG=sosl_server
REM Default log filename for single job runs.
SET SOSL_BASE_LOG=sosl_job_
REM The maximum of parallel started scripts. After this amount if scripts is started, next scripts are
REM only loaded, if the run count is below this value.
SET SOSL_MAX_PARALLEL=8
REM *****************************************************************************************************
REM Variables used in the script and loaded by called CMDs.
REM Variable to hold GUIDs produced for each session. Used to create unique identifiers for SOSLERRORLOG
REM by calling sosl_guid.cmd.
SET SOSL_GUID=undefined
REM Variable to hold timestamp for logging, can be fetched by calling sosl_timestamp.cmd.
SET SOSL_DATETIME=undefined
REM Variable to store current error information.
SET SOSL_ERRMSG=undefined
REM Variable for storing exit codes from ERRORLEVEL.
SET SOSL_EXITCODE=-1
REM Variable to store the current count of running processes.
SET SOSL_RUNCOUNT=0
REM Get the full path of the run directory
SET SOSL_RUNDIR=%CD%
REM Get the full path of the base git directory
CD ..
SET SOSL_GITDIR=%CD%
CD %SOSL_RUNDIR%
REM create at least a temporary log directory in the default place to be able to log early errors
SET SOSL_TMP_LOG=%SOSL_PATH_LOG%
MKDIR %SOSL_PATH_LOG% 2>NUL
REM fetch a guid for the start process, check error for this CMD only once
CALL sosl_guid.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_guid.cmd
  GOTO :SOSL_ERROR
)
REM fetch a timestamp, check error for timestamp CMD only once
CALL sosl_timestamp.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_ERROR
)
REM Fetch configured variables and overwrite definition if needed, check error for this CMD only once
REM Default is load configuration from database.
CALL sosl_config.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_config.cmd
  GOTO :SOSL_ERROR
)
REM If we have reached this point, we can delete temporary log path not needed
IF NOT [%SOSL_PATH_LOG%]==[%SOSL_TMP_LOG%] RMDIR /S /Q %SOSL_TMP_LOG%
REM Create log and tmp directories if they do not exist, ignore config directory, user responsibility
MKDIR %SOSL_PATH_LOG% 2>NUL
MKDIR %SOSL_PATH_TMP% 2>NUL
REM Create log entry, check error for timestamp CMD only once
CALL sosl_timestamp.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_ERROR
)
ECHO %SOSL_DATETIME% SOSL configuration loaded >> %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%
REM fetch a guid for the start process, check error for this CMD only once
CALL sosl_guid.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_guid.cmd
  GOTO :SOSL_ERROR
)
CALL sosl_timestamp.cmd
ECHO %SOSL_DATETIME% Current GUID for session start: %SOSL_GUID% >> %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%
REM Add an extra line echo if last empty line is missing
REM (TYPE %SOSL_PATH_CFG%sosl_login.cfg && ECHO. && ECHO @@..\sosl_sql\sosl_whoami.sql "%SOSL_GUID%_whoami" "%SOSL_DATETIME%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%") | sqlplus
CALL sosl_timestamp.cmd
REM The scriptname should not contain whitespaces or - otherwise parameter is separated into to different parameters.
REM All script parameter must be enclosed in ".
REM CALL sosl_sql.cmd @@..\sosl_sql\sosl_whoami.sql "%SOSL_GUID%_whoami" "%SOSL_DATETIME%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_whoami.sql
  GOTO :SOSL_ERROR
)
REM Log additional information on the current parameter
REM CALL sosl_log_config.cmd
REM Skip error handling
GOTO SOSL_EXIT
:SOSL_ERROR
REM do not care if SOSL_DATETIME is correct or undefined
ECHO %SOSL_DATETIME% %SOSL_ERRMSG% >> %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%

:SOSL_EXIT
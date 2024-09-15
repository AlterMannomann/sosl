REM @ECHO OFF - disabled during testing
REM CMD must be called in this directory to make relative paths work. You may use START /D or task
REM scheduler to set the correct path the CMD is running in.
REM Basically define variable defaults on highest level to be accessible for all called CMD files
REM you may change this variables using sosl_config.cmd or database, **NO NEED TO TOUCH THIS FILE**.
REM *****************************************************************************************************
REM Defaults that cannot be changed.
REM If using CMD we do not need to ask what system we are in, it must be Windows.
REM All path are Windows style notation using \ as terminator as some
REM DOS commands cannot deal with unix style notation /.
SET SOSL_OS=WINDOWS
REM Get the full path of the run directory
SET SOSL_RUNDIR=%CD%
REM Get the full path of the base git directory
CD ..
SET SOSL_GITDIR=%CD%
CD %SOSL_RUNDIR%
REM *****************************************************************************************************
REM Variables that can be manipulated by sosl_config.cmd or loaded from database.
REM Default fallback path to configuration files of SOSL using defined repository structure for startup
REM until parameters are loaded. SHOULD be configured in sosl_config.cmd or the database.
SET SOSL_PATH_CFG=..\sosl_templates\
REM Default fallback path to temporary files of SOSL using defined repository structure for startup until
REM parameters are loaded.
SET SOSL_PATH_TMP=..\setup\logs\
REM Default fallback path to logging files of SOSL using defined repository structure for startup until
REM parameters are loaded.
SET SOSL_PATH_LOG=..\setup\logs\
REM Default log file extension.
SET SOSL_EXT_LOG=log
REM Default process lock file extension.
SET SOSL_EXT_LOCK=lock
REM Default log filename for start and end of SOSL server CMD.
SET SOSL_START_LOG=sosl_server
REM Default log filename for single job runs.
SET SOSL_BASE_LOG=sosl_job_
REM *****************************************************************************************************
REM Fetch configured values
CALL sosl_config.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_config.cmd
  GOTO :SOSL_ERROR
)
REM Create log and tmp directories if they do not exist, ignore config directory, user responsibility
MKDIR %SOSL_PATH_LOG% 2>NUL
MKDIR %SOSL_PATH_TMP% 2>NUL
REM *****************************************************************************************************
REM Define variables fetched from database
REM The maximum of parallel started scripts. After this amount if scripts is started, next scripts are
REM only loaded, if the run count is below this value.
SET SOSL_MAX_PARALLEL=8
REM Defines the run mode of the server. Either RUN, SLEEP or STOP any other value will be interpreted as
REM STOP.
SET SOSL_RUNMODE=RUN
REM Defines the wait time, if scripts are available for execution, by default 1 second. Remember to give
REM always other processes a chance.
SET SOSL_MIN_WAIT=1
REM Defines the wait time, if scripts are not available for execution and RUNMODE is not SLEEP, by
REM default 2 minutes.
SET SOSL_DEF_WAIT=120
REM Defines the wait time, if scripts are not available for execution and RUNMODE is SLEEP, by default 10
REM minutes.
SET SOSL_MAX_WAIT=600
REM Variable to hold GUIDs produced for each session. Used to create unique identifiers for SOSLERRORLOG
REM by calling sosl_guid.cmd.
SET SOSL_GUID=undefined
REM fetch a guid for the start process
CALL sosl_guid.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_guid.cmd
  GOTO :SOSL_ERROR
)
REM *****************************************************************************************************
REM Get and update the configuration in the database.
CALL sosl_config_db.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_config_db.cmd
  GOTO :SOSL_ERROR
)
REM *****************************************************************************************************
REM Variables used in the script and loaded by called CMDs.
REM Variable to hold timestamp for logging, can be fetched by calling sosl_timestamp.cmd.
SET SOSL_DATETIME=undefined
REM Variable to store current error information.
SET SOSL_ERRMSG=undefined
REM Variable for storing exit codes from ERRORLEVEL.
SET SOSL_EXITCODE=-1
REM Variable to store the current count of running processes.
SET SOSL_RUNCOUNT=0
REM *****************************************************************************************************
REM Create log entries
CALL sosl_timestamp.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_ERROR
)
ECHO %SOSL_DATETIME% SOSL configuration loaded, running on %SOSL_OS% >> %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%
CALL sosl_timestamp.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_ERROR
)
ECHO %SOSL_DATETIME% Current GUID for session start: %SOSL_GUID%, repository directory %SOSL_GITDIR%  >> %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%
REM *****************************************************************************************************

:SOSL_LOOP

REM Skip error handling
GOTO SOSL_EXIT
:SOSL_ERROR
REM do not care if SOSL_DATETIME is correct or undefined
ECHO %SOSL_DATETIME% %SOSL_ERRMSG% >> %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%

:SOSL_EXIT
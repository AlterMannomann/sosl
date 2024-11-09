ECHO ON
REM @ECHO OFF - disabled during testing
REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM CMD expansion necessary
SETLOCAL ENABLEEXTENSIONS
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
REM Default login file for SOSL schema, used when not acting as executor
SET SOSL_LOGIN=sosl_login.cfg
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
SET SOSL_DEFAULT_WAIT=1
REM Defines the wait time, if scripts are not available for execution and RUNMODE is not SLEEP, by
REM default 2 minutes.
SET SOSL_NOJOB_WAIT=120
REM Defines the wait time, if scripts are not available for execution and RUNMODE is SLEEP, by default 10
REM minutes.
SET SOSL_PAUSE_WAIT=600
REM Defines the start hour:minutes for the SOSL server in 24h format, if -1 SOSL server is active the whole time.
SET SOSL_START_JOBS=08:00
REM Defines the end hour:minutes for the SOSL server in 24h format, ignored if SOSL_START_JOBS is -1.
REM After this hour, the SOSL server will not make any connections to the database until SOSL_START_JOBS
REM hour is reached. Local log will be written with alive pings.
SET SOSL_STOP_JOBS=18:30
REM The SOSL schema to use for prefixing SOSL packages and functions.
SET SOSL_SCHEMA=SOSL
REM *****************************************************************************************************
REM Define internal variables
REM Current login file name for execution. Will be used whenever acting as an executor. Will be overwritten
REM whenever a new script is available by the executor definition for the configuration file. Should start
REM with the same value as SOSL_LOGIN.
SET CUR_SOSL_LOGIN=%SOSL_PATH_CFG%%SOSL_LOGIN%
REM Defines the wait time used in the loop.
SET CUR_WAIT_TIME=%SOSL_DEFAULT_WAIT%
REM Defines the current fetched run id. -1 is for not having a valid run id.
SET CUR_RUN_ID=-1
REM Defines if the current time is okay to run scripts. Depends on SOSL_START_JOBS and SOSL_STOP_JOBS
REM settings, based on the server time of the SOSL CMD server environment. 0 means SOSL CMD server can
REM request new jobs, if available. -1 means that the server waits until SOSL_START_JOBS hour is reached.
SET CUR_RUNTIME_OK=0
REM Set with the current amount of waiting scripts.
SET CUR_HAS_SCRIPTS=0
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
REM Set lock file name
SET LOCK_FILE=%SOSL_PATH_TMP%sosl_server.%SOSL_EXT_LOCK%
REM Create lock file. Contains the run mode at start. Can be overwritten locally to stop
REM the CMD server with stop_sosl_locally.cmd. Pause mode can only be set by database table SOSL_CONFIG.
ECHO %SOSL_RUNMODE% > %LOCK_FILE%
REM *****************************************************************************************************
REM Create log entries
CALL sosl_timestamp.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_ERROR
)
ECHO %SOSL_DATETIME% SOSL configuration loaded, running on %SOSL_OS% >> %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%
ECHO %SOSL_DATETIME% LOCK file created: %LOCK_FILE% >> %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%

CALL sosl_timestamp.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_ERROR
)
ECHO %SOSL_DATETIME% Current GUID for session start: %SOSL_GUID%, repository directory %SOSL_GITDIR%  >> %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%
REM *****************************************************************************************************
REM Start the loop, do not break the loop on minor errors

:SOSL_LOOP
REM Start loop always with SOSL login
SET CUR_SOSL_LOGIN=%SOSL_PATH_CFG%%SOSL_LOGIN%
REM Check if the we have reached max run count, go directly to wait if reached
REM Takes the last value set for max parallel and wait time, will not fetch new values from database
REM unless the run count falls under max parallel
CALL sosl_get_run_count.cmd
IF %SOSL_RUNCOUNT% GEQ %SOSL_MAX_PARALLEL% GOTO :SOSL_WAIT
REM Fetch current parameters for each loop
REM fetch a guid for the start process
CALL sosl_guid.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_guid.cmd
  GOTO :SOSL_ERROR
)
REM *****************************************************************************************************
REM Get and update the configuration from the database.
CALL sosl_loop_config.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_loop_config.cmd
  GOTO :SOSL_ERROR
) ELSE (
  IF EXIST %SOSL_PATH_TMP%%SOSL_GUID%.tmp DEL %SOSL_PATH_TMP%%SOSL_GUID%.tmp
)
REM Get local settings
CALL sosl_read_local.cmd
REM Check runmode and adjust wait time based on run mode
IF %SOSL_RUNMODE%==STOP GOTO :SOSL_EXIT
REM Check defined run hours, if not successful will return to this point

:SHORT_LOOP
CALL sosl_run_hours.cmd
IF %CUR_RUNTIME_OK%==-1 (
  SET CUR_WAIT_TIME=%SOSL_PAUSE_WAIT%
  CALL sosl_log.cmd "Not within timeframe between %SOSL_START_JOBS% and %SOSL_STOP_JOBS%. Set wait time to %CUR_WAIT_TIME% seconds" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
  CALL sosl_wait.cmd
  GOTO :SHORT_LOOP
)
REM Get a guid for has scripts
CALL sosl_guid.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_guid.cmd
  GOTO :SOSL_ERROR
)
REM Check if scripts available and adjust wait time on has_scripts result
CALL sosl_has_scripts.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  CALL sosl_log.cmd "Error calling sosl_has_scripts.cmd" %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%
) ELSE (
  IF EXIST %SOSL_PATH_TMP%%SOSL_GUID%.tmp DEL %SOSL_PATH_TMP%%SOSL_GUID%.tmp
)
REM If no script, wait and loop again
IF %CUR_HAS_SCRIPTS%==0 GOTO :SOSL_WAIT
REM wait also on errors
IF %CUR_HAS_SCRIPTS% LSS 0 GOTO :SOSL_WAIT
REM If script available execute it and check state
REM Get a guid for running a script
CALL sosl_guid.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_guid.cmd
  GOTO :SOSL_ERROR
)
REM The called function will START the execute script as an independend session
CALL sosl_get_next_script.cmd
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  CALL sosl_log.cmd "Error calling sosl_get_next_script.cmd" %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%
) ELSE (
  IF EXIST %SOSL_PATH_TMP%%SOSL_GUID%.tmp DEL %SOSL_PATH_TMP%%SOSL_GUID%.tmp
)
REM Wait as defined and repeat loop

:SOSL_WAIT
CALL sosl_wait.cmd
REM repeat loop
GOTO :SOSL_LOOP

:SOSL_ERROR
REM do not care if SOSL_DATETIME is correct or undefined
ECHO %SOSL_DATETIME% %SOSL_ERRMSG% >> %SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%

:SOSL_EXIT
CALL sosl_shutdown.cmd
IF EXIST %LOCK_FILE% DEL %LOCK_FILE%
ENDLOCAL
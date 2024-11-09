ECHO ON
REM (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
REM Not allowed to be used as AI training material without explicite permission.
REM Read configuration from database. Edit table SOSL_CONFIG in the database to change the values.
REM Set global variables valid in the script.
SET TMP_FILE=%SOSL_PATH_TMP%conf.tmp
SET CUR_SOSL_LOGIN=%SOSL_PATH_CFG%%SOSL_LOGIN%
REM *****************************************************************************************************
REM Now we can start logging
REM Set server state to active and inform about the basics
REM *****************************************************************************************************
REM Inform database that the CMD server is active.
SET IDENTIFIER=%SOSL_GUID%_set_active
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_SERVER_STATE" "ACTIVE" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.sql with SOSL_SERVER_STATE
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Log the start of the CMD server.
SET IDENTIFIER=%SOSL_GUID%_start
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql.cmd "@@..\sosl_sql\server\sosl_start.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_start.sql
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM The maximum of parallel started scripts. After this amount of scripts is started, next scripts are
REM only loaded, if the run count is below this value.
REM Fetch SOSL_MAX_PARALLEL
SET IDENTIFIER=%SOSL_GUID%_load_parallel
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_MAX_PARALLEL" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.sql with SOSL_MAX_PARALLEL
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_MAX_PARALLEL=%%c
REM *****************************************************************************************************
REM Defines if SOSL server should run or stop.
REM Fetch SOSL_RUNMODE
SET IDENTIFIER=%SOSL_GUID%_load_runmode
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_RUNMODE" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.cmd with SOSL_RUNMODE
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_RUNMODE=%%c
REM make sure we have either RUN, PAUSE or STOP
IF NOT %SOSL_RUNMODE%==RUN (
  IF NOT %SOSL_RUNMODE%==PAUSE (
    SET SOSL_RUNMODE=STOP
  ) ELSE (
    SET SOSL_RUNMODE=PAUSE
  )
)
REM *****************************************************************************************************
REM The default wait time if scripts are available
REM Fetch SOSL_DEFAULT_WAIT
SET IDENTIFIER=%SOSL_GUID%_load_def_wait
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_DEFAULT_WAIT" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.sql with SOSL_DEFAULT_WAIT
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_DEFAULT_WAIT=%%c
REM *****************************************************************************************************
REM The default wait time if no scripts are available
REM Fetch SOSL_NOJOB_WAIT
SET IDENTIFIER=%SOSL_GUID%_load_nojob_wait
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_NOJOB_WAIT" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.sql with SOSL_NOJOB_WAIT
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_NOJOB_WAIT=%%c
REM *****************************************************************************************************
REM The pause wait time if server state is set to PAUSE
REM Fetch SOSL_PAUSE_WAIT
SET IDENTIFIER=%SOSL_GUID%_load_pause_wait
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_PAUSE_WAIT" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.sql with SOSL_PAUSE_WAIT
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_PAUSE_WAIT=%%c
REM *****************************************************************************************************
REM The hour of the day at which the server can start to request jobs
REM Fetch SOSL_START_JOBS
SET IDENTIFIER=%SOSL_GUID%_load_start_jobs
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_START_JOBS" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.sql with SOSL_START_JOBS
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_START_JOBS=%%c
REM *****************************************************************************************************
REM The hour of the day at which the server should stop to request jobs
REM Fetch SOSL_STOP_JOBS
SET IDENTIFIER=%SOSL_GUID%_load_stop_jobs
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_STOP_JOBS" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.sql with SOSL_STOP_JOBS
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_STOP_JOBS=%%c
REM *****************************************************************************************************
REM The SOSL schema as configured on installation.
REM Fetch SOSL_SCHEMA
SET IDENTIFIER=%SOSL_GUID%_load_sosl_schema
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_get_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_SCHEMA" "%TMP_FILE%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_get_config.sql with SOSL_SCHEMA
  GOTO :SOSL_CFG_ERROR
)
FOR /F %%c IN (%TMP_FILE%) DO SET SOSL_SCHEMA=%%c
REM *****************************************************************************************************
REM Now update the database with the current settings we are running.
REM Set SOSL_PATH_CFG
SET IDENTIFIER=%SOSL_GUID%_set_path_cfg
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_PATH_CFG" "%SOSL_PATH_CFG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_PATH_CFG
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_PATH_TMP
SET IDENTIFIER=%SOSL_GUID%_set_path_tmp
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_PATH_TMP" "%SOSL_PATH_TMP%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_PATH_TMP
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_PATH_LOG
SET IDENTIFIER=%SOSL_GUID%_set_path_log
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_PATH_LOG" "%SOSL_PATH_LOG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_PATH_LOG
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_EXT_LOG
SET IDENTIFIER=%SOSL_GUID%_set_ext_log
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_EXT_LOG" "%SOSL_EXT_LOG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_EXT_LOG
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_EXT_LOCK
SET IDENTIFIER=%SOSL_GUID%_set_ext_lock
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_EXT_LOCK" "%SOSL_EXT_LOCK%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_EXT_LOCK
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_START_LOG
SET IDENTIFIER=%SOSL_GUID%_set_start_log
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_START_LOG" "%SOSL_START_LOG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_START_LOG
  GOTO :SOSL_CFG_ERROR
)
REM *****************************************************************************************************
REM Set SOSL_BASE_LOG
SET IDENTIFIER=%SOSL_GUID%_set_base_log
CALL sosl_timestamp.cmd
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_timestamp.cmd
  GOTO :SOSL_CFG_ERROR
)
CALL sosl_sql_cfg.cmd "@@..\sosl_sql\server\sosl_set_config.sql" "%IDENTIFIER%" "%SOSL_DATETIME%" "SOSL_BASE_LOG" "%SOSL_BASE_LOG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%" "%SOSL_GUID%"
SET SOSL_EXITCODE=%ERRORLEVEL%
IF NOT %SOSL_EXITCODE%==0 (
  SET SOSL_ERRMSG=Error executing sosl_set_config.cmd with SOSL_BASE_LOG
  GOTO :SOSL_CFG_ERROR
)
REM skip error handling
GOTO :SOSL_CFG_END
:SOSL_CFG_ERROR
REM log to whatever definition of log file we have, on errors use the default
CALL sosl_log.cmd "%SOSL_ERRMSG%" "%SOSL_PATH_LOG%%SOSL_START_LOG%.%SOSL_EXT_LOG%"
REM On errors do not delete the temporary file
EXIT /B -1
:SOSL_CFG_END
REM Delete temporary file if it exists
IF EXIST %TMP_FILE% DEL %TMP_FILE%
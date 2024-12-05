#! /bin/bash
# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# Not allowed to be used as AI training material without explicite permission.
# Bash script must be called in this directory to make relative paths work.
# Basically define variable defaults on highest level to be accessible for all called bash scripts
# you may change this variables using sosl_config.sh or database, **NO NEED TO TOUCH THIS FILE**.
# *****************************************************************************************************
# Defaults that cannot be changed.
# Shell scripts run in a unix environment, even if it is git bash on Windows.
# Shell commands deal with unix style notation / for path delimiter.
sosl_os=UNIX
# Get the full path of the run directory
sosl_rundir=$(dirname $(realpath -s "$0"))
cd $sosl_rundir
# Get the full path of the base git directory
cd ..
sosl_gitdir=$(pwd)
cd $sosl_rundir
# *****************************************************************************************************
# Variables that can be manipulated by sosl_config.cmd or loaded from database.
# Default fallback path to configuration files of SOSL using defined repository structure for startup
# until parameters are loaded. SHOULD be configured in sosl_config.cmd or the database.
sosl_path_cfg=../sosl_templates/
# Default fallback path to temporary files of SOSL using defined repository structure for startup until
# parameters are loaded.
sosl_path_tmp=../setup/logs/
# Default login file for SOSL schema, used when not acting as executor
sosl_login=sosl_login.cfg
# Default fallback path to logging files of SOSL using defined repository structure for startup until
# parameters are loaded.
sosl_path_log=../setup/logs/
# Default log file extension.
sosl_ext_log=log
# Default process lock file extension.
sosl_ext_lock=lock
# Default log filename for start and end of SOSL server CMD.
sosl_start_log=sosl_server
# Default log filename for single job runs.
sosl_base_log=sosl_job_
# *****************************************************************************************************
# Source SOSL functions
. sosl_functions.sh
sosl_exitcode=$?
if [ $sosl_exitcode -ne 0 ]; then
  sosl_errmsg='Error executing sosl_functions.sh error code: '$sosl_exitcode
  sosl_error
fi
# *****************************************************************************************************
# Fetch configured values
. sosl_config.sh
sosl_exitcode=$?
if [ $sosl_exitcode -ne 0 ]; then
  sosl_errmsg='Error executing sosl_config.sh error code: '$sosl_exitcode
  sosl_error
fi
# Create log and tmp directories if they do not exist, ignore config directory, user responsibility
if ! [ -d "$sosl_path_log" ]; then mkdir $sosl_path_log; fi
if ! [ -d "$sosl_path_tmp" ]; then mkdir $sosl_path_tmp; fi
# Set lock file name
lock_file=$sosl_path_tmp'sosl_server.'$sosl_ext_lock
# If lock file exists, do not start the server
if [ -f $lock_file ]; then
  sosl_show_log "Error lock file $lock_file already exist. Second instance not allowed"
  exit
fi
# *****************************************************************************************************
# Define variables fetched from database
# The maximum of parallel started scripts. After this amount if scripts is started, next scripts are
# only loaded, if the run count is below this value.
sosl_max_parallel=8
# Defines the run mode of the server. Either RUN, SLEEP or STOP any other value will be interpreted as
# STOP.
sosl_runmode=RUN
# Defines the wait time, if scripts are available for execution, by default 1 second. #ember to give
# always other processes a chance.
sosl_default_wait=1
# Defines the wait time, if scripts are not available for execution and RUNMODE is not SLEEP, by
# default 2 minutes.
sosl_nojob_wait=120
# Defines the wait time, if scripts are not available for execution and RUNMODE is SLEEP, by default 10
# minutes.
sosl_pause_wait=600
# Defines the start hour:minutes for the SOSL server in 24h format, if -1 SOSL server is active the whole time.
sosl_start_jobs=08:00
# Defines the end hour:minutes for the SOSL server in 24h format, ignored if SOSL_START_JOBS is -1.
# After this hour, the SOSL server will not make any connections to the database until SOSL_START_JOBS
# hour is reached. Local log will be written with alive pings.
sosl_stop_jobs=18:00
# The SOSL schema to use for prefixing SOSL packages and functions.
sosl_schema=SOSL
# *****************************************************************************************************
# Define internal variables
# Current login file name for execution. Will be used whenever acting as an executor. Will be overwritten
# whenever a new script is available by the executor definition for the configuration file. Should start
# with the same value as SOSL_LOGIN.
cur_sosl_login=$sosl_path_cfg$sosl_login
# Defines the wait time used in the loop.
cur_wait_time=$sosl_default_wait
# Defines the current fetched run id. -1 is for not having a valid run id.
cur_run_id=-1
# Defines if the current time is okay to run scripts. Depends on SOSL_START_JOBS and SOSL_STOP_JOBS
# settings, based on the server time of the SOSL CMD server environment. 0 means SOSL CMD server can
# request new jobs, if available. -1 means that the server waits until SOSL_START_JOBS hour is reached.
cur_runtime_ok=0
# Set with the current amount of waiting scripts.
cur_has_scripts=0
# Variable to hold GUIDs produced for each session. Used to create unique identifiers for SOSLERRORLOG
# by calling sosl_guid.
sosl_guid=$(sosl_guid)
# *****************************************************************************************************
# Get and update the configuration in the database. Shutdown on errors.
sosl_config_db
# *****************************************************************************************************
# Variables used in the script and loaded by called functions.
# Variable to hold timestamp for logging, can be fetched by calling sosl_timestamp.cmd.
sosl_datetime=undefined
# Variable to store current error information.
sosl_errmsg=undefined
# Variable for storing exit codes from functions.
sosl_exitcode=-1
# Variable to store the current count of running processes.
sosl_runcount=0
# Create lock file. Contains the run mode at start. Can be overwritten locally to stop
# the CMD server with stop_sosl_locally.cmd. Pause mode can only be set by database table SOSL_CONFIG.
echo $sosl_runmode > $lock_file
# *****************************************************************************************************
# Create log entries
sosl_log "SOSL configuration loaded, running on $sosl_os"
sosl_log "LOCK file created: $lock_file"
sosl_log "Current GUID for session start: $sosl_guid, repository directory $sosl_gitdir"
# *****************************************************************************************************
# Start the loop, do not break the loop on minor errors
# for (( ; ; ));
while [ 0 ]
do
  if [ $sosl_runmode == "STOP" ]; then sosl_shutdown; fi
  sosl_check_vars
  # Start loop always with SOSL login
  cur_sosl_login=$sosl_path_cfg$sosl_login
  # Check if the we have reached max run count, call directly wait if reached
  # Takes the last value set for max parallel and wait time, will not fetch new values from database
  # unless the run count falls under max parallel
  sosl_get_run_count
  if [ $sosl_runcount -ge $sosl_max_parallel ]; then
    # wait until runcount less, do not log the waits
    sosl_wait 0
  else
    # check the situation
    # fetch a guid for the start process
    sosl_guid=$(sosl_guid)
    # Get and update the configuration from the database. Shutdown server on errors if no scripts are running.
    sosl_loop_config
    # Get local settings and check running scripts. Shutdown server if no scripts are running and LOCK file is set to STOP.
    sosl_read_local
    # Check defined run hours and set cur_runtime_ok. Shutdown server on errors if no scripts are running.
    sosl_run_hours
    if [ $cur_runtime_ok -eq 0 ]; then
      # Get a guid for has scripts
      sosl_guid=$(sosl_guid)
      # Check if scripts available and adjust wait time on has_scripts result
      sosl_has_scripts
      if [ $cur_has_scripts -eq 0 ]; then
        sosl_wait 1
      else
        # fetch next script
        # Get a guid for get next script
        sosl_guid=$(sosl_guid)
        # run the next script
        sosl_get_next_script
        # and wait as defined by cur_wait_time
        sosl_wait 1
      fi
    else
      # ignore run hour changes if scripts are running
      if [ $sosl_runcount -eq 0 ]; then
        sosl_wait 1
      fi
    fi
  fi
done
sosl_show_log "Unexpected server loop end"
sosl_shutdown
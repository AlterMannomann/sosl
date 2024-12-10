#! /bin/bash
# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
# Not allowed to be used as AI training material without explicite permission.
# build a formatted log date YYYY-MM-DD HH24:MI:SS.FF6 format equal to Windows version
function log_date () {
  echo $(date +"%F %T.%6N -")
}
function get_time () {
  echo $(date +"%H:%M")
}
# log given parameter
function sosl_log () {
  echo $(log_date) $1 >> $sosl_path_log$sosl_start_log.$sosl_ext_log
}
# log errors with global variable if used in more than one context
function sosl_error_log () {
  sosl_log "$sosl_errmsg"
}
# log and display given  parameter
function sosl_show_log () {
  sosl_log "$1"
  echo $1
}
# builds a random hex number in the format of windows GUID
function sosl_prepare_guid () {
  rnd1=$(xxd -l 4 -ps -u /dev/urandom)
  rnd2=$(xxd -l 2 -ps -u /dev/urandom)
  rnd3=$(xxd -l 2 -ps -u /dev/urandom)
  rnd4=$(xxd -l 2 -ps -u /dev/urandom)
  rnd5=$(xxd -l 6 -ps -u /dev/urandom)
  echo $rnd1-$rnd2-$rnd3-$rnd4-$rnd5
}
# delete a file if it exists, parameter file name with relative or full path
function sosl_del_file () {
  if [[ -n $1 && -f $1 ]]; then
    rm $1
    sosl_log "File $1 successfully deleted"
  else
    sosl_log "Given filename: $1 empty or does not exist"
  fi
}
# exit server and #ove lock file if it exists
function sosl_exit () {
  sosl_del_file "$lock_file"
  echo SOSL server stopped
  exit
}
# wait defined time in cur_wait_time, parameter log wait if 1
function sosl_wait () {
  if [[ $1 -eq 1 ]]; then
    sosl_log "Wait for $cur_wait_time seconds"
  fi
  sleep $cur_wait_time
}
# get run count
function sosl_get_run_count () {
  local_pattern=$sosl_path_tmp*run.$sosl_ext_lock
  # ignore errors if no file is found, handle special file situations
  sosl_runcount=$(ls 2>/dev/null -Ubad1 -- $local_pattern | wc -l)
  # overwrite any error from ls not finding a file
  return 0
}
# Used for configuration set and get scripts. Depending on script type, 5th parameter content changes.
# Config sql call with 6 SQL parameters (2-7). On get scripts the return value is stored in a temporary
# file (parameter 5) and caller reads from there. On set scripts parameter 5 contains the config value to set.
# Expects the following parameter.
# Parameter 1: scriptname and relative path with @@ leading
# Parameter 2: identifier for error log
# Parameter 3: OS timestamp
# Parameter 4: config name
# Parameter 5: temporary content file and relative path for get scripts, config value for set scripts
# Parameter 6: log file and relative path
# Parameter 7: GUID of the process
# Add an extra line echo if last empty line is missing, errors must be handled by the caller
function sosl_sql_cfg () {
  (cat $cur_sosl_login && echo && echo $1 \"$2\" \"$3\" \"$4\" \"$5\" \"$6\" \"$7\") | sqlplus
}
# Used for sql scripts of the SOSL server.
# Expects the following parameter.
# Parameter 1: scriptname and relative path with @@ leading
# Parameter 2: identifier for error log
# Parameter 3: OS timestamp
# Parameter 4: log file and relative path
# Parameter 5: GUID of the process
function sosl_sql () {
  (cat $cur_sosl_login && echo && echo $1 \"$2\" \"$3\" \"$4\" \"$5\") | sqlplus
}
# Used for sql scripts retrieving data
# Expects the following parameter.
# Parameter 1: scriptname and relative path with @@ leading
# Parameter 2: identifier for error log
# Parameter 3: OS timestamp
# Parameter 4: temporary content file and relative path
# Parameter 5: log file and relative path
# Parameter 6: GUID of the process
function sosl_sql_tmp () {
  (cat $cur_sosl_login && echo && echo $1 \"$2\" \"$3\" \"$4\" \"$5\" \"$6\") | sqlplus
}
# Used for scripts using only one parameter.
# Expects the following parameter.
# Parameter 1: scriptname and relative path with @@ leading
# Parameter 2: identifier for error log
# Parameter 3: OS timestamp
# Parameter 4: script parameter
# Parameter 5: temporary content file and relative path
# Parameter 6: log file and relative path
# Parameter 7: GUID of the process
function sosl_sql_par () {
  (cat $cur_sosl_login && echo && echo $1 \"$2\" \"$3\" \"$4\" \"$5\" \"$6\" \"$7\") | sqlplus
}
# Used for executing waiting scripts from SOSL. Depends on definition of session_login as done by sosl_execute_script.
# Expects the following parameter.
# Parameter 1: session login configuration file
# Parameter 2: wrapper scriptname and relative path
# Parameter 3: run id of the waiting script
# Parameter 4: identifier for error log
# Parameter 5: OS timestamp
# Parameter 6: log file and relative path
# Parameter 7: GUID of the process
# Parameter 8: SOSL schema to use for SOSL packages and functions
function sosl_sql_execute () {
  (cat $1 && echo && echo $2 \"$3\" \"$4\" \"$5\" \"$6\" \"$7\" \"$8\") | sqlplus
}
# gets a guid, shutdown on errors
function sosl_guid () {
  sosl_prepare_guid
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_prepare_guid error code: '$sosl_exitcode
    sosl_error
  fi
}
# try to shut down server correct, inform database
function sosl_shutdown () {
  sosl_guid=$(sosl_guid)
  # Set server state to inactive and inform about the basics used
  identifier=$sosl_guid'_set_inactive'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_SERVER_STATE" "INACTIVE" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_set_config.sql error code: '$sosl_exitcode
    sosl_error_log
    sosl_show_log "Error Shut down failed, could not set SOSL_SERVER_STATE"
    sosl_exit
  fi
  identifier=$sosl_guid'_stop'
  sosl_datetime=$(log_date)
  sosl_sql "@@../sosl_sql/server/sosl_stop.sql" "$identifier" "$sosl_datetime" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql with sosl_stop.sql error code: '$sosl_exitcode
    sosl_error_log
    sosl_show_log "Error Shut down failed, could not log server stop to database"
    sosl_exit
  fi
  sosl_exit
}
# log and display variable sosl_errormsg and exit server
function sosl_error () {
  sosl_show_log "$sosl_errmsg"
  if [ $sosl_runcount -eq 0 ]; then
    sosl_shutdown
  else
    sosl_show_log "Running scripts detected, maybe scripts are hanging if database is not available"
    sosl_show_log "Check scripts running and shutdown the server manually if appropriate"
  fi
}
# check global variables needed for the SOSL server and shuts down server on error
function sosl_check_vars () {
  if [[ -z $sosl_os ]]; then
    sosl_errmsg="Error variable sosl_os undefined"
    sosl_error
  fi
  if [[ -z $sosl_rundir ]]; then
    sosl_errmsg="Error variable sosl_rundir undefined"
    sosl_error
  fi
  if [[ -z $sosl_path_cfg ]]; then
    sosl_errmsg="Error variable sosl_path_cfg undefined"
    sosl_error
  fi
  if [[ -z $sosl_path_tmp ]]; then
    sosl_errmsg="Error variable sosl_path_tmp undefined"
    sosl_error
  fi
  if [[ -z $sosl_login ]]; then
    sosl_errmsg="Error variable sosl_login undefined"
    sosl_error
  fi
  if [[ -z $sosl_path_log ]]; then
    sosl_errmsg="Error variable sosl_path_log undefined"
    sosl_error
  fi
  if [[ -z $sosl_ext_log ]]; then
    sosl_errmsg="Error variable sosl_ext_log undefined"
    sosl_error
  fi
  if [[ -z $sosl_ext_lock ]]; then
    sosl_errmsg="Error variable sosl_ext_lock undefined"
    sosl_error
  fi
  if [[ -z $sosl_start_log ]]; then
    sosl_errmsg="Error variable sosl_start_log undefined"
    sosl_error
  fi
  if [[ -z $sosl_base_log ]]; then
    sosl_errmsg="Error variable sosl_base_log undefined"
    sosl_error
  fi
  if [[ -z $sosl_max_parallel ]]; then
    sosl_errmsg="Error variable sosl_max_parallel undefined"
    sosl_error
  fi
  if [[ -z $sosl_runmode ]]; then
    sosl_errmsg="Error variable sosl_runmode undefined"
    sosl_error
  fi
  if [[ -z $sosl_default_wait ]]; then
    sosl_errmsg="Error variable sosl_default_wait undefined"
    sosl_error
  fi
  if [[ -z $sosl_nojob_wait ]]; then
    sosl_errmsg="Error variable sosl_nojob_wait undefined"
    sosl_error
  fi
  if [[ -z $sosl_pause_wait ]]; then
    sosl_errmsg="Error variable sosl_pause_wait undefined"
    sosl_error
  fi
  if [[ -z $sosl_start_jobs ]]; then
    sosl_errmsg="Error variable sosl_start_jobs undefined"
    sosl_error
  fi
  if [[ -z $sosl_stop_jobs ]]; then
    sosl_errmsg="Error variable sosl_stop_jobs undefined"
    sosl_error
  fi
  if [[ -z $sosl_schema ]]; then
    sosl_errmsg="Error variable sosl_schema undefined"
    sosl_error
  fi
  if [[ -z $cur_sosl_login ]]; then
    sosl_errmsg="Error variable cur_sosl_login undefined"
    sosl_error
  fi
  if [[ -z $cur_wait_time ]]; then
    sosl_errmsg="Error variable cur_wait_time undefined"
    sosl_error
  fi
  if [[ -z $cur_run_id ]]; then
    sosl_errmsg="Error variable cur_run_id undefined"
    sosl_error
  fi
  if [[ -z $cur_runtime_ok ]]; then
    sosl_errmsg="Error variable cur_runtime_ok undefined"
    sosl_error
  fi
  if [[ -z $cur_has_scripts ]]; then
    sosl_errmsg="Error variable cur_has_scripts undefined"
    sosl_error
  fi
  if [[ -z $sosl_guid ]]; then
    sosl_errmsg="Error variable sosl_guid undefined"
    sosl_error
  fi
}
# read local lock file and shutdown if set to stop and no scripts running
function sosl_read_local () {
  # overwrite runmode only if no scripts are running
  if [[ $sosl_runcount -eq 0 ]]; then
    # read lock file and overwrite runmode with lock file content, if STOP
    local_runmode=$(cat $lock_file)
    if [[ $local_runmode == "STOP" ]]; then
      sosl_show_log "Local overwrite of runmode detected, stop the server"
      sosl_shutdown
    fi
  else
    # ensure runmode is RUN or PAUSE on scripts active
    if ! [[ $sosl_runmode == "RUN" || $sosl_runmode == "PAUSE" ]]; then
      sosl_runmode=RUN
    fi
  fi
}
# check if we are in time to run, set wait time accordingly or shutdown server on errors if no scripts running
function sosl_run_hours () {
  # check basics
  if [[ $sosl_start_jobs == $sosl_stop_jobs ]]; then
    sosl_errmsg="Error start jobs ($sosl_start_jobs) is not allowed to be equal to stop jobs ($sosl_stop_jobs)"
    sosl_error
  fi
  if [[ $sosl_start_jobs == "-1" ]]; then
    sosl_errmsg="Error start jobs ($sosl_start_jobs) is invalid"
    sosl_error
  fi
  if [[ $sosl_stop_jobs == "-1" ]]; then
    sosl_errmsg="Error stop jobs ($sosl_stop_jobs) is invalid"
    sosl_error
  fi
  local_time=$(get_time)
  # check daybreak
  if [[ $sosl_start_jobs > $sosl_stop_jobs ]]; then
    if [[ $local_time > $sosl_stop_jobs ]]; then
      cur_runtime_ok=-1
    fi
  else
    # normal time frame
    if [[ $local_time < $sosl_start_jobs || $local_time > $sosl_stop_jobs ]]; then
      cur_runtime_ok=-1
    fi
  fi
  # change pause time if necessary
  if [[ $cur_runtime_ok -eq -1 ]]; then
    cur_wait_time=$sosl_pause_wait
  fi
}
# check scripts available adjust wait time
function sosl_has_scripts () {
  # Set global variables valid in the script.
  tmp_file=$sosl_path_tmp$sosl_guid'_has_script.tmp'
  cur_sosl_login=$sosl_path_cfg$sosl_login
  identifier=$sosl_guid'_has_scripts'
  sosl_datetime=$(log_date)
  sosl_sql_tmp "@@../sosl_sql/server/sosl_has_scripts.sql" "$identifier" "$sosl_datetime" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [[ $sosl_exitcode -ne 0 ]]; then
    sosl_errmsg='Error executing sosl_sql_tmp with sosl_has_scripts.sql error code: '$sosl_exitcode
    sosl_error
  fi
  cur_has_scripts=$(cat $tmp_file)
  if [[ -z $cur_has_scripts ]]; then
    sosl_errmsg='Error retrieving a valid value from database. Fix database issue before running the server'
    sosl_error
  fi
  if [[ $cur_has_scripts -lt 0 ]]; then
    sosl_errmsg="Error retrieving invalid value $cur_has_scripts from database. Fix database issue before running the server"
    sosl_error
  fi
  if [[ $cur_has_scripts -eq 0 ]]; then
    cur_wait_time=$sosl_nojob_wait
  else
    cur_wait_time=$sosl_default_wait
  fi
  sosl_del_file "$tmp_file"
}
# execute a script by run id, should be run as an independent process adding & at the end of the call
# Expects the following parameter.
# Parameter 1: login config filename including relative or absolute path used for login
# Parameter 2: the run id associated with the script to run
# Parameter 3: log file and relative path
# Parameter 4: GUID of the process
# Parameter 5: SOSL schema to use for SOSL packages and functions
# Parameter 6: The lock file extension
# Parameter 7: The temporary path for this script
function sosl_execute_script () {
  # check parameters, we depend on them
  if [[ -z "$1" ]]; then
    sosl_errmsg="Error sosl_execute_script parameter 1 session_login undefined"
    sosl_error
  else
    session_login=$1
  fi
  if [[ -z "$2" ]]; then
    sosl_errmsg="Error sosl_execute_script parameter 2 session_run_id undefined"
    sosl_error
  else
    session_run_id=$2
  fi
  if [[ -z "$3" ]]; then
    sosl_errmsg="Error sosl_execute_script parameter 3 session_log undefined"
    sosl_error
  else
    session_log=$3
  fi
  if [[ -z "$4" ]]; then
    sosl_errmsg="Error sosl_execute_script parameter 4 session_guid undefined"
    sosl_error
  else
    session_guid=$4
  fi
  if [[ -z "$5" ]]; then
    sosl_errmsg="Error sosl_execute_script parameter 5 session_sosl_schema undefined"
    sosl_error
  else
    session_sosl_schema=$5
  fi
  if [[ -z "$6" ]]; then
    sosl_errmsg="Error sosl_execute_script parameter 6 session_lock_ext undefined"
    sosl_error
  else
    session_lock_ext=$6
  fi
  if [[ -z "$7" ]]; then
    sosl_errmsg="Error sosl_execute_script parameter 7 session_tmp_dir undefined"
    sosl_error
  else
    session_tmp_dir=$7
  fi
  # build the local vars from parameters
  session_tmp_file=$session_tmp_dir$session_guid'_execute.tmp'
  session_identifier=$session_guid'_execute'
  session_lock_file=$session_tmp_dir$session_guid'_run.'$session_lock_ext
  # create lock file with basic information
  echo "Script run id $session_run_id execution with guid $session_guid" > $session_lock_file
  session_datetime=$(log_date)
  # call the script
  sosl_sql_execute "$session_login" "@@../sosl_sql/server/sosl_execute.sql" "$session_run_id" "$session_identifier" "$session_datetime" "$session_log" "$session_guid" "$session_sosl_schema" &> $session_tmp_file
  sosl_exitcode=$?
  if [[ $sosl_exitcode -ne 0 ]]; then
    # only log the error
    sosl_errmsg="Error executing script with sosl_execute.sql and run id $session_run_id error code: $sosl_exitcode"
    sosl_error_log
    # delete lock file but not the tmp file
    sosl_del_file "$session_lock_file"
  else
    sosl_del_file "$session_lock_file"
    sosl_del_file "$session_tmp_file"
  fi
}
# get next script
function sosl_get_next_script () {
  # Set global variables valid in the function.
  cur_sosl_login=$sosl_path_cfg$sosl_login
  tmp_file_run=$sosl_path_tmp$sosl_guid'_run_id.tmp'
  tmp_file_cfg=$sosl_path_tmp$sosl_guid'_cfg_file.tmp'
  local_run_id=-1
  local_cfg=INVALID
  identifier=$sosl_guid'_get_run_id'
  sosl_datetime=$(log_date)
  sosl_sql_tmp "@@../sosl_sql/server/sosl_get_next_run_id.sql" "$identifier" "$sosl_datetime" "$tmp_file_run" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [[ $sosl_exitcode -ne 0 ]]; then
    sosl_errmsg='Error executing sosl_sql_tmp with sosl_get_next_run_id.sql error code: '$sosl_exitcode
    sosl_error
  fi
  local_run_id=$(cat $tmp_file_run)
  # get config file to use for script
  identifier=$sosl_guid'_get_cfg'
  sosl_datetime=$(log_date)
  sosl_sql_par "@@../sosl_sql/server/sosl_get_cfg.sql" "$identifier" "$sosl_datetime" "$local_run_id" "$tmp_file_cfg" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [[ $sosl_exitcode -ne 0 ]]; then
    sosl_errmsg='Error executing sosl_sql_par with sosl_get_cfg.sql error code: '$sosl_exitcode
    sosl_error
  fi
  local_cfg=$(cat $tmp_file_cfg)
  # start and do not wait for the result
  sosl_execute_script "$local_cfg" "$local_run_id" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid" "$sosl_schema" "$sosl_ext_lock" "$sosl_path_tmp" &
  # delete the temp files
  sosl_del_file "$tmp_file_run"
  sosl_del_file "$tmp_file_cfg"
}
# load database configuration, shutdown server on errors
function sosl_loop_config () {
  tmp_file=$sosl_path_tmp'conf_get.tmp'
  cur_sosl_login=$sosl_path_cfg$sosl_login
  # Fetch SOSL_START_JOBS
  identifier=$sosl_guid'_load_start_jobs'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_START_JOBS" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_get_config.sql error code: '$sosl_exitcode
    sosl_del_file "$tmp_file"
    sosl_error
  fi
  sosl_start_jobs=$(cat $tmp_file)
  # Fetch SOSL_STOP_JOBS
  identifier=$sosl_guid'_load_stop_jobs'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_STOP_JOBS" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_get_config.sql error code: '$sosl_exitcode
    sosl_del_file "$tmp_file"
    sosl_error
  fi
  sosl_stop_jobs=$(cat $tmp_file)
  # Fetch SOSL_MAX_PARALLEL
  identifier=$sosl_guid'_load_parallel'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_MAX_PARALLEL" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_get_config.sql error code: '$sosl_exitcode
    sosl_del_file "$tmp_file"
    sosl_error
  fi
  sosl_max_parallel=$(cat $tmp_file)
  # Fetch SOSL_RUNMODE
  identifier=$sosl_guid'_load_runmode'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_RUNMODE" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_get_config.sql error code: '$sosl_exitcode
    sosl_del_file "$tmp_file"
    sosl_error
  fi
  sosl_runmode=$(cat $tmp_file)
  # Fetch SOSL_DEFAULT_WAIT
  identifier=$sosl_guid'_load_def_wait'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_DEFAULT_WAIT" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_get_config.sql error code: '$sosl_exitcode
    sosl_del_file "$tmp_file"
    sosl_error
  fi
  sosl_default_wait=$(cat $tmp_file)
  # Fetch SOSL_NOJOB_WAIT
  identifier=$sosl_guid'_load_nojob_wait'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_NOJOB_WAIT" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_get_config.sql error code: '$sosl_exitcode
    sosl_del_file "$tmp_file"
    sosl_error
  fi
  sosl_nojob_wait=$(cat $tmp_file)
  # Fetch SOSL_PAUSE_WAIT
  identifier=$sosl_guid'_load_pause_wait'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_PAUSE_WAIT" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_get_config.sql error code: '$sosl_exitcode
    sosl_del_file "$tmp_file"
    sosl_error
  fi
  sosl_pause_wait=$(cat $tmp_file)
  # delete the temp file
  sosl_del_file "$tmp_file"
}
# load and set database configuration
function sosl_config_db () {
  # Read configuration from database. Edit table SOSL_CONFIG in the database to change the values.
  # Set global variables valid in the script.
  tmp_file=$sosl_path_tmp'dbconf.tmp'
  cur_sosl_login=$sosl_path_cfg$sosl_login
  # Inform database that the CMD server is active.
  identifier=$sosl_guid'_set_active'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_SERVER_STATE" "ACTIVE" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_set_config.sql error code: '$sosl_exitcode
    sosl_error
  fi
  # Set SOSL_PATH_CFG
  identifier=$sosl_guid'_set_path_cfg'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_PATH_CFG" "$sosl_path_cfg" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_set_config.sql error code: '$sosl_exitcode
    sosl_error
  fi
  # Set SOSL_PATH_TMP
  identifier=$sosl_guid'_set_path_tmp'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_PATH_TMP" "$sosl_path_tmp" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_set_config.sql error code: '$sosl_exitcode
    sosl_error
  fi
  # Set SOSL_PATH_LOG
  identifier=$sosl_guid'_set_path_log'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_PATH_LOG" "$sosl_path_log" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_set_config.sql error code: '$sosl_exitcode
    sosl_error
  fi
  # Set SOSL_EXT_LOG
  identifier=$sosl_guid'_set_ext_log'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_EXT_LOG" "$sosl_ext_log" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_set_config.sql error code: '$sosl_exitcode
    sosl_error
  fi
  # Set SOSL_EXT_LOCK
  identifier=$sosl_guid'_set_ext_lock'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_EXT_LOCK" "$sosl_ext_lock" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_set_config.sql error code: '$sosl_exitcode
    sosl_error
  fi
  # Set SOSL_START_LOG
  identifier=$sosl_guid'_set_start_log'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_START_LOG" "$sosl_start_log" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_set_config.sql error code: '$sosl_exitcode
    sosl_error
  fi
  # Set SOSL_BASE_LOG
  identifier=$sosl_guid'_set_base_log'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_BASE_LOG" "$sosl_base_log" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_set_config.sql error code: '$sosl_exitcode
    sosl_error
  fi
  # Fetch loop configuration
  sosl_loop_config
  # Fetch SOSL_SCHEMA
  identifier=$sosl_guid'_load_sosl_schema'
  sosl_datetime=$(log_date)
  sosl_sql_cfg "@@../sosl_sql/server/sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_SCHEMA" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  sosl_exitcode=$?
  if [ $sosl_exitcode -ne 0 ]; then
    sosl_errmsg='Error executing sosl_sql_cfg with sosl_get_config.sql error code: '$sosl_exitcode
    sosl_del_file "$tmp_file"
    sosl_error
  fi
  sosl_schema=$(cat $tmp_file)
  # delete the temp file
  sosl_del_file "$tmp_file"
}

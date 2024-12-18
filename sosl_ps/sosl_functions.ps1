# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
# Not allowed to be used as AI training material without explicite permission.
# build a formatted log date YYYY-MM-DD HH24:MI:SS.FF6 format equal to Windows version
function log_date {
  (Get-Date).toString("yyyy-MM-dd HH:mm:ss.ffffff -")
}
function get_time {
  (Get-Date).toString("HH:mm")
}
# log given parameter
function sosl_log {
  param(
    [string]$LogMessage
  )
  $private:logFileName = -join($sosl_path_log, $sosl_start_log, ".", $sosl_ext_log)
  # Using ASCII to overcome PS problems writing correct UTF8 without BOM
  echo "$(log_date) $LogMessage" >> $logFileName
}
# log errors with global variable if used in more than one context
function sosl_error_log {
  sosl_log $sosl_errmsg
}
# log and display given  parameter
function sosl_show_log {param([string]$LogMessage)
  sosl_log $LogMessage
  echo $LogMessage
}
# delete a file if it exists, parameter file name with relative or full path
function sosl_del_file {
  param(
    [string]$DelFile = "undefined"
  )
  try {
    if (($DelFile -ne "") -and ($DelFile -ne $null) -and (Test-Path $DelFile)) {
      Remove-Item $DelFile
      sosl_log "File $DelFile successfully deleted"
    } elseif (($DelFile -ne "") -and ($DelFile -ne $null)) {
      sosl_log "Given filename: $DelFile does not exist"
    }
  } catch {
    sosl_show_log "Error executing sosl_del_file line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
  }
}
# exit server and #ove lock file if it exists
function sosl_exit {param([string]$DelFile)
  sosl_del_file $lock_file
  echo "SOSL server stopped"
  exit
}
# wait defined time in cur_wait_time, parameter log wait if 1
function sosl_wait {
  param (
    [Parameter(Mandatory=$true)]
    [int]$showWait = 1
  )
  try {
    if ($showWait -eq 1) {
      sosl_log "Wait for $cur_wait_time seconds"
    }
    Start-Sleep -Seconds $cur_wait_time
  } catch {
    sosl_show_log "Error executing sosl_wait line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_exit
  }
}
# get run count
function sosl_get_run_count {
  try {
    $private:local_pattern="*run.$sosl_ext_lock"
    # ignore errors if no file is found, handle special file situations
    $sosl_runcount = (Get-ChildItem -Path $sosl_path_tmp -Filter $local_pattern).Count
    # overwrite any error from ls not finding a file
    return $sosl_runcount
  } catch {
    sosl_show_log "Error executing sosl_get_run_count line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    return 0
  }
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
function sosl_sql_cfg {
  param (
    [string]$l_scriptfile,
    [string]$l_identifier,
    [string]$l_os_time,
    [string]$l_conf_name,
    [string]$l_tmpOrValue,
    [string]$l_logfile,
    [string]$l_guid
  )
  try {
    # Powershell does not pipe correctly to sqlplus, use cmd to do the job
    $private:sqlCMD = "(TYPE $cur_sosl_login && ECHO. && ECHO $l_scriptfile `"$l_identifier`" `"$l_os_time`" `"$l_conf_name`" `"$l_tmpOrValue`" `"$l_logfile`" `"$l_guid`") | sqlplus"
    cmd /c "$sqlCMD"
  } catch {
    sosl_show_log "Error executing $l_scriptfile line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_exit
  }
}
# Used for sql scripts of the SOSL server.
# Expects the following parameter.
# Parameter 1: scriptname and relative path with @@ leading
# Parameter 2: identifier for error log
# Parameter 3: OS timestamp
# Parameter 4: log file and relative path
# Parameter 5: GUID of the process
function sosl_sql {
  param (
    [string]$l_scriptfile,
    [string]$l_identifier,
    [string]$l_os_time,
    [string]$l_logfile,
    [string]$l_guid
  )
  try {
    # Powershell does not pipe correctly to sqlplus, use cmd to do the job
    $private:sqlCMD = "(TYPE $cur_sosl_login && ECHO. && ECHO $l_scriptfile `"$l_identifier`" `"$l_os_time`" `"$l_logfile`" `"$l_guid`") | sqlplus"
    cmd /c "$sqlCMD"
  } catch {
    sosl_show_log "Error executing $l_scriptfile line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_exit
  }
}
# Used for sql scripts retrieving data
# Expects the following parameter.
# Parameter 1: scriptname and relative path with @@ leading
# Parameter 2: identifier for error log
# Parameter 3: OS timestamp
# Parameter 4: temporary content file and relative path
# Parameter 5: log file and relative path
# Parameter 6: GUID of the process
function sosl_sql_tmp {
  param (
    [string]$l_scriptfile,
    [string]$l_identifier,
    [string]$l_os_time,
    [string]$l_tmpfile,
    [string]$l_logfile,
    [string]$l_guid
  )
  try {
    # Powershell does not pipe correctly to sqlplus, use cmd to do the job
    $private:sqlCMD = "(TYPE $cur_sosl_login && ECHO. && ECHO $l_scriptfile `"$l_identifier`" `"$l_os_time`" `"$l_tmpfile`" `"$l_logfile`" `"$l_guid`") | sqlplus"
    cmd /c "$sqlCMD"
  } catch {
    sosl_show_log "Error executing $l_scriptfile line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_exit
  }
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
function sosl_sql_par {
  param (
    [string]$l_scriptfile,
    [string]$l_identifier,
    [string]$l_os_time,
    [string]$l_script_param,
    [string]$l_tmp_file,
    [string]$l_logfile,
    [string]$l_guid
  )
  try {
    # Powershell does not pipe correctly to sqlplus, use cmd to do the job
    $private:sqlCMD = "(TYPE $cur_sosl_login && ECHO. && ECHO $l_scriptfile `"$l_identifier`" `"$l_os_time`" `"$l_script_param`" `"$l_tmp_file`" `"$l_logfile`" `"$l_guid`") | sqlplus"
    cmd /c "$sqlCMD"
  } catch {
    sosl_show_log "Error executing $l_scriptfile line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_exit
  }
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
function sosl_sql_execute {
  param (
    [string]$l_session_cfg,
    [string]$l_scriptfile,
    [string]$l_identifier,
    [string]$l_run_id,
    [string]$l_os_time,
    [string]$l_logfile,
    [string]$l_guid,
    [string]$l_schema
  )
  try {
    # Powershell does not pipe correctly to sqlplus, use cmd to do the job
    $private:sqlCMD = "(TYPE $l_session_cfg && ECHO. && ECHO $l_scriptfile `"$l_identifier`" `"$l_run_id`" `"$l_os_time`" `"$l_logfile`" `"$l_guid`" `"$l_schema`") | sqlplus"
    cmd /c "$sqlCMD"
  } catch {
    # don't fail external scripts on execution errors, report them instead
    sosl_show_log "Error executing $l_scriptfile line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    return 1
  }
}
# gets a guid, shutdown on errors
function sosl_guid {
  try {
    $private:localGuid = "$(New-Guid)".ToUpper()
    echo $localGuid
  } catch {
    sosl_show_log "Error executing sosl_guid line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_exit
  }
}
# try to shut down server correct, inform database
function sosl_shutdown {
  try {
    $sosl_guid = sosl_guid
    # Set server state to inactive and inform about the basics used
    $identifier = -join($sosl_guid, "_set_inactive")
    $sosl_datetime = log_date
    sosl_sql_cfg "@@..\sosl_sql\server\sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_SERVER_STATE" "INACTIVE" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
    $identifier = -join($sosl_guid, "_stop")
    $sosl_datetime = log_date
    sosl_sql "@@..\sosl_sql\server\sosl_stop.sql" "$identifier" "$sosl_datetime" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
    sosl_exit
  } catch {
    sosl_show_log "Error executing sosl_shutdown line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_exit
  }
}
# log and display variable sosl_errormsg and exit server
function sosl_error {
  sosl_show_log $sosl_errmsg
  sosl_shutdown
}
# check global variables needed for the SOSL server and shuts down server on error
function sosl_check_vars {
  try {
    if (($sosl_os -eq "") -or ($sosl_os -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_os undefined"
      sosl_error
    }
    if (($sosl_rundir -eq "") -or ($sosl_rundir -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_rundir undefined"
      sosl_error
    }
    if (($sosl_path_cfg -eq "") -or ($sosl_path_cfg -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_path_cfg undefined"
      sosl_error
    }
    if (($sosl_path_tmp -eq "") -or ($sosl_path_tmp -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_path_tmp undefined"
      sosl_error
    }
    if (($sosl_login -eq "") -or ($sosl_login -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_login undefined"
      sosl_error
    }
    if (($sosl_path_log -eq "") -or ($sosl_path_log -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_path_log undefined"
      sosl_error
    }
    if (($sosl_ext_log -eq "") -or ($sosl_ext_log -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_ext_log undefined"
      sosl_error
    }
    if (($sosl_ext_lock -eq "") -or ($sosl_ext_lock -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_ext_lock undefined"
      sosl_error
    }
    if (($sosl_start_log -eq "") -or ($sosl_start_log -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_start_log undefined"
      sosl_error
    }
    if (($sosl_base_log -eq "") -or ($sosl_base_log -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_base_log undefined"
      sosl_error
    }
    if ($sosl_max_parallel -eq $null) {
      $global:sosl_errmsg = "Error variable sosl_max_parallel undefined"
      sosl_error
    }
    if (($sosl_runmode -eq "") -or ($sosl_runmode -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_runmode undefined"
      sosl_error
    }
    if ($sosl_default_wait -eq $null) {
      $global:sosl_errmsg = "Error variable sosl_default_wait undefined"
      sosl_error
    }
    if ($sosl_nojob_wait -eq $null) {
      $global:sosl_errmsg = "Error variable sosl_nojob_wait undefined"
      sosl_error
    }
    if ($sosl_pause_wait -eq $null) {
      $global:sosl_errmsg = "Error variable sosl_pause_wait undefined"
      sosl_error
    }
    if (($sosl_start_jobs -eq "") -or ($sosl_start_jobs -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_start_jobs undefined"
      sosl_error
    }
    if (($sosl_stop_jobs -eq "") -or ($sosl_stop_jobs -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_stop_jobs undefined"
      sosl_error
    }
    if (($sosl_schema -eq "") -or ($sosl_schema -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_schema undefined"
      sosl_error
    }
    if (($cur_sosl_login -eq "") -or ($cur_sosl_login -eq $null)) {
      $global:sosl_errmsg = "Error variable cur_sosl_login undefined"
      sosl_error
    }
    if ($cur_wait_time -eq $null) {
      $global:sosl_errmsg = "Error variable cur_wait_time undefined"
      sosl_error
    }
    if ($cur_run_id -eq $null) {
      $global:sosl_errmsg = "Error variable cur_run_id undefined"
      sosl_error
    }
    if ($cur_runtime_ok -eq $null) {
      $global:sosl_errmsg = "Error variable cur_runtime_ok undefined"
      sosl_error
    }
    if ($cur_has_scripts -eq $null) {
      $global:sosl_errmsg = "Error variable cur_has_scripts undefined"
      sosl_error
    }
    if (($sosl_guid -eq "") -or ($sosl_guid -eq $null)) {
      $global:sosl_errmsg = "Error variable sosl_guid undefined"
      sosl_error
    }
  } catch {
    sosl_show_log "Error executing sosl_check_vars line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_shutdown
  }
}
# read local lock file and shutdown if set to stop and no scripts running
function sosl_read_local {
  try {
    # overwrite runmode only if no scripts are running
    if ($sosl_runcount -eq 0) {
      # read lock file and overwrite runmode with lock file content, if STOP
      $private:local_runmode = (cat $lock_file)
      if ($local_runmode -eq "STOP") {
        sosl_show_log "Local overwrite of runmode detected, stop the server"
        $global:sosl_runmode = "STOP"
        sosl_shutdown
      }
    } else {
      # ensure runmode is RUN or PAUSE on scripts active
      if (($sosl_runmode -ne "RUN") -or ($sosl_runmode -ne "PAUSE")) {
        $global:sosl_runmode = "RUN"
      }
    }
  } catch {
    sosl_show_log "Error executing sosl_read_local line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_shutdown
  }
}
# check if we are in time to run, set wait time accordingly or shutdown server on errors if no scripts running
function sosl_run_hours {
  try {
    # check basics
    if ($sosl_start_jobs -eq $sosl_stop_jobs) {
      $global:sosl_errmsg = "Error start jobs ($sosl_start_jobs) is not allowed to be equal to stop jobs ($sosl_stop_jobs)"
      sosl_error
    }
    if ($sosl_start_jobs -eq "-1") {
      $global:sosl_errmsg = "Error start jobs ($sosl_start_jobs) is invalid"
      sosl_error
    }
    if ($sosl_stop_jobs -eq "-1") {
      $global:sosl_errmsg = "Error stop jobs ($sosl_stop_jobs) is invalid"
      sosl_error
    }
    $private:local_time = get_time
    # check daybreak
    if ($sosl_start_jobs -gt $sosl_stop_jobs) {
      if ($local_time -gt $sosl_stop_jobs) {
        $global:cur_runtime_ok = -1
      }
    } else {
      # normal time frame
      if (($local_time -lt $sosl_start_jobs) -or ($local_time -gt $sosl_stop_jobs)) {
        $global:cur_runtime_ok = -1
      }
    }
    # change pause time if necessary
    if ($cur_runtime_ok -eq -1) {
      $global:cur_wait_time = $sosl_pause_wait
    }
  } catch {
    sosl_show_log "Error executing sosl_run_hours line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_shutdown
  }
}
# check scripts available adjust wait time
function sosl_has_scripts {
  try {
    # Set global variables valid in the script.
    $tmp_file = -join($sosl_path_tmp, $sosl_guid, "_has_script.tmp")
    $cur_sosl_login = "$sosl_path_cfg$sosl_login"
    $identifier = -join($sosl_guid, "_has_scripts")
    $sosl_datetime = log_date
    sosl_sql_tmp "@@..\sosl_sql\server\sosl_has_scripts.sql" "$identifier" "$sosl_datetime" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
    $global:cur_has_scripts = (cat $tmp_file)
    if ($cur_has_scripts -eq $null) {
      $global:sosl_errmsg = 'Error retrieving a valid value from database. Fix database issue before running the server'
      sosl_error
    }
    if ($cur_has_scripts -lt 0) {
      $global:sosl_errmsg = "Error retrieving invalid value $cur_has_scripts from database. Fix database issue before running the server"
      sosl_error
    }
    if ($cur_has_scripts -eq 0) {
      $global:cur_wait_time = $sosl_nojob_wait
    } else {
      $global:cur_wait_time = $sosl_default_wait
    }
    sosl_del_file "$tmp_file"
  } catch {
    sosl_show_log "Error executing sosl_has_scripts line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_shutdown
  }
}
# execute a script by run id, should be run as an independent process adding & at the end of the call
# Expects the following parameter. Do not fail the SOSL server if script execution fails.
# Parameter 1: login config filename including relative or absolute path used for login
# Parameter 2: the run id associated with the script to run
# Parameter 3: log file and relative path
# Parameter 4: GUID of the process
# Parameter 5: SOSL schema to use for SOSL packages and functions
# Parameter 6: The lock file extension
# Parameter 7: The temporary path for this script
function sosl_execute_script {
  param (
    [string]$l_session_cfg,
    [string]$l_run_id,
    [string]$l_logfile,
    [string]$l_guid,
    [string]$l_schema,
    [string]$l_lockfile_ext,
    [string]$l_temp_path
  )
  try {
    # check parameters, we depend on them
    if (($l_session_cfg -eq "") -or ($l_session_cfg -eq $null)) {
      $global:sosl_errmsg = "Error sosl_execute_script parameter 1 session_cfg undefined"
      sosl_error
    }
    if (($l_run_id -eq "") -or ($l_run_id -eq $null)) {
      $global:sosl_errmsg = "Error sosl_execute_script parameter 2 run_id undefined"
      sosl_error
    }
    if (($l_logfile -eq "") -or ($l_logfile -eq $null)) {
      $global:sosl_errmsg = "Error sosl_execute_script parameter 3 logfile undefined"
      sosl_error
    }
    if (($l_guid -eq "") -or ($l_guid -eq $null)) {
      $global:sosl_errmsg = "Error sosl_execute_script parameter 4 guid undefined"
      sosl_error
    }
    if (($l_schema -eq "") -or ($l_schema -eq $null)) {
      $global:sosl_errmsg = "Error sosl_execute_script parameter 5 schema undefined"
      sosl_error
    }
    if (($l_lockfile_ext -eq "") -or ($l_lockfile_ext -eq $null)) {
      $global:sosl_errmsg = "Error sosl_execute_script parameter 5 lockfile extension undefined"
      sosl_error
    }
    if (($l_temp_path -eq "") -or ($l_temp_path -eq $null)) {
      $global:sosl_errmsg = "Error sosl_execute_script parameter 5 temp path undefined"
      sosl_error
    }
    # build the local vars from parameters
    $session_tmp_file = -join($l_temp_path, $l_guid, "_execute.tmp")
    $session_identifier = -join($l_guid, "_execute")
    $session_lock_file = -join($l_temp_path, $l_guid, "_run.", $l_lockfile_ext)
    # create lock file with basic information
    echo "Script run id $l_run_id execution with guid $l_guid" > $session_lock_file
    $session_datetime = log_date
    # call the script
    sosl_sql_execute "$session_login" "@@..\sosl_sql\server\sosl_execute.sql" "$l_run_id" "$session_identifier" "$session_datetime" "$l_logfile" "$l_guid" "$l_schema" > $session_tmp_file
    $sosl_exitcode = $?
    if ($sosl_exitcode -ne 0) {
      # only log the error
      $global:sosl_errmsg = "Error executing script with sosl_execute.sql and run id $l_run_id error code: $sosl_exitcode"
      sosl_error_log
      # delete lock file but not the tmp file
      sosl_del_file "$session_lock_file"
    } else {
      sosl_del_file "$session_lock_file"
      sosl_del_file "$session_tmp_file"
    }
  } catch {
    # inform about error but continue
    sosl_show_log "Error executing sosl_execute_script line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    # delete lock file if it exists but not the tmp file
    sosl_del_file "$session_lock_file"
  }
}
# get next script
function sosl_get_next_script {
  try {
    # Set global variables valid in the function.
    $cur_sosl_login = "$sosl_path_cfg$sosl_login"
    $tmp_file_run = -join($sosl_path_tmp, $sosl_guid, "_run_id.tmp")
    $tmp_file_cfg = -join($sosl_path_tmp, $sosl_guid, "_cfg_file.tmp")
    $private:local_run_id = -1
    $private:local_cfg = "INVALID"
    $identifier = -join($sosl_guid, "_get_run_id")
    $sosl_datetime = log_date
    sosl_sql_tmp "@@..\sosl_sql\server\sosl_get_next_run_id.sql" "$identifier" "$sosl_datetime" "$tmp_file_run" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
    $private:local_run_id = (cat $tmp_file_run)
    # get config file to use for script
    $identifier = -join($sosl_guid, "_get_cfg")
    $sosl_datetime = log_date
    sosl_sql_par "@@..\sosl_sql\server\sosl_get_cfg.sql" "$identifier" "$sosl_datetime" "$local_run_id" "$tmp_file_cfg" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
    $private:local_cfg = (cat $tmp_file_cfg)
    # start and do not wait for the result
    Start-Job -Name $sosl_guid -ScriptBlock { sosl_execute_script "$local_cfg" "$local_run_id" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid" "$sosl_schema" "$sosl_ext_lock" "$sosl_path_tmp" }
    # delete the temp files
    sosl_del_file "$tmp_file_run"
    sosl_del_file "$tmp_file_cfg"
  } catch {
    sosl_show_log "Error executing sosl_get_next_script line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_shutdown
  }
}
# load database configuration, shutdown server on errors
function sosl_loop_config {
  $private:tmp_file = -join($sosl_path_tmp, "conf_get.tmp")
  $cur_sosl_login = -join($sosl_path_cfg, $sosl_login)
  # Fetch SOSL_START_JOBS
  $identifier = -join($sosl_guid, "_load_start_jobs")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_START_JOBS" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  $global:sosl_start_jobs = (cat $tmp_file)
  # Fetch SOSL_STOP_JOBS
  $identifier = -join($sosl_guid, "_load_stop_jobs")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_STOP_JOBS" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  $global:sosl_stop_jobs = (cat $tmp_file)
  # Fetch SOSL_MAX_PARALLEL
  $identifier = -join($sosl_guid, "_load_parallel")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_MAX_PARALLEL" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  $global:sosl_max_parallel = (cat $tmp_file)
  # Fetch SOSL_RUNMODE
  $identifier = -join($sosl_guid, "_load_runmode")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_RUNMODE" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  $global:sosl_runmode = (cat $tmp_file)
  # Fetch SOSL_DEFAULT_WAIT
  $identifier = -join($sosl_guid, "_load_def_wait")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_DEFAULT_WAIT" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  $global:sosl_default_wait = (cat $tmp_file)
  # Fetch SOSL_NOJOB_WAIT
  $identifier = -join($sosl_guid, "_load_nojob_wait")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_NOJOB_WAIT" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  $global:sosl_nojob_wait = (cat $tmp_file)
  # Fetch SOSL_PAUSE_WAIT
  $identifier = -join($sosl_guid, "_load_pause_wait")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_PAUSE_WAIT" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  $global:sosl_pause_wait = (cat $tmp_file)
  # delete the temp file
  sosl_del_file "$tmp_file"
}
# load and set database configuration
function sosl_config_db {
  # Read configuration from database. Edit table SOSL_CONFIG in the database to change the values.
  # Set global variables valid in the script.
  $private:tmp_file = -join($sosl_path_tmp, "dbconf.tmp")
  $cur_sosl_login = -join($sosl_path_cfg, $sosl_login)
  # Inform database that the CMD server is active.
  $identifier = -join($sosl_guid, "_set_active")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_SERVER_STATE" "ACTIVE" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  # Set SOSL_PATH_CFG
  $identifier = -join($sosl_guid, "_set_path_cfg")
  $sosl_datetime=log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_PATH_CFG" "$sosl_path_cfg" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  # Set SOSL_PATH_TMP
  $identifier = -join($sosl_guid, "_set_path_tmp")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_PATH_TMP" "$sosl_path_tmp" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  # Set SOSL_PATH_LOG
  $identifier = -join($sosl_guid, "_set_path_log")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_PATH_LOG" "$sosl_path_log" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  # Set SOSL_EXT_LOG
  $identifier = -join($sosl_guid, "_set_ext_log")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_EXT_LOG" "$sosl_ext_log" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  # Set SOSL_EXT_LOCK
  $identifier = -join($sosl_guid, "_set_ext_lock")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_EXT_LOCK" "$sosl_ext_lock" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  # Set SOSL_START_LOG
  $identifier = -join($sosl_guid, "_set_start_log")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_START_LOG" "$sosl_start_log" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  # Set SOSL_BASE_LOG
  $identifier = -join($sosl_guid, "_set_base_log")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_set_config.sql" "$identifier" "$sosl_datetime" "SOSL_BASE_LOG" "$sosl_base_log" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  # Fetch loop configuration
  sosl_loop_config
  # Fetch SOSL_SCHEMA
  $identifier = -join($sosl_guid, "_load_sosl_schema")
  $sosl_datetime = log_date
  sosl_sql_cfg "@@..\sosl_sql\server\sosl_get_config.sql" "$identifier" "$sosl_datetime" "SOSL_SCHEMA" "$tmp_file" "$sosl_path_log$sosl_start_log.$sosl_ext_log" "$sosl_guid"
  $global:sosl_schema = (cat $tmp_file)
  # delete the temp file
  sosl_del_file "$tmp_file"
}

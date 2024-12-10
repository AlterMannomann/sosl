# (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
# and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
# Not allowed to be used as AI training material without explicite permission.
<#
.SYNOPSIS
	Powershell version of the SOSL server.
.DESCRIPTION
	PowerShell script must be executed in this directory to make relative paths work. On execution will try to switch to this directory.
.EXAMPLE
	PS> .\sosl_server.ps1
#>
try {
  if ($IsLinux) {
    "⚠️ Error wrong OS running under Linux. This Powershell script is intended for Windows OS"
    exit 1
  }
  # Handle UTF8, Windows must be switched to UTF8 support, active codepage in PS should be 65001.
  $PSDefaultParameterValues['*:Encoding'] = 'Default'
  $OutputEncoding = [System.Text.Utf8Encoding]::new($false)
  # Defaults that cannot be changed.
  # Shell scripts run in a windows environment. Path notation is \ for delimiter
  $global:sosl_os = "WINDOWS"
  # Get the full path of the run directory
  $global:sosl_rundir = $PSScriptRoot
  cd $sosl_rundir
  cd ..
  $global:sosl_gitdir=$pwd
  cd $sosl_rundir
  # *****************************************************************************************************
  # Variables that can be manipulated by sosl_config.ps1.
  # Default fallback path to configuration files of SOSL using defined repository structure for startup
  # until parameters are loaded. SHOULD be configured in sosl_config.ps1.
  $global:sosl_path_cfg = "..\sosl_templates\"
  # Default fallback path to temporary files of SOSL using defined repository structure for startup until
  # parameters are loaded.
  $global:sosl_path_tmp = "..\setup\logs\"
  # Default login file for SOSL schema, used when not acting as executor
  $global:sosl_login = "sosl_login.cfg"
  # Default fallback path to logging files of SOSL using defined repository structure for startup until
  # parameters are loaded.
  $global:sosl_path_log = "..\setup\logs\"
  # Default log file extension.
  $global:sosl_ext_log = "log"
  # Default process lock file extension.
  $global:sosl_ext_lock = "lock"
  # Default log filename for start and end of SOSL server CMD.
  $global:sosl_start_log = "sosl_server"
  # Default log filename for single job runs.
  $global:sosl_base_log = "sosl_job_"
  # *****************************************************************************************************
  # Source SOSL functions
  . .\sosl_functions.ps1
  $sosl_exitcode=$?
  if (! $sosl_exitcode) {
    $sosl_errmsg = "Error executing sosl_functions.ps1 line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_error
  }
  . .\sosl_config.ps1
  $sosl_exitcode=$?
  if (! $sosl_exitcode) {
    $sosl_errmsg = "Error executing sosl_config.ps1 line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
    sosl_error
  }
  # Create log and tmp directories if they do not exist, ignore config directory, user responsibility
  if ( -not (Test-Path $sosl_path_log)) {
    (New-Item -Path $sosl_path_log -Type Directory) > $null
  }
  if ( -not (Test-Path $sosl_path_tmp)) {
    (New-Item -Path $sosl_path_tmp -Type Directory) > $null
  }
  # Set lock file name
  $global:lock_file = -join($sosl_path_tmp, "sosl_server.", $sosl_ext_lock)
  # If lock file exists, do not start the server
  if ((Test-Path $lock_file)) {
    sosl_show_log "Error lock file $lock_file already exist. Second instance not allowed"
    exit 1
  }
  # *****************************************************************************************************
  # Define variables fetched from database
  # The maximum of parallel started scripts. After this amount if scripts is started, next scripts are
  # only loaded, if the run count is below this value.
  [int]$global:sosl_max_parallel = 8
  # Defines the run mode of the server. Either RUN, SLEEP or STOP any other value will be interpreted as
  # STOP.
  $global:sosl_runmode = "RUN"
  # Defines the wait time, if scripts are available for execution, by default 1 second. #ember to give
  # always other processes a chance.
  [int]$global:sosl_default_wait = 1
  # Defines the wait time, if scripts are not available for execution and RUNMODE is not SLEEP, by
  # default 2 minutes.
  [int]$global:sosl_nojob_wait = 120
  # Defines the wait time, if scripts are not available for execution and RUNMODE is SLEEP, by default 10
  # minutes.
  [int]$global:sosl_pause_wait = 600
  # Defines the start hour:minutes for the SOSL server in 24h format, if -1 SOSL server is active the whole time.
  $global:sosl_start_jobs = "08:00"
  # Defines the end hour:minutes for the SOSL server in 24h format, ignored if SOSL_START_JOBS is -1.
  # After this hour, the SOSL server will not make any connections to the database until SOSL_START_JOBS
  # hour is reached. Local log will be written with alive pings.
  $global:sosl_stop_jobs = "18:00"
  # The SOSL schema to use for prefixing SOSL packages and functions.
  $global:sosl_schema = "SOSL"
  # *****************************************************************************************************
  # Define internal variables
  # Current login file name for execution. Will be used whenever acting as an executor. Will be overwritten
  # whenever a new script is available by the executor definition for the configuration file. Should start
  # with the same value as SOSL_LOGIN.
  $global:cur_sosl_login = -join($sosl_path_cfg, $sosl_login)
  # Defines the wait time used in the loop.
  $global:cur_wait_time = $sosl_default_wait
  # Defines the current fetched run id. -1 is for not having a valid run id.
  $global:cur_run_id = -1
  # Defines if the current time is okay to run scripts. Depends on SOSL_START_JOBS and SOSL_STOP_JOBS
  # settings, based on the server time of the SOSL CMD server environment. 0 means SOSL CMD server can
  # request new jobs, if available. -1 means that the server waits until SOSL_START_JOBS hour is reached.
  $global:cur_runtime_ok = 0
  # Set with the current amount of waiting scripts.
  $global:cur_has_scripts = 0
  # Variable to hold GUIDs produced for each session. Used to create unique identifiers for SOSLERRORLOG
  # by calling sosl_guid.
  $global:sosl_guid = sosl_guid
  # *****************************************************************************************************
  # Get and update the configuration in the database. Shutdown on errors.
  sosl_config_db
  # *****************************************************************************************************
  # Variables used in the script and loaded by called functions.
  # Variable to hold timestamp for logging, can be fetched by calling sosl_timestamp.cmd.
  $global:sosl_datetime = "undefined"
  # Variable to store current error information.
  $global:sosl_errmsg = "undefined"
  # Variable for storing exit codes from functions.
  $global:sosl_exitcode = -1
  # Variable to store the current count of running processes.
  $global:sosl_runcount = 0
  # Create lock file. Contains the run mode at start. Can be overwritten locally to stop
  # the CMD server with stop_sosl_locally.cmd. Pause mode can only be set by database table SOSL_CONFIG.
  echo $sosl_runmode > $lock_file
  # Create log entries
  sosl_log "SOSL configuration loaded, running on $sosl_os"
  sosl_log "LOCK file created: $lock_file"
  sosl_log "Current GUID for session start: $sosl_guid, repository directory $sosl_gitdir"
  # *****************************************************************************************************
  # Start the loop, do not break the loop on minor errors
  while ($true) {
    if ($sosl_runmode -eq "STOP") {
      sosl_shutdown
    }
    sosl_check_vars
    # Start loop always with SOSL login
    $global:cur_sosl_login = "$sosl_path_cfg$sosl_login"
    # Check if the we have reached max run count, call directly wait if reached
    # Takes the last value set for max parallel and wait time, will not fetch new values from database
    # unless the run count falls under max parallel
    sosl_get_run_count
    if ($sosl_runcount -ge $sosl_max_parallel) {
      # wait until runcount less, do not log the waits
      sosl_wait 0
    } else {
      # check the situation
      # fetch a guid for the start process
      $global:sosl_guid = sosl_guid
      # Get and update the configuration from the database. Shutdown server on errors if no scripts are running.
      sosl_loop_config
      # Get local settings and check running scripts. Shutdown server if no scripts are running and LOCK file is set to STOP.
      sosl_read_local
      # Check defined run hours and set cur_runtime_ok. Shutdown server on errors if no scripts are running.
      sosl_run_hours
      if ($cur_runtime_ok -eq 0) {
        # Get a guid for has scripts
        $global:sosl_guid = sosl_guid
        # Check if scripts available and adjust wait time on has_scripts result
        sosl_has_scripts
        if ($cur_has_scripts -eq 0) {
          sosl_wait 1
        } else {
          # fetch next script
          # Get a guid for get next script
          $global:sosl_guid = sosl_guid
          # run the next script
          sosl_get_next_script
          # and wait as defined by cur_wait_time
          sosl_wait 1
        }
      } else {
        # ignore run hour changes if scripts are running
        if ($sosl_runcount -eq 0) {
          sosl_wait 1
        }
      }
    }
  }
	sosl_shutdown
} catch {
	"Error in line $($_.InvocationInfo.ScriptLineNumber): $($Error[0])"
	exit 1
}
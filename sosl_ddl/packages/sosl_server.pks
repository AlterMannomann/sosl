-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- server interface package of the Simple Oracle Script Loader
CREATE OR REPLACE PACKAGE sosl_server
AS
  /**
  * This package contains the server interface used by the Simple Oracle Script Loader.
  * All server scripts depend on this package. The default error return value is -1, either
  * as number or as string. The SOSL server can only deal with this two types of return
  * values: NUMBER or VARCHAR2. And it can only deal with functions usable in a SELECT statement.
  * All interpreted values are read in as COLUMN variables, it makes no difference, if -1 or '-1'
  * is delivered as error code.
  */

  /*====================================== start internal functions made visible for testing ======================================*/
  -- SOSL server will not call this functions directly, so return type can be different from NUMBER or VARCHAR2

  /* FUNCTION SOSL_SERVER.HAS_CONFIG_NAME
  * Checks if a given case sensitive configuration name exists. Errors get logged.
  *
  * @param p_config_name The config name of the configuration item.
  *
  * @return Either TRUE if the configuration name exists or FALSE, including FALSE on error.
  */
  FUNCTION has_config_name(p_config_name IN VARCHAR2)
    RETURN BOOLEAN
  ;
  /*====================================== end internal functions made visible for testing ======================================*/

  /** Function SOSL_SERVER.SET_CONFIG
  * Sets an existing configuration value for a given and existing case sensitive configuration name. Invalid
  * config names get logged. Invalid config values for SOSL_RUNMODE and SOSL_SERVER_STATE are ignored and will
  * not change the config value. Errors get logged.
  * SOSL_RUNMODE values: RUN, WAIT, STOP
  * SOSL_SERVER_STATE values: ACTIVE, INACTIVE, PAUSE
  *
  * @param p_config_name The valid config name of the configuration item.
  * @param p_config_value The value to assign to the configuration item.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_config( p_config_name  IN VARCHAR2
                     , p_config_value IN VARCHAR2
                     )
    RETURN NUMBER
  ;

  /** Function SOSL_SERVER.GET_CONFIG
  * Gets an existing configuration value for a given and existing case sensitive configuration name. Errors get logged.
  *
  * @param p_config_name The config name of the configuration item.
  *
  * @return The configured value as VARCHAR2 or '-1' string on error.
  */
  FUNCTION get_config(p_config_name IN VARCHAR2)
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_SERVER.SET_SERVER_STATE
  * A shortcut function using sosl_server.set_config for SOSL_SERVER_STATE. Errors get logged.
  *
  * @param p_server_state A valid server state: ACTIVE, INACTIVE, PAUSE.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_server_state(p_server_state IN VARCHAR2)
    RETURN NUMBER
  ;


  /* FUNCTION SOSL_SERVER.SET_RUNMODE
  * A shortcut function using sosl_server.set_config for SOSL_RUNMODE. Errors get logged.
  *
  * @param p_server_state A valid run mode: RUN, WAIT, STOP.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_runmode(p_runmode IN VARCHAR2)
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SERVER.GET_EXECUTOR_CFG
  * Retrieves the config login file to use for a specific executor by a given run id. Errors get logged.
  *
  * @param p_run_id A valid run id for table SOSL_RUN_QUEUE.
  *
  * @return The configuration login filename including relative or absolute path or '-1' on errors.
  */
  FUNCTION get_executor_cfg(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_SERVER.SET_GUID
  * Sets the GUID of the SOSL server, used during script execution, in SOSL_RUN_QUEUE. The GUID will be
  * a generic identifier for this script execution. All identifiers in SOSLERRLOG will start with this GUID
  * for a specific script execution.
  *
  * @param p_run_id A valid run id for table SOSL_RUN_QUEUE.
  * @param p_guid The GUID used by the SOSL server for this script execution.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_guid( p_run_id IN NUMBER
                   , p_guid   IN VARCHAR2
                   )
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SERVER.SET_IDENTIFIER
  * Sets the exact SOSL IDENTIFIER of the SOSL server, used during main script execution, in SOSL_RUN_QUEUE. The identifier
  * will exactly match SOSLERRLOG.IDENTIFIER in case of errors for a specific script execution. It will start with the GUID
  * for the whole script execution process.
  *
  * @param p_run_id A valid run id for table SOSL_RUN_QUEUE.
  * @param p_identifier The exact identifier used by the SOSL server for the main part of the script execution.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_identifier( p_run_id     IN NUMBER
                         , p_identifier IN VARCHAR2
                         )
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SERVER.SET_SCRIPT_STARTED
  * Short cut function for sosl_sys.set_run_state to guarantee correct run states. On errors the script state will
  * be set to error. Before calling this function at least GUID should be set for the current script.
  *
  * @param p_run_id A valid run id for table SOSL_RUN_QUEUE.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_script_started(p_run_id IN NUMBER)
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SERVER.SET_SCRIPT_RUNNING
  * Short cut function for sosl_sys.set_run_state to guarantee correct run states. On errors the script state will
  * be set to error. Before calling this function the exact SOSL identifier should be set for the current script.
  *
  * @param p_run_id A valid run id for table SOSL_RUN_QUEUE.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_script_running(p_run_id IN NUMBER)
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SERVER.SET_SCRIPT_FINISHED
  * Short cut function for sosl_sys.set_run_state to guarantee correct run states. On errors the script state will
  * be set to error.
  *
  * @param p_run_id A valid run id for table SOSL_RUN_QUEUE.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_script_finished(p_run_id IN NUMBER)
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SERVER.SET_SCRIPT_RUNNING
  * Short cut function for sosl_sys.set_run_state to guarantee correct run states. On errors the script state will
  * be set to error. Before calling this function the GUID and exact SOSL identifier should be set for the current script.
  *
  * @param p_run_id A valid run id for table SOSL_RUN_QUEUE.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_script_error(p_run_id IN NUMBER)
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SERVER.INFO_LOG
  * Provides a possibility to output content for a local log as well as logging it to SOSL_SERVER_LOG. Can be
  * be called within every SELECT statement. On success log category will always be SOSL_SERVER, log type INFO.
  *
  * @param p_srv_caller The script calling this function.
  * @param p_srv_message The message to use for the local log as well as to the SOSL_SERVER_LOG.
  * @param p_identifier In almost all cases scripts called from the server have an identifier, that they use for SOSLERRORLOG. NULL by default.
  * @param p_local_log In almost all cases scripts called from the server have a log file, that they use. NULL by default.
  * @param p_srv_run_id Scripts issued by executors will have a run id which is retrieved from the SOSL server. If a run id is given, the log is also enhanced with executor details for this script. NULL by default.
  * @param p_srv_guid In very rare cases scripts called from the server have also the GUID, that they use. NULL by default.
  *
  * @return Will return p_message or error information.
  */
  FUNCTION info_log( p_srv_caller   IN VARCHAR2
                   , p_srv_message  IN VARCHAR2
                   , p_identifier   IN VARCHAR2 DEFAULT NULL
                   , p_local_log    IN VARCHAR2 DEFAULT NULL
                   , p_srv_run_id   IN NUMBER   DEFAULT NULL
                   , p_srv_guid     IN VARCHAR2 DEFAULT NULL
                   )
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_SERVER.WARNING_LOG
  * Provides a possibility to output content for a local log as well as logging it to SOSL_SERVER_LOG. Can be
  * be called within every SELECT statement. On success log category will always be SOSL_SERVER, log type WARNING.
  *
  * @param p_caller The script calling this function.
  * @param p_message The message to use for the local log as well as to the SOSL_SERVER_LOG.
  *
  * @return Will return p_message or error information.
  */
  FUNCTION warning_log( p_caller       IN VARCHAR2
                      , p_message      IN VARCHAR2
                      )
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_SERVER.ERROR_LOG
  * Provides a possibility to output content for a local log as well as logging it to SOSL_SERVER_LOG. Can be
  * be called within every SELECT statement. On success log category will always be SOSL_SERVER, log type ERROR.
  *
  * @param p_caller The script calling this function.
  * @param p_message The message to use for the local log as well as to the SOSL_SERVER_LOG.
  *
  * @return Will return p_message or error information.
  */
  FUNCTION error_log( p_caller       IN VARCHAR2
                    , p_message      IN VARCHAR2
                    )
    RETURN VARCHAR2
  ;

END;
/
-- grants
GRANT EXECUTE ON sosl_server TO sosl_executor;
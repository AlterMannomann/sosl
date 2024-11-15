-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Basic package providing the API to the Simple Oracle Script Loader.
CREATE OR REPLACE PACKAGE sosl_api
AS
  /**
  * This package contains SOSL API functions and procedures to be used by users with the role SOSL_USER or higher.
  * Some functions are limited to roles, higher than SOSL_USER. Config login information are not visible to SOSL_USER
  * role. Mainly used to manage executors and retrieve basic information.
  * This package is made for users to interactively manage executors and get or set parameter. The return value is
  * therefore usually a string that can be interpreted by a human being, not by programs or a number for IDs. The functions
  * can be used with select statements as well as in PLSQL blocks or code. Inserts and updates will run as autonomous
  * transactions.
  */

  /** Function SOSL_API.GET_CONFIG
  * Gets an existing configuration value for a given and existing case sensitive configuration name.
  * In case of errors details can be found in SOSL_SERVER_LOG_V. See SOSL_CONFIG_V for available configuration
  * values.
  *
  * @return The configured value as VARCHAR2 or an error text message.
  */
  FUNCTION get_config(p_config_name IN VARCHAR2)
    RETURN VARCHAR2
  ;

  /** Function SOSL_API.SET_RUNMODE
  * REQUIRES role SOSL_EXECUTOR or higher.
  * Sets the runmode for the SOSL server. Allowed values are RUN (default if no parameter given), PAUSE or STOP.
  * Depending on the current wait time and defined timeframe at server start, the server will read this state the
  * next time it is connecting to the database. If the server is inactive, the runmode will be used on server start.
  * In case of errors details can be found in SOSL_SERVER_LOG_V.
  *
  * This will not stop the server immediately as it depends on the server reading the entry. If in wait mode, depending
  * on the wait time, the server will stop after waiting. If the server is running outside of the given time frame that
  * was set on server start, the server will stop after entering the time frame known to the server at server start.
  * If you want to stop the server immediately you may do this on the local server.
  *
  * You may stop the server by database, but YOU CAN'T START THE SERVER BY DATABASE. This has to be done locally on
  * the SOSL server machine.
  *
  * @param p_runmode The desired run mode. Possible values are RUN, STOP, PAUSE. Default is RUN.
  *
  * @return A success or error text message.
  */
  FUNCTION set_runmode(p_runmode IN VARCHAR2 DEFAULT 'RUN')
    RETURN VARCHAR2
  ;

  /** Function SOSL_API.SET_TIMEFRAME
  * REQUIRES role SOSL_EXECUTOR or higher.
  * Set the timeframe where the server is allowed to connect to the database. If the server detects that it is
  * running out of the given timeframe it will not connect to the database and using the wait time defined for
  * SOSL_PAUSE_WAIT. Take care on setting this times that pause wait time is not too long and leads to overlaps
  * with the timeframe set. The larger SOSL_PAUSE_WAIT is, the bigger can be an overlap where the server is still
  * waiting, even if the timeframe for running has already started.
  *
  * If the pause wait time is one hour, than it is recommended that timeframe set is also fitting with the pause
  * wait time, e.g. 08:00 - 18:00, 07:30 - 19:30. To avoid overlaps you should set the from time to a value a few
  * minutes below the hourly waits, e.g. desired server at 08:00 is up, set 07:55 - 18:00, to ensure that the server
  * is up and running at 08:00.
  *
  * The server can handle daybreaks, so you might also set the timeframe to 21:55 - 06:00.
  *
  * If from or to is set to '-1', the timeframe will be disabled and ignored.
  *
  * ATTENTION! The time is related to the local server time of the SOSL server, not to the time of the database
  * server in case they differ.
  *
  * @param p_from The start time for the SOSL server in 24h format with leading zeros and : as delimiter or string '-1'.
  * @param p_to The end time for the SOSL server in 24h format with leading zeros and : as delimiter or string '-1'.
  *
  * @return A success or error text message.
  */
  FUNCTION set_timeframe( p_from IN VARCHAR2 DEFAULT '07:55'
                        , p_to   IN VARCHAR2 DEFAULT '18:00'
                        )
    RETURN VARCHAR2
  ;

  /** Function SOSL_API.CREATE_EXECUTOR
  * REQUIRES role SOSL_EXECUTOR or higher.
  * Creates a new executor definition if it did not exist already. DB_USER is set automatically using the SESSION_USER from
  * SYS_CONTEXT. The executor is neither activated nor marked as reviewed. To use the executor you must activate it and the
  * reviewed state must have been set.
  * The given interface functions must conform to the following declarations, must exist and be granted to SOSL_EXECUTOR role:
  *
  * fn_has_scripts: FUNCTION your_has_script RETURN NUMBER;
  * @return A positive integer including 0 for amount of scripts waiting or -1 on errors.
  * @task: Return the amount of waiting scripts.
  *
  * fn_get_next_script: FUNCTION your_get_next_script RETURN SOSL.SOSL_PAYLOAD;
  * @return A valid and filled SOSL_PAYLOAD object containing EXECUTOR_ID, EXT_SCRIPT_ID and SCRIPT_FILE or NULL on errors.
  * @task: Return the details of the next waiting script.
  *
  * fn_set_script_status: FUNCTION your_set_script_status(p_run_id IN NUMBER, p_status IN NUMBER) RETURN NUMBER;
  * @return Execution indicator: 0 on success or -1 on errors.
  * @task: Set the internal status of your scripts queued for execution.
  *
  * fn_send_db_mail: FUNCTION your_send_mail(p_run_id IN NUMBER, p_status IN NUMBER) RETURN NUMBER;
  * @return Execution indicator: 0 on success or -1 on errors.
  * @task: Prepare and send a mail based on script status.
  *
  * For examples see package SOSL_IF.
  *
  * @param p_executor_name The unique executor definition name.
  * @param p_function_owner The existing and for SOSL visible database user that owns the interface functions.
  * @param p_fn_has_scripts The fully qualified interface function for has_scripts. Must exist and be granted to SOSL_EXECUTOR.
  * @param p_fn_get_next_script The fully qualified interface function for get_next_script. Must exist and be granted to SOSL_EXECUTOR.
  * @param p_fn_set_script_status The fully qualified interface function for set_script_status. Must exist and be granted to SOSL_EXECUTOR.
  * @param p_cfg_file The filename including relative or absolute path that contains the login for the executor.
  * @param p_use_mail Defines if mail should be used (1) or not (0). Default is no mail usage.
  * @param p_fn_send_db_mail The fully qualified interface function for send mail. If mail should be used the parameter is mandatory, must exist and be granted to SOSL_EXECUTOR.
  * @param p_executor_description An optional description for the new executor.
  *
  * @return The new executor id for the created executor or -1 on errors. Check SOSL_SERVER_LOG for details on errors.
  */
  FUNCTION create_executor( p_executor_name         IN VARCHAR2
                          , p_function_owner        IN VARCHAR2
                          , p_fn_has_scripts        IN VARCHAR2
                          , p_fn_get_next_script    IN VARCHAR2
                          , p_fn_set_script_status  IN VARCHAR2
                          , p_cfg_file              IN VARCHAR2
                          , p_use_mail              IN NUMBER     DEFAULT 0
                          , p_fn_send_db_mail       IN VARCHAR2   DEFAULT NULL
                          , p_executor_description  IN VARCHAR2   DEFAULT NULL
                          )
    RETURN NUMBER
  ;

  /** Function SOSL_API.ACTIVATE_EXECUTOR
  * REQUIRES role SOSL_EXECUTOR or higher.
  * Sets the executor, identified by the given id, to active.
  *
  * @param p_executor_id The executor id to activate.
  *
  * @return A success or error text message.
  */
  FUNCTION activate_executor(p_executor_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL_API.DEACTIVATE_EXECUTOR
  * REQUIRES role SOSL_EXECUTOR or higher.
  * Sets the executor, identified by the given id, to deactivated.
  *
  * @param p_executor_id The executor id to activate.
  *
  * @return A success or error text message.
  */
  FUNCTION deactivate_executor(p_executor_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL_API.SET_EXECUTOR_REVIEWED
  * REQUIRES role SOSL_REVIEWER or higher.
  * Sets the executor, identified by the given id, to reviewed.
  *
  * @param p_executor_id The executor id to set to reviewed.
  *
  * @return A success or error text message.
  */
  FUNCTION set_executor_reviewed(p_executor_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL_API.REVOKE_EXECUTOR_REVIEWED
  * REQUIRES role SOSL_REVIEWER or higher.
  * Sets the executor, identified by the given id, to not reviewed.
  *
  * @param p_executor_id The executor id to set to not reviewed.
  *
  * @return A success or error text message.
  */
  FUNCTION revoke_executor_reviewed(p_executor_id IN NUMBER)
    RETURN VARCHAR2
  ;

END;
/
GRANT EXECUTE ON sosl_api TO sosl_user;
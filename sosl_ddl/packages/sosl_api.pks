-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- Basic package providing the API to the Simple Oracle Script Loader.
CREATE OR REPLACE PACKAGE sosl_api
AS
  /**
  * This package contains SOSL API functions and procedures to be used by users with the role SOSL_USER or higher.
  * Some functions are limited to roles, higher than SOSL_USER. Config login information are not visible to SOSL_USER
  * role. Mainly used to manage executors and retrieve basic information.
  * This package is made for users to interactively manage executors and get or set parameter. The return value is
  * therefore usually a string that can be interpreted by a human being, not by programs or a number, mainly for IDs.
  * The functions can be used with select statements as well as in PLSQL blocks or code. Inserts and updates will run
  * as autonomous transactions.
  */

  --========================================= Functions for role SOSL_USER =========================================--

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

  /* FUNCTION SOSL_API.HAS_SCRIPTS
  * Wrapper function for SOSL_SYS.HAS_SCRIPTS. Provided for reports to be run with SOSL_USER role.
  * Collects and sums the output of all defined executor has_scripts functions of active and reviewed executors that
  * return a number greater or equal to 0 as well as messages waiting in SOSL_RUN_QUEUE to be processed. Errors will get logged.
  * DOES NOT consider RUN mode like SOSL_SERVER which will return 0, if run mode is STOP or PAUSE. Will return all
  * waiting scripts.
  *
  * @return The total amount of scripts waiting for processing or -1 on unhandled exceptions/all functions have errors.
  */
  FUNCTION has_scripts
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_API.HAS_RUN_SCRIPTS
  * Wrapper function for SOSL_SERVER.HAS_SCRIPTS. Provided for reports to be run with SOSL_USER role.
  * Collects and sums the output of all defined executor has_scripts functions of active and reviewed executors that
  * return a number greater or equal to 0 as well as messages waiting in SOSL_RUN_QUEUE to be processed. Errors will get logged.
  * DOES consider RUN mode and returns 0, if run mode is STOP or PAUSE.
  *
  * @return The total amount of scripts waiting for processing or -1 on unhandled exceptions/all functions have errors.
  */
  FUNCTION has_run_scripts
    RETURN NUMBER
  ;

  /** Function SOSL_API.CREATE_EXECUTOR
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

  /** Function SOSL_API.DB_IN_TIME
  * Wrapper for SOSL_UTIL.DB_IN_TIME.
  * Checks if the database is within the defined start and stop time of the SOSL server. If the database time is
  * not in sync with the local server time of the SOSL server, the result may be wrong. Sync the time of the database
  * and the local server to get reliable results.
  *
  * @return TRUE if the current database time is within the server timeframe otherwise FALSE.
  */
  FUNCTION db_in_time
    RETURN BOOLEAN
  ;

  --======================================= Functions for role SOSL_REVIEWER =======================================--

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

  --======================================= Functions for SOSL_EXECUTOR/SOSL_ADMIN =======================================--

  /** Function SOSL_API.SET_RUNMODE
  * REQUIRES role SOSL_ADMIN.
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
  *
  * @see sosl_constants.SERVER_RUN_MODE, sosl_constants.SERVER_PAUSE_MODE, sosl_constants.SERVER_STOP_MODE
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

  --======================================= Interface for executor functions =======================================--
  -- The following functions are only for interface implementations related to SOSL. All start with IF_.
  -- Any unauthorized usage from users not having the SOSL_EXECUTOR role will be logged and will have no effect.
  -- Wrapper functions for internal SOSL functionality.

  /* FUNCTION SOSL_API.IF_EXCEPTION_LOG
  * Wrapper for SOSL_LOG.EXCEPTION_LOG. For details see sosl_api.pks.
  * If logging fails the database is most likely in an unknown state. Exceptions at this point must break the application
  * to stop running until database is working correctly again. NEVER try to catch and surpress this exceptions, let the
  * application fail in this case (probably after cleanup if you use an own wrapper).
  *
  * @param p_caller The full name of function, procedure or package that has caused the unhandled exception. Case sensitive.
  * @param p_category The log category for the function, procedure or package. Case sensitive.
  * @param p_sqlerrmsg The full error message, usually SQLERRM. Limited to VARCHAR2 limit 32767 chars.
  */
  PROCEDURE if_exception_log( p_caller     IN VARCHAR2
                            , p_category   IN VARCHAR2
                            , p_sqlerrmsg  IN VARCHAR2
                            )
  ;

  /* PROCEDURE SOSL_API.IF_GENERIC_LOG
  * Wrapper for SOSL_LOG.MINIMAL_LOG. See sosl_log.pks. Any invalid log type will cause the log type set
  * to SOSL_CONSTANTS.LOG_WARNING_TYPE.
  *
  * @param p_caller The full name of function, procedure or package that should be logged. Case sensitive.
  * @param p_category The log category for the function, procedure or package. Case sensitive.
  * @param p_log_type The log type for the logging as defined in SOSL_CONSTANTS.LOG_... constants.
  * @param p_short_msg The short success message, preferably smaller than 4000 chars. Will be formatted using p_caller.
  * @param p_full_msg The complete success message, with details. Will not be formatted but may contain parts of p_short_msg, if message is longer than 4000 chars.
  */
  PROCEDURE if_generic_log( p_caller     IN VARCHAR2
                          , p_category   IN VARCHAR2
                          , p_log_type   IN VARCHAR2
                          , p_short_msg  IN VARCHAR2
                          , p_full_msg   IN CLOB     DEFAULT NULL
                          )
  ;
  PROCEDURE if_generic_log( p_caller     IN VARCHAR2
                          , p_category   IN VARCHAR2
                          , p_log_type   IN VARCHAR2
                          , p_short_msg  IN VARCHAR2
                          , p_full_msg   IN VARCHAR2
                          )
  ;

  /* FUNCTION SOSL_API.IF_DISPLAY_LOG
  * Allows to output of the log message (limited to 4000 char) to write in SQL statements.
  * Can be used in executor scripts for error and success messages that get logged and are
  * displayed in the spool file of the executor script.
  *
  * @param p_caller The full name of function, procedure or package that should be logged. Case sensitive.
  * @param p_category The log category for the function, procedure or package. Case sensitive.
  * @param p_log_type The log type for the logging as defined in SOSL_CONSTANTS.LOG_... constants.
  * @param p_short_msg The short success message, will be limited to 4000 chars on return. Will be formatted using p_caller.
  *
  * @return The first 4000 char of p_short_msg.
  */
  FUNCTION if_display_log( p_caller     IN VARCHAR2
                         , p_category   IN VARCHAR2
                         , p_log_type   IN VARCHAR2
                         , p_short_msg  IN VARCHAR2
                         )
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_API.IF_GET_PAYLOAD
  * Wrapper for SOSL_SERVER.GET_PAYLOAD. Builds a SOSL_PAYLOAD object from the given run id.
  *
  * @param p_run_id The run id to get the SOSL_PAYLOAD object for.
  *
  * @return On success a valid SOSL_PAYLOAD object or NULL on errors.
  */
  FUNCTION if_get_payload(p_run_id IN NUMBER)
    RETURN SOSL_PAYLOAD
  ;

  /* FUNCTION SOSL_API.IF_HAS_RUN_ID
  * Wrapper for SOSL_SERVER.HAS_RUN_ID. Checks if a given run id exists. Errors get logged.
  *
  * @param p_run_id The run id to verify.
  *
  * @return TRUE if run id exists otherwise FALSE.
  */
  FUNCTION if_has_run_id(p_run_id IN NUMBER)
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_API.IF_DUMMY_MAIL
  * Wrapper for SOSL_SERVER.DUMMY_MAIL. This is a testing function that will NOT send any mail.
  * It will log the mail message created in SOSL_SERVER_LOG using
  * the field full_message, so output can be controlled.
  *
  * @param p_sender The valid mail sender address, e.g. mail.user@some.org.
  * @param p_recipients The semicolon separated list of mail recipient addresses.
  * @param p_subject A preferablly short subject for the mail.
  * @param p_message The correctly formatted mail message.
  *
  * @return Will return TRUE on success or FALSE on errors.
  */
  FUNCTION if_dummy_mail( p_sender      IN VARCHAR2
                        , p_recipients  IN VARCHAR2
                        , p_subject     IN VARCHAR2
                        , p_message     IN VARCHAR2
                        )
    RETURN BOOLEAN
  ;

END;
/
GRANT EXECUTE ON sosl_api TO sosl_user;
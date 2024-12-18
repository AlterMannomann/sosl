-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- main package of the Simple Oracle Script Loader
CREATE OR REPLACE PACKAGE sosl_sys
AS

  /* FUNCTION SOSL_SYS.GET_VALID_EXECUTOR_CNT
  * Determines the count of all valid executors. A valid executor is defined as an executor that is
  * marked as active and reviewed.
  *
  * @return The total count of all valid executors or -1 on errors.
  */
  FUNCTION get_valid_executor_cnt
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SYS.GET_WAITING_CNT
  * Determines the count of all scripts in the run queue with status WAITING.
  *
  * @return The count of all waiting scripts in the run queue or -1 on errors.
  */
  FUNCTION get_waiting_cnt
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SYS.GET_WAITING_CNT
  * Determines the count of all scripts of an executor in the run queue with status WAITING.
  *
  * @param p_executor_id The executor id to get all scripts in the run queue with status WAITING.
  *
  * @return The count of all waiting scripts in the run queue or -1 on errors.
  */
  FUNCTION get_waiting_cnt(p_executor_id IN NUMBER)
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SYS.DEACTIVATE_BY_FN_HAS_SCRIPTS
  * Deactivates all executors using the given function owner and function for has_scripts.
  * Runs as an autonomous transaction. Used to deactivate executors having functions configured
  * that throw exceptions or errors on calling them. Errors will be logged. SOSL schema and role
  * admins are ignored.
  *
  * @param p_function_owner The owner of the has_scripts function definition.
  * @param p_fn_has_scripts The defined script call for has_scripts.
  * @param p_log_reason A detailed reason why executor has be deactivated.
  *
  * @return TRUE if successful executed, FALSE on internal exceptions not handled.
  */
  FUNCTION deactivate_by_fn_has_scripts( p_function_owner IN VARCHAR2
                                       , p_fn_has_scripts IN VARCHAR2
                                       , p_log_reason     IN VARCHAR2
                                       )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_SYS.DEACTIVATE_BY_FN_GET_NEXT_SCRIPT
  * Deactivates all executors using the given function owner and function for get_next_script.
  * Runs as an autonomous transaction. Used to deactivate executors having functions configured
  * that throw exceptions or errors on calling them. Errors will be logged. SOSL schema and role
  * admins are ignored.
  *
  * @param p_function_owner The owner of the get_next_script function definition.
  * @param p_fn_get_next_script The defined script call for get_next_script.
  * @param p_log_reason A detailed reason why executor has be deactivated.
  *
  * @return TRUE if successful executed, FALSE on internal exceptions not handled.
  */
  FUNCTION deactivate_by_fn_get_next_script( p_function_owner     IN VARCHAR2
                                           , p_fn_get_next_script IN VARCHAR2
                                           , p_log_reason         IN VARCHAR2
                                           )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_SYS.DEACTIVATE_BY_FN_SET_SCRIPT_STATUS
  * Deactivates all executors using the given function owner and function for set_script_status.
  * Runs as an autonomous transaction. Used to deactivate executors having functions configured
  * that throw exceptions or errors on calling them. Errors will be logged. SOSL schema and role
  * admins are ignored.
  *
  * @param p_function_owner The owner of the set_script_status function definition.
  * @param p_fn_set_script_status The defined script call for set_script_status.
  * @param p_log_reason A detailed reason why executor has be deactivated.
  *
  * @return TRUE if successful executed, FALSE on internal exceptions not handled.
  */
  FUNCTION deactivate_by_fn_set_script_status( p_function_owner       IN VARCHAR2
                                             , p_fn_set_script_status IN VARCHAR2
                                             , p_log_reason           IN VARCHAR2
                                             )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_SYS.DEACTIVATE_BY_FN_SEND_DB_MAIL
  * Deactivates all executors using the given function owner and function for send_db_mail.
  * Runs as an autonomous transaction. Used to deactivate executors having functions configured
  * that throw exceptions or errors on calling them. Errors will be logged. SOSL schema and role
  * admins are ignored.
  *
  * @param p_function_owner The owner of the send_db_mail function definition.
  * @param p_fn_send_db_mail The defined script call for send_db_mail.
  * @param p_log_reason A detailed reason why executor has be deactivated.
  *
  * @return TRUE if successful executed, FALSE on internal exceptions not handled.
  */
  FUNCTION deactivate_by_fn_send_db_mail( p_function_owner  IN VARCHAR2
                                        , p_fn_send_db_mail IN VARCHAR2
                                        , p_log_reason      IN VARCHAR2
                                        )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_SYS.BUILD_SCRIPT_CALL
  * Builds a SELECT FROM dual statement with the given function name and,
  * if NOT NULL, function owner that can be executed dynamically. The return values and
  * types are not checked and must be handled by the caller. By SOSL default the function
  * owner is set and NOT NULL. Anyway this functions handles also NULL on function owner.
  *
  * WORKS ONLY FOR FUNCTION WITHOUT PARAMETER, e.g. has_scripts and get_next_script.
  *
  * BE AWARE that oracle cannot distinguish between package functions where the package is named
  * like the schema, if names are equal, e.g. if a package exists, called SOSL, like the schema SOSL,
  * Oracle would search with SOSL.myfunction not a function in the SOSL schema, it would search
  * myfunction in the package SOSL if executed dynamically.
  *
  * @param p_function_owner If set, the function owner of the function. Will prefix the call.
  * @param p_function_name The name of the function or package function.
  *
  * @return A statement to retrieve the function call e.g. SELECT owner.function FROM dual.
  */
  FUNCTION build_script_call( p_function_owner  IN VARCHAR2
                            , p_function_name   IN VARCHAR2
                            )
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_SYS.BUILD_SIGNAL_CALL
  * Builds a SELECT FROM dual statement with the given function name and, if NOT NULL, function owner that can be
  * executed dynamically and the given parameter. The return values and
  * types are not checked and must be handled by the caller. By SOSL default the function
  * owner is set and NOT NULL. Anyway this functions handles also NULL on function owner.
  *
  * WORKS ONLY FOR FUNCTION WITH DEFINED PARAMETER, e.g. set_script_status and send_db_mail.
  *
  * BE AWARE that oracle cannot distinguish between package functions where the package is named
  * like the schema, if names are equal, e.g. if a package exists, called SOSL, like the schema SOSL,
  * Oracle would search with SOSL.myfunction not a function in the SOSL schema, it would search
  * myfunction in the package SOSL if executed dynamically.
  *
  * @param p_function_owner If set, the function owner of the function. Will prefix the call.
  * @param p_function_name The name of the function or package function.
  * @param p_run_id The first function parameter representing the run id.
  * @param p_status The second function parameter representing the status that should be set.
  *
  * @return A statement to retrieve the function call e.g. SELECT owner.function(1, 0) FROM dual.
  */
  FUNCTION build_signal_call( p_function_owner  IN VARCHAR2
                            , p_function_name   IN VARCHAR2
                            , p_run_id          IN NUMBER
                            , p_status          IN NUMBER
                            )
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_SYS.GET_HAS_SCRIPT_CNT
  * Determines the count result of the defined has_script functions for the given function
  * owner and function name.
  * Failures on specific executors are only considered, if none of the defined functions
  * could be executed without errors. Defined scripts will be executed dynamically. Make
  * sure that has_scripts executes fast, especially if more than one executor is active.
  *
  * ATTENTION Will deactivate all executors with scripts throwing execptions!
  *
  * @param p_function_name The function to execute for getting the payload. Package functions allowed.
  * @param p_function_owner The function owner of the function to execute.
  *
  * @return The count result of the has_scripts function or -1 on severe errors.
  */
  FUNCTION get_has_script_cnt( p_function_name  IN VARCHAR2
                             , p_function_owner IN VARCHAR2
                             )
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SYS.GET_HAS_SCRIPT_CNT
  * Determines the count result of all defined has_script functions of valid executors.
  * Failures on specific executors are only considered, if none of the defined functions
  * could be executed without errors. Defined scripts will be executed dynamically. Make
  * sure that has_scripts executes fast, especially if more than one executor is active.
  *
  * Will only execute unique functions. If different executors share the same function owner
  * and function definition, then the function is only executed once and not per executor.
  * Call syntax is functionOwner.functionName where functionName can also be a package call.
  *
  * ATTENTION Will deactivate all executors with scripts throwing execptions!
  *
  * @return The total count of all defined has_scripts function or -1 on severe errors.
  */
  FUNCTION get_has_script_cnt
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SYS.IS_EXECUTOR_VALID
  * Checks if the given executor id is valid in sense of active and reviewed. Errors will be logged.
  *
  * @param p_executor_id The id of the executor to check if the executor is active and reviewed.
  *
  * @return If executor exists, is reviewed and active, returns TRUE otherwise FALSE, also in case of errors.
  */
  FUNCTION is_executor_valid(p_executor_id IN NUMBER)
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_SYS.IS_EXECUTOR
  * Checks if the given executor id exists in SOSL_EXECUTOR_DEFINITION. Errors will be logged.
  *
  * @param p_executor_id The id of the executor to check.
  *
  * @return If executor exists returns TRUE otherwise FALSE, also in case of errors.
  */
  FUNCTION is_executor(p_executor_id IN NUMBER)
    RETURN BOOLEAN
  ;

  /**
  * This package contains the main functions and procedures used by the Simple Oracle Script Loader to handle executors and scripts.
  * It is not allowed to use this package for function assignments in SOSL_EXECUTOR_DEFINITION.
  */

  /*FUNCTION SOSL_SYS.HAS_VALID_EXECUTORS
  * Checks if any valid executor (active and reviewed) exists. Errors get logged, return on error is FALSE.
  *
  * @return Return TRUE if at least one active and reviewed executor exists, otherwise FALSE.
  */
  FUNCTION has_valid_executors
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_SYS.HAS_SCRIPTS
  * This function will be used by the wrapper function SOSL_SERVER.HAS_SCRIPTS.
  * Collects and sums the output of all defined executor has_scripts functions of active and reviewed executors that
  * return a number greater or equal to 0 as well as messages waiting in SOSL_RUN_QUEUE to be processed. Errors will get logged.
  *
  * @return The total amount of scripts waiting for processing or -1 on unhandled exceptions/all functions have errors.
  */
  FUNCTION has_scripts
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SYS.HAS_RUN_ID
  * Checks if a given run id exists. Errors get logged.
  *
  * @param p_run_id The run id to verify.
  *
  * @return TRUE if run id exists otherwise FALSE.
  */
  FUNCTION has_run_id(p_run_id IN NUMBER)
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_SYS.GET_RUN_STATE
  * Return the current run state for a given run id. Errors get logged.
  *
  * @param p_run_id The run id to get the run state for.
  *
  * @return On success the current run state or -1 on errors.
  */
  FUNCTION get_run_state(p_run_id IN NUMBER)
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SYS.GET_PAYLOAD
  * Builds a SOSL_PAYLOAD object from the given run id.
  *
  * @param p_run_id The run id to get the SOSL_PAYLOAD object for.
  *
  * @return On success a valid SOSL_PAYLOAD object or NULL on errors.
  */
  FUNCTION get_payload(p_run_id IN NUMBER)
    RETURN SOSL_PAYLOAD
  ;

  /* FUNCTION SOSL_SYS.SIGNAL_STATUS_CHANGE
  * Uses the defined executor from given run id to execute the defined interface function for set_script_status.
  * The given run id must be valid, as well as the defined function for set_script_status. Otherwise the executor is deactivated.
  * If mail is activated, will also call the mail functions, errors on mail are logged and ignored (will not lead to FALSE return value).
  *
  * @param p_run_id The valid run id to signal state changes.
  * @param p_status A valid run state.
  *
  * @return TRUE if run state successfully signalled otherwise FALSE.
  */
  FUNCTION signal_status_change( p_run_id IN NUMBER
                               , p_status IN NUMBER
                               )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_SYS.SET_RUN_STATE
  * Sets the given run state in SOSL_RUN_QUEUE.
  *
  * Run states must follow the state hierarchy: WAITING, ENQUEUED, STARTED, RUNNING, FINISHED. Every state allows to set the
  * state to ERROR or to the following state. Wrong state hierarchy will lead to run state ERROR. If state is equal to current
  * state, no change will take place.
  *
  * @param p_run_id The valid run id to update.
  * @param p_status A valid run state.
  *
  * @return TRUE if run state successfully updated otherwise FALSE.
  */
  FUNCTION set_run_state( p_run_id IN NUMBER
                        , p_status IN NUMBER
                        )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_SYS.SET_SCRIPT_STATUS
  * This function will be used by wrapper functions in SOSL_SERVER package. It will first set the status of the script
  * associated to the given run id in SOSL_RUN_QUEUE and then signal the state to all defined set_script_status functions.
  * Invalid status will lead to run state ERROR used. Errors will get logged. Invalid functions will deactivate the related
  * executors. If at least one status could be set successfully, it will return success (0).
  *
  * Run states must follow the state hierarchy: WAITING, ENQUEUED, STARTED, RUNNING, FINISHED. Every state allows to set the
  * state to ERROR or to the following state. Wrong state hierarchy will lead to run state ERROR. If state is equal to current
  * state, no change will take place.
  *
  * @param p_run_id The valid run id of the script that should change run state.
  * @param p_status A valid status as defined in SOSL_CONSTANTS for run states.
  *
  * @return Return 0 if successful executed otherwise -1.
  */
  FUNCTION set_script_status( p_run_id IN NUMBER
                            , p_status IN NUMBER
                            )
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SYS.REGISTER_NEXT_SCRIPT
  * Fetches the PAYLOAD from a given configured function for SOSL_SERVER.GET_NEXT_SCRIPT and stores it in SOSL_RUN_QUEUE with the
  * status WAITING. On errors, if sufficient data are available, the next script information is stored with status ERROR.
  * All executors using a function with errors will get deactivated.
  *
  * @param p_function_name The function to execute for getting the payload. Package functions allowed.
  * @param p_function_owner The function owner of the function to execute.
  *
  * @return TRUE if fetch was successful, otherwise FALSE.
  */
  FUNCTION register_next_script( p_function_name  IN VARCHAR2
                               , p_function_owner IN VARCHAR2
                               )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_SYS.REGISTER_WAITING
  * Registers all waiting scripts available by defined GET_NEXT_SCRIPT function and persisting them in SOSL_RUN_QUEUE.
  * State may be WAITING or ERROR, if errors occured and SOSL_PAYLOAD has usable values. Errors get logged.
  *
  * @return TRUE if successfully registered any waiting script, otherwise FALSE.
  */
  FUNCTION register_waiting
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_SYS.FETCH_NEXT_RUN_ID
  * Gets the next available RUN_ID from scripts with status WAITING in SOSL_RUN_QUEUE. Mainly sorted by create date but on
  * similar create date randomly.
  *
  * @return The RUN_ID of the next script to execute or -1 on errors.
  */
  FUNCTION fetch_next_run_id
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SYS.GET_NEXT_SCRIPT
  * This function will be used by the wrapper function SOSL_SERVER.GET_NEXT_SCRIPT.
  * It collects from all executors the next script to execute, queues them in SOSL_RUN_QUEUE and then fetches the first script in the
  * run queue as next script to execute. If no scripts are available or on errors, the function will return -1.
  * Errors will be logged. From interface functions it excepts the return type SOSL_PAYLOAD.
  *
  * @return The next script reference as RUN_ID from SOSL_RUN_QUEUE, containing run id that can be related to executor, external script id and scriptfile.
  */
  FUNCTION get_next_script
    RETURN NUMBER
  ;

END;
/
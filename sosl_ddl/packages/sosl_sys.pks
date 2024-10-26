-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
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
  * that throw exceptions on calling them. Errors will be logged.
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

  /* FUNCTION SOSL_SYS.BUILD_SCRIPT_CALL
  * Builds a SELECT FROM dual statement with the given function name and,
  * if NOT NULL, function owner that can be executed dynamically. The return values and
  * types are not checked and must be handled by the caller. By SOSL default the function
  * owner is set and NOT NULL. Anyway this functions handles also NULL on function owner.
  *
  * BE AWARE that oracle cannot distinguish between package functions where the package is named
  * like the schema, if names are equal, e.g. if a package exists, called SOSL, like the schema SOSL,
  * Oracle would search with SOSL.myfunction not a function in the SOSL schema, it would search
  * myfunction in the package SOSL if executed dynamically.
  *
  * @param p_function_name The name of the function or package function.
  * @param p_function_owner If set, the function owner of the function. Will prefix the call.
  *
  * @return A statement to retrieve the function call e.g. SELECT owner.function FROM dual.
  */
  FUNCTION build_script_call( p_function_name   IN VARCHAR2
                            , p_function_owner  IN VARCHAR2 DEFAULT NULL
                            )
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_SYS.GET_HAS_SCRIPT_CNT
  * Determines the count result of all defined has_script functions of valid executors.
  * Failures on specific executors are only considered, if none of the defined functions
  * could be executed without errors. Defined scripts will be executed dynamically. Make
  * sure that has_scripts execute fast, especially if more than one executor is active.
  *
  * Will only execute unique functions. If different executors share the same function owner
  * and function definition, then the function is only executed once and not per executor.
  * Call syntax is functionOwner.functionName where functionName can also be a package call.
  *
  * ATTENTION Will all executors with scripts throwing execptions!
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

  /**
  * This package contains the main functions and procedures used by the Simple Oracle Script Loader to handle executors and scripts.
  * It is not allowed to use this package for function assignments in SOSL_EXECUTOR.
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
  * This function will be used by the wrapper function HAS_SCRIPTS.
  * Collects and sums the output of all defined executor has_scripts functions of active and reviewed executors that
  * return a number greater or equal to 0 as well as messages waiting in SOSL_RUN_QUEUE to be processed. Errors will get logged.
  *
  * @return The total amount of scripts waiting for processing or -1 on unhandled exceptions/all functions have errors.
  */
  FUNCTION has_scripts
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_SYS.GET_NEXT_SCRIPT
  * This function will be used by the wrapper function GET_NEXT_SCRIPT.
  * It collects from all executors the next script to execute, queues them in SOSL_RUN_QUEUE and then fetches the first script in the
  * run queue as next script to execute. If no scripts are available or on errors, the function will return -1.
  * Errors will be logged. From interface functions it excepts the return type SOSL_PAYLOAD.
  *
  * @return The next script reference as RUN_ID from SOSL_RUN_QUEUE, containing run id that can be related to executor, external script id and scriptfile.
  */
  FUNCTION get_next_script
    RETURN NUMBER
  ;


  /** Function SOSL_SYS.SET_CONFIG
  * Sets an existing configuration value for a given configuration name.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_config( p_config_name  IN VARCHAR2
                     , p_config_value IN VARCHAR2
                     )
    RETURN NUMBER
  ;

  /** Function SOSL_SYS.GET_CONFIG
  * Gets an existing configuration value for a given and existing case sensitive configuration name.
  *
  * @return The configured value as VARCHAR2 or -1 string on error.
  */
  FUNCTION get_config(p_config_name IN VARCHAR2)
    RETURN VARCHAR2
  ;


  /** Function SOSL_SYS.BASE_PATH
  * Returns the base path to use for the given run id. Used to switch the run base path for scripts
  * running from a different directory.
  *
  * @return The configured full base path or a simple point for current directory if nothing is configured.
  */
  FUNCTION base_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL_SYS.CFG_PATH
  * Returns the relative configuration path to use for the given run id. A sosl_login.cfg file is expected
  * at the given location.
  *
  * @return The configured relative configuration path or the configured default set by the sosl server.
  */
  FUNCTION cfg_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL_SYS.TMP_PATH
  * Returns the relative temporary path to use for the given run id.
  *
  * @return The configured relative temporary path or the configured default set by the sosl server.
  */
  FUNCTION tmp_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL_SYS.LOG_PATH
  * Returns the relative log path to use for the given run id.
  *
  * @return The configured relative log path or the configured default set by the sosl server.
  */
  FUNCTION log_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

END;
/
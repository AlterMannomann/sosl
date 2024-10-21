-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- main package of the Simple Oracle Script Loader
CREATE OR REPLACE PACKAGE sosl
AS
  /**
  * This package contains the main functions and procedures used by the Simple Oracle Script Loader to handle executors and scripts.
  * It is not allowed to use this package for function assignments in SOSL_EXECUTOR.
  */

  /* FUNCTION SOSL.HAS_SCRIPTS
  * This function will be used by the wrapper function HAS_SCRIPTS.
  * Collects and sums the output of all defined executor has_scripts functions of active and reviewed executors that
  * return a number greater 0 as well as messages waiting in the queue to be processed. Errors will get logged.
  *
  * @return The amount of scripts waiting for all valid executor has_ids functions and waiting queue messages or -1 on unhandled exceptions or if all functions have errors.
  */
  FUNCTION has_scripts
    RETURN NUMBER
  ;

  /* FUNCTION SOSL.HAS_SCRIPTS
  * Gets any waiting scripts for a defined active and reviewed executor has_scripts function or for a given queue table name.
  * Will return 0 if the executor/queue does not exist or is not active and reviewed. Will return -1 on exceptions caused by this
  * function or the defined function. Errors will get logged.
  *
  * @param p_identifier The executor id or queue table name to get waiting script count.
  *
  * @return The amount of scripts waiting for processing or -1 on errors.
  */
  FUNCTION has_scripts(p_identifier IN NUMBER)
    RETURN NUMBER
  ;
  FUNCTION has_scripts(p_identifier IN VARCHAR2)
    RETURN NUMBER
  ;

  /* FUNCTION SOSL.HAS_SCRIPTS_FOR_FN
  * Checks only by function, to avoid duplicate counts, if different executors share the same function and are both active.
  *
  * @param p_fn_has_scripts The defined function call for HAS_SCRIPTS.
  *
  * @return The amount of scripts waiting for processing or -1 on errors.
  */
  FUNCTION has_scripts_for_fn(p_fn_has_scripts IN VARCHAR2)
    RETURN NUMBER
  ;

  /* FUNCTION SOSL.GET_NEXT_SCRIPT
  * This function will be used by the wrapper function GET_NEXT_SCRIPT.
  * It collects from all executors the next script to execute, queues them in SOSL_SCRIPT_QUEUE and then fetches the first script in the
  * message queue as next script to execute. If no scripts are available or on errors, the function will return NULL.
  * Errors will be logged.
  *
  * @return The next script as SOSL_PAYLOAD type, containing the external script id, the executor id and the script filename including relative or full path.
  */
  FUNCTION get_next_script
    RETURN SOSL_PAYLOAD
  ;


  /** Function SOSL.SET_CONFIG
  * Sets an existing configuration value for a given configuration name.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_config( p_config_name  IN VARCHAR2
                     , p_config_value IN VARCHAR2
                     )
    RETURN NUMBER
  ;

  /** Function SOSL.GET_CONFIG
  * Gets an existing configuration value for a given and existing case sensitive configuration name.
  *
  * @return The configured value as VARCHAR2 or -1 string on error.
  */
  FUNCTION get_config(p_config_name IN VARCHAR2)
    RETURN VARCHAR2
  ;


  /** Function SOSL.BASE_PATH
  * Returns the base path to use for the given run id. Used to switch the run base path for scripts
  * running from a different directory.
  *
  * @return The configured full base path or a simple point for current directory if nothing is configured.
  */
  FUNCTION base_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL.CFG_PATH
  * Returns the relative configuration path to use for the given run id. A sosl_login.cfg file is expected
  * at the given location.
  *
  * @return The configured relative configuration path or the configured default set by the sosl server.
  */
  FUNCTION cfg_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL.TMP_PATH
  * Returns the relative temporary path to use for the given run id.
  *
  * @return The configured relative temporary path or the configured default set by the sosl server.
  */
  FUNCTION tmp_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL.LOG_PATH
  * Returns the relative log path to use for the given run id.
  *
  * @return The configured relative log path or the configured default set by the sosl server.
  */
  FUNCTION log_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

END;
/
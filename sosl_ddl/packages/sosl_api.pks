-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- main API package of the Simple Oracle Script Loader
CREATE OR REPLACE PACKAGE sosl_api
AS
  /**
  * This package contains the main functions and procedures used in the API of the Simple Oracle Script Loader.
  */

  /* FUNCTION HAS_SCRIPTS
  * This function will be used by the wrapper function HAS_SCRIPTS.
  * Collects and sums the output of all defined executor has_scripts functions of active and reviewed executors that
  * return a number greater 0 as well as messages waiting in the queue to be processed. Errors will get logged.
  *
  * @return The amount of scripts waiting for all valid executor has_ids functions and waiting queue messages or -1 on unhandled exceptions or if all functions have errors.
  */
  FUNCTION has_scripts
    RETURN NUMBER
  ;

  /* FUNCTION HAS_SCRIPTS
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

  /* FUNCTION HAS_SCRIPTS_FOR_FN
  * Checks only by function, to avoid duplicate counts, if different executors share the same function and are both active.
  *
  * @param p_fn_has_scripts The defined function call for HAS_SCRIPTS.
  *
  * @return The amount of scripts waiting for processing or -1 on errors.
  */
  FUNCTION has_scripts_for_fn(p_fn_has_scripts IN VARCHAR2)
    RETURN NUMBER
  ;

END;
/
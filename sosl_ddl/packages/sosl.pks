-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- main package of the Simple Oracle Script Loader
CREATE OR REPLACE PACKAGE sosl
AS
  /**
  * This package contains the main functions and procedures used by the Simple Oracle Script Loader.
  */

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

  /** Function SOSL.HAS_RUN_IDS
  * Determines if script run ids are available to be executed. Only run ids with run state enqueued
  * and script id NOT NULL are considered.
  *
  * @return The number of script run ids waiting for execution.
  */
  FUNCTION has_run_ids
    RETURN NUMBER
  ;

  /** Function SOSL.NEXT_RUN_ID
  * Determines the next script run id to execute. Will set the run state from enqueued to started.
  *
  * @return The run id of the next script to execute.
  */
  FUNCTION next_run_id
    RETURN NUMBER
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

  /** Procedure SOSL.RUN_PLAN
  * Main function of scheduled plans called with the plan id. Will run and execute the plan.
  *
  * @param p_plan_id The plan id of the plan to execute.
  */
  PROCEDURE run_plan(p_plan_id IN NUMBER);

END;
/
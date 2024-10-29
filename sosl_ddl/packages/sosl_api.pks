-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Basic package providing the API to the Simple Oracle Script Loader.
CREATE OR REPLACE PACKAGE sosl_api
AS
  /**
  * This package contains SOSL API functions and procedures to be used by executors.
  */

  /* FUNCTION SOSL_API.GET_PAYLOAD
  * Builds a SOSL_PAYLOAD object from the given run id. Wrapper for SOSL_SYS.
  *
  * @param p_run_id The run id to get the SOSL_PAYLOAD object for.
  *
  * @return On success a valid SOSL_PAYLOAD object or NULL on errors.
  */
  FUNCTION get_payload(p_run_id IN NUMBER)
    RETURN SOSL_PAYLOAD
  ;

  /** Function SOSL_API.SET_CONFIG
  * Sets an existing configuration value for a given configuration name.
  *
  * @return Exit code, either 0 = successful or -1 on error.
  */
  FUNCTION set_config( p_config_name  IN VARCHAR2
                     , p_config_value IN VARCHAR2
                     )
    RETURN NUMBER
  ;

  /** Function SOSL_API.GET_CONFIG
  * Gets an existing configuration value for a given and existing case sensitive configuration name.
  *
  * @return The configured value as VARCHAR2 or -1 string on error.
  */
  FUNCTION get_config(p_config_name IN VARCHAR2)
    RETURN VARCHAR2
  ;


  /** Function SOSL_API.BASE_PATH
  * Returns the base path to use for the given run id. Used to switch the run base path for scripts
  * running from a different directory.
  *
  * @return The configured full base path or a simple point for current directory if nothing is configured.
  */
  FUNCTION base_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL_API.CFG_PATH
  * Returns the relative configuration path to use for the given run id. A sosl_login.cfg file is expected
  * at the given location.
  *
  * @return The configured relative configuration path or the configured default set by the sosl server.
  */
  FUNCTION cfg_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL_API.TMP_PATH
  * Returns the relative temporary path to use for the given run id.
  *
  * @return The configured relative temporary path or the configured default set by the sosl server.
  */
  FUNCTION tmp_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /** Function SOSL_API.LOG_PATH
  * Returns the relative log path to use for the given run id.
  *
  * @return The configured relative log path or the configured default set by the sosl server.
  */
  FUNCTION log_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_API.DUMMY_MAIL
  * This is a testing function that will NOT send any mail. It will log the mail message created in SOSL_SERVER_LOG using
  * the field full_message, so output can be controlled.
  *
  * @param p_sender The valid mail sender address, e.g. mail.user@some.org.
  * @param p_recipients The semicolon separated list of mail recipient addresses.
  * @param p_subject A preferablly short subject for the mail.
  * @param p_message The correctly formatted mail message.
  *
  * @return Will return TRUE on success or FALSE on errors.
  */
  FUNCTION dummy_mail( p_sender      IN VARCHAR2
                     , p_recipients  IN VARCHAR2
                     , p_subject     IN VARCHAR2
                     , p_message     IN VARCHAR2
                     )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_API.HAS_RUN_ID
  * Checks if a given run id exists. Errors get logged.
  *
  * @param p_run_id The run id to verify.
  *
  * @return TRUE if run id exists otherwise FALSE.
  */
  FUNCTION has_run_id(p_run_id IN NUMBER)
    RETURN BOOLEAN
  ;

END;
/
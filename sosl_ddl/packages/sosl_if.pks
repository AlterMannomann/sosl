-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- interface package of the Simple Oracle Script Loader
CREATE OR REPLACE PACKAGE sosl_if
AS
  /**
  * This package contains the internal interface to SOSL used by the Simple Oracle Script Loader.
  * Can be seen as tutorial and implementation hint for own interfaces.
  */

  /** Function SOSL_IF.HAS_SCRIPTS
  * Determines if script ids are available to be executed. To be defined in SOSL_EXECUTOR.
  *
  * @return The number of script ids waiting for execution.
  */
  FUNCTION has_scripts
    RETURN NUMBER
  ;

  /** Function SOSL_IF.GET_NEXT_SCRIPT
  * Returns the next script id to execute. To be defined in SOSL_EXECUTOR.
  *
  * @return The id of the next script to execute.
  */
  FUNCTION get_next_script
    RETURN SOSL_PAYLOAD
  ;

  /** Function SOSL_IF.SET_SCRIPT_STATUS
  * Sets the status of a script. To be defined in SOSL_EXECUTOR.
  *
  * @param p_reference The reference to the script to update as SOSL_PAYLOAD containing executor_id, ext_script_id and script_file.
  * @param p_status The status for the script to set. Status: 0 WAITING, 1 PREPARING, 2 ENQUEUED, 3 RUNNING, 4 SUCCESS, 5 ERROR.
  * @param p_status_msg An optional message related to current status change, like error messages. SOSL will provide the identifier of SOSLERRORLOG in case of errors.
  *
  * @return 0 on success, -1 on errors.
  */
  FUNCTION set_script_status( p_reference   IN SOSL_PAYLOAD
                            , p_status      IN NUMBER
                            , p_status_msg  IN VARCHAR2 DEFAULT NULL
                            )
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_IF.SEND_MAIL
  * This function is mainly used for testing. In the default setting, it will only send the mail message to
  * SOSL_SERVER_LOG.
  *
  * @param p_sender The valid mail sender address, e.g. mail.user@some.org.
  * @param p_recipients The semicolon separated list of mail recipient addresses.
  * @param p_subject A preferablly short subject for the mail.
  * @param p_message The correctly formatted mail message.
  * @param p_test_mode The default is test mode, set to FALSE if mail should be used.
  *
  * @return Will return 0 on success or -1 on errors.
  */
  FUNCTION send_mail( p_sender      IN VARCHAR2
                    , p_recipients  IN VARCHAR2
                    , p_subject     IN VARCHAR2
                    , p_message     IN VARCHAR2
                    , p_test_mode   IN BOOLEAN  DEFAULT TRUE
                    )
    RETURN NUMBER
  ;

END;
/
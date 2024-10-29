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

  /* FUNCTION SOSL_IF.SEND_MAIL
  * This interface function is mainly used for testing. In the default setting, it will only send the mail message to
  * SOSL_SERVER_LOG. To be defined in SOSL_EXECUTOR. Will be called on every status change, if mail is activated.
  *
  * @param p_run_id The valid run id of the script that should change run state.
  * @param p_status A valid status as defined in SOSL_CONSTANTS for run states.
  *
  * @return Return 0 if successful executed otherwise -1.
  */
  FUNCTION send_mail( p_run_id IN NUMBER
                    , p_status IN NUMBER
                    )
    RETURN NUMBER
  ;

END;
/
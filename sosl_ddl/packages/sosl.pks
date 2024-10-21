-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- main package of the Simple Oracle Script Loader
CREATE OR REPLACE PACKAGE sosl
AS
  /**
  * This package contains the internal interface to SOSL used by the Simple Oracle Script Loader.
  * Can be seen as tutorial and implementation hint for own interfaces.
  */

  /** Function SOSL.HAS_SCRIPTS
  * Determines if script ids are available to be executed. To be defined in SOSL_EXECUTOR.
  *
  * @return The number of script ids waiting for execution.
  */
  FUNCTION has_scripts
    RETURN NUMBER
  ;

  /** Function SOSL.GET_NEXT_SCRIPT
  * Returns the next script id to execute. To be defined in SOSL_EXECUTOR.
  *
  * @return The id of the next script to execute.
  */
  FUNCTION get_next_script
    RETURN SOSL_PAYLOAD
  ;

  /** Function SOSL.SET_SCRIPT_STATUS
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

END;
/
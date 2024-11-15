-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- interface package of the Simple Oracle Script Loader
-- As this package depends on the schema SOSL is installed, getting fully qualified calls must be determined
-- dynamically using SQLPlus variable SOSL_SCHEMA. Fully qualifying is only used for example code of interfacing.
COLUMN SOSL_SCHEMA NEW_VAL SOSL_SCHEMA
SELECT config_value AS SOSL_SCHEMA FROM sosl_config WHERE config_name = 'SOSL_SCHEMA';

CREATE OR REPLACE PACKAGE sosl_if
AS
  /**
  * This package contains the internal interface to SOSL used by the Simple Oracle Script Loader.
  * Can be seen as tutorial and implementation hint for own interfaces.
  */

  /** Function SOSL_IF.HAS_SCRIPTS
  * Determines if script ids are available to be executed. To be defined in SOSL_EXECUTOR_DEFINITION.
  *
  * @return The number of script ids waiting for execution.
  */
  FUNCTION has_scripts
    RETURN NUMBER
  ;

  /** Function SOSL_IF.GET_NEXT_SCRIPT
  * Returns the details of the next script to execute. SOSL_PAYLOAD contains the EXECUTOR_ID from SOSL_EXECUTOR_DEFINITION,
  * the EXT_SCRIPT_ID as used in SOSL_IF_SCRIPT.SCRIPT_ID and the SCRIPT_FILE as defined in SOSL_IF_SCRIPT.SCRIPT_NAME.
  * To be defined in SOSL_EXECUTOR_DEFINITION.
  *
  * @return The details of the next script to execute as SOSL_PAYLOAD object or NULL on errors.
  */
  FUNCTION get_next_script
    RETURN &SOSL_SCHEMA..SOSL_PAYLOAD
  ;

  /** Function SOSL_IF.SET_SCRIPT_STATUS
  * Sets the status of a script in SOSL_IF_SCRIPT. Collects needed data based on RUN_ID. To be defined in SOSL_EXECUTOR_DEFINITION.
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
  * This interface function is mainly used for testing. It will only send the mail message to SOSL_SERVER_LOG. Will be called on every
  * status change, if mail is activated. Collects needed data based on RUN_ID.
  * To be defined in SOSL_EXECUTOR_DEFINITION if USE_MAIL is activated.
  *
  * @param p_run_id The valid run id of the script that should send a mail on changing run state.
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
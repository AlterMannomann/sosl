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

  /* FUNCTION SOSL_IF.ADD_SCRIPT
  * Adds a new script to SOSL_IF_SCRIPT.
  *
  * @param p_script_name The script filename including relative or full path. Must exist on the server SOSL is running.
  * @param p_executor_id The executor id associated with the script. NULL allowed. Scripts without executor are never executed by SOSL.
  * @param p_run_order The order in which the script should be executed. Equal order numbers mean random execution of ths script.
  * @param p_script_active Sets the script to active (1) or inactive (0). Only active scripts are executed.
  *
  * @return Return the new script id or -1 on errors.
  */
  FUNCTION add_script( p_script_name    IN VARCHAR2
                     , p_executor_id    IN NUMBER
                     , p_run_order      IN NUMBER   DEFAULT 1
                     , p_script_active  IN NUMBER   DEFAULT 0
                     )
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_IF.SET_RUN_STATE
  * Sets the run state of a script. Scripts with a run state other than 0 are not
  * considered by SOSL for execution or a probably executed currently by SOSL.
  *
  * @param p_script_id The id of the script to change the run state.
  * @param p_run_state A valid status as defined in SOSL_CONSTANTS for run states.
  *
  * @return Return 0 if successful executed otherwise -1.
  */
  FUNCTION set_run_state( p_script_id IN NUMBER
                        , p_run_state IN NUMBER DEFAULT 0
                        )
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_IF.SET_ACTIVE_STATE
  * Sets the usage state of a script. Inactive scripts are not executed by SOSL.
  *
  * @param p_script_id The id of the script to change the script state.
  * @param p_script_active The usage state of the script. Either active (1) or inactive (0).
  *
  * @return Return 0 if successful executed otherwise -1.
  */
  FUNCTION set_active_state( p_script_id      IN NUMBER
                           , p_script_active  IN NUMBER DEFAULT 0
                           )
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_IF.RESET_SCRIPTS
  * Resets all scripts to run_state 0, so they can be executed again.
  *
  * @return Return 0 if successful executed otherwise -1.
  */
  FUNCTION reset_scripts
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_IF.ACTIVATE_SCRIPTS
  * Activate all scripts, so they can be executed depending on the state.
  *
  * @return Return 0 if successful executed otherwise -1.
  */
  FUNCTION activate_scripts
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_IF.DEACTIVATE_SCRIPTS
  * Dectivate all scripts, so they cannot be executed.
  *
  * @return Return 0 if successful executed otherwise -1.
  */
  FUNCTION deactivate_scripts
    RETURN NUMBER
  ;

END;
/
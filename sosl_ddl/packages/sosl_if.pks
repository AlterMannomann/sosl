-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
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
  * The package is divided in three parts:
  * - wrapper for SOSL_API
  *   - maintenance section for the SOSL api in use
  * - functionality of SOSL_IF external executor simulation
  *   - your implementation section of script run functionality
  * - interface functions for SOSL to be defined in the executor definition
  *   - provide functionality to SOSL
  *
  * You might think about splitting the sections into different packages to have a better control
  * of grants and users. The interface to SOSL should only be executable for the SOSL executor itself.
  * If your implementation is well done, there should be no need to adjust the interface functions
  * apart from package and functions names.
  */

  LOG_CATEGORY      CONSTANT CHAR(27) := 'SOSL_IF external simulation';
  SCRIPT_ACTIVE     CONSTANT INTEGER  := 1;
  SCRIPT_INACTIVE   CONSTANT INTEGER  := 0;
  SCRIPT_DELIVERED  CONSTANT INTEGER  := 1;
  -- Run states
  SCRIPT_WAITING    CONSTANT INTEGER  := 0;
  SCRIPT_ENQUEUED   CONSTANT INTEGER  := 1;
  SCRIPT_STARTED    CONSTANT INTEGER  := 2;
  SCRIPT_RUNNING    CONSTANT INTEGER  := 3;
  SCRIPT_FINISHED   CONSTANT INTEGER  := 4;
  SCRIPT_ERROR      CONSTANT INTEGER  := -1;
  -- formatting
  LF                CONSTANT CHAR(1)  := CHR(10);
  CR                CONSTANT CHAR(1)  := CHR(13);
  CRLF              CONSTANT CHAR(2)  := CHR(13) || CHR(10);
  --========================== Wrapper for SOSL_API ==========================--

  /** PROCEDURE SOSL_IF.LOG_EXCEPTION
  * A wrapper for SOSL_API.IF_EXCEPTION_LOG with reduced parameters as log category is given.
  * No catch of exceptions, if logging fails, database is not in solid state, e.g. tablespace overflow.
  *
  * @param p_caller The full name of function, procedure or package that has caused the unhandled exception. Case sensitive.
  * @param p_sqlerrmsg The full error message, usually SQLERRM. Limited to VARCHAR2 limit 32767 chars.
  */
  PROCEDURE log_exception( p_caller     IN VARCHAR2
                         , p_sqlerrmsg  IN VARCHAR2
                         )
  ;

  /** PROCEDURE SOSL_IF.LOG_INFO
  * A wrapper for SOSL_API.IF_GENERIC_LOG with reduced parameters as log category and type is given.
  * No catch of exceptions, if logging fails, database is not in solid state, e.g. tablespace overflow.
  * You may use this function to extend it with your own SOSL independent logging.
  *
  * @param p_caller The full name of function, procedure or package that logs the information. Case sensitive.
  * @param p_message The info message to log. Limited to VARCHAR2 limit 32767 chars.
  */
  PROCEDURE log_info( p_caller  IN VARCHAR2
                    , p_message IN VARCHAR2
                    )
  ;

  /** FUNCTION SOSL_IF.LOG_INFO_SHOW
  * A wrapper for SOSL_API.IF_DISPLAY_LOG with reduced parameters as log category and type is given.
  * No catch of exceptions, if logging fails, database is not in solid state, e.g. tablespace overflow.
  * You may use this function to extend it with your own SOSL independent logging.
  *
  * @param p_caller The full name of function, procedure or package that logs the information. Case sensitive.
  * @param p_message The info message to log. Limited to VARCHAR2 limit 32767 chars. Recommended to use messages shorter than 4000 char.
  *
  * @return The given message reduced to 4000 chars.
  */
  FUNCTION log_info_show( p_caller  IN VARCHAR2
                        , p_message IN VARCHAR2
                        )
    RETURN VARCHAR2
  ;

  /** PROCEDURE SOSL_IF.LOG_ERROR
  * A wrapper for SOSL_API.IF_GENERIC_LOG with reduced parameters as log category and type is given.
  * No catch of exceptions, if logging fails, database is not in solid state, e.g. tablespace overflow.
  * You may use this function to extend it with your own SOSL independent logging.
  *
  * @param p_caller The full name of function, procedure or package that logs the error. Case sensitive.
  * @param p_message The error message to log. Limited to VARCHAR2 limit 32767 chars.
  */
  PROCEDURE log_error( p_caller  IN VARCHAR2
                     , p_message IN VARCHAR2
                     )
  ;

  /** FUNCTION SOSL_IF.LOG_ERROR_SHOW
  * A wrapper for SOSL_API.IF_DISPLAY_LOG with reduced parameters as log category and type is given.
  * No catch of exceptions, if logging fails, database is not in solid state, e.g. tablespace overflow.
  * You may use this function to extend it with your own SOSL independent logging.
  *
  * @param p_caller The full name of function, procedure or package that logs the error. Case sensitive.
  * @param p_message The error message to log. Limited to VARCHAR2 limit 32767 chars. Recommended to use messages shorter than 4000 char.
  *
  * @return The given message reduced to 4000 chars.
  */
  FUNCTION log_error_show( p_caller  IN VARCHAR2
                         , p_message IN VARCHAR2
                         )
    RETURN VARCHAR2
  ;

  /** PROCEDURE SOSL_IF.LOG_WARNING
  * A wrapper for SOSL_API.IF_GENERIC_LOG with reduced parameters as log category and type is given.
  * No catch of exceptions, if logging fails, database is not in solid state, e.g. tablespace overflow.
  * You may use this function to extend it with your own SOSL independent logging.
  *
  * @param p_caller The full name of function, procedure or package that logs the warning. Case sensitive.
  * @param p_message The warning message to log. Limited to VARCHAR2 limit 32767 chars.
  */
  PROCEDURE log_warning( p_caller  IN VARCHAR2
                       , p_message IN VARCHAR2
                       )
  ;

  /* FUNCTION SOSL_IF.GET_PAYLOAD
  * Wrapper for SOSL_API.IF_GET_PAYLOAD. Builds a SOSL_PAYLOAD object from the given run id.
  * The run id must exist to get a valid payload object.
  *
  * @param p_run_id The run id to get the SOSL_PAYLOAD object for.
  *
  * @return On success a valid SOSL_PAYLOAD object or NULL on errors.
  */
  FUNCTION get_payload(p_run_id IN NUMBER)
    RETURN &SOSL_SCHEMA..SOSL_PAYLOAD
  ;

  /* FUNCTION SOSL_IF.HAS_RUN_ID
  * Wrapper for SOSL_API.IF_HAS_RUN_ID. Checks if a given run id exists. Errors get logged.
  *
  * @param p_run_id The run id to verify.
  *
  * @return TRUE if run id exists otherwise FALSE.
  */
  FUNCTION has_run_id(p_run_id IN NUMBER)
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_IF.DUMMY_MAIL
  * Wrapper for SOSL_API.IF_DUMMY_MAIL. This is a testing function that will NOT send any mail.
  * It will log the mail message created in SOSL_SERVER_LOG using
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

  /* FUNCTION SOSL_IF.MAP_RUN_STATE
  * Maps the run states from SOSL as defined by SOSL_CONSTANTS to own run states. In this
  * case the run states are equal, but you can use this to manage your own run states of
  * whatever type they are.
  *
  * @param p_run_state The run state from SOSL.
  *
  * @return The internal run state as defined in SOSL_IF constants. In case of errors always an error run state is returned.
  */
  FUNCTION map_run_state(p_run_state IN NUMBER)
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_IF.MAP_RUN_STATE_TEXT
  * Maps the run states from SOSL as defined by SOSL_CONSTANTS to own run state text. You can use
  * this to manage your own run state text.
  *
  * @param p_run_state The run state from SOSL.
  *
  * @return The internal run state text representation. In case of errors always ERROR is returned.
  */
  FUNCTION map_run_state_text(p_run_state IN NUMBER)
    RETURN VARCHAR2
  ;
  --========================== Internal executor functionality ==========================--
  -- adjust this functions to your needs and system

  /** Function SOSL_IF.GET_SCRIPT_COUNT
  * Determines how many scripts are available to be executed. Exceptions are handled and logged.
  * Any exception will cause a -1 return value to avoid that next script is delivered.
  *
  * @return The number of scripts waiting for execution or -1 on errors.
  */
  FUNCTION get_script_count
    RETURN NUMBER
  ;

  /** Function SOSL_IF.SET_SCRIPT_DELIVERED
  * Runs as autonomous transaction. Will try to set the given script id to delivered. Rollback on
  * errors. Any exception will cause a FALSE return value and has to be considered by next script.
  *
  * @return TRUE if the script delivered state was updated successfully otherwise FALSE.
  */
  FUNCTION set_script_delivered(p_script_id IN NUMBER)
    RETURN BOOLEAN
  ;

  /** Function SOSL_IF.PROVIDE_NEXT_SCRIPT
  * Returns the details of the next script to execute. SOSL_PAYLOAD contains the EXECUTOR_ID from SOSL_EXECUTOR_DEFINITION,
  * the EXT_SCRIPT_ID as used in SOSL_IF_SCRIPT.SCRIPT_ID and the SCRIPT_FILE as defined in SOSL_IF_SCRIPT.SCRIPT_NAME.
  * Handles update of the script delivered.
  *
  * @return The details of the next script to execute as SOSL_PAYLOAD object or NULL on errors.
  */
  FUNCTION provide_next_script
    RETURN &SOSL_SCHEMA..SOSL_PAYLOAD
  ;

  /** Function SOSL_IF.UPDATE_SCRIPT_STATUS
  * Sets the status of a script in SOSL_IF_SCRIPT as an autonomous transaction. Collects needed data based on RUN_ID.
  * On errors a rollback is initiated. If this function fails, SOSL run state and internal run state may differ.
  *
  * @param p_run_id The valid run id of the script that should change run state.
  * @param p_sosl_run_state A valid status as defined in SOSL_CONSTANTS for run states.
  *
  * @return Return 0 if successful executed otherwise -1.
  */
  FUNCTION update_script_status( p_run_id         IN NUMBER
                               , p_sosl_run_state IN NUMBER
                               )
    RETURN NUMBER
  ;

  /** Function SOSL_IF.MAIL_SENDER
  * Get the sender of a mail depending on run id and script status. Can be used to define a different
  * sender mail address based on script and status.
  * THIS EXAMPLE only contains a hardcoded fake mail address for dummy mail testing.
  *
  * @param p_run_id The valid run id of the script that should change run state.
  * @param p_sosl_run_state A valid status as defined in SOSL_CONSTANTS for run states.
  *
  * @return Return a valid mail adress for the sender to use in a related mail for the given run id.
  */
  FUNCTION mail_sender( p_run_id         IN NUMBER
                      , p_sosl_run_state IN NUMBER
                      )
    RETURN VARCHAR2
  ;

  /** Function SOSL_IF.MAIL_RECIPIENTS
  * Get the recipients of a mail depending on run id and script status. Can be used to define a different
  * recipient mail address lists based on script and status.
  * THIS EXAMPLE only contains a hardcoded fake mail address list for dummy mail testing.
  *
  * @param p_run_id The valid run id of the script that should change run state.
  * @param p_sosl_run_state A valid status as defined in SOSL_CONSTANTS for run states.
  *
  * @return Return a valid mail adress list for the recipients to use in a related mail for the given run id.
  */
  FUNCTION mail_recipients( p_run_id         IN NUMBER
                          , p_sosl_run_state IN NUMBER
                          )
    RETURN VARCHAR2
  ;

  /** Function SOSL_IF.MAIL_HOST
  * Get the mail host depending on run id and script status. Can be used to define a different
  * mail host based on script and status.
  * THIS EXAMPLE only contains a hardcoded fake mail host not needed for dummy mail testing.
  *
  * @param p_run_id The valid run id of the script that should change run state.
  * @param p_sosl_run_state A valid status as defined in SOSL_CONSTANTS for run states.
  *
  * @return Return a valid mail host for to use in a related mail for the given run id.
  */
  FUNCTION mail_host( p_run_id         IN NUMBER
                    , p_sosl_run_state IN NUMBER
                    )
    RETURN VARCHAR2
  ;

  /** Function SOSL_IF.MAIL_PORT
  * Get the SMTP mail port to use depending on run id and script status. Can be used to define a different
  * mail port based on script and status.
  * THIS EXAMPLE only contains the hardcoded default port 25 not used for dummy mail.
  *
  * @param p_run_id The valid run id of the script that should change run state.
  * @param p_sosl_run_state A valid status as defined in SOSL_CONSTANTS for run states.
  *
  * @return Return a valid mail port for to use in a related mail for the given run id.
  */
  FUNCTION mail_port( p_run_id         IN NUMBER
                    , p_sosl_run_state IN NUMBER
                    )
    RETURN NUMBER
  ;

  /** Function SOSL_IF.MAIL_SUBJECT
  * Get the mail subject depending on run id and script status. Can be used to define a different
  * mail subject based on script and status.
  * THIS EXAMPLE only creates a simple mail subject for dummy mail testing.
  *
  * @param p_run_id The valid run id of the script that should change run state.
  * @param p_sosl_run_state A valid status as defined in SOSL_CONSTANTS for run states.
  * @param p_sosl_payload A valid SOSL payload for the given run id.
  *
  * @return Return the mail subject to use in a related mail for the given run id or a hardcoded error subject.
  */
  FUNCTION mail_subject( p_run_id         IN NUMBER
                       , p_sosl_run_state IN NUMBER
                       , p_sosl_payload   IN &SOSL_SCHEMA..SOSL_PAYLOAD
                       )
    RETURN VARCHAR2
  ;

  /** Function SOSL_IF.MAIL_BODY
  * Get the mail body depending on run id and script status. Can be used to define a different
  * mail body based on script and status.
  * THIS EXAMPLE only creates a simple mail body for dummy mail testing.
  *
  * @param p_run_id The valid run id of the script that should change run state.
  * @param p_sosl_run_state A valid status as defined in SOSL_CONSTANTS for run states.
  * @param p_sosl_payload A valid SOSL payload for the given run id.
  *
  * @return Return the mail body to use in a related mail for the given run id or a hardcoded error body.
  */
  FUNCTION mail_body( p_run_id         IN NUMBER
                    , p_sosl_run_state IN NUMBER
                    , p_sosl_payload   IN &SOSL_SCHEMA..SOSL_PAYLOAD
                    )
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_IF.DELIVER_MAIL
  * Prepare and deliver a mail based on script identified by run id and state.
  * Collects needed data based on RUN_ID. Can be used to define the mail functionality.
  * THIS EXAMPLE only sends a dummy mail to SOSL_SERVER_LOG.
  *
  * @param p_run_id The valid run id of the script that should send a mail on changing run state.
  * @param p_status A valid status as defined in SOSL_CONSTANTS for run states.
  *
  * @return Return 0 if successful executed otherwise -1.
  */
  FUNCTION deliver_mail( p_run_id IN NUMBER
                       , p_status IN NUMBER
                       )
    RETURN NUMBER
  ;
  --========================== Maintenance functionality ==========================--

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
  --========================== Interface provided to SOSL ==========================--
  -- the defined functions to use in the executor definition of SOSL

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
GRANT EXECUTE ON sosl_if TO sosl_executor;
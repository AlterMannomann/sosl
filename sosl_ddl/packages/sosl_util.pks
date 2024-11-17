-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Basic util package not using data objects of the Simple Oracle Script Loader, apart from sosl_sys and logging.
CREATE OR REPLACE PACKAGE sosl_util
AS
  /**
  * This package contains basic functions and procedures used by the Simple Oracle Script Loader that have minimal dependencies on
  * SOSL object. Provides logging.
  */

  /* PROCEDURE SOSL_UTIL.SPLIT_FUNCTION_NAME
  * Splits the given function name into its parts. Supposed delimiter is the point ".".
  * @param p_function_name The function or package function name to check. Package functions must be qualified with the package name, e.g. my_package.my_function.
  * @param p_package OUT parameter, contains the package name if any or NULL.
  * @param p_function OUT parameter, contains the pure function name.
  */
  PROCEDURE split_function_name( p_function_name IN  VARCHAR2
                               , p_package       OUT VARCHAR2
                               , p_function      OUT VARCHAR2
                               )
  ;

  /* FUNCTION SOSL_UTIL.HAS_DB_USER
  * Checks if a given user is visible for SOSL by checking ALL_USERS. Users must be visible to SOSL to be able to dynamically
  * grant the necessary rights on the API for script execution.
  *
  * @param p_username The database user name to check.
  *
  * @return TRUE if the user is visible in ALL_USERS to SOSL, otherwise FALSE.
  */
  FUNCTION has_db_user(p_username IN VARCHAR2)
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_UTIL.HAS_FUNCTION
  * Checks if a given function or package function name is visible for SOSL by checking ALL_ATTRIBUTES. Internal SOSL packages,
  * apart from SOSL_IF% packages, are excluded from the search to avoid self references.
  *
  * @param p_owner The owner of the function or package function name to check.
  * @param p_function_name The function or package function name to check. Package functions must be qualified with the package name, e.g. my_package.my_function.
  * @param p_datatype The return datatype of the function expected, e.g. a valid Oracle datatype like NUMBER or VARCHAR2.
  *
  * @return TRUE if the function is visible in ALL_ATTRIBUTES to SOSL and has the required return datatype, otherwise FALSE.
  */
  FUNCTION has_function( p_owner          IN VARCHAR2
                       , p_function_name  IN VARCHAR2
                       , p_datatype       IN VARCHAR2
                       )
    RETURN BOOLEAN
  ;

  /*FUNCTION SOSL_UTIL.GET_COL_LENGTH
  * Returns the column length for a given table and column or -1 if table or column does not exist from USER_TAB_COLUMNS using
  * DATA_LENGTH. DATA_LENGTH is misleading if not a char type or CLOB, as CLOB types report 4000 which is definitely wrong.
  * The only types handled are NUMBER and CLOB. All other types return the DATA_LENGTH.
  *
  * Length for numbers is calculated by adding precision and scale.
  *
  * CLOB will return the PLSQL equation of a VARCHAR2/CLOB, which is 32767 and still wrong, but useful to see if a PLSQL can handle
  * the CLOB. Be careful with CLOB handling. If source is not a table column, PLSQL most likely limits it to 32767 cutting longer content.
  *
  * Objects not in the current schema will not be considered and return -1 AS USER_TAB_COLUMN is used.
  *
  * No handling for date and timestamp values, as their char representation has too much dependencies on NLS and formatting to get a
  * reliable length.
  *
  * Byte and char semantic is not considered only the effective chars that can be stored in CHAR or VARCHAR2 as defined by DATA_LENGTH.
  *
  * @param p_table The name of the table. Case insensitive. Will be transformed to UPPER.
  * @param p_column The name of the column. Case insensitive. Will be transformed to UPPER.
  *
  * @return The calculated length of the column. Fix PLSQL limit 32767 for CLOB types. DATA_LENGTH for data and timestamp types.
  */
  FUNCTION get_col_length( p_table  IN VARCHAR2
                         , p_column IN VARCHAR2
                         )
    RETURN INTEGER
  ;

  /* FUNCTION SOSL_UTIL.GET_COL_TYPE
  * Returns the type of a column from USER_TAB_COLUMNS as defined in DATA_TYPE or NA_TYPE if table or column doesn't exist.
  * Objects not in the current schema will not be considered and return NA_TYPE.
  *
  * @param p_table The name of the table. Case insensitive. Will be transformed to UPPER.
  * @param p_column The name of the column. Case insensitive. Will be transformed to UPPER.
  *
  * @return The type of the column as defined in DATA_TYPE or sosl_sys.NA_TYPE on errors or not found columns and tables.
  */
  FUNCTION get_col_type( p_table  IN VARCHAR2
                       , p_column IN VARCHAR2
                       )
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_UTIL.CHECK_COL
  * This function can check NUMBER and VARCHAR2/CHAR columns for length and type. Passing a number for a char column type will result
  * in FALSE. Providing a P_VALUE with a length longer than the length calculated, will result in FALSE. It will not consider
  * implicite Oracle conversions. Expects type like defined.
  *
  * Number length is calculated by TO_CHAR string representation removing all delimiters and counting only numbers 0-9.
  * Passing a VARCHAR2 value is valid for CHAR and VARCHAR2 column types.
  *
  * @param p_table The name of the table. Case insensitive. Will be transformed to UPPER.
  * @param p_column The name of the column. Case insensitive. Will be transformed to UPPER.
  * @param p_value The value for the table column to check against column definition.
  *
  * @return TRUE if value and column match in type and length, otherwise FALSE.
  */
  FUNCTION check_col( p_table  IN VARCHAR2
                    , p_column IN VARCHAR2
                    , p_value  IN VARCHAR2
                    )
    RETURN BOOLEAN
  ;
  FUNCTION check_col( p_table  IN VARCHAR2
                    , p_column IN VARCHAR2
                    , p_value  IN NUMBER
                    )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_UTIL.HAS_ROLE
  * This function determines if a given database user has the requested role granted. This will also include
  * implicite roles granted by role hierarchy.
  *
  * @param p_db_user The database user to check. Has to be a valid database user.
  * @param p_role The role to check. Limited to roles starting with SOSL. Must be a valid and existing role.
  *
  * @return Will return TRUE, if user has the role assigned, otherwise FALSE, also in case of errors which get logged.
  */
  FUNCTION has_role( p_db_user IN VARCHAR2
                   , p_role    IN VARCHAR2
                   )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_UTIL.GRANT_ROLE
  * This function grants a given database user the given role.
  *
  * @param p_db_user The database user to get the role grant. Has to be a valid database user.
  * @param p_role The role to grant. Limited to roles starting with SOSL. Must be a valid and existing role with ADMIN rights for SOSL schema.
  *
  * @return Will return TRUE, if user has the role or has been granted the role successfully, otherwise FALSE, also in case of errors which get logged.
  */
  FUNCTION grant_role( p_db_user IN VARCHAR2
                     , p_role    IN VARCHAR2
                     )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_UTIL.REVOKE_ROLE
  * This function revoke a given role from a given database user.
  *
  * @param p_db_user The database user to remove the role grant. Has to be a valid database user.
  * @param p_role The role to remove. Limited to roles starting with SOSL. Must be a valid and existing role with ADMIN rights for SOSL schema.
  *
  * @return Will return TRUE, if user has not the role or has been revoked the role successfully, otherwise FALSE, also in case of errors which get logged.
  */
  FUNCTION revoke_role( p_db_user IN VARCHAR2
                      , p_role    IN VARCHAR2
                      )
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_UTIL.UTC_MAIL_DATE
  * Returns the current date timestamp as a formatted string for date values in mail.
  *
  * @return A date string conform to RFC5322 for using mail or NULL on errors.
  *
  * @see https://datatracker.ietf.org/doc/html/rfc5322
  */
  FUNCTION utc_mail_date
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_UTIL.FORMAT_MAIL
  * This function formats a mail message conforming to RFC5322. The content of p_message is not checked against RFC. This is
  * the repsonsibility of the user. This is for small messages that do not exceed 32k in total.
  *
  * @param p_sender The valid mail sender address, e.g. mail.user@some.org.
  * @param p_recipients The semicolon separated list of mail recipient addresses.
  * @param p_subject A preferablly short subject for the mail.
  * @param p_message The correctly formatted mail message.
  *
  * @return A formatted string with complete mail message that can be used with RFC compliant mail servers or NULL on errors.
  */
  FUNCTION format_mail( p_sender      IN VARCHAR2
                      , p_recipients  IN VARCHAR2
                      , p_subject     IN VARCHAR2
                      , p_message     IN VARCHAR2
                      )
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_UTIL.CHECK_MAIL_ADDRESS
  * Checks the format of an email address roughly. Does not check if this is a valid and working email address.
  * Format checking based on a minimal email address like a@b.io, which requires a minimum length of six chars
  * and having the @ and the . as domain separator in the email address. Errors will get logged.
  *
  * @param The email address to check, basic expected format is user@company.domain.
  *
  * @return Return TRUE if the address fulfills the minimum criteria for a mail address otherwise FALSE, including for errors.
  */
  FUNCTION check_mail_address_format(p_mail_address IN VARCHAR2)
    RETURN BOOLEAN
  ;

  /* FUNCTION SOSL_UTIL.DUMMY_MAIL
  * This is a testing function that will NOT send any mail. It will log the mail message created in SOSL_SERVER_LOG using
  * the field full_message, so output can be controlled.
  *
  * @param p_sender The valid mail sender address, e.g. mail.user@some.org.
  * @param p_recipients The semicolon separated list of mail recipient addresses.
  * @param p_subject A preferablly short subject for the mail.
  * @param p_message The correctly formatted mail message.
  *
  * @return Will return 0 on success or -1 on errors.
  */
  FUNCTION dummy_mail( p_sender      IN VARCHAR2
                     , p_recipients  IN VARCHAR2
                     , p_subject     IN VARCHAR2
                     , p_message     IN VARCHAR2
                     )
    RETURN NUMBER
  ;

  /* FUNCTION SOSL_UTIL.TXT_BOOLEAN
  * Provides text values to display instead of BOOLEAN or NUMBER values interpreted as BOOLEAN. Numbers are interpreted
  * similar to Oracle SQL, where 0 is FALSE and 1 is TRUE. 1 is considered as TRUE, any other value as FALSE. NULL values
  * are interpreted as sosl_sys.NA_TYPE. Maximum 10 characters for TRUE/FALSE equation.
  *
  * @param p_bool The BOOLEAN or NUMBER value that should be interpreted.
  * @param p_true The text equation for TRUE, maximum 10 characters. Longer strings get cut. Case is not controlled.
  * @param p_false The text equation for FALSE, maximum 10 characters. Longer strings get cut. Case is not controlled.
  *
  * @return The text equation for the given p_bool value or sosl_constants.GEN_NA_TYPE on errors.
  */
  FUNCTION txt_boolean( p_bool   IN BOOLEAN
                      , p_true   IN VARCHAR2 DEFAULT 'TRUE'
                      , p_false  IN VARCHAR2 DEFAULT 'FALSE'
                      )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION txt_boolean( p_bool   IN NUMBER
                      , p_true   IN VARCHAR2 DEFAULT 'TRUE'
                      , p_false  IN VARCHAR2 DEFAULT 'FALSE'
                      )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;

  /* FUNCTION SOSL_UTIL.YES_NO
  * A simple wrapper for txt_boolean with YES/NO instead of TRUE/FALSE.
  *
  * @param p_bool The BOOLEAN or NUMBER value that should be interpreted.
  * @param p_true The text equation for TRUE, maximum 10 characters. Longer strings get cut. Case is not controlled.
  * @param p_false The text equation for FALSE, maximum 10 characters. Longer strings get cut. Case is not controlled.
  *
  * @return The text equation for the given p_bool value or sosl_constants.GEN_NA_TYPE on errors.
  */
  FUNCTION yes_no( p_bool   IN BOOLEAN
                 , p_true   IN VARCHAR2 DEFAULT 'YES'
                 , p_false  IN VARCHAR2 DEFAULT 'NO'
                 )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION yes_no( p_bool   IN NUMBER
                 , p_true   IN VARCHAR2 DEFAULT 'YES'
                 , p_false  IN VARCHAR2 DEFAULT 'NO'
                 )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;

  /* FUNCTION SOSL_UTIL.OBJECT_DATE
  * Works only for objects in the current schema, using USER_OBJECTS. Will return the LAST_DDL_TIME or the NA date type
  * from SOSL_CONSTANTS if the object could not be found. Object type has to conform to object types used in USER_OBJECTS.
  *
  * @param p_object_name The name of the object, will be transformed to UPPERCASE as SOSL does not use mixed case.
  * @param p_object_type A valid object type for USER_OBJECTS, e.g. FUNCTION, PACKAGE, PACKAGE BODY, PROCEDURE.
  *
  * @return The LAST_DDL_TIME as noted in USER_OBJECTS or SOSL_CONSTANTS.GEN_NA_DATE_TYPE on errors or not found.
  */
  FUNCTION object_date( p_object_name IN VARCHAR2
                      , p_object_type IN VARCHAR2
                      )
    RETURN DATE
  ;

  /* FUNCTION SOSL_UTIL.GET_VALID_RUN_STATE
  * Checks if given run state in valid and returns the valid run state or error state.
  *
  * @param The run state to check. See SOSL_CONSTANTS for defined run states.
  *
  * @return Either the given run state if valid or SOSL_CONSTANTS.RUN_STATE_ERROR.
  */
  FUNCTION get_valid_run_state(p_run_state IN NUMBER)
    RETURN NUMBER
  ;

  /** Function SOSL_UTIL.CREATE_EXECUTOR
  * Creates a new executor definition if it did not exist already. Runs as autonomous transaction.
  * The given interface functions must conform to the following declarations, must exist and be granted to SOSL_EXECUTOR role:
  *
  * fn_has_scripts: FUNCTION your_has_script RETURN NUMBER;
  * @return A positive integer including 0 for amount of scripts waiting or -1 on errors.
  * @task: Return the amount of waiting scripts.
  *
  * fn_get_next_script: FUNCTION your_get_next_script RETURN SOSL.SOSL_PAYLOAD;
  * @return A valid and filled SOSL_PAYLOAD object containing EXECUTOR_ID, EXT_SCRIPT_ID and SCRIPT_FILE or NULL on errors.
  * @task: Return the details of the next waiting script.
  *
  * fn_set_script_status: FUNCTION your_set_script_status(p_run_id IN NUMBER, p_status IN NUMBER) RETURN NUMBER;
  * @return Execution indicator: 0 on success or -1 on errors.
  * @task: Set the internal status of your scripts queued for execution.
  *
  * fn_send_db_mail: FUNCTION your_send_mail(p_run_id IN NUMBER, p_status IN NUMBER) RETURN NUMBER;
  * @return Execution indicator: 0 on success or -1 on errors.
  * @task: Prepare and send a mail based on script status.
  *
  * For examples see package SOSL_IF.
  *
  * @param p_executor_name The unique executor definition name.
  * @param p_function_owner The existing and for SOSL visible database user that owns the interface functions.
  * @param p_fn_has_scripts The fully qualified interface function for has_scripts. Must exist and be granted to SOSL_EXECUTOR.
  * @param p_fn_get_next_script The fully qualified interface function for get_next_script. Must exist and be granted to SOSL_EXECUTOR.
  * @param p_fn_set_script_status The fully qualified interface function for set_script_status. Must exist and be granted to SOSL_EXECUTOR.
  * @param p_cfg_file The filename including relative or absolute path that contains the login for the executor.
  * @param p_use_mail Defines if mail should be used (1) or not (0). Default is no mail usage.
  * @param p_fn_send_db_mail The fully qualified interface function for send mail. If mail should be used the parameter is mandatory, must exist and be granted to SOSL_EXECUTOR.
  * @param p_executor_description An optional description for the new executor.
  *
  * @return The new executor id or -1 on errors.
  */
  FUNCTION create_executor( p_executor_name         IN VARCHAR2
                          , p_db_user               IN VARCHAR2
                          , p_function_owner        IN VARCHAR2
                          , p_fn_has_scripts        IN VARCHAR2
                          , p_fn_get_next_script    IN VARCHAR2
                          , p_fn_set_script_status  IN VARCHAR2
                          , p_cfg_file              IN VARCHAR2
                          , p_use_mail              IN NUMBER     DEFAULT 0
                          , p_fn_send_db_mail       IN VARCHAR2   DEFAULT NULL
                          , p_executor_description  IN VARCHAR2   DEFAULT NULL
                          )
    RETURN NUMBER
  ;

  /** Function SOSL_UTIL.ACTIVE_STATE_EXECUTOR
  * Sets the EXECUTOR_ACTIVE flag. Runs as autonomous transaction.
  *
  * @param p_executor_id The id of the executor that should be changed.
  * @param p_active_state The desired active state of the executor. Either 0 - not activated (default) or 1 - activated.
  *
  * @return Execution indicator: 0 if successful otherwise -1.
  */
  FUNCTION active_state_executor( p_executor_id   IN NUMBER
                                , p_active_state  IN NUMBER DEFAULT 0
                                )
    RETURN NUMBER
  ;

  /** Function SOSL_UTIL.REVIEW_STATE_EXECUTOR
  * Sets the EXECUTOR_REVIEWED flag. Runs as autonomous transaction.
  *
  * @param p_executor_id The id of the executor that should be changed.
  * @param p_review_state The reviewed state of the executor. Either 0 - review not ok (default) or 1 - reviewed and accepted.
  *
  * @return Execution indicator: 0 if successful otherwise -1.
  */
  FUNCTION review_state_executor( p_executor_id   IN NUMBER
                                , p_review_state  IN NUMBER DEFAULT 0
                                )
    RETURN NUMBER
  ;

  FUNCTION db_in_time
    RETURN BOOLEAN
  ;

END;
/

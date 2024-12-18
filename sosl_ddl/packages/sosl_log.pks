-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- Basic logging package, dependencies only to sosl_server_log and sosl_sys.
CREATE OR REPLACE PACKAGE sosl_log
AS
  /**
  * This package contains basic functions and procedures used by the Simple Oracle Script Loader for managing logging.
  * The interface has as well functions and procedures. Functions inform about success or error, whereas severe procedure exceptions
  * must be handled by the caller. The intention is to log as much information as possible before running into an exception
  * that can't be handled any longer.
  *
  * CURRENT ORACLE error: NOCOPY for IN parameters creates compile errors, whereas documentation allows IN NOCOPY var. Any
  * CLOB handling errors are possibly caused by the inability to provide a CLOB as reference.
  */

  /*====================================== start internal functions made visible for testing ======================================*/
  /* PROCEDURE SOSL_LOG.LOG_FALLBACK
  * This procedure tries some fallback actions, if logging raised an exception. It will not throw an extra exception. Intended to be
  * used during exception handling before raising the error.
  * It will try to log the error in one of this tables: SOSL_SERVER_LOG, SOSLERRORLOG, SPERRORLOG or, if everything fails output the error
  * via DBMS_OUTPUT.
  *
  * As we can't determine if the message contains an illegal character forcing the exception, the caller should transfer SQLERRM and
  * verify the transmitted content before passing it to this procedure or avoid transmitting parameters which should cause errors.
  *
  * If error could be logged it matches as follows:
  * SOSL_SERVER_LOG(caller, sosl_identifier, message) VALUES (p_script, p_identifier, p_message)
  * SOSLERRORLOG, SPERRORLOG(script, identifier, message) VALUES (p_script, p_identifier, p_message)
  * It will not prevent the exception, only try to log it somewhere, where it could be found without needing to analyze the db server
  * logs. Everything runs as autonomous transaction.
  *
  * DO NOT USE THIS PROCEDURE. It is internal for this package and only visible for testing.
  *
  * @param p_script The package function or procedure causing the error, e.g. sosl_log.log_event.
  * @param p_identifier The identifier for this error. Saved in SOSL_IDENTIFIER in SOSL_SERVER_LOG or IDENTIFIER in the error log tables.
  * @param p_message The message to save. Reduce it to SQLERRM if possible.
  */
  PROCEDURE log_fallback( p_script      IN VARCHAR2
                        , p_identifier  IN VARCHAR2
                        , p_message     IN VARCHAR2
                        )
  ;
  /* PROCEDURE SOSL_LOG.LOG_EVENT
  * Writes a log entry as autonomous transaction. This is the internal base procedure, exposed for testing.
  * If on errors writing log entries is not possible the procedure hands the exception to the caller. This is the pure insert without
  * any checks. It takes the values as given and table may trigger exceptions. DO NOT USE THIS PROCEDURE. It is internal for this package.
  *
  * @param p_message The message to log. Limited to 4000 chars. If longer it is split and rest is stored in full_message CLOB by trigger. If NULL p_full_message must be provided.
  * @param p_log_type The log type is basically defined by SOSL_SYS. Currently: INFO, WARNING, ERROR, FATAL, SUCCESS. Must be valid.
  * @param p_log_category An optional logging category.
  * @param p_guid The GUID the process is running with. Can be used as LIKE reference on SOSLERRORLOG. Most likely used by CMD server.
  * @param p_sosl_identifier The exact identifier for SOSLERRORLOG if available. Most likely used by CMD server.
  * @param p_executor_id The associated executor id if available. Used as well by CMD server and SOSL packages and functions.
  * @param p_ext_script_id The (external) script id if available. Used as well by CMD server and SOSL packages and functions.
  * @param p_script_file The script file name and path if available. Used as well by CMD server and SOSL packages and functions.
  * @param p_caller Caller identification if available, to distinguish database processes from SOSL CMD server processes or external usage.
  * @param p_run_id The associated run id if available. Most likely used by SOSL packages and functions.
  * @param p_full_message The full message as CLOB if the message size exceeds the PLSQL limit of 32767 bytes. Must be given if p_message is NULL.
  */
  PROCEDURE log_event( p_message          IN VARCHAR2
                     , p_log_type         IN VARCHAR2
                     , p_log_category     IN VARCHAR2
                     , p_guid             IN VARCHAR2
                     , p_sosl_identifier  IN VARCHAR2
                     , p_executor_id      IN NUMBER
                     , p_ext_script_id    IN VARCHAR2
                     , p_script_file      IN VARCHAR2
                     , p_caller           IN VARCHAR2
                     , p_run_id           IN NUMBER
                     , p_full_message     IN CLOB
                     )
  ;
/*====================================== end internal functions made visible for testing ======================================*/

  /* FUNCTION SOSL_LOG.LOG_TYPE_VALID
  * Central function to check the log type. Supports the log types defined in SOSL_CONSTANTS. If log types should get expanded
  * adjust constants, this function, the table constraint on log_type and probably the default value for SOSL_SERVER_LOG in
  * table definition and trigger.
  *
  * @param p_log_type The log type to check. Case insensitive.
  *
  *@return TRUE if the given log type is supported. FALSE if not. Exceptions and errors will lead also to FALSE.
  */
  FUNCTION log_type_valid(p_log_type IN VARCHAR2)
    RETURN BOOLEAN
    DETERMINISTIC
    PARALLEL_ENABLE
  ;

  /* FUNCTION SOSL_LOG.GET_VALID_LOG_TYPE
  * Verifies an given log type, returns either the given log type as upper case or the defined error default.
  *
  * @param p_log_type The log type to verify and return. Case insensitive.
  * @param p_error_default The alternative log type to return, if the log type is invalid. Must be a valid log type and not INFO or SUCCESS. If invalid, FATAL is returned.
  *
  * @return The valid log type as upper case on success. The valid error default if log type not supported. FATAL if the error default is invalid.
  */
  FUNCTION get_valid_log_type( p_log_type       IN VARCHAR2
                             , p_error_default  IN VARCHAR2 DEFAULT sosl_constants.LOG_ERROR_TYPE
                             )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;

  /* FUNCTION SOSL_LOG.DISTRIBUTE
  * This functions distributes char data between a VARCHAR2 and a CLOB variable by the following rules:
  * p_string empty or NULL: Fill p_string to p_max_string_length - p_split_end length.
  * p_string length > p_max_string_length: Cut p_string to p_max_string_length, including p_split_end appended.
  *          p_clob NOT EMPTY: add split_start, rest of p_string before p_clob content.
  *          p_clob EMPTY: add split_start and rest of p_string.
  * p_string length > 0 and < p_max_string_length: no change of p_string and p_clob.
  * p_string and p_clob empty or NULL: leave unchanged, return FALSE otherwise always TRUE.
  * In case of exceptions will try to write SQLERRM to p_string as CLOBs tend to be more error prone.
  * Mainly used by SOSL_SERVER_LOG.
  *
  * @param p_string The string to distribute or check. In PLSQL strings can get 32767 chars long, whereas table columns are limited currently to 4000.
  * @param p_clob The CLOB to distribute or check. Uses NOCOPY to guarantee that CLOB full length is used as given.
  * @param p_max_string_length The maximum length p_string should have. If this size is exeeded the string gets distribute between p_string and p_clob.
  * @param p_split_end The split end characters to indicate that the string is continued in p_clob.
  * @param p_split_start The split start characters for the continuing string in the CLOB.
  * @param p_delimiter The delimiter between rest of string in CLOB and original CLOB content, if both have content and string must be splitted.
  *
  * @return FALSE if p_string and p_clob are empty/NULL or an exception had occurred, otherwise TRUE.
  */
  FUNCTION distribute( p_string            IN OUT         VARCHAR2
                     , p_clob              IN OUT NOCOPY  CLOB
                     , p_max_string_length IN             INTEGER   DEFAULT 4000
                     , p_split_end         IN             VARCHAR2  DEFAULT '...'
                     , p_split_start       IN             VARCHAR2  DEFAULT '...'
                     , p_delimiter         IN             VARCHAR2  DEFAULT ' - '
                     )
    RETURN BOOLEAN
  ;

  /* PROCEDURE SOSL_LOG.FULL_LOG
  * Procedure with all parameters for logging. Will check parameters before logging. You should at least set also p_log_category
  * and p_caller, to be able to assign the log entry to a specific event and object. On parameter errors a separate log entry is
  * created. Intention is to write a log in any case and not throw any exception. This still may happen on main system malfunctions
  * but is limited to this events.
  * To keep things as fast as possible, column length checks are hardcoded, no extra round trip to USER_TAB_COLUMNS. If table definition
  * changes, this package has to be adjusted.
  *
  * @param p_message The message to log. Limited to 4000 chars. If longer it is split and rest is stored in full_message CLOB by trigger. If NULL p_full_message must be provided.
  * @param p_log_type The log type is basically defined by SOSL_SYS. Currently: INFO, WARNING, ERROR, FATAL, SUCCESS. Will be set to ERROR if not valid.
  * @param p_log_category An optional logging category.
  * @param p_caller Caller identification if available, to distinguish database processes from SOSL CMD server processes or external usage.
  * @param p_guid The GUID the process is running with. Can be used as LIKE reference on SOSLERRORLOG. Most likely used by CMD server.
  * @param p_sosl_identifier The exact identifier for SOSLERRORLOG if available. Most likely used by CMD server.
  * @param p_executor_id The associated executor id if available. Used as well by CMD server and SOSL packages and functions.
  * @param p_ext_script_id The (external) script id if available. Used as well by CMD server and SOSL packages and functions.
  * @param p_script_file The script file name and path if available. Used as well by CMD server and SOSL packages and functions.
  * @param p_run_id The associated run id if available. Most likely used by SOSL packages and functions.
  * @param p_full_message The full message as CLOB if the message size exceeds the PLSQL limit of 32767 bytes. Must be given if p_message is NULL.
  */
  PROCEDURE full_log( p_message          IN VARCHAR2
                    , p_log_type         IN VARCHAR2    DEFAULT sosl_constants.LOG_INFO_TYPE
                    , p_log_category     IN VARCHAR2    DEFAULT 'not set'
                    , p_caller           IN VARCHAR2    DEFAULT NULL
                    , p_guid             IN VARCHAR2    DEFAULT NULL
                    , p_sosl_identifier  IN VARCHAR2    DEFAULT NULL
                    , p_executor_id      IN NUMBER      DEFAULT NULL
                    , p_ext_script_id    IN VARCHAR2    DEFAULT NULL
                    , p_script_file      IN VARCHAR2    DEFAULT NULL
                    , p_run_id           IN NUMBER      DEFAULT NULL
                    , p_full_message     IN CLOB        DEFAULT NULL
                    )
  ;

  /* PROCEDURE SOSL_LOG.EXCEPTION_LOG
  * Prepared and standardize logging for unhandled exceptions with reduced parameters. It will try to log the exception
  * and then return to the caller. Will do a simple NVL check on parameters, nothing more before formatting and submitting
  * the log entry. Will set log type to SOSL_CONSTANTS.LOG_FATAL_TYPE. Will raise any exception. If logging fails the
  * database is most likely in an unknown state. Exceptions at this point must break the application to stop running until
  * database is working correctly again.
  *
  * @param p_caller The full name of function, procedure or package that has caused the unhandled exception. Case sensitive.
  * @param p_category The log category for the function, procedure or package. Case sensitive.
  * @param p_sqlerrmsg The full error message, usually SQLERRM. Limited to VARCHAR2 limit 32767 chars.
  */
  PROCEDURE exception_log( p_caller     IN VARCHAR2
                         , p_category   IN VARCHAR2
                         , p_sqlerrmsg  IN VARCHAR2
                         )
  ;

  /* PROCEDURE SOSL_LOG.MINIMAL_LOG
  * Prepared and standardize logging for any log type with reduced parameters. Will do a simple NVL check on parameters, nothing more
  * before formatting and submitting the log entry. Will log own exceptions but not raise those exceptions.
  *
  * @param p_caller The full name of function, procedure or package that should be logged. Case sensitive.
  * @param p_category The log category for the function, procedure or package. Case sensitive.
  * @param p_log_type The log type for the logging as defined in SOSL_CONSTANTS.LOG_... constants.
  * @param p_short_msg The short success message, preferably smaller than 4000 chars. Will be formatted using p_caller.
  * @param p_full_msg The complete success message, with details. Will not be formatted but may contain parts of p_short_msg, if message is longer than 4000 chars.
  */
  PROCEDURE minimal_log( p_caller     IN VARCHAR2
                       , p_category   IN VARCHAR2
                       , p_log_type   IN VARCHAR2
                       , p_short_msg  IN VARCHAR2
                       , p_full_msg   IN CLOB     DEFAULT NULL
                       )
  ;
  PROCEDURE minimal_log( p_caller     IN VARCHAR2
                       , p_category   IN VARCHAR2
                       , p_log_type   IN VARCHAR2
                       , p_short_msg  IN VARCHAR2
                       , p_full_msg   IN VARCHAR2
                       )
  ;

  /* PROCEDURE SOSL_LOG.MINIMAL_ERROR_LOG
  * Prepared and standardize logging for errors with reduced parameters. Will do a simple NVL check on parameters, nothing more
  * before formatting and submitting the log entry. Will log own exceptions but not raise those exceptions.
  * Will set log type to SOSL_CONSTANTS.LOG_ERROR_TYPE.
  *
  * @param p_caller The full name of function, procedure or package that has caused the error. Case sensitive.
  * @param p_category The log category for the function, procedure or package. Case sensitive.
  * @param p_short_msg The short error message, preferably smaller than 4000 chars. Will be formatted using p_caller.
  * @param p_full_msg The complete error message, with details on the error. Will not be formatted but may contain parts of p_short_msg, if message is longer than 4000 chars.
  */
  PROCEDURE minimal_error_log( p_caller     IN VARCHAR2
                             , p_category   IN VARCHAR2
                             , p_short_msg  IN VARCHAR2
                             , p_full_msg   IN CLOB     DEFAULT NULL
                             )
  ;
  PROCEDURE minimal_error_log( p_caller     IN VARCHAR2
                             , p_category   IN VARCHAR2
                             , p_short_msg  IN VARCHAR2
                             , p_full_msg   IN VARCHAR2
                             )
  ;

  /* PROCEDURE SOSL_LOG.MINIMAL_ERROR_LOG
  * Prepared and standardize logging for information with reduced parameters. Will do a simple NVL check on parameters, nothing more
  * before formatting and submitting the log entry. Will log own exceptions but not raise those exceptions.
  * Will set log type to SOSL_CONSTANTS.LOG_INFO_TYPE.
  *
  * @param p_caller The full name of function, procedure or package that should be logged. Case sensitive.
  * @param p_category The log category for the function, procedure or package. Case sensitive.
  * @param p_short_msg The short info message, preferably smaller than 4000 chars. Will be formatted using p_caller.
  * @param p_full_msg The complete info message, with details. Will not be formatted but may contain parts of p_short_msg, if message is longer than 4000 chars.
  */
  PROCEDURE minimal_info_log( p_caller     IN VARCHAR2
                            , p_category   IN VARCHAR2
                            , p_short_msg  IN VARCHAR2
                            , p_full_msg   IN CLOB      DEFAULT NULL
                            )
  ;
  PROCEDURE minimal_info_log( p_caller     IN VARCHAR2
                            , p_category   IN VARCHAR2
                            , p_short_msg  IN VARCHAR2
                            , p_full_msg   IN VARCHAR2
                            )
  ;

  /* PROCEDURE SOSL_LOG.MINIMAL_WARNING_LOG
  * Prepared and standardize logging for warning with reduced parameters. Will do a simple NVL check on parameters, nothing more
  * before formatting and submitting the log entry. Will log own exceptions but not raise those exceptions.
  * Will set log type to SOSL_CONSTANTS.LOG_WARNING_TYPE.
  *
  * @param p_caller The full name of function, procedure or package that should be logged. Case sensitive.
  * @param p_category The log category for the function, procedure or package. Case sensitive.
  * @param p_short_msg The short warning message, preferably smaller than 4000 chars. Will be formatted using p_caller.
  * @param p_full_msg The complete warning message, with details. Will not be formatted but may contain parts of p_short_msg, if message is longer than 4000 chars.
  */
  PROCEDURE minimal_warning_log( p_caller     IN VARCHAR2
                               , p_category   IN VARCHAR2
                               , p_short_msg  IN VARCHAR2
                               , p_full_msg   IN CLOB     DEFAULT NULL
                               )
  ;
  PROCEDURE minimal_warning_log( p_caller     IN VARCHAR2
                               , p_category   IN VARCHAR2
                               , p_short_msg  IN VARCHAR2
                               , p_full_msg   IN VARCHAR2
                               )
  ;

  /* PROCEDURE SOSL_LOG.MINIMAL_SUCCESS_LOG
  * Prepared and standardize logging for success with reduced parameters. Will do a simple NVL check on parameters, nothing more
  * before formatting and submitting the log entry. Will log own exceptions but not raise those exceptions.
  * Will set log type to SOSL_CONSTANTS.LOG_SUCCESS_TYPE.
  *
  * @param p_caller The full name of function, procedure or package that should be logged. Case sensitive.
  * @param p_category The log category for the function, procedure or package. Case sensitive.
  * @param p_short_msg The short success message, preferably smaller than 4000 chars. Will be formatted using p_caller.
  * @param p_full_msg The complete success message, with details. Will not be formatted but may contain parts of p_short_msg, if message is longer than 4000 chars.
  */
  PROCEDURE minimal_success_log( p_caller     IN VARCHAR2
                               , p_category   IN VARCHAR2
                               , p_short_msg  IN VARCHAR2
                               , p_full_msg   IN CLOB     DEFAULT NULL
                               )
  ;
  PROCEDURE minimal_success_log( p_caller     IN VARCHAR2
                               , p_category   IN VARCHAR2
                               , p_short_msg  IN VARCHAR2
                               , p_full_msg   IN VARCHAR2
                               )
  ;

  /* PROCEDURE SOSL_LOG.LOG_COLUMN_CHANGE
  * Checks old and new values of a given column for differences and logs the difference. The log type will be WARNING if
  * forbidden is TRUE, otherwise INFO. Supported types: VARCHAR2, NUMBER, DATE and TIMESTAMP
  *
  * @param p_old_value The old column value.
  * @param p_new_value The new column value.
  * @param p_column_name The name of the table and column, e.g. table.column that is checked for changes. No checks, apart from NULL, only log info. Used as log category.
  * @param p_caller The name of the procedure, package, trigger or function that is calling this procedure. No checks, apart from NULL, only log info.
  * @param p_forbidden Influences the log type, if TRUE the log type is WARNING else the log type is INFO.
  */
  PROCEDURE log_column_change( p_old_value     IN VARCHAR2
                             , p_new_value     IN VARCHAR2
                             , p_column_name   IN VARCHAR2
                             , p_caller        IN VARCHAR2
                             , p_forbidden     IN BOOLEAN  DEFAULT TRUE
                             )
  ;
  PROCEDURE log_column_change( p_old_value     IN NUMBER
                             , p_new_value     IN NUMBER
                             , p_column_name   IN VARCHAR2
                             , p_caller        IN VARCHAR2
                             , p_forbidden     IN BOOLEAN  DEFAULT TRUE
                             )
  ;
  PROCEDURE log_column_change( p_old_value     IN DATE
                             , p_new_value     IN DATE
                             , p_column_name   IN VARCHAR2
                             , p_caller        IN VARCHAR2
                             , p_forbidden     IN BOOLEAN  DEFAULT TRUE
                             )
  ;
  PROCEDURE log_column_change( p_old_value     IN TIMESTAMP
                             , p_new_value     IN TIMESTAMP
                             , p_column_name   IN VARCHAR2
                             , p_caller        IN VARCHAR2
                             , p_forbidden     IN BOOLEAN  DEFAULT TRUE
                             )
  ;

END;
/

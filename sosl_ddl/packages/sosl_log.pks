-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Basic logging package, dependencies only to sosl_server_log.
CREATE OR REPLACE PACKAGE sosl_log
AS
  /**
  * This package contains basic functions and procedures used by the Simple Oracle Script Loader for managing logging.
  * Apart from sosl_server_log table, there are no dependencies, severe exceptions must be catched or handled by the caller.
  * The interface has as well functions and procedures. Functions inform about success or error, whereas procedure exceptions
  * must be handled by the caller.
  *
  * CURRENT ORACLE error: NOCOPY for IN parameters creates compile errors, whereas documentation allows IN NOCOPY var. Any
  * CLOB handling errors are possibly caused by the inability to provide a CLOB as reference.
  */

  /*====================================== start internal functions made visible for testing ======================================*/
  /* PROCEDURE LOG_FALLBACK
  * This procedure tries some fallback actions, if logging raised an exception. It will not throw an exception. It will try to log the error in
  * SOSL_SERVER_LOG, SOSLERRORLOG, SPERRORLOG or, if everything fails output the error via DBMS_OUTPUT. As we can't determine if the message contains
  * an illegal character forcing the exception, the caller should transfer SQLERRM and verify the transmitted content before passing it to this procedure
  * or avoid transmitting parameters which should cause errors. If error could be logged to one of the tables, it can be found in this tables with
  * identifier SOSL_LOG. It will not prevent the exception, only try to log it somewhere, where it could be found without needing to analyze the db server
  * logs. Everything runs as autonomous transaction. DO NOT USE THIS PROCEDURE. It is internal for this package.
  *
  * @param p_script The package function or procedure causing the error, e.g. SOSL_LOG.LOG_EVENT.
  * @param p_identifier The identifier for this error. Saved in SOSL_IDENTIFIER in SOSL_SERVER_LOG or IDENTIFIER in the error log tables.
  * @param p_message The message to save. Reduce it to SQLERRM if possible.
  */
  PROCEDURE log_fallback( p_script      IN VARCHAR2
                        , p_identifier  IN VARCHAR2
                        , p_message     IN VARCHAR2
                        )
  ;
  /* PROCEDURE LOG_EVENT
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
                     , p_caller           IN VARCHAR2
                     , p_run_id           IN NUMBER
                     , p_full_message     IN CLOB
                     )
  ;
/*====================================== end internal functions made visible for testing ======================================*/

  /* PROCEDURE FULL_LOG
  * Procedure with all parameters for logging. Will check parameters before logging. You should at least set also p_log_category
  * and p_caller, to be able to assign the log entry to a specific event and object. On parameter errors a separate log entry is
  * created. Intention is to write a log in any case and not throw any exception. This still may happen on main system malfunctions
  * but is limited to this events.
  *
  * @param p_message The message to log. Limited to 4000 chars. If longer it is split and rest is stored in full_message CLOB by trigger. If NULL p_full_message must be provided.
  * @param p_log_type The log type is basically defined by SOSL_SYS. Currently: INFO, WARNING, ERROR, FATAL, SUCCESS. Will be set to ERROR if not valid.
  * @param p_log_category An optional logging category.
  * @param p_caller Caller identification if available, to distinguish database processes from SOSL CMD server processes or external usage.
  * @param p_guid The GUID the process is running with. Can be used as LIKE reference on SOSLERRORLOG. Most likely used by CMD server.
  * @param p_sosl_identifier The exact identifier for SOSLERRORLOG if available. Most likely used by CMD server.
  * @param p_executor_id The associated executor id if available. Used as well by CMD server and SOSL packages and functions.
  * @param p_ext_script_id The (external) script id if available. Used as well by CMD server and SOSL packages and functions.
  * @param p_run_id The associated run id if available. Most likely used by SOSL packages and functions.
  * @param p_full_message The full message as CLOB if the message size exceeds the PLSQL limit of 32767 bytes. Must be given if p_message is NULL.
  */
  PROCEDURE full_log( p_message          IN VARCHAR2
                    , p_log_type         IN VARCHAR2    DEFAULT sosl_sys.INFO_TYPE
                    , p_log_category     IN VARCHAR2    DEFAULT NULL
                    , p_caller           IN VARCHAR2    DEFAULT NULL
                    , p_guid             IN VARCHAR2    DEFAULT NULL
                    , p_sosl_identifier  IN VARCHAR2    DEFAULT NULL
                    , p_executor_id      IN NUMBER      DEFAULT NULL
                    , p_ext_script_id    IN VARCHAR2    DEFAULT NULL
                    , p_run_id           IN NUMBER      DEFAULT NULL
                    , p_full_message     IN CLOB        DEFAULT NULL
                    )
  ;

  PROCEDURE cmd_log( p_message          IN VARCHAR2
                   , p_log_type         IN VARCHAR2     DEFAULT sosl_sys.INFO_TYPE
                   , p_caller           IN VARCHAR2     DEFAULT NULL
                   , p_guid             IN VARCHAR2     DEFAULT NULL
                   , p_sosl_identifier  IN VARCHAR2     DEFAULT NULL
                   , p_executor_id      IN NUMBER       DEFAULT NULL
                   , p_ext_script_id    IN VARCHAR2     DEFAULT NULL
                   , p_full_message     IN CLOB         DEFAULT NULL
                   )
  ;

END;
/
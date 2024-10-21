-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Basic logging package, dependencies only to sosl_server_log and sosl_sys.
CREATE OR REPLACE PACKAGE sosl_log
AS
  /**
  * This package contains basic functions and procedures used by the Simple Oracle Script Loader for managing logging.
  * Apart from sosl_server_log table, there are no dependencies, severe exceptions must be catched or handled by the caller.
  * The interface has as well functions and procedures. Functions inform about success or error, whereas procedure exceptions
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
  * @param p_run_id The associated run id if available. Most likely used by SOSL packages and functions.
  * @param p_full_message The full message as CLOB if the message size exceeds the PLSQL limit of 32767 bytes. Must be given if p_message is NULL.
  */
  PROCEDURE full_log( p_message          IN VARCHAR2
                    , p_log_type         IN VARCHAR2    DEFAULT sosl_sys.INFO_TYPE
                    , p_log_category     IN VARCHAR2    DEFAULT 'not set'
                    , p_caller           IN VARCHAR2    DEFAULT NULL
                    , p_guid             IN VARCHAR2    DEFAULT NULL
                    , p_sosl_identifier  IN VARCHAR2    DEFAULT NULL
                    , p_executor_id      IN NUMBER      DEFAULT NULL
                    , p_ext_script_id    IN VARCHAR2    DEFAULT NULL
                    , p_run_id           IN NUMBER      DEFAULT NULL
                    , p_full_message     IN CLOB        DEFAULT NULL
                    )
  ;

  /* FUNCTION SOSL_LOG.DUMMY_MAIL
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

END;
/
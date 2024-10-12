-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Basic logging package, dependencies only to sosl_server_log.
CREATE OR REPLACE PACKAGE sosl_log
AS
  /**
  * This package contains basic functions and procedures used by the Simple Oracle Script Loader for managing logging.
  * Apart from sosl_server_log table, there are no dependencies, severe exceptions must be catched or handled by the caller.
  * The interface has as well functions and procedures. Functions inform about success or error, whereas procedure exceptions
  * must be handled by the caller.
  */

  /*====================================== start internal functions made visible for testing ======================================*/
  /* PROCEDURE LOG_EVENT
  * Writes a log entry as autonomous transaction. This is the internal base procedure, exposed for testing.
  * If on errors writing log entries is not possible the procedure hands the exception to the caller. This is the pure insert without
  * any chacks. It takes the values as given and table may trigger exceptions. It is recommended to use the provided interfaces for logging.
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
                     , p_ext_script_id    IN NUMBER
                     , p_caller           IN VARCHAR2
                     , p_run_id           IN NUMBER
                     , p_full_message     IN CLOB
                     )
  ;
/*====================================== end internal functions made visible for testing ======================================*/

END;
/
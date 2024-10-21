-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Basic sys util package not using data objects of the Simple Oracle Script Loader, no dependencies.
CREATE OR REPLACE PACKAGE sosl_sys
AS
  /**
  * This package contains basic functions and procedures used by the Simple Oracle Script Loader that have no dependencies on any SOSL object.
  * As there are no dependencies, exceptions must be catched or handled by the caller. No logging for this functions and procedures.
  * For complex functions and procedures consider to put them in SOSL_UTIL where you have access and possibilities to log errors.
  */

  /*====================================== start package constants used by SOSL ======================================*/
  -- define log_type constants used in SOSL_SERVER_LOG
  ERROR_TYPE     CONSTANT CHAR(5) := 'ERROR';
  WARNING_TYPE   CONSTANT CHAR(7) := 'WARNING';
  FATAL_TYPE     CONSTANT CHAR(5) := 'FATAL';
  INFO_TYPE      CONSTANT CHAR(4) := 'INFO';
  SUCCESS_TYPE   CONSTANT CHAR(7) := 'SUCCESS';
  -- Generic n/a type. Should be different from table defaults like 'not set' as table triggers interpret their DDL default value as fallback
  -- to set default values using package variables, which is not supported in table DDL by Oracle using DEFAULT. Packages may use variables
  -- from other packages in DEFAULT declarations.
  NA_TYPE        CONSTANT CHAR(3) := 'n/a';
  -- numerical equations to TRUE/YES and FALSE/NO
  YES            CONSTANT INTEGER := 1;
  NO             CONSTANT INTEGER := 0;
  -- default error numeric expression, that is returned by functions to indicate an error had occured
  ERR_NUM        CONSTANT INTEGER := -1;
  -- default success numeric expression, that is returned by functions to indicate processing was successful
  SUCCESS_NUM    CONSTANT INTEGER := 0;
  /*====================================== end package constants used by SOSL ======================================*/

  /* FUNCTION SOSL_SYS.LOG_TYPE_VALID
  * Central function to check the log type. Currently supports INFO, WARNING, ERROR, FATAL, SUCCESS. If log types should get expanded
  * adjust this function first and probably the default value for SOSL_SERVER_LOG.
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

  /* FUNCTION SOSL_SYS.GET_VALID_LOG_TYPE
  * Verifies an given log type, returns either the given log type as upper case or the defined error default.
  *
  * @param p_log_type The log type to verify and return. Case insensitive.
  * @param p_error_default The alternative log type to return, if the log type is invalid. Must be a valid log type and not INFO or SUCCESS. If invalid, FATAL is returned.
  *
  * @return The valid log type as upper case on success. The valid error default if log type not supported. FATAL if the error default is invalid.
  */
  FUNCTION get_valid_log_type( p_log_type       IN VARCHAR2
                             , p_error_default  IN VARCHAR2 DEFAULT sosl_sys.ERROR_TYPE
                             )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;

  /* FUNCTION SOSL_SYS.DISTRIBUTE
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

  /* FUNCTION SOSL_SYS.TXT_BOOLEAN
  * Provides text values to display instead of BOOLEAN or NUMBER values interpreted as BOOLEAN. Numbers are interpreted
  * similar to Oracle SQL, where 0 is FALSE and 1 is TRUE. 1 is considered as TRUE, any other value as FALSE. NULL values
  * are interpreted as sosl_sys.NA_TYPE. Maximum 10 characters for TRUE/FALSE equation.
  *
  * @param p_bool The BOOLEAN or NUMBER value that should be interpreted.
  * @param p_true The text equation for TRUE, maximum 10 characters. Longer strings get cut. Case is not controlled.
  * @param p_false The text equation for FALSE, maximum 10 characters. Longer strings get cut. Case is not controlled.
  *
  * @return The text equation for the given p_bool value.
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

  /* FUNCTION SOSL_SYS.YES_NO
  * A simple wrapper for txt_boolean with YES/NO instead of TRUE/FALSE.
  *
  * @param p_bool The BOOLEAN or NUMBER value that should be interpreted.
  * @param p_true The text equation for TRUE, maximum 10 characters. Longer strings get cut. Case is not controlled.
  * @param p_false The text equation for FALSE, maximum 10 characters. Longer strings get cut. Case is not controlled.
  *
  * @return The text equation for the given p_bool value.
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

  /* FUNCTION SOSL_SYS.UTC_MAIL_DATE
  * Returns the current date timestamp as a formatted string for date values in mail.
  *
  * @return A date string conform to RFC5322 for using mail.
  *
  * @see https://datatracker.ietf.org/doc/html/rfc5322
  */
  FUNCTION utc_mail_date
    RETURN VARCHAR2
  ;

  /* FUNCTION SOSL_SYS.FORMAT_MAIL
  * This function formats a mail message conforming to RFC5322. The content of p_message is not checked against RFC. This is
  * the repsonsibility of the user. This is for small messages that do not exceed 32k in total.
  *
  * @param p_sender The valid mail sender address, e.g. mail.user@some.org.
  * @param p_recipients The semicolon separated list of mail recipient addresses.
  * @param p_subject A preferablly short subject for the mail.
  * @param p_message The correctly formatted mail message.
  *
  * @return A formatted string with complete mail message that can be used with RFC compliant mail servers.
  */
  FUNCTION format_mail( p_sender      IN VARCHAR2
                      , p_recipients  IN VARCHAR2
                      , p_subject     IN VARCHAR2
                      , p_message     IN VARCHAR2
                      )
    RETURN VARCHAR2
  ;

END;
/
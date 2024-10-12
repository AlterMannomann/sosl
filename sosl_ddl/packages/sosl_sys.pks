-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Basic sys util package not using data objects of the Simple Oracle Script Loader, no dependencies.
CREATE OR REPLACE PACKAGE sosl_sys
AS
  /**
  * This package contains basic functions and procedures used by the Simple Oracle Script Loader that have no dependencies on any SOSL object.
  * As there are no dependencies, exceptions must be catched or handled by the caller. No logging for this functions and procedures.
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
  /*====================================== end package constants used by SOSL ======================================*/

  /*====================================== start internal functions made visible for testing ======================================*/
  /* PROCEDURE SPLIT_FUNCTION_NAME
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
  /*====================================== end internal functions made visible for testing ======================================*/

  /* FUNCTION HAS_DB_USER
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

  /* FUNCTION HAS_FUNCTION
  * Checks if a given function or package function name is visible for SOSL by checking ALL_ATTRIBUTES.
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

  /* FUNCTION LOG_TYPE_VALID
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

  /* FUNCTION GET_VALID_LOG_TYPE
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
END;
/
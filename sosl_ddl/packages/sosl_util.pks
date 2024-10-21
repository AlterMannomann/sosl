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

  /* FUNCTION SOSL_SYS.HAS_FUNCTION
  * Checks if a given function or package function name is visible for SOSL by checking ALL_ATTRIBUTES. The package SOSL_API is
  * excluded from the search to avoid references in SOSL_EXECUTOR.
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

  /*FUNCTION SOSL_SYS.GET_COL_LENGTH
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

  /* FUNCTION SOSL_SYS.GET_COL_TYPE
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

  /* FUNCTION SOSL_SYS.CHECK_COL
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

END;
/
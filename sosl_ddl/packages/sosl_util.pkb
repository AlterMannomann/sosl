-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE PACKAGE BODY sosl_util
AS
  -- for description see header file
  PROCEDURE split_function_name( p_function_name IN  VARCHAR2
                               , p_package       OUT VARCHAR2
                               , p_function      OUT VARCHAR2
                               )
  IS
  BEGIN
    IF INSTR(p_function_name, '.') > 0
    THEN
      p_package   := TRIM(SUBSTR(p_function_name, 1, INSTR(p_function_name, '.') -1));
      p_function  := TRIM(SUBSTR(p_function_name, INSTR(p_function_name, '.') +1));
    ELSE
      p_package   := NULL;
      p_function  := TRIM(p_function_name);
    END IF;
  END split_function_name;

  FUNCTION has_db_user(p_username IN VARCHAR2)
    RETURN BOOLEAN
  IS
    l_has_user  NUMBER;
    l_return    BOOLEAN;
  BEGIN
    l_return := FALSE;
    SELECT COUNT(*) INTO l_has_user FROM all_users WHERE username = p_username;
    IF l_has_user != 0
    THEN
      l_return := TRUE;
    END IF;
    RETURN l_return;
  END has_db_user;

  FUNCTION has_function( p_owner          IN VARCHAR2
                       , p_function_name  IN VARCHAR2
                       , p_datatype       IN VARCHAR2
                       )
    RETURN BOOLEAN
  IS
    l_has_function  NUMBER;
    l_package       VARCHAR2(128);
    l_function      VARCHAR2(128);
    l_return        BOOLEAN;
  BEGIN
    l_return := FALSE;
    split_function_name(p_function_name, l_package, l_function);
    SELECT COUNT(*)
      INTO l_has_function
      FROM all_arguments
     WHERE position                   = 0                               -- only functions
       AND argument_name              IS NULL                           -- only functions
       AND data_type                  = p_datatype
       AND owner                      = UPPER(p_owner)
       AND NVL(package_name, 'N/A')   = NVL(UPPER(l_package), 'N/A')    -- may not contain a package name
       AND object_name                = UPPER(l_function)
       AND package_name              != 'SOSL'                          -- exclude base package should never be referenced
    ;
    IF l_has_function != 0
    THEN
      l_return := TRUE;
    END IF;
    RETURN l_return;
  END has_function;

  FUNCTION get_col_length( p_table  IN VARCHAR2
                         , p_column IN VARCHAR2
                         )
    RETURN INTEGER
  IS
    l_return          INTEGER;
    l_has_column      INTEGER;
    l_data_type       user_tab_columns.data_type%TYPE;
    l_data_length     user_tab_columns.data_length%TYPE;
    l_data_precision  user_tab_columns.data_precision%TYPE;
    l_data_scale      user_tab_columns.data_scale%TYPE;
  BEGIN
    l_return := -1;
    SELECT COUNT(*) INTO l_has_column FROM user_tab_columns WHERE table_name = UPPER(p_table) AND column_name = UPPER(p_column);
    IF l_has_column = 1
    THEN
      -- column match calculate length
      SELECT data_type
           , data_length
           , data_precision
           , data_scale
        INTO l_data_type
           , l_data_length
           , l_data_precision
           , l_data_scale
        FROM user_tab_columns
       WHERE table_name  = UPPER(p_table)
         AND column_name = UPPER(p_column)
      ;
      IF l_data_type = 'NUMBER'
      THEN
        IF l_data_scale != 0
        THEN
          -- consider delimiter
          l_return := l_data_precision + l_data_scale;
        ELSE
          l_return := l_data_precision;
        END IF;
      ELSIF l_data_type = 'CLOB'
      THEN
        l_return := 32767;
      ELSE
        l_return := l_data_length;
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN sosl_sys.ERR_NUM;
  END get_col_length;

  FUNCTION get_col_type( p_table  IN VARCHAR2
                       , p_column IN VARCHAR2
                       )
    RETURN VARCHAR2
  IS
    l_return      VARCHAR2(128);
    l_has_column  INTEGER;
    l_data_type   user_tab_columns.data_type%TYPE;
  BEGIN
    l_return := sosl_sys.NA_TYPE;
    SELECT COUNT(*) INTO l_has_column FROM user_tab_columns WHERE table_name = UPPER(p_table) AND column_name = UPPER(p_column);
    IF l_has_column = 1
    THEN
      -- column match get data type
      SELECT data_type
        INTO l_return
        FROM user_tab_columns
       WHERE table_name  = UPPER(p_table)
         AND column_name = UPPER(p_column)
      ;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN sosl_sys.NA_TYPE;
  END get_col_type;

  FUNCTION check_col( p_table  IN VARCHAR2
                    , p_column IN VARCHAR2
                    , p_value  IN VARCHAR2
                    )
    RETURN BOOLEAN
  IS
    l_return  BOOLEAN;
  BEGIN
    l_return := FALSE;
    IF sosl_util.get_col_type(p_table, p_column) IN ('VARCHAR2', 'CHAR')
    THEN
      IF NVL(LENGTH(p_value), 0) <= sosl_util.get_col_length(p_table, p_column)
      THEN
        l_return := TRUE;
      END IF;
    END IF;
    RETURN l_return;
  END check_col; -- VARCHAR2 variant

  FUNCTION check_col( p_table  IN VARCHAR2
                    , p_column IN VARCHAR2
                    , p_value  IN NUMBER
                    )
    RETURN BOOLEAN
  IS
    l_return  BOOLEAN;
    l_number  VARCHAR2(128);
  BEGIN
    l_return := FALSE;
    IF sosl_util.get_col_type(p_table, p_column) = 'NUMBER'
    THEN
      l_number := REGEXP_REPLACE(TO_CHAR(p_value), '[^0-9]', '');
      IF NVL(LENGTH(l_number), 0) <= sosl_util.get_col_length(p_table, p_column)
      THEN
        l_return := TRUE;
      END IF;
    END IF;
    RETURN l_return;
  END check_col; -- NUMBER variant

END;
/
-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE OR REPLACE PACKAGE BODY sosl_sys
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
      p_function  := TRIM(SUBSTR(p_function_name, INSTR(p_function_name, '.') +1, INSTR(p_function_name, '.', 1, 2) - INSTR(p_function_name, '.') -1));
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
    sosl_sys.split_function_name(p_function_name, l_package, l_function);
    SELECT COUNT(*)
      INTO l_has_function
      FROM all_arguments
     WHERE position                   = 0                               -- only functions
       AND argument_name              IS NULL                           -- only functions
       AND data_type                  = p_datatype
       AND owner                      = p_owner
       AND NVL(package_name, 'N/A')   = NVL(UPPER(l_package), 'N/A')    -- may not contain a package name
       AND object_name                = UPPER(l_function)
    ;
    IF l_has_function != 0
    THEN
      l_return := TRUE;
    END IF;
    RETURN l_return;
  END has_function;

  FUNCTION log_type_valid(p_log_type IN VARCHAR2)
    RETURN BOOLEAN
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
    l_return  BOOLEAN;
  BEGIN
    l_return := FALSE;
    IF UPPER(p_log_type) IN ( sosl_sys.INFO_TYPE
                            , sosl_sys.WARNING_TYPE
                            , sosl_sys.ERROR_TYPE
                            , sosl_sys.FATAL_TYPE
                            , sosl_sys.SUCCESS_TYPE
                            )
    THEN
      l_return := TRUE;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN FALSE;
  END log_type_valid;

  FUNCTION get_valid_log_type( p_log_type       IN VARCHAR2
                             , p_error_default  IN VARCHAR2 DEFAULT sosl_sys.ERROR_TYPE
                             )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
    l_return  VARCHAR2(30);
  BEGIN
    l_return := sosl_sys.FATAL_TYPE;
    IF log_type_valid(p_log_type)
    THEN
      l_return := UPPER(p_log_type);
    ELSE
      IF      log_type_valid(p_error_default)
         AND  UPPER(p_error_default) NOT IN ( sosl_sys.INFO_TYPE
                                            , sosl_sys.SUCCESS_TYPE
                                            )
      THEN
        l_return := UPPER(p_error_default);
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN sosl_sys.FATAL_TYPE;
  END get_valid_log_type;

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
      RETURN -1;
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

  FUNCTION distribute( p_string            IN OUT         VARCHAR2
                     , p_clob              IN OUT NOCOPY  CLOB
                     , p_max_string_length IN             INTEGER   DEFAULT 4000
                     , p_split_end         IN             VARCHAR2  DEFAULT '...'
                     , p_split_start       IN             VARCHAR2  DEFAULT '...'
                     , p_delimiter         IN             VARCHAR2  DEFAULT ' - '
                     )
    RETURN BOOLEAN
  IS
    l_string  VARCHAR2(32767);
  BEGIN
    IF     (p_string IS NULL OR NVL(LENGTH(TRIM(p_string)), 0) = 0)
       AND (p_clob   IS NULL OR NVL(LENGTH(TRIM(p_clob)), 0) = 0)
    THEN
      RETURN FALSE;
    END IF;
    IF     p_string IS NOT NULL AND NVL(LENGTH(TRIM(p_string)), 0) > 0
       AND p_clob   IS NOT NULL AND NVL(LENGTH(TRIM(p_clob)), 0) > 0
    THEN
      IF LENGTH(p_string) > p_max_string_length
      THEN
        -- need to split
        l_string := p_split_start || SUBSTR(p_string, (p_max_string_length - LENGTH(p_split_end) + 1)) || p_delimiter;
        p_string := SUBSTR(p_string, 1, (p_max_string_length - LENGTH(p_split_end))) || p_split_end;
        p_clob   := l_string || p_clob;
      END IF;
      RETURN TRUE;
    END IF;
    IF p_string IS NOT NULL AND NVL(LENGTH(TRIM(p_string)), 0) > 0
    THEN
      IF LENGTH(p_string) > p_max_string_length
      THEN
        -- need to split
        l_string := p_split_start || SUBSTR(p_string, (p_max_string_length - LENGTH(p_split_end) + 1));
        p_string := SUBSTR(p_string, 1, (p_max_string_length - LENGTH(p_split_end))) || p_split_end;
        p_clob   := TO_CLOB(l_string);
      ELSE
        p_clob := TO_CLOB(l_string);
      END IF;
      RETURN TRUE;
    END IF;
    IF p_clob IS NOT NULL AND NVL(LENGTH(TRIM(p_clob)), 0) > 0
    THEN
      IF LENGTH(p_clob) > p_max_string_length
      THEN
        p_string := TO_CHAR(SUBSTR(p_clob, 1, (p_max_string_length - LENGTH(p_split_end))) || p_split_end);
      ELSE
        p_string := TO_CHAR(p_clob);
      END IF;
      RETURN TRUE;
    END IF;
    -- should not reach this point
    p_string := 'ERROR sosl_sys.distribute: INCOMPLETE LOGIC';
    RETURN FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      p_string := TRIM(SUBSTR(SQLERRM, 1, 4000));
      RETURN FALSE;
  END distribute;

  FUNCTION check_col( p_table  IN VARCHAR2
                    , p_column IN VARCHAR2
                    , p_value  IN VARCHAR2
                    )
    RETURN BOOLEAN
  IS
    l_return  BOOLEAN;
  BEGIN
    l_return := FALSE;
    IF sosl_sys.get_col_type(p_table, p_column) IN ('VARCHAR2', 'CHAR')
    THEN
      IF NVL(LENGTH(p_value), 0) <= sosl_sys.get_col_length(p_table, p_column)
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
    IF sosl_sys.get_col_type(p_table, p_column) = 'NUMBER'
    THEN
      l_number := REGEXP_REPLACE(TO_CHAR(p_value), '[^0-9]', '');
      IF NVL(LENGTH(l_number), 0) <= sosl_sys.get_col_length(p_table, p_column)
      THEN
        l_return := TRUE;
      END IF;
    END IF;
    RETURN l_return;
  END check_col; -- NUMBER variant

  FUNCTION txt_boolean( p_bool   IN BOOLEAN
                      , p_true   IN VARCHAR2 DEFAULT 'TRUE'
                      , p_false  IN VARCHAR2 DEFAULT 'FALSE'
                      )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    IF p_bool
    THEN
      RETURN TRIM(SUBSTR(NVL(p_true, 'TRUE'), 1, 10));
    ELSE
      RETURN TRIM(SUBSTR(NVL(p_false, 'FALSE'), 1, 10));
    END IF;
  END txt_boolean; -- boolean input

  FUNCTION txt_boolean( p_bool   IN NUMBER
                      , p_true   IN VARCHAR2 DEFAULT 'TRUE'
                      , p_false  IN VARCHAR2 DEFAULT 'FALSE'
                      )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_sys.txt_boolean((p_bool = 1), p_true, p_false);
  END txt_boolean; -- number input

  FUNCTION yes_no( p_bool   IN BOOLEAN
                 , p_true   IN VARCHAR2 DEFAULT 'YES'
                 , p_false  IN VARCHAR2 DEFAULT 'NO'
                 )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_sys.txt_boolean(p_bool, p_true, p_false);
  END yes_no;

  FUNCTION yes_no( p_bool   IN NUMBER
                 , p_true   IN VARCHAR2 DEFAULT 'YES'
                 , p_false  IN VARCHAR2 DEFAULT 'NO'
                 )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_sys.txt_boolean((p_bool = 1), p_true, p_false);
  END yes_no;

END;
/
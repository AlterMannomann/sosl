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

END;
/
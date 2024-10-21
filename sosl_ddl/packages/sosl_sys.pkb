-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE PACKAGE BODY sosl_sys
AS
  -- for description see header file
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

  FUNCTION utc_mail_date
    RETURN VARCHAR2
  IS
    l_date VARCHAR2(500);
  BEGIN
    l_date := TO_CHAR(SYSTIMESTAMP AT TIME ZONE SESSIONTIMEZONE, 'Dy, DD Mon YYYY HH24:MI:SS TZHTZM');
    RETURN l_date;
  END utc_mail_date;

  FUNCTION format_mail( p_sender      IN VARCHAR2
                      , p_recipients  IN VARCHAR2
                      , p_subject     IN VARCHAR2
                      , p_message     IN VARCHAR2
                      )
    RETURN VARCHAR2
  IS
    l_crlf          VARCHAR2(2)       := CHR(13) || CHR(10);
    l_mail_message  VARCHAR2(32767);
  BEGIN
    l_mail_message := 'From: ' || p_sender || l_crlf ||
                      'To: ' || p_recipients || l_crlf ||
                      'Date: ' || sosl_sys.utc_mail_date || l_crlf ||
                      'Subject: ' || p_subject || l_crlf ||
                      p_message
    ;
    RETURN l_mail_message;
  END format_mail;

END;
/
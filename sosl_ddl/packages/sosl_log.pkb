-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE PACKAGE BODY sosl_log
AS
  -- for description see header file
  PROCEDURE log_fallback( p_script      IN VARCHAR2
                        , p_identifier  IN VARCHAR2
                        , p_message     IN VARCHAR2
                        )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_saved BOOLEAN;
  BEGIN
    l_saved := FALSE;
    -- try to save information in tables probably available
    BEGIN
      INSERT INTO sosl_server_log
        ( message
        , log_type
        , log_category
        , sosl_identifier
        , caller
        )
        VALUES
          ( p_message
          , sosl_constants.LOG_FATAL_TYPE
          , 'SOSL_LOG internal error'
          , p_identifier
          , p_script
          )
      ;
      COMMIT;
      l_saved := TRUE;
    EXCEPTION
      WHEN OTHERS THEN
        l_saved := FALSE;
    END;
    IF NOT l_saved
    THEN
      BEGIN
        INSERT INTO soslerrorlog
          ( message
          , identifier
          , script
          , username
          , timestamp
          )
          VALUES
            ( p_message
            , p_identifier
            , p_script
            , SYS_CONTEXT('USERENV', 'SESSION_USER')
            , SYSTIMESTAMP
            )
        ;
        COMMIT;
        l_saved := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          l_saved := FALSE;
      END;
    END IF;
    IF NOT l_saved
    THEN
      BEGIN
        INSERT INTO sperrorlog
          ( message
          , identifier
          , script
          , username
          , timestamp
          )
          VALUES
            ( p_message
            , p_identifier
            , p_script
            , SYS_CONTEXT('USERENV', 'SESSION_USER')
            , SYSTIMESTAMP
            )
        ;
        COMMIT;
        l_saved := TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          l_saved := FALSE;
      END;
    END IF;
    -- all inserts failed, use DBMS_OUTPUT
    IF NOT l_saved
    THEN
      DBMS_OUTPUT.PUT_LINE('SOSL_LOG.LOG_FALLBACK could not save error. Fatal error in ' || p_script || ' error: ' || p_message);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      -- fallback failed, let caller handle and raise the error, do nothing therefore.
      NULL;
  END log_fallback;

  PROCEDURE log_event( p_message          IN VARCHAR2
                     , p_log_type         IN VARCHAR2
                     , p_log_category     IN VARCHAR2
                     , p_guid             IN VARCHAR2
                     , p_sosl_identifier  IN VARCHAR2
                     , p_executor_id      IN NUMBER
                     , p_ext_script_id    IN VARCHAR2
                     , p_script_file      IN VARCHAR2
                     , p_caller           IN VARCHAR2
                     , p_run_id           IN NUMBER
                     , p_full_message     IN CLOB
                     )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO sosl_server_log
      ( message
      , log_type
      , log_category
      , guid
      , sosl_identifier
      , executor_id
      , ext_script_id
      , script_file
      , caller
      , run_id
      , full_message
      )
      VALUES
        ( p_message
        , p_log_type
        , p_log_category
        , p_guid
        , p_sosl_identifier
        , p_executor_id
        , p_ext_script_id
        , p_script_file
        , p_caller
        , p_run_id
        , p_full_message
        )
    ;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      -- try fallback
      log_fallback('sosl_log.log_event', 'SOSL_LOG', SQLERRM);
      -- try ROLLBACK
      ROLLBACK;
      -- and raise the error again now
      RAISE;
  END log_event;

  FUNCTION log_type_valid(p_log_type IN VARCHAR2)
    RETURN BOOLEAN
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
    l_return            BOOLEAN;
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.log_type_valid';
  BEGIN
    l_return := FALSE;
    IF UPPER(p_log_type) IN ( sosl_constants.LOG_INFO_TYPE
                            , sosl_constants.LOG_WARNING_TYPE
                            , sosl_constants.LOG_ERROR_TYPE
                            , sosl_constants.LOG_FATAL_TYPE
                            , sosl_constants.LOG_SUCCESS_TYPE
                            )
    THEN
      l_return := TRUE;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      log_event( p_message => l_self_caller || ': Unhandled EXCEPTION = ' || TRIM(SUBSTR(SQLERRM, 1, 500)) || CASE WHEN LENGTH(SQLERRM) > 500 THEN ' ... see full_message for complete details.' END
               , p_log_type => sosl_constants.LOG_FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_script_file => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- full details
               , p_full_message => SQLERRM
               )
      ;
      RETURN FALSE;
  END log_type_valid;

  FUNCTION get_valid_log_type( p_log_type       IN VARCHAR2
                             , p_error_default  IN VARCHAR2 DEFAULT sosl_constants.LOG_ERROR_TYPE
                             )
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
    l_return            VARCHAR2(30);
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.get_valid_log_type';
  BEGIN
    l_return := sosl_constants.LOG_FATAL_TYPE;
    IF log_type_valid(p_log_type)
    THEN
      l_return := UPPER(p_log_type);
    ELSE
      IF      log_type_valid(p_error_default)
         AND  UPPER(p_error_default) NOT IN ( sosl_constants.LOG_INFO_TYPE
                                            , sosl_constants.LOG_SUCCESS_TYPE
                                            )
      THEN
        l_return := UPPER(p_error_default);
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      log_event( p_message => l_self_caller || ': Unhandled EXCEPTION = ' || TRIM(SUBSTR(SQLERRM, 1, 500)) || CASE WHEN LENGTH(SQLERRM) > 500 THEN ' ... see full_message for complete details.' END
               , p_log_type => sosl_constants.LOG_FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_script_file => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- full details
               , p_full_message => SQLERRM
               )
      ;
      RETURN sosl_constants.LOG_FATAL_TYPE;
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
    l_string            VARCHAR2(32767);
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.distribute';
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
    log_event( p_message => l_self_caller || ': Logic incomplete. Procedure should exit before and not reach end of procedure'
             , p_log_type => sosl_constants.LOG_FATAL_TYPE
             , p_log_category => l_self_log_category
             , p_guid => NULL
             , p_sosl_identifier => NULL
             , p_executor_id => NULL
             , p_ext_script_id => NULL
             , p_script_file => NULL
             , p_caller => l_self_caller
             , p_run_id => NULL
               -- full details
             , p_full_message => SQLERRM
             )
    ;
    RETURN FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      log_event( p_message => l_self_caller || ': Unhandled EXCEPTION = ' || TRIM(SUBSTR(SQLERRM, 1, 500)) || CASE WHEN LENGTH(SQLERRM) > 500 THEN ' ... see full_message for complete details.' END
               , p_log_type => sosl_constants.LOG_FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_script_file => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- full details
               , p_full_message => SQLERRM
               )
      ;
      RETURN FALSE;
  END distribute;

  PROCEDURE full_log( p_message          IN VARCHAR2
                    , p_log_type         IN VARCHAR2    DEFAULT sosl_constants.LOG_INFO_TYPE
                    , p_log_category     IN VARCHAR2    DEFAULT 'not set'
                    , p_caller           IN VARCHAR2    DEFAULT NULL
                    , p_guid             IN VARCHAR2    DEFAULT NULL
                    , p_sosl_identifier  IN VARCHAR2    DEFAULT NULL
                    , p_executor_id      IN NUMBER      DEFAULT NULL
                    , p_ext_script_id    IN VARCHAR2    DEFAULT NULL
                    , p_script_file      IN VARCHAR2    DEFAULT NULL
                    , p_run_id           IN NUMBER      DEFAULT NULL
                    , p_full_message     IN CLOB        DEFAULT NULL
                    )
  IS
    -- set variables to current type
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.full_log';
    l_log_category      sosl_server_log.log_category%TYPE;
    l_log_type          sosl_server_log.log_type%TYPE;
    l_caller            sosl_server_log.caller%TYPE;
    l_guid              sosl_server_log.guid%TYPE;
    l_sosl_identifier   sosl_server_log.sosl_identifier%TYPE;
    l_executor_id       sosl_server_log.executor_id%TYPE;
    l_ext_script_id     sosl_server_log.ext_script_id%TYPE;
    l_script_file       sosl_server_log.script_file%TYPE;
    l_run_id            sosl_server_log.run_id%TYPE;
    l_col_length        INTEGER;
  BEGIN
    -- basic column checks message splitting is left to table triggers
    l_log_type := sosl_log.get_valid_log_type(p_log_type);
    -- LOG_CATEGORY
    IF NVL(LENGTH(TRIM(p_log_category)), 0) > 256
    THEN
      -- write extra log entry and cut original content to limit
      log_event( p_message => l_self_caller || ': p_log_category length exceeds column length (256) in SOSL_SERVER_LOG. See full message for message causing the error.'
               , p_log_type => sosl_constants.LOG_FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_script_file => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- details and original message
               , p_full_message => ('LOG_CATEGORY: ' || TRIM(p_log_category) || ' length: ' || LENGTH(TRIM(p_log_category)) || ' msg: ' || p_message || ' - ' || p_full_message)
               )
      ;
      l_log_category := SUBSTR(TRIM(p_log_category), 1, 256);
    ELSE
      l_log_category := NVL(TRIM(p_log_category), sosl_constants.GEN_NA_TYPE);
    END IF;
    -- CALLER
    IF NVL(LENGTH(TRIM(p_caller)), 0) > 256
    THEN
      -- write extra log entry and cut original content to limit
      log_event( p_message => l_self_caller || ': p_caller length exceeds column length (256) in SOSL_SERVER_LOG. See full message for message causing the error.'
               , p_log_type => sosl_constants.LOG_FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_script_file => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- details and original message
               , p_full_message => ('CALLER: ' || TRIM(p_caller) || ' length: ' || LENGTH(TRIM(p_caller)) || ' msg: ' || p_message || ' - ' || p_full_message)
               )
      ;
      l_caller := SUBSTR(TRIM(p_caller), 1, 256);
    ELSE
      l_caller := TRIM(p_caller);
    END IF;
    -- GUID
    IF NVL(LENGTH(TRIM(p_guid)), 0) > 64
    THEN
      -- write extra log entry and cut original content to limit
      log_event( p_message => l_self_caller || ': p_guid length exceeds column length (64) in SOSL_SERVER_LOG. See full message for message causing the error.'
               , p_log_type => sosl_constants.LOG_FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_script_file => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- details and original message
               , p_full_message => ('GUID: ' || TRIM(p_guid) || ' length: ' || LENGTH(TRIM(p_guid)) || ' msg: ' || p_message || ' - ' || p_full_message)
               )
      ;
      l_guid := SUBSTR(TRIM(p_guid), 1, 64);
    ELSE
      l_guid := TRIM(p_guid);
    END IF;
    -- SOSL_IDENTIFIER
    IF NVL(LENGTH(TRIM(p_sosl_identifier)), 0) > 256
    THEN
      -- write extra log entry and cut original content to limit
      log_event( p_message => l_self_caller || ': p_sosl_identifier length exceeds column length (256) in SOSL_SERVER_LOG. See full message for message causing the error.'
               , p_log_type => sosl_constants.LOG_FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_script_file => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- details and original message
               , p_full_message => ('SOSL_IDENTIFIER: ' || TRIM(p_sosl_identifier) || ' length: ' || LENGTH(TRIM(p_sosl_identifier)) || ' msg: ' || p_message || ' - ' || p_full_message)
               )
      ;
      l_sosl_identifier := SUBSTR(TRIM(p_sosl_identifier), 1, 256);
    ELSE
      l_sosl_identifier := TRIM(p_sosl_identifier);
    END IF;
    -- EXT_SCRIPT_ID
    IF NVL(LENGTH(TRIM(p_ext_script_id)), 0) > 4000
    THEN
      -- write extra log entry and cut original content to limit
      log_event( p_message => l_self_caller || ': p_ext_script_id length exceeds column length (4000) in SOSL_SERVER_LOG. See full message for message causing the error.'
               , p_log_type => sosl_constants.LOG_FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_script_file => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- details and original message
               , p_full_message => ('EXT_SCRIPT_ID: ' || TRIM(p_ext_script_id) || ' length: ' || LENGTH(TRIM(p_ext_script_id)) || ' msg: ' || p_message || ' - ' || p_full_message)
               )
      ;
      l_ext_script_id := SUBSTR(TRIM(p_ext_script_id), 1, 4000);
    ELSE
      l_ext_script_id := TRIM(p_ext_script_id);
    END IF;
    -- SCRIPT_FILE
    IF NVL(LENGTH(TRIM(p_script_file)), 0) > 4000
    THEN
      -- write extra log entry and cut original content to limit
      log_event( p_message => l_self_caller || ': p_script_file length exceeds column length (4000) in SOSL_SERVER_LOG. See full message for message causing the error.'
               , p_log_type => sosl_constants.LOG_FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_script_file => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- details and original message
               , p_full_message => ('SCRIPT_FILE: ' || TRIM(p_script_file) || ' length: ' || LENGTH(TRIM(p_script_file)) || ' msg: ' || p_message || ' - ' || p_full_message)
               )
      ;
      l_script_file := SUBSTR(TRIM(p_script_file), 1, 4000);
    ELSE
      l_script_file := TRIM(p_script_file);
    END IF;
    -- no check on numbers
    l_executor_id := p_executor_id;
    l_run_id := p_run_id;
    -- try to write the given data to SOSL_SERVER_LOG
    log_event( p_message => p_message
             , p_log_type => l_log_type
             , p_log_category => l_log_category
             , p_guid => l_guid
             , p_sosl_identifier => l_sosl_identifier
             , p_executor_id => l_executor_id
             , p_ext_script_id => l_ext_script_id
             , p_script_file => l_script_file
             , p_caller => l_caller
             , p_run_id => l_run_id
             , p_full_message => p_full_message
             )
    ;
  EXCEPTION
    WHEN OTHERS THEN
      log_event( p_message => l_self_caller || ': Unhandled EXCEPTION = ' || TRIM(SUBSTR(SQLERRM, 1, 500)) || CASE WHEN LENGTH(SQLERRM) > 500 THEN ' ... see full_message for complete details.' END
               , p_log_type => sosl_constants.LOG_FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_script_file => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- full details and original message
               , p_full_message => (SQLERRM || ': ' || p_message)
               )
      ;
  END full_log;

  PROCEDURE exception_log( p_caller     IN VARCHAR2
                         , p_category   IN VARCHAR2
                         , p_sqlerrmsg  IN VARCHAR2
                         )
  IS
    l_category  sosl_server_log.log_category%TYPE;
    l_caller    sosl_server_log.caller%TYPE;
    l_message   VARCHAR2(32767);
  BEGIN
    l_category  := NVL(p_category, sosl_constants.GEN_NA_TYPE);
    l_caller    := NVL(p_caller, sosl_constants.GEN_NA_TYPE);
    l_message   := NVL(p_sqlerrmsg, 'Called sosl_log.exception_log without message.');
    log_event( p_message => l_caller || ': Unhandled EXCEPTION = ' || TRIM(SUBSTR(l_message, 1, 500)) || CASE WHEN LENGTH(l_message) > 500 THEN ' ... see full_message for complete details.' END
             , p_log_type => sosl_constants.LOG_FATAL_TYPE
             , p_log_category => l_category
             , p_guid => NULL
             , p_sosl_identifier => NULL
             , p_executor_id => NULL
             , p_ext_script_id => NULL
             , p_script_file => NULL
             , p_caller => l_caller
             , p_run_id => NULL
               -- full details and original message
             , p_full_message => l_message
             )
    ;
  EXCEPTION
    WHEN OTHERS THEN
      -- no extra trouble if already in exception state
      NULL;
  END exception_log;

  PROCEDURE minimal_error_log( p_caller     IN VARCHAR2
                             , p_category   IN VARCHAR2
                             , p_short_msg  IN VARCHAR2
                             , p_full_msg   IN CLOB     DEFAULT NULL
                             )
  IS
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.minimal_error_log CLOB';
    l_category          sosl_server_log.log_category%TYPE;
    l_caller            sosl_server_log.caller%TYPE;
    l_short_msg         VARCHAR2(32767);
    l_full_msg          CLOB;
  BEGIN
    l_category  := NVL(p_category, sosl_constants.GEN_NA_TYPE);
    l_caller    := NVL(p_caller, sosl_constants.GEN_NA_TYPE);
    IF p_short_msg IS NULL AND p_full_msg IS NULL
    THEN
      l_short_msg := l_caller || ': ERROR = Called sosl_log.minimal_error_log without any message.';
      l_full_msg  := l_caller || ': ERROR = Called sosl_log.minimal_error_log without any message.';
    ELSIF p_short_msg IS NULL AND p_full_msg IS NOT NULL
    THEN
      -- split long message
      l_short_msg := l_caller || ': ERROR = ' || SUBSTR(p_full_msg, 1, 500) || CASE WHEN LENGTH(p_full_msg) > 500 THEN ' ... see full_message for complete details.' END;
      l_full_msg  := p_full_msg;
    ELSIF LENGTH(p_short_msg) > 3600
    THEN
      -- a very long short message, handle the overflow and distribute it to full message, we do not check for 4000 length to have some formatting space
      l_short_msg := l_caller || ': ERROR = ' || SUBSTR(p_short_msg, 1, 500) || ' ... see full_message for complete details.';
      l_full_msg  := '... ' || SUBSTR(p_short_msg, 501) || ' - ' || p_full_msg;
    ELSE
      -- if long message is NULL we do not care, maybe NULL or given, handled as given.
      l_short_msg := l_caller || ': ERROR = ' || p_short_msg;
      l_full_msg  := p_full_msg;
    END IF;
    log_event( p_message => l_short_msg
             , p_log_type => sosl_constants.LOG_ERROR_TYPE
             , p_log_category => l_category
             , p_guid => NULL
             , p_sosl_identifier => NULL
             , p_executor_id => NULL
             , p_ext_script_id => NULL
             , p_script_file => NULL
             , p_caller => l_caller
             , p_run_id => NULL
               -- full details and original message
             , p_full_message => l_full_msg
             )
    ;
  EXCEPTION
    WHEN OTHERS THEN
      -- log exception as we should not be already in exception state, only application error
      -- do not raise again
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
  END minimal_error_log;

  PROCEDURE minimal_error_log( p_caller     IN VARCHAR2
                             , p_category   IN VARCHAR2
                             , p_short_msg  IN VARCHAR2
                             , p_full_msg   IN VARCHAR2
                             )
  IS
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.minimal_error_log VARCHAR2';
  BEGIN
    sosl_log.minimal_error_log(p_caller, p_category, p_short_msg, TO_CLOB(p_full_msg));
  EXCEPTION
    WHEN OTHERS THEN
      -- log exception as we should not be already in exception state, only application error
      -- do not raise again
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
  END minimal_error_log;

  PROCEDURE minimal_info_log( p_caller     IN VARCHAR2
                            , p_category   IN VARCHAR2
                            , p_short_msg  IN VARCHAR2
                            , p_full_msg   IN CLOB      DEFAULT NULL
                            )
  IS
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.minimal_info_log CLOB';
    l_category          sosl_server_log.log_category%TYPE;
    l_caller            sosl_server_log.caller%TYPE;
    l_short_msg         VARCHAR2(32767);
    l_full_msg          CLOB;
  BEGIN
    l_category  := NVL(p_category, sosl_constants.GEN_NA_TYPE);
    l_caller    := NVL(p_caller, sosl_constants.GEN_NA_TYPE);
    IF p_short_msg IS NULL AND p_full_msg IS NULL
    THEN
      l_short_msg := l_caller || ': ERROR = Called sosl_log.minimal_info_log without any message.';
      l_full_msg  := l_caller || ': ERROR = Called sosl_log.minimal_info_log without any message.';
    ELSIF p_short_msg IS NULL AND p_full_msg IS NOT NULL
    THEN
      -- split long message
      l_short_msg := SUBSTR(p_full_msg, 1, 500) || CASE WHEN LENGTH(p_full_msg) > 500 THEN ' ... see full_message for complete details.' END;
      l_full_msg  := p_full_msg;
    ELSIF LENGTH(p_short_msg) > 3600
    THEN
      -- a very long short message, handle the overflow and distribute it to full message, we do not check for 4000 length to have some formatting space
      l_short_msg := SUBSTR(p_short_msg, 1, 500) || ' ... see full_message for complete details.';
      l_full_msg  := '... ' || SUBSTR(p_short_msg, 501) || ' - ' || p_full_msg;
    ELSE
      -- if long message is NULL we do not care, maybe NULL or given, handled as given.
      l_short_msg := p_short_msg;
      l_full_msg  := p_full_msg;
    END IF;
    log_event( p_message => l_short_msg
             , p_log_type => sosl_constants.LOG_INFO_TYPE
             , p_log_category => l_category
             , p_guid => NULL
             , p_sosl_identifier => NULL
             , p_executor_id => NULL
             , p_ext_script_id => NULL
             , p_script_file => NULL
             , p_caller => l_caller
             , p_run_id => NULL
               -- full details and original message
             , p_full_message => l_full_msg
             )
    ;
  EXCEPTION
    WHEN OTHERS THEN
      -- log exception as we should not be already in exception state, only application error
      -- do not raise again
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
  END minimal_info_log;

  PROCEDURE minimal_info_log( p_caller     IN VARCHAR2
                            , p_category   IN VARCHAR2
                            , p_short_msg  IN VARCHAR2
                            , p_full_msg   IN VARCHAR2
                            )
  IS
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.minimal_info_log VARCHAR2';
  BEGIN
    sosl_log.minimal_info_log(p_caller, p_category, p_short_msg, TO_CLOB(p_full_msg));
  EXCEPTION
    WHEN OTHERS THEN
      -- log exception as we should not be already in exception state, only application error
      -- do not raise again
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
  END minimal_info_log;

  PROCEDURE minimal_warning_log( p_caller     IN VARCHAR2
                               , p_category   IN VARCHAR2
                               , p_short_msg  IN VARCHAR2
                               , p_full_msg   IN CLOB     DEFAULT NULL
                               )
  IS
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.minimal_warning_log CLOB';
    l_category          sosl_server_log.log_category%TYPE;
    l_caller            sosl_server_log.caller%TYPE;
    l_short_msg         VARCHAR2(32767);
    l_full_msg          CLOB;
  BEGIN
    l_category  := NVL(p_category, sosl_constants.GEN_NA_TYPE);
    l_caller    := NVL(p_caller, sosl_constants.GEN_NA_TYPE);
    IF p_short_msg IS NULL AND p_full_msg IS NULL
    THEN
      l_short_msg := l_caller || ': ERROR = Called sosl_log.minimal_warning_log without any message.';
      l_full_msg  := l_caller || ': ERROR = Called sosl_log.minimal_warning_log without any message.';
    ELSIF p_short_msg IS NULL AND p_full_msg IS NOT NULL
    THEN
      -- split long message
      l_short_msg := SUBSTR(p_full_msg, 1, 500) || CASE WHEN LENGTH(p_full_msg) > 500 THEN ' ... see full_message for complete details.' END;
      l_full_msg  := p_full_msg;
    ELSIF LENGTH(p_short_msg) > 3600
    THEN
      -- a very long short message, handle the overflow and distribute it to full message, we do not check for 4000 length to have some formatting space
      l_short_msg := SUBSTR(p_short_msg, 1, 500) || ' ... see full_message for complete details.';
      l_full_msg  := '... ' || SUBSTR(p_short_msg, 501) || ' - ' || p_full_msg;
    ELSE
      -- if long message is NULL we do not care, maybe NULL or given, handled as given.
      l_short_msg := p_short_msg;
      l_full_msg  := p_full_msg;
    END IF;
    log_event( p_message => l_short_msg
             , p_log_type => sosl_constants.LOG_WARNING_TYPE
             , p_log_category => l_category
             , p_guid => NULL
             , p_sosl_identifier => NULL
             , p_executor_id => NULL
             , p_ext_script_id => NULL
             , p_script_file => NULL
             , p_caller => l_caller
             , p_run_id => NULL
               -- full details and original message
             , p_full_message => l_full_msg
             )
    ;
  EXCEPTION
    WHEN OTHERS THEN
      -- log exception as we should not be already in exception state, only application error
      -- do not raise again
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
  END minimal_warning_log;

  PROCEDURE minimal_warning_log( p_caller     IN VARCHAR2
                               , p_category   IN VARCHAR2
                               , p_short_msg  IN VARCHAR2
                               , p_full_msg   IN VARCHAR2
                               )
  IS
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.minimal_warning_log VARCHAR2';
  BEGIN
    sosl_log.minimal_warning_log(p_caller, p_category, p_short_msg, TO_CLOB(p_full_msg));
  EXCEPTION
    WHEN OTHERS THEN
      -- log exception as we should not be already in exception state, only application error
      -- do not raise again
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
  END minimal_warning_log;

  PROCEDURE log_column_change( p_old_value     IN VARCHAR2
                             , p_new_value     IN VARCHAR2
                             , p_column_name   IN VARCHAR2
                             , p_caller        IN VARCHAR2
                             , p_forbidden     IN BOOLEAN  DEFAULT TRUE
                             )
  IS
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.log_column_change VARCHAR2';
    l_log_category      sosl_server_log.log_category%TYPE;
    l_caller            sosl_server_log.caller%TYPE;
  BEGIN
    l_log_category := NVL(UPPER(p_column_name), sosl_constants.GEN_NA_TYPE);
    l_caller       := NVL(p_caller, sosl_constants.GEN_NA_TYPE);
      -- log parameter errors
    IF p_column_name IS NULL
    THEN
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'ERROR Parameter p_column_name is missing.');
    END IF;
    IF p_caller IS NULL
    THEN
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'ERROR Parameter p_caller is missing.');
    END IF;
    IF NVL(p_old_value, sosl_constants.GEN_NA_TYPE) != NVL(p_new_value, sosl_constants.GEN_NA_TYPE)
    THEN
      IF p_forbidden
      THEN
        sosl_log.minimal_warning_log( l_caller
                                    , l_log_category
                                    , 'FORBIDDEN change of column ' || NVL(p_column_name, sosl_constants.GEN_NA_TYPE) || ' tried to: ' || NVL(p_new_value, sosl_constants.GEN_NULL_TEXT)
                                    , 'Change issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                    )
        ;
      ELSE
        sosl_log.minimal_info_log( l_caller
                                 , l_log_category
                                 , 'Change of column ' || NVL(p_column_name, sosl_constants.GEN_NA_TYPE) || ' from: ' || NVL(p_old_value, sosl_constants.GEN_NULL_TEXT) || ' to: ' || NVL(p_new_value, sosl_constants.GEN_NULL_TEXT)
                                 , 'Change issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                 )
        ;
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      -- log exception as we should not be already in exception state, only application error
      -- do not raise again
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
  END log_column_change; -- VARCHAR2

  PROCEDURE log_column_change( p_old_value     IN NUMBER
                             , p_new_value     IN NUMBER
                             , p_column_name   IN VARCHAR2
                             , p_caller        IN VARCHAR2
                             , p_forbidden     IN BOOLEAN  DEFAULT TRUE
                             )
  IS
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.log_column_change NUMBER';
    l_log_category      sosl_server_log.log_category%TYPE;
    l_caller            sosl_server_log.caller%TYPE;
  BEGIN
    l_log_category := NVL(UPPER(p_column_name), sosl_constants.GEN_NA_TYPE);
    l_caller       := NVL(p_caller, sosl_constants.GEN_NA_TYPE);
      -- log parameter errors
    IF p_column_name IS NULL
    THEN
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'ERROR Parameter p_column_name is missing.');
    END IF;
    IF p_caller IS NULL
    THEN
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'ERROR Parameter p_caller is missing.');
    END IF;
    -- use TO_CHAR for comparing NULL values as there is no invalid number symbol
    IF NVL(TO_CHAR(p_old_value), sosl_constants.GEN_NA_TYPE) != NVL(TO_CHAR(p_new_value), sosl_constants.GEN_NA_TYPE)
    THEN
      IF p_forbidden
      THEN
        sosl_log.minimal_warning_log( l_caller
                                    , l_log_category
                                    , 'FORBIDDEN change of column ' || NVL(p_column_name, sosl_constants.GEN_NA_TYPE) || ' tried to: ' || NVL(TO_CHAR(p_new_value), sosl_constants.GEN_NULL_TEXT)
                                    , 'Change issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                    )
        ;
      ELSE
        sosl_log.minimal_info_log( l_caller
                                 , l_log_category
                                 , 'Change of column ' || NVL(p_column_name, sosl_constants.GEN_NA_TYPE) || ' from: ' || NVL(TO_CHAR(p_old_value), sosl_constants.GEN_NULL_TEXT) || ' to: ' || NVL(TO_CHAR(p_new_value), sosl_constants.GEN_NULL_TEXT)
                                 , 'Change issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                 )
        ;
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      -- log exception as we should not be already in exception state, only application error
      -- do not raise again
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
  END log_column_change; -- NUMBER

  PROCEDURE log_column_change( p_old_value     IN DATE
                             , p_new_value     IN DATE
                             , p_column_name   IN VARCHAR2
                             , p_caller        IN VARCHAR2
                             , p_forbidden     IN BOOLEAN  DEFAULT TRUE
                             )
  IS
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.log_column_change DATE';
    l_log_category      sosl_server_log.log_category%TYPE;
    l_caller            sosl_server_log.caller%TYPE;
  BEGIN
    l_log_category := NVL(UPPER(p_column_name), sosl_constants.GEN_NA_TYPE);
    l_caller       := NVL(p_caller, sosl_constants.GEN_NA_TYPE);
      -- log parameter errors
    IF p_column_name IS NULL
    THEN
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'ERROR Parameter p_column_name is missing.');
    END IF;
    IF p_caller IS NULL
    THEN
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'ERROR Parameter p_caller is missing.');
    END IF;
    IF NVL(p_old_value, sosl_constants.GEN_NA_DATE_TYPE) != NVL(p_new_value, sosl_constants.GEN_NA_DATE_TYPE)
    THEN
      IF p_forbidden
      THEN
        sosl_log.minimal_warning_log( l_caller
                                    , l_log_category
                                    , 'FORBIDDEN change of column ' || NVL(p_column_name, sosl_constants.GEN_NA_TYPE) || ' tried to: ' || NVL(TO_CHAR(p_new_value, sosl_constants.GEN_DATE_FORMAT), sosl_constants.GEN_NULL_TEXT)
                                    , 'Change issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                    )
        ;
      ELSE
        sosl_log.minimal_info_log( l_caller
                                 , l_log_category
                                 , 'Change of column ' || NVL(p_column_name, sosl_constants.GEN_NA_TYPE) || ' from: ' || NVL(TO_CHAR(p_old_value, sosl_constants.GEN_DATE_FORMAT), sosl_constants.GEN_NULL_TEXT) || ' to: ' || NVL(TO_CHAR(p_new_value, sosl_constants.GEN_DATE_FORMAT), sosl_constants.GEN_NULL_TEXT)
                                 , 'Change issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                 )
        ;
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      -- log exception as we should not be already in exception state, only application error
      -- do not raise again
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
  END log_column_change; -- DATE

  PROCEDURE log_column_change( p_old_value     IN TIMESTAMP
                             , p_new_value     IN TIMESTAMP
                             , p_column_name   IN VARCHAR2
                             , p_caller        IN VARCHAR2
                             , p_forbidden     IN BOOLEAN  DEFAULT TRUE
                             )
  IS
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.log_column_change TIMESTAMP';
    l_log_category      sosl_server_log.log_category%TYPE;
    l_caller            sosl_server_log.caller%TYPE;
  BEGIN
    l_log_category := NVL(UPPER(p_column_name), sosl_constants.GEN_NA_TYPE);
    l_caller       := NVL(p_caller, sosl_constants.GEN_NA_TYPE);
      -- log parameter errors
    IF p_column_name IS NULL
    THEN
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'ERROR Parameter p_column_name is missing.');
    END IF;
    IF p_caller IS NULL
    THEN
      sosl_log.minimal_error_log(l_self_caller, l_self_log_category, 'ERROR Parameter p_caller is missing.');
    END IF;
    IF NVL(p_old_value, sosl_constants.GEN_NA_TIMESTAMP_TYPE) != NVL(p_new_value, sosl_constants.GEN_NA_TIMESTAMP_TYPE)
    THEN
      IF p_forbidden
      THEN
        sosl_log.minimal_warning_log( l_caller
                                    , l_log_category
                                    , 'FORBIDDEN change of column ' || NVL(p_column_name, sosl_constants.GEN_NA_TYPE) || ' tried to: ' || NVL(TO_CHAR(p_new_value, sosl_constants.GEN_TIMESTAMP_FORMAT), sosl_constants.GEN_NULL_TEXT)
                                    , 'Change issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                    )
        ;
      ELSE
        sosl_log.minimal_info_log( l_caller
                                 , l_log_category
                                 , 'Change of column ' || NVL(p_column_name, sosl_constants.GEN_NA_TYPE) || ' from: ' || NVL(TO_CHAR(p_old_value, sosl_constants.GEN_TIMESTAMP_FORMAT), sosl_constants.GEN_NULL_TEXT) || ' to: ' || NVL(TO_CHAR(p_new_value, sosl_constants.GEN_TIMESTAMP_FORMAT), sosl_constants.GEN_NULL_TEXT)
                                 , 'Change issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                                 )
        ;
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      -- log exception as we should not be already in exception state, only application error
      -- do not raise again
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
  END log_column_change; -- TIMESTAMP

END;
/
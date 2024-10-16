-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
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
          , sosl_sys.FATAL_TYPE
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
      BEGIN
        DBMS_OUTPUT.PUT_LINE('Fatal error in ' || p_script || ' error: ' || p_message);
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      -- do exactly nothing to avoid an additional exception on database malfunction
      NULL;
  END log_fallback;

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
        , p_caller
        , p_run_id
        , p_full_message
        )
    ;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      -- use fallback
      log_fallback('SOSL_LOG.LOG_EVENT', 'SOSL_LOG', SQLERRM);
      -- try ROLLBACK
      ROLLBACK;
      -- and raise the error again now
      RAISE;
  END log_event;

  PROCEDURE full_log( p_message          IN VARCHAR2
                    , p_log_type         IN VARCHAR2    DEFAULT sosl_sys.INFO_TYPE
                    , p_log_category     IN VARCHAR2    DEFAULT NULL
                    , p_caller           IN VARCHAR2    DEFAULT NULL
                    , p_guid             IN VARCHAR2    DEFAULT NULL
                    , p_sosl_identifier  IN VARCHAR2    DEFAULT NULL
                    , p_executor_id      IN NUMBER      DEFAULT NULL
                    , p_ext_script_id    IN VARCHAR2    DEFAULT NULL
                    , p_run_id           IN NUMBER      DEFAULT NULL
                    , p_full_message     IN CLOB        DEFAULT NULL
                    )
  IS
    -- set variables to current type
    l_log_category    sosl_server_log.log_category%TYPE;
    l_caller          sosl_server_log.caller%TYPE;
    l_guid            sosl_server_log.guid%TYPE;
    l_sosl_identifier sosl_server_log.sosl_identifier%TYPE;
    l_executor_id     sosl_server_log.executor_id%TYPE;
    l_ext_script_id   sosl_server_log.ext_script_id%TYPE;
    l_run_id          sosl_server_log.run_id%TYPE;
  BEGIN
    -- we leave info type and message splitting to be handled by table trigger, only check other parameters for type and length.
    IF NOT sosl_sys.check_col('SOSL_SERVER_LOG', 'LOG_CATEGORY', p_log_category)
    THEN
      -- write extra log entry and cut original content to limit
      log_event( 'p_log_category length exceeds column length in SOSL_SERVER_LOG. See full message for message causing the error.'
               , sosl_sys.FATAL_TYPE
               , 'LOG USAGE ERROR'
               , NULL, NULL, NULL, NULL, NULL, NULL
               , (p_message || ' - ' || p_full_message)
               )
      ;
      l_log_category := SUBSTR(p_log_category, 1, sosl_sys.get_col_length('SOSL_SERVER_LOG', 'LOG_CATEGORY'));
    ELSE
      l_log_category := p_log_category;
    END IF;
    IF NOT sosl_sys.check_col('SOSL_SERVER_LOG', 'CALLER', p_caller)
    THEN
      -- write extra log entry and cut original content to limit
      log_event( 'p_caller length exceeds column length in SOSL_SERVER_LOG. See full message for message causing the error.'
               , sosl_sys.FATAL_TYPE
               , 'LOG USAGE ERROR'
               , NULL, NULL, NULL, NULL, NULL, NULL
               , (p_message || ' - ' || p_full_message)
               )
      ;
      l_caller := SUBSTR(p_caller, 1, sosl_sys.get_col_length('SOSL_SERVER_LOG', 'CALLER'));
    ELSE
      l_caller := p_caller;
    END IF;
    IF NOT sosl_sys.check_col('SOSL_SERVER_LOG', 'GUID', p_guid)
    THEN
      -- write extra log entry and cut original content to limit
      log_event( 'p_guid length exceeds column length in SOSL_SERVER_LOG. See full message for message causing the error.'
               , sosl_sys.FATAL_TYPE
               , 'LOG USAGE ERROR'
               , NULL, NULL, NULL, NULL, NULL, NULL
               , (p_message || ' - ' || p_full_message)
               )
      ;
      l_guid := SUBSTR(p_guid, 1, sosl_sys.get_col_length('SOSL_SERVER_LOG', 'GUID'));
    ELSE
      l_guid := p_guid;
    END IF;
    IF NOT sosl_sys.check_col('SOSL_SERVER_LOG', 'SOSL_IDENTIFIER', p_sosl_identifier)
    THEN
      -- write extra log entry and cut original content to limit
      log_event( 'p_sosl_identifier length exceeds column length in SOSL_SERVER_LOG. See full message for message causing the error.'
               , sosl_sys.FATAL_TYPE
               , 'LOG USAGE ERROR'
               , NULL, NULL, NULL, NULL, NULL, NULL
               , (p_message || ' - ' || p_full_message)
               )
      ;
      l_sosl_identifier := SUBSTR(p_sosl_identifier, 1, sosl_sys.get_col_length('SOSL_SERVER_LOG', 'SOSL_IDENTIFIER'));
    ELSE
      l_sosl_identifier := p_sosl_identifier;
    END IF;
    IF NOT sosl_sys.check_col('SOSL_SERVER_LOG', 'EXECUTOR_ID', p_executor_id)
    THEN
      -- write extra log entry and cut original content to limit
      log_event( 'p_executor_id length exceeds column length in SOSL_SERVER_LOG. See full message for message causing the error. EXECUTOR_ID: ' || p_executor_id
               , sosl_sys.FATAL_TYPE
               , 'LOG USAGE ERROR'
               , NULL, NULL, NULL, NULL, NULL, NULL
               , (p_message || ' - ' || p_full_message)
               )
      ;
      -- we can't shorten the number, leave it to oracle
      l_executor_id := p_executor_id;
    ELSE
      l_executor_id := p_executor_id;
    END IF;
    IF NOT sosl_sys.check_col('SOSL_SERVER_LOG', 'EXT_SCRIPT_ID', p_ext_script_id)
    THEN
      -- write extra log entry and cut original content to limit
      log_event( 'ext_script_id length exceeds column length in SOSL_SERVER_LOG. See full message for message causing the error.'
               , sosl_sys.FATAL_TYPE
               , 'LOG USAGE ERROR'
               , NULL, NULL, NULL, NULL, NULL, NULL
               , (p_message || ' - ' || p_full_message)
               )
      ;
      l_ext_script_id := SUBSTR(p_ext_script_id, 1, sosl_sys.get_col_length('SOSL_SERVER_LOG', 'EXT_SCRIPT_ID'));
    ELSE
      l_ext_script_id := p_ext_script_id;
    END IF;
    IF NOT sosl_sys.check_col('SOSL_SERVER_LOG', 'RUN_ID', p_run_id)
    THEN
      -- write extra log entry and cut original content to limit
      log_event( 'p_run_id length exceeds column length in SOSL_SERVER_LOG. See full message for message causing the error. RUN_ID: ' || p_run_id
               , sosl_sys.FATAL_TYPE
               , 'LOG USAGE ERROR'
               , NULL, NULL, NULL, NULL, NULL, NULL
               , (p_message || ' - ' || p_full_message)
               )
      ;
      -- we can't shorten the number, leave it to oracle
      l_run_id := p_run_id;
    ELSE
      l_run_id := p_run_id;
    END IF;
    -- try to write the given data to SOSL_SERVER_LOG
    log_event(p_message, p_log_type, l_log_category, l_guid, l_sosl_identifier, l_executor_id, l_ext_script_id, l_caller, l_run_id, p_full_message);
  EXCEPTION
    WHEN OTHERS THEN
      log_event( 'full log error: ' || TRIM(SUBSTR(SQLERRM, 1, 3900))
               , sosl_sys.FATAL_TYPE
               , 'FULL_LOG ERROR'
               , NULL, NULL, NULL, NULL, NULL, NULL
               , SQLERRM || ': ' || p_message
               )
      ;
  END full_log;

  PROCEDURE cmd_log( p_message          IN VARCHAR2
                   , p_log_type         IN VARCHAR2     DEFAULT sosl_sys.INFO_TYPE
                   , p_caller           IN VARCHAR2     DEFAULT NULL
                   , p_guid             IN VARCHAR2     DEFAULT NULL
                   , p_sosl_identifier  IN VARCHAR2     DEFAULT NULL
                   , p_executor_id      IN NUMBER       DEFAULT NULL
                   , p_ext_script_id    IN VARCHAR2     DEFAULT NULL
                   , p_full_message     IN CLOB         DEFAULT NULL
                   )
  IS
  BEGIN
    full_log( p_message => p_message
            , p_log_type => p_log_type
            , p_caller => p_caller
            , p_guid => p_guid
            , p_sosl_identifier => p_sosl_identifier
            , p_executor_id => p_executor_id
            , p_ext_script_id => p_ext_script_id
            , p_full_message => p_full_message
            )
    ;
  EXCEPTION
    WHEN OTHERS THEN
      log_event( 'CMD log error: ' || TRIM(SUBSTR(SQLERRM, 1, 3900))
               , sosl_sys.FATAL_TYPE
               , 'CMD_LOG ERROR'
               , NULL, NULL, NULL, NULL, NULL, NULL
               , SQLERRM || ': ' || p_message
               )
      ;
  END cmd_log;

END;
/
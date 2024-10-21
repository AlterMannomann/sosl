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
      -- try fallback
      log_fallback('sosl_log.log_event', 'SOSL_LOG', SQLERRM);
      -- try ROLLBACK
      ROLLBACK;
      -- and raise the error again now
      RAISE;
  END log_event;

  PROCEDURE full_log( p_message          IN VARCHAR2
                    , p_log_type         IN VARCHAR2    DEFAULT sosl_sys.INFO_TYPE
                    , p_log_category     IN VARCHAR2    DEFAULT 'not set'
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
    l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_LOG';
    l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_log.full_log';
    l_log_category      sosl_server_log.log_category%TYPE;
    l_caller            sosl_server_log.caller%TYPE;
    l_guid              sosl_server_log.guid%TYPE;
    l_sosl_identifier   sosl_server_log.sosl_identifier%TYPE;
    l_executor_id       sosl_server_log.executor_id%TYPE;
    l_ext_script_id     sosl_server_log.ext_script_id%TYPE;
    l_run_id            sosl_server_log.run_id%TYPE;
    l_col_length        INTEGER;
  BEGIN
    -- basic column checks message splitting is left to table triggers
    -- LOG_CATEGORY
    IF NVL(LENGTH(TRIM(p_log_category)), 0) > 256
    THEN
      -- write extra log entry and cut original content to limit
      log_event( p_message => 'p_log_category length exceeds column length (256) in SOSL_SERVER_LOG. See full message for message causing the error.'
               , p_log_type => sosl_sys.FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- details and original message
               , p_full_message => ('LOG_CATEGORY: ' || TRIM(p_log_category) || ' length: ' || LENGTH(TRIM(p_log_category)) || ' msg: ' || p_message || ' - ' || p_full_message)
               )
      ;
      l_log_category := SUBSTR(TRIM(p_log_category), 1, 256);
    ELSE
      l_log_category := NVL(TRIM(p_log_category), sosl_sys.NA_TYPE);
    END IF;
    -- CALLER
    IF NVL(LENGTH(TRIM(p_caller)), 0) > 256
    THEN
      -- write extra log entry and cut original content to limit
      log_event( p_message => 'p_caller length exceeds column length (256) in SOSL_SERVER_LOG. See full message for message causing the error.'
               , p_log_type => sosl_sys.FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
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
      log_event( p_message => 'p_guid length exceeds column length (64) in SOSL_SERVER_LOG. See full message for message causing the error.'
               , p_log_type => sosl_sys.FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
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
      log_event( p_message => 'p_sosl_identifier length exceeds column length (256) in SOSL_SERVER_LOG. See full message for message causing the error.'
               , p_log_type => sosl_sys.FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
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
      log_event( p_message => 'p_ext_script_id length exceeds column length (4000) in SOSL_SERVER_LOG. See full message for message causing the error.'
               , p_log_type => sosl_sys.FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
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
    -- no check on numbers
    l_executor_id := p_executor_id;
    l_run_id := p_run_id;
    -- try to write the given data to SOSL_SERVER_LOG
    log_event( p_message => p_message
             , p_log_type => p_log_type
             , p_log_category => l_log_category
             , p_guid => l_guid
             , p_sosl_identifier => l_sosl_identifier
             , p_executor_id => l_executor_id
             , p_ext_script_id => l_ext_script_id
             , p_caller => l_caller
             , p_run_id => l_run_id
             , p_full_message => p_full_message
             )
    ;
  EXCEPTION
    WHEN OTHERS THEN
      log_event( p_message => 'full log error: ' || TRIM(SUBSTR(SQLERRM, 1, 3900))
               , p_log_type => sosl_sys.FATAL_TYPE
               , p_log_category => l_self_log_category
               , p_guid => NULL
               , p_sosl_identifier => NULL
               , p_executor_id => NULL
               , p_ext_script_id => NULL
               , p_caller => l_self_caller
               , p_run_id => NULL
                 -- full details and original message
               , p_full_message => (SQLERRM || ': ' || p_message)
               )
      ;
  END full_log;

  FUNCTION dummy_mail( p_sender      IN VARCHAR2
                     , p_recipients  IN VARCHAR2
                     , p_subject     IN VARCHAR2
                     , p_message     IN VARCHAR2
                     )
    RETURN NUMBER
  IS
    l_message       VARCHAR2(32767);
    l_category      sosl_server_log.log_category%TYPE   := 'MAIL DUMMY';
    l_caller        sosl_server_log.caller%TYPE         := 'sosl_log.dummy_mail';
  BEGIN
    l_message := sosl_sys.format_mail(p_sender, p_recipients, p_subject, p_message);
    full_log( p_message => 'Fake mail with subject "' || p_subject || '" created in full_message. Check the results.'
            , p_log_type => sosl_sys.INFO_TYPE
            , p_log_category => l_category
            , p_caller => l_caller
            , p_full_message => l_message
            )
    ;
    RETURN sosl_sys.SUCCESS_NUM;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.full_log( p_message => 'Unhandled exception in sosl_log.dummy_mail function: ' || SQLERRM
                       , p_log_type => sosl_sys.FATAL_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
      RETURN sosl_sys.ERR_NUM;
  END dummy_mail;

END;
/
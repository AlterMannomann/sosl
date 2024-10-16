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
                     , p_ext_script_id    IN NUMBER
                     , p_caller           IN VARCHAR2
                     , p_run_id           IN NUMBER
                     , p_full_message     IN NOCOPY CLOB
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
                    , p_ext_script_id    IN NUMBER      DEFAULT NULL
                    , p_run_id           IN NUMBER      DEFAULT NULL
                    , p_full_message     IN NOCOPY CLOB DEFAULT NULL
                    )
  IS
    l_param_error   BOOLEAN;
    -- set variables to current type
    l_log_type      sosl_server_log.log_type%TYPE;
    l_col_type      VARCHAR2(128);
    l_col_length    NUMBER;
  BEGIN
    l_param_error := FALSE;
    -- first check parameters
    -- get type information and length
    l_col_type := sosl_sys.get_col_type('SOSL_SERVER_LOG', 'MESSAGE');
    l_col_length := sosl_sys.get_col_length('SOSL_SERVER_LOG', 'MESSAGE');
    IF LENGTH(p_message) > l_col_length
    THEN
      -- split the message, take care of full message if NOT NULL
      IF p_full_message IS NULL
      THEN
        l_full_message := 'Rest of message: ...' || SUBSTR(p_message, l_col_length - 2);
        l_message      := SUBSTR(p_message, 1, l_col_length - 3) || '...';
      ELSE

      END IF;
    END IF;

    -- try to write the given data to SOSL_SERVER_LOG
    -- if parameter check failed add an additional record
    NULL;
  END full_log;

  PROCEDURE cmd_log( p_message          IN VARCHAR2
                   , p_log_type         IN VARCHAR2     DEFAULT sosl_sys.INFO_TYPE
                   , p_caller           IN VARCHAR2     DEFAULT NULL
                   , p_guid             IN VARCHAR2     DEFAULT NULL
                   , p_sosl_identifier  IN VARCHAR2     DEFAULT NULL
                   , p_executor_id      IN NUMBER       DEFAULT NULL
                   , p_ext_script_id    IN NUMBER       DEFAULT NULL
                   , p_full_message     IN NOCOPY CLOB  DEFAULT NULL
                   )
  IS
  BEGIN
    NULL;
  END cmd_log;

END;
/
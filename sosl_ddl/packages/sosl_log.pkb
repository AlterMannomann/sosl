-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE OR REPLACE PACKAGE BODY sosl_log
AS
  -- for description see header file
  PROCEDURE log_event( p_message          IN VARCHAR2
                     , p_log_type         IN VARCHAR2
                     , p_log_category     IN VARCHAR2
                     , p_guid             IN VARCHAR2
                     , p_sosl_identifier  IN VARCHAR2
                     , p_executor_id      IN NUMBER
                     , p_ext_script_id    IN NUMBER
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
      -- try ROLLBACK
      ROLLBACK;
      -- and raise the error
      RAISE;
  END log_event;

END;
/
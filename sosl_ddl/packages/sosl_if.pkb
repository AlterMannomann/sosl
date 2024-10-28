-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE PACKAGE BODY sosl_if
AS
  -- see package header for documentation
  FUNCTION has_scripts
    RETURN NUMBER
  IS
    l_return            NUMBER;
    l_self_log_category sosl_server_log.log_category%TYPE   := 'HAS_SCRIPTS';
    l_self_caller       sosl_server_log.caller%TYPE         := 'sosl_if.has_scripts';
  BEGIN
    SELECT COUNT(*)
      INTO l_return
      FROM sosl_if_script
    ;
    RETURN -1;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
      RETURN -1;
  END has_scripts;

  FUNCTION get_next_script
    RETURN SOSL_PAYLOAD
  IS
  BEGIN
    RETURN NULL;
  END get_next_script;

  FUNCTION set_script_status( p_reference   IN SOSL_PAYLOAD
                            , p_status      IN NUMBER
                            , p_status_msg  IN VARCHAR2 DEFAULT NULL
                            )
    RETURN NUMBER
  IS
  BEGIN
    RETURN -1;
  END set_script_status;

  FUNCTION send_mail( p_sender      IN VARCHAR2
                    , p_recipients  IN VARCHAR2
                    , p_subject     IN VARCHAR2
                    , p_message     IN VARCHAR2
                    , p_test_mode   IN BOOLEAN  DEFAULT TRUE
                    )
    RETURN NUMBER
  IS
    l_return  NUMBER;
  BEGIN
    RETURN sosl_util.dummy_mail(p_sender, p_recipients, p_subject, p_message);
  END send_mail;

END;
/
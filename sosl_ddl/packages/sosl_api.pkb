-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE PACKAGE BODY sosl_api
AS
  -- for description see header file
  FUNCTION get_payload(p_run_id IN NUMBER)
    RETURN SOSL_PAYLOAD
  IS
    l_sosl_payload  SOSL_PAYLOAD;
  BEGIN
    l_sosl_payload := sosl_sys.get_payload(p_run_id);
    RETURN l_sosl_payload;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_api.get_payload', 'SOSL_API', SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN NULL;
  END get_payload;

  FUNCTION get_config(p_config_name IN VARCHAR2)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END get_config;

  FUNCTION base_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END base_path;

  FUNCTION cfg_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END cfg_path;

  FUNCTION tmp_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END tmp_path;

  FUNCTION log_path(p_run_id IN NUMBER)
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN NULL;
  END log_path;

  FUNCTION dummy_mail( p_sender      IN VARCHAR2
                     , p_recipients  IN VARCHAR2
                     , p_subject     IN VARCHAR2
                     , p_message     IN VARCHAR2
                     )
    RETURN BOOLEAN
  IS
    l_result  NUMBER;
    l_return  BOOLEAN;
  BEGIN
    l_result  := sosl_util.dummy_mail(p_sender, p_recipients, p_subject, p_message);
    l_return  := (l_result = 0);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_api.dummy_mail', 'SOSL_API', SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN FALSE;
  END dummy_mail;

  FUNCTION has_run_id(p_run_id IN NUMBER)
    RETURN BOOLEAN
  IS
    l_return BOOLEAN;
  BEGIN
    l_return := sosl_sys.has_run_id(p_run_id);
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_log.exception_log('sosl_api.has_run_id', 'SOSL_API', SQLERRM);
      -- sosl_constants.NUM_ERROR can be tweaked by modifying the package, make sure, value is below zero
      RETURN FALSE;
  END has_run_id;

END;
/
-- grants
GRANT EXECUTE ON sosl_api TO sosl_executor;
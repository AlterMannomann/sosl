-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE PACKAGE BODY sosl_constants
AS
  -- for description see header file

  FUNCTION run_state_text(p_run_state IN NUMBER)
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
    l_return VARCHAR2(30);
  BEGIN
    l_return := CASE p_run_state
                  WHEN sosl_constants.RUN_STATE_WAITING
                  THEN 'Waiting'
                  WHEN sosl_constants.RUN_STATE_ENQUEUED
                  THEN 'Enqueued'
                  WHEN sosl_constants.RUN_STATE_STARTED
                  THEN 'Started'
                  WHEN sosl_constants.RUN_STATE_RUNNING
                  THEN 'Running'
                  WHEN sosl_constants.RUN_STATE_FINISHED
                  THEN 'Finished'
                  WHEN sosl_constants.RUN_STATE_ERROR
                  THEN 'ERROR'
                  ELSE sosl_constants.GEN_NA_TYPE
                END;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN sosl_constants.GEN_NA_TYPE;
  END run_state_text;

  FUNCTION get_log_error_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.LOG_ERROR_TYPE;
  END get_log_error_type;

  FUNCTION get_log_warning_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.LOG_WARNING_TYPE;
  END get_log_warning_type;

  FUNCTION get_log_fatal_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.LOG_FATAL_TYPE;
  END get_log_fatal_type;

  FUNCTION get_log_info_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.LOG_INFO_TYPE;
  END get_log_info_type;

  FUNCTION get_log_success_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.LOG_SUCCESS_TYPE;
  END get_log_success_type;

  FUNCTION get_gen_na_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.GEN_NA_TYPE;
  END get_gen_na_type;

  FUNCTION get_gen_na_date_type
    RETURN DATE
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.GEN_NA_DATE_TYPE;
  END get_gen_na_date_type;

  FUNCTION get_gen_na_timestamp_type
    RETURN DATE
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.GEN_NA_TIMESTAMP_TYPE;
  END get_gen_na_timestamp_type;

  FUNCTION get_gen_date_format
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.GEN_DATE_FORMAT;
  END get_gen_date_format;

  FUNCTION get_gen_timestamp_format
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.GEN_TIMESTAMP_FORMAT;
  END get_gen_timestamp_format;

  FUNCTION get_gen_null_text
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.GEN_NULL_TEXT;
  END get_gen_null_text;

  FUNCTION get_num_yes
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.NUM_YES;
  END get_num_yes;

  FUNCTION get_num_no
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.NUM_NO;
  END get_num_no;

  FUNCTION get_num_error
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.NUM_ERROR;
  END get_num_error;

  FUNCTION get_num_success
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.NUM_SUCCESS;
  END get_num_success;

  FUNCTION get_run_state_waiting
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.RUN_STATE_WAITING;
  END get_run_state_waiting;

  FUNCTION get_run_state_enqueued
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.RUN_STATE_ENQUEUED;
  END get_run_state_enqueued;

  FUNCTION get_run_state_started
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.RUN_STATE_STARTED;
  END get_run_state_started;

  FUNCTION get_run_state_running
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.RUN_STATE_RUNNING;
  END get_run_state_running;

  FUNCTION get_run_state_finished
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.RUN_STATE_FINISHED;
  END get_run_state_finished;

  FUNCTION get_run_state_error
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.RUN_STATE_ERROR;
  END get_run_state_error;

  FUNCTION get_server_run_mode
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.SERVER_RUN_MODE;
  END get_server_run_mode;

  FUNCTION get_server_pause_mode
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.SERVER_PAUSE_MODE;
  END get_server_pause_mode;

  FUNCTION get_server_stop_mode
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.SERVER_STOP_MODE;
  END get_server_stop_mode;

  FUNCTION get_lf
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.LF;
  END get_lf;

  FUNCTION get_cr
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.CR;
  END get_cr;

  FUNCTION get_crlf
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.CRLF;
  END get_crlf;

  FUNCTION gray
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.PURE_GRAY;
  END gray;

  FUNCTION red
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.PURE_RED;
  END red;

  FUNCTION yellow
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.PURE_YELLOW;
  END yellow;

  FUNCTION green
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  IS
  BEGIN
    RETURN sosl_constants.PURE_GREEN;
  END green;

END;
/
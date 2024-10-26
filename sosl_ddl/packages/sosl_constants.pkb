-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE PACKAGE BODY sosl_constants
AS
  -- for description see header file
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

END;
/
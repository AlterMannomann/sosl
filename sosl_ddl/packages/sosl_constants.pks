-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- Basic package for constants used by the Simple Oracle Script Loader, no dependencies.
CREATE OR REPLACE PACKAGE sosl_constants
AS
  /**
  * This package contains SOSL constant declarations and functions for retrieving the constant with pure SQL.
  * As there are no dependencies, exceptions must be catched or handled by the caller. No logging for this functions.
  */

  /*====================================== start package constants used by SOSL ======================================*/
  -- define log_type constants used in SOSL_SERVER_LOG
  LOG_ERROR_TYPE        CONSTANT CHAR(5)  := 'ERROR';
  LOG_WARNING_TYPE      CONSTANT CHAR(7)  := 'WARNING';
  LOG_FATAL_TYPE        CONSTANT CHAR(5)  := 'FATAL';
  LOG_INFO_TYPE         CONSTANT CHAR(4)  := 'INFO';
  LOG_SUCCESS_TYPE      CONSTANT CHAR(7)  := 'SUCCESS';
  -- Generic n/a type. Should be different from table defaults like 'not set' as table triggers interpret their DDL default value as fallback
  -- to set default values using package variables, which is not supported in table DDL by Oracle using DEFAULT. Packages may use variables
  -- from other packages in DEFAULT declarations.
  GEN_NA_TYPE           CONSTANT CHAR(3)    := 'n/a';
  GEN_NA_DATE_TYPE      CONSTANT DATE       := TO_DATE('01.01.1900', 'DD.MM.YYYY');
  GEN_NA_TIMESTAMP_TYPE CONSTANT TIMESTAMP  := TO_TIMESTAMP('01.01.1900', 'DD.MM.YYYY');
  GEN_DATE_FORMAT       CONSTANT CHAR(21)   := 'YYYY-MM-DD HH24:MI:SS';
  GEN_TIMESTAMP_FORMAT  CONSTANT CHAR(24)   := 'YYYY-MM-DD HH24:MI:SS.FF';
  GEN_NULL_TEXT         CONSTANT CHAR(4)    := 'NULL';
  -- numerical equations to TRUE/YES and FALSE/NO
  NUM_YES               CONSTANT INTEGER  := 1;
  NUM_NO                CONSTANT INTEGER  := 0;
  -- default error numeric expression, that is returned by functions to indicate an error had occured
  NUM_ERROR             CONSTANT INTEGER  := -1;
  -- default success numeric expression, that is returned by functions to indicate processing was successful
  NUM_SUCCESS           CONSTANT INTEGER  := 0;
  -- Run states
  RUN_STATE_WAITING     CONSTANT INTEGER  := 0;
  RUN_STATE_ENQUEUED    CONSTANT INTEGER  := 1;
  RUN_STATE_STARTED     CONSTANT INTEGER  := 2;
  RUN_STATE_RUNNING     CONSTANT INTEGER  := 3;
  RUN_STATE_FINISHED    CONSTANT INTEGER  := 4;
  RUN_STATE_ERROR       CONSTANT INTEGER  := -1;
  -- server run modes
  SERVER_RUN_MODE       CONSTANT CHAR(3)  := 'RUN';
  SERVER_PAUSE_MODE     CONSTANT CHAR(5)  := 'PAUSE';
  SERVER_STOP_MODE      CONSTANT CHAR(4)  := 'STOP';
  -- formatting
  LF                    CONSTANT CHAR(1)  := CHR(10);
  CR                    CONSTANT CHAR(1)  := CHR(13);
  CRLF                  CONSTANT CHAR(2)  := CHR(13) || CHR(10);
  -- SQL Developer gauge formatting - only works with SQL Developer
  -- syntax: SQLDEV:GAUGE:min:max:min_treshold:max_treshold:value
  PURE_GRAY             CONSTANT CHAR(23) := 'SQLDEV:GAUGE:0:0:0:0:-1';
  PURE_RED              CONSTANT CHAR(23) := 'SQLDEV:GAUGE:0:0:1:0:-1';
  PURE_YELLOW           CONSTANT CHAR(23) := 'SQLDEV:GAUGE:0:1:0:1:-1';
  PURE_GREEN            CONSTANT CHAR(23) := 'SQLDEV:GAUGE:0:1:1:0:-1';
  /*====================================== end package constants used by SOSL ======================================*/

  /* FUNCTION SOSL_CONSTANTS.run_state_text
  * Returns the text interpretation (english) for the supported run states.
  *
  * @param p_run_state The numerical run state to express as text.
  *
  * @return The text equation for the given run state or sosl_constants.GEN_NA_TYPE on errors.
  */
  FUNCTION run_state_text(p_run_state IN NUMBER)
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;

  -- All get_ functions only return the defined constant, no extra code. Constant name prefixed with GET_.
  FUNCTION get_log_error_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_log_warning_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_log_fatal_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_log_info_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_log_success_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_gen_na_type
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_gen_na_date_type
    RETURN DATE
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_gen_na_timestamp_type
    RETURN DATE
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_gen_date_format
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_gen_timestamp_format
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_gen_null_text
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_num_yes
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_num_no
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_num_error
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_num_success
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_run_state_waiting
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_run_state_enqueued
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_run_state_started
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_run_state_running
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_run_state_finished
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_run_state_error
    RETURN NUMBER
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_server_run_mode
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_server_pause_mode
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_server_stop_mode
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_lf
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_cr
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;
  FUNCTION get_crlf
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;

  FUNCTION gray
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;

  FUNCTION red
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;

  FUNCTION yellow
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;

  FUNCTION green
    RETURN VARCHAR2
    DETERMINISTIC
    PARALLEL_ENABLE
  ;

END;
/
-- grants
GRANT EXECUTE ON sosl_constants TO sosl_user;
-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- As this package depends on the schema SOSL is installed, getting fully qualified calls must be determined
-- dynamically using SQLPlus variable SOSL_SCHEMA.
COLUMN SOSL_SCHEMA NEW_VAL SOSL_SCHEMA
SELECT config_value AS SOSL_SCHEMA FROM sosl_config WHERE config_name = 'SOSL_SCHEMA';

CREATE OR REPLACE PACKAGE BODY sosl_if
AS
  -- see package header for documentation, can be used as an template for own interface functions
  -- therefore all packages calls are fully qualified
  -- ==============================
  -- first wrap the SOSL api interface functions to have a central place for SOSL API changes
  -- logging, reduce parameters
  PROCEDURE log_exception( p_caller     IN VARCHAR2
                         , p_sqlerrmsg  IN VARCHAR2
                         )
  IS
  BEGIN
    &SOSL_SCHEMA..sosl_api.if_exception_log(p_caller, sosl_if.LOG_CATEGORY, p_sqlerrmsg);
  END log_exception;

  PROCEDURE log_info( p_caller  IN VARCHAR2
                    , p_message IN VARCHAR2
                    )
  IS
  BEGIN
    -- set short message to NULL and use the VARCHAR2 interface for full message, leave it up to SOSL to summarize the short message
    &SOSL_SCHEMA..sosl_api.if_generic_log(p_caller, sosl_if.LOG_CATEGORY, &SOSL_SCHEMA..sosl_constants.LOG_INFO_TYPE, NULL, p_message);
  END log_info;

  FUNCTION log_info_show( p_caller  IN VARCHAR2
                        , p_message IN VARCHAR2
                        )
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN &SOSL_SCHEMA..sosl_api.if_display_log(p_caller, sosl_if.LOG_CATEGORY, &SOSL_SCHEMA..sosl_constants.LOG_INFO_TYPE, p_message);
  END log_info_show;

  PROCEDURE log_error( p_caller  IN VARCHAR2
                     , p_message IN VARCHAR2
                     )
  IS
  BEGIN
    -- set short message to NULL and use the VARCHAR2 interface for full message, leave it up to SOSL to summarize the short message
    &SOSL_SCHEMA..sosl_api.if_generic_log(p_caller, sosl_if.LOG_CATEGORY, &SOSL_SCHEMA..sosl_constants.LOG_ERROR_TYPE, NULL, p_message);
  END log_error;

  FUNCTION log_error_show( p_caller  IN VARCHAR2
                         , p_message IN VARCHAR2
                         )
    RETURN VARCHAR2
  IS
  BEGIN
    RETURN &SOSL_SCHEMA..sosl_api.if_display_log(p_caller, sosl_if.LOG_CATEGORY, &SOSL_SCHEMA..sosl_constants.LOG_ERROR_TYPE, p_message);
  END log_error_show;

  PROCEDURE log_warning( p_caller  IN VARCHAR2
                       , p_message IN VARCHAR2
                       )
  IS
  BEGIN
    -- set short message to NULL and use the VARCHAR2 interface for full message, leave it up to SOSL to summarize the short message
    &SOSL_SCHEMA..sosl_api.if_generic_log(p_caller, sosl_if.LOG_CATEGORY, &SOSL_SCHEMA..sosl_constants.LOG_WARNING_TYPE, NULL, p_message);
  END log_warning;

  FUNCTION get_payload(p_run_id IN NUMBER)
    RETURN &SOSL_SCHEMA..SOSL_PAYLOAD
  IS
  BEGIN
    RETURN &SOSL_SCHEMA..sosl_api.if_get_payload(p_run_id);
  END get_payload;

  FUNCTION has_run_id(p_run_id IN NUMBER)
    RETURN BOOLEAN
  IS
  BEGIN
    RETURN &SOSL_SCHEMA..sosl_api.if_has_run_id(p_run_id);
  END has_run_id;

  FUNCTION dummy_mail( p_sender      IN VARCHAR2
                     , p_recipients  IN VARCHAR2
                     , p_subject     IN VARCHAR2
                     , p_message     IN VARCHAR2
                     )
    RETURN BOOLEAN
  IS
  BEGIN
    RETURN &SOSL_SCHEMA..sosl_api.if_dummy_mail(p_sender, p_recipients, p_subject, p_message);
  END dummy_mail;

  FUNCTION map_run_state(p_run_state IN NUMBER)
    RETURN NUMBER
  IS
    l_return  NUMBER;
    -- adjust the variables to your function
    l_caller  VARCHAR2(256) := 'sosl_if.map_run_state';
  BEGIN
    IF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_WAITING
    THEN
      l_return := sosl_if.SCRIPT_WAITING;
    ELSIF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_ENQUEUED
    THEN
      l_return := sosl_if.SCRIPT_ENQUEUED;
    ELSIF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_STARTED
    THEN
      l_return := sosl_if.SCRIPT_STARTED;
    ELSIF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_RUNNING
    THEN
      l_return := sosl_if.SCRIPT_RUNNING;
    ELSIF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_FINISHED
    THEN
      l_return := sosl_if.SCRIPT_FINISHED;
    ELSIF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_ERROR
    THEN
      l_return := sosl_if.SCRIPT_ERROR;
    ELSE
      l_return := sosl_if.SCRIPT_ERROR;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN sosl_if.SCRIPT_ERROR;
  END map_run_state;

  FUNCTION map_run_state_text(p_run_state IN NUMBER)
    RETURN VARCHAR2
  IS
    l_return  VARCHAR2(128);
    -- adjust the variables to your function
    l_caller  VARCHAR2(256) := 'sosl_if.map_run_state_text';
  BEGIN
    IF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_WAITING
    THEN
      l_return := 'WAITING';
    ELSIF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_ENQUEUED
    THEN
      l_return := 'ENQUEUED';
    ELSIF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_STARTED
    THEN
      l_return := 'STARTED';
    ELSIF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_RUNNING
    THEN
      l_return := 'RUNNING';
    ELSIF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_FINISHED
    THEN
      l_return := 'FINISHED';
    ELSIF p_run_state = &SOSL_SCHEMA..sosl_constants.RUN_STATE_ERROR
    THEN
      l_return := 'ERROR';
    ELSE
      l_return := 'ERROR';
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN 'ERROR';
  END map_run_state_text;

  -- ==============================
  -- now define the own functionality, the point where you adjust your implementation

  FUNCTION get_script_count
    RETURN NUMBER
  IS
    l_return  NUMBER;
    -- adjust the variables to your function
    l_caller  VARCHAR2(256) := 'sosl_if.get_script_count';
  BEGIN
    -- for your own interface function replace the following part with your routine to detect scripts waiting
    SELECT COUNT(*)
      INTO l_return
      FROM sosl_if_script -- replace this table with your implementation table or queue
           -- internal conditions about scripts ready to execute, replace them with your conditions
     WHERE script_active = sosl_if.SCRIPT_ACTIVE
       AND run_state     = sosl_if.SCRIPT_WAITING
       AND delivered    != sosl_if.SCRIPT_DELIVERED
           -- we need an assigned executor for the payload
       AND executor_id  IS NOT NULL
    ;
    -- end of individual section
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END get_script_count;

  FUNCTION set_script_delivered(p_script_id IN NUMBER)
    RETURN BOOLEAN
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_caller  VARCHAR2(256) := 'sosl_if.set_script_delivered';
  BEGIN
    UPDATE sosl_if_script
       SET delivered = sosl_if.SCRIPT_DELIVERED
     WHERE script_id = p_script_id
    ;
    COMMIT;
    RETURN TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN FALSE;
  END set_script_delivered;

  FUNCTION provide_next_script
    RETURN &SOSL_SCHEMA..SOSL_PAYLOAD
  IS
    l_payload       &SOSL_SCHEMA..SOSL_PAYLOAD;
    l_executor_id   NUMBER;
    l_script_id     NUMBER;
    l_script_cnt    NUMBER;
    l_ext_script_id VARCHAR2(4000);
    l_script_file   VARCHAR2(4000);
    -- adjust the variables to your function
    l_caller        VARCHAR2(256) := 'sosl_if.provide_next_script';
    CURSOR cur_script_data
    IS
      -- replace select with your own definition that delivers the executor id, the external script id as CHAR and the
      -- script file name including full or relative path
      SELECT executor_id
           , TRIM(TO_CHAR(script_id)) AS ext_script_id
           , script_name AS script_file
           , script_id
        FROM sosl_if_script -- replace this table with your implementation table or queue
             -- internal conditions about scripts ready to execute, replace them with your conditions
       WHERE script_active = sosl_if.SCRIPT_ACTIVE
         AND run_state     = sosl_if.SCRIPT_WAITING
         AND delivered    != sosl_if.SCRIPT_DELIVERED
             -- we need an assigned executor for the payload
         AND executor_id  IS NOT NULL
             -- adjust the order in which scripts get delivered
       ORDER BY run_order
    ;
  BEGIN
    l_payload := NULL;
    -- check if we have scripts, replace with your own has_scripts function
    l_script_cnt := sosl_if.get_script_count;
    IF l_script_cnt > 0
    THEN
      -- fetch only the first record, statement apart from order is identical to has_scripts statement
      OPEN cur_script_data;
      FETCH cur_script_data INTO l_executor_id, l_ext_script_id, l_script_file, l_script_id;
      CLOSE cur_script_data;
      -- you may want to add checks for the payload data before building the SOSL_PAYLOAD
      l_payload := &SOSL_SCHEMA..SOSL_PAYLOAD(l_executor_id, l_ext_script_id, l_script_file);
      -- if we arrive here, we can update the script and set it to delivered before delivering it
      IF NOT sosl_if.set_script_delivered(l_script_id)
      THEN
        sosl_if.log_error(l_caller, 'Could not set script to delivered, sosl_if.set_script_delivered failed');
        -- reset payload
        l_payload := NULL;
      END IF;
    ELSE
      -- log error information
      sosl_if.log_error(l_caller, 'Called without having scripts to run, sosl_if.get_script_count reports: ' || l_script_cnt);
      l_payload := NULL;
    END IF;
    RETURN l_payload;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN NULL;
  END provide_next_script;

  FUNCTION update_script_status( p_run_id         IN NUMBER
                               , p_sosl_run_state IN NUMBER
                               )
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_caller      VARCHAR2(256) := 'sosl_if.update_script_status';
    l_return      NUMBER;
    l_script_id   NUMBER;
    l_executor_id NUMBER;
    l_run_state   NUMBER;
    l_payload     &SOSL_SCHEMA..SOSL_PAYLOAD;
  BEGIN
    l_return    := -1;
    l_run_state := sosl_if.map_run_state(p_sosl_run_state);
    l_payload   := sosl_if.get_payload(p_run_id);
    IF l_payload IS NOT NULL
    THEN
      -- transform to internal type
      l_script_id   := TO_NUMBER(l_payload.ext_script_id);
      l_executor_id := l_payload.executor_id;
      -- update internal script table, replace with your routine to update internal status
      UPDATE sosl_if_script
         SET run_state = l_run_state
       WHERE script_id   = l_script_id
         AND executor_id = l_executor_id
      ;
      COMMIT;
      l_return := 0;
    ELSE
      -- log error information
      sosl_if.log_error(l_caller, 'Invalid SOSL_PAYLOAD for run_id: ' || p_run_id || ' and run state ' || p_sosl_run_state);
      l_return := -1;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END update_script_status;

  FUNCTION mail_sender( p_run_id         IN NUMBER
                      , p_sosl_run_state IN NUMBER
                      )
    RETURN VARCHAR2
  IS
  BEGIN
    -- implement here the functionality to determine the mail sender
    -- for the given script or state. To get the script details you
    -- will need to get the SOSL payload for the given run id.
    RETURN 'fake_sender@fake_domain.com';
  END mail_sender;

  FUNCTION mail_recipients( p_run_id         IN NUMBER
                          , p_sosl_run_state IN NUMBER
                          )
    RETURN VARCHAR2
  IS
  BEGIN
    -- implement here the functionality to determine the mail recipients list
    -- for the given script or state delimited by semicolon. To get the script details you
    -- will need to get the SOSL payload for the given run id.
    RETURN 'fake_recipient_group@fake_domain.com; fake_recipient_special@fake_domain.com';
  END mail_recipients;

  FUNCTION mail_host( p_run_id         IN NUMBER
                    , p_sosl_run_state IN NUMBER
                    )
    RETURN VARCHAR2
  IS
  BEGIN
    -- implement here the functionality to determine the mail host to use
    -- for the given script or state. To get the script details you
    -- will need to get the SOSL payload for the given run id.
    RETURN 'fake.mail.com';
  END mail_host;

  FUNCTION mail_port( p_run_id         IN NUMBER
                    , p_sosl_run_state IN NUMBER
                    )
    RETURN NUMBER
  IS
  BEGIN
    -- implement here the functionality to determine the mail port to use
    -- for the given script or state. To get the script details you
    -- will need to get the SOSL payload for the given run id.
    RETURN 25;
  END mail_port;

  FUNCTION mail_subject( p_run_id         IN NUMBER
                       , p_sosl_run_state IN NUMBER
                       , p_sosl_payload   IN &SOSL_SCHEMA..SOSL_PAYLOAD
                       )
    RETURN VARCHAR2
  IS
    l_mail_subject  VARCHAR2(256);
    l_caller        VARCHAR2(256) := 'sosl_if.mail_subject';
  BEGIN
    IF p_sosl_payload IS NOT NULL
    THEN
      l_mail_subject  := 'SOSL ' || sosl_if.map_run_state_text(p_sosl_run_state) || ' Script: ' || TRIM(NVL(p_sosl_payload.script_file, 'ERROR not available'));
    ELSE
      l_mail_subject  := 'SOSL ERROR ' || l_caller || ' - invalid payload for run id ' || p_run_id;
    END IF;
    RETURN l_mail_subject;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN 'EXCEPTION sosl_if.mail_subject building the subject, see logs for details';
  END mail_subject;

  FUNCTION mail_body( p_run_id         IN NUMBER
                    , p_sosl_run_state IN NUMBER
                    , p_sosl_payload   IN &SOSL_SCHEMA..SOSL_PAYLOAD
                    )
    RETURN VARCHAR2
  IS
    l_mail_body VARCHAR2(32767);
    l_caller    VARCHAR2(256) := 'sosl_if.mail_body';
  BEGIN
    IF p_sosl_payload IS NOT NULL
    THEN
      l_mail_body := 'Dear SOSL user' || sosl_if.LF || sosl_if.LF ||
                     CASE
                       WHEN sosl_if.map_run_state(p_sosl_run_state) = sosl_if.SCRIPT_ERROR
                       THEN 'An ERROR happened during script execution.'
                       ELSE 'The state of the script execution has changed to ' || sosl_if.map_run_state_text(p_sosl_run_state)
                     END || sosl_if.LF ||
                     'Script: ' || p_sosl_payload.script_file || sosl_if.LF ||
                     'Executor ID: ' || p_sosl_payload.executor_id || sosl_if.LF ||
                     'Script ID: ' || p_sosl_payload.ext_script_id || sosl_if.LF ||
                     'SOSL_RUN_QUEUE.RUN_ID: ' || p_run_id || sosl_if.LF ||
                     sosl_if.LF ||
                     'Best regards' || sosl_if.LF ||
                     'Your SOSL team'|| sosl_if.LF ||
                     sosl_if.LF ||
                     'Contact fake_admin@fake_domain.com for more information.'
      ;
    ELSE
      l_mail_body := 'Dear SOSL user' || sosl_if.LF || sosl_if.LF ||
                     'An SEVERE ERROR happened during script execution.' || sosl_if.LF ||
                     'Script cannot be identified, given payload is empty' || sosl_if.LF ||
                     'SOSL_RUN_QUEUE.RUN_ID: ' || p_run_id || sosl_if.LF ||
                     'Intended state change to: ' || sosl_if.map_run_state_text(p_sosl_run_state) || sosl_if.LF ||
                     sosl_if.LF ||
                     'Best regards' || sosl_if.LF ||
                     'Your SOSL team'|| sosl_if.LF ||
                     sosl_if.LF ||
                     'Contact fake_admin@fake_domain.com for more information.'
      ;
    END IF;
    RETURN l_mail_body;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN 'EXCEPTION sosl_if.mail_body building the body, see logs for details';
  END mail_body;

  FUNCTION deliver_mail( p_run_id IN NUMBER
                       , p_status IN NUMBER
                       )
    RETURN NUMBER
  IS
    l_return        NUMBER;
    l_mail_port     NUMBER;
    l_mail_host     VARCHAR2(256);
    l_mail_subject  VARCHAR2(256);
    l_mail_body     VARCHAR2(32767);
    l_sender        VARCHAR2(128);
    l_recipients    VARCHAR2(1024);
    l_payload       &SOSL_SCHEMA..SOSL_PAYLOAD;
    l_caller        VARCHAR2(256) := 'sosl_if.deliver_mail';
  BEGIN
    l_return := -1;
    -- implement here the functionality of the mail handling
    -- for the given script or state.
    -- ONLY DUMMY mail implemented so far
    l_payload := sosl_if.get_payload(p_run_id);
    IF l_payload IS NOT NULL
    THEN
      l_mail_host     := sosl_if.mail_host(p_run_id, p_status);
      l_mail_port     := sosl_if.mail_port(p_run_id, p_status);
      l_sender        := sosl_if.mail_sender(p_run_id, p_status);
      l_recipients    := sosl_if.mail_recipients(p_run_id, p_status);
      l_mail_subject  := sosl_if.mail_subject(p_run_id, p_status, l_payload);
      l_mail_body     := sosl_if.mail_body(p_run_id, p_status, l_payload);
      IF sosl_if.dummy_mail(l_sender, l_recipients, l_mail_subject, l_mail_body)
      THEN
        sosl_if.log_info(l_caller, 'Send mail with subject: ' || l_mail_subject);
        l_return := 0;
      ELSE
        sosl_if.log_error(l_caller, 'Calling sosl_if.dummy_mail failed, see logs for details');
        l_return := -1;
      END IF;
    ELSE
      sosl_if.log_error(l_caller, 'Invalid SOSL payload for run id ' || p_run_id || ' and state change to ' || p_status);
      l_return := -1;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END deliver_mail;
  -- ==============================
  -- maintenance functions

  FUNCTION add_script( p_script_name    IN VARCHAR2
                     , p_executor_id    IN NUMBER
                     , p_run_order      IN NUMBER   DEFAULT 1
                     , p_script_active  IN NUMBER   DEFAULT 0
                     )
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return  NUMBER;
    -- adjust the variables to your function
    l_caller  VARCHAR2(256) := 'sosl_if.add_script';
  BEGIN
    -- no checks just insert, replace this with your routine to add scripts
    INSERT INTO sosl_if_script
      ( script_name
      , executor_id
      , run_order
      , script_active
      )
      VALUES ( p_script_name
             , p_executor_id
             , p_run_order
             , p_script_active
             )
      RETURNING script_id INTO l_return
    ;
    COMMIT;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END add_script;

  FUNCTION set_run_state( p_script_id IN NUMBER
                        , p_run_state IN NUMBER DEFAULT 0
                        )
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    -- adjust the variables to your function
    l_caller  VARCHAR2(256) := 'sosl_if.set_run_state';
  BEGIN
    -- we are simple here, switching the active state to waiting switches also the delivered state to 0
    IF p_run_state = sosl_if.SCRIPT_WAITING
    THEN
      -- replace this with your update routine
      UPDATE sosl_if_script
        SET run_state = p_run_state
          , delivered = 0
      WHERE script_id = p_script_id
      ;
    ELSE
      -- replace this with your update routine
      UPDATE sosl_if_script
        SET run_state = p_run_state
      WHERE script_id = p_script_id
      ;
    END IF;
    COMMIT;
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END set_run_state;

  FUNCTION set_active_state( p_script_id      IN NUMBER
                           , p_script_active  IN NUMBER DEFAULT 0
                           )
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    -- adjust the variables to your function
    l_caller  VARCHAR2(256) := 'sosl_if.set_active_state';
  BEGIN
    -- replace this with your update routine
    UPDATE sosl_if_script
      SET script_active = p_script_active
    WHERE script_id = p_script_id
    ;
    COMMIT;
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END set_active_state;

  FUNCTION reset_scripts
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_result  NUMBER;
    -- adjust the variables to your function
    l_caller  VARCHAR2(256) := 'sosl_if.reset_scripts';
    CURSOR cur_scripts
    IS
      SELECT script_id
        FROM sosl_if_script
       WHERE run_state != sosl_if.SCRIPT_WAITING
    ;
  BEGIN
    sosl_if.log_info(l_caller, 'Reset all scripts in SOSL_IF_SCRIPT to run_state WAITING');
    FOR rec IN cur_scripts
    LOOP
      -- errors should be already logged
      l_result := sosl_if.set_run_state(rec.script_id, sosl_if.SCRIPT_WAITING);
    END LOOP;
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END reset_scripts;

  FUNCTION activate_scripts
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_result  NUMBER;
    -- adjust the variables to your function
    l_caller  VARCHAR2(256) := 'sosl_if.activate_scripts';
    CURSOR cur_scripts
    IS
      SELECT script_id
        FROM sosl_if_script
       WHERE script_active != sosl_if.SCRIPT_ACTIVE
    ;
  BEGIN
    sosl_if.log_info(l_caller, 'Activate all scripts in SOSL_IF_SCRIPT to enable them for execution');
    FOR rec IN cur_scripts
    LOOP
      -- errors should be already logged
      l_result := sosl_if.set_active_state(rec.script_id, sosl_if.SCRIPT_ACTIVE);
    END LOOP;
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END activate_scripts;

  FUNCTION deactivate_scripts
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_result        NUMBER;
    -- adjust the variables to your function
    l_caller        VARCHAR2(256) := 'sosl_if.deactivate_scripts';
    CURSOR cur_scripts
    IS
      SELECT script_id
        FROM sosl_if_script
       WHERE script_active != sosl_if.SCRIPT_INACTIVE
    ;
  BEGIN
    sosl_if.log_info(l_caller, 'Deactivate all scripts in SOSL_IF_SCRIPT to disable them for execution');
    FOR rec IN cur_scripts
    LOOP
      -- errors should be already logged
      l_result := sosl_if.set_active_state(rec.script_id, sosl_if.SCRIPT_INACTIVE);
    END LOOP;
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END deactivate_scripts;
  -- ==============================
  -- eventually provide the interface functions for SOSL

  FUNCTION has_scripts
    RETURN NUMBER
  IS
    l_return       NUMBER;
    -- adjust the variables to your function
    l_caller       VARCHAR2(256) := 'sosl_if.has_scripts';
  BEGIN
    RETURN sosl_if.get_script_count;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END has_scripts;

  FUNCTION get_next_script
    RETURN &SOSL_SCHEMA..SOSL_PAYLOAD
  IS
    l_caller  VARCHAR2(256) := 'sosl_if.get_next_script';
  BEGIN
    RETURN sosl_if.provide_next_script;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN NULL;
  END get_next_script;

  FUNCTION set_script_status( p_run_id IN NUMBER
                            , p_status IN NUMBER
                            )
    RETURN NUMBER
  IS
    l_caller        VARCHAR2(256) := 'sosl_if.set_script_status';
  BEGIN
    RETURN sosl_if.update_script_status(p_run_id, p_status);
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END set_script_status;

  FUNCTION send_mail( p_run_id IN NUMBER
                    , p_status IN NUMBER
                    )
    RETURN NUMBER
  IS
    l_caller        VARCHAR2(256) := 'sosl_if.send_mail';
  BEGIN
    RETURN sosl_if.deliver_mail(p_run_id, p_status);
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      sosl_if.log_exception(l_caller, SQLERRM);
      RETURN -1;
  END send_mail;

END;
/
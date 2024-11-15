-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- As this package depends on the schema SOSL is installed, getting fully qualified calls must be determined
-- dynamically using SQLPlus variable SOSL_SCHEMA.
COLUMN SOSL_SCHEMA NEW_VAL SOSL_SCHEMA
SELECT config_value AS SOSL_SCHEMA FROM sosl_config WHERE config_name = 'SOSL_SCHEMA';

CREATE OR REPLACE PACKAGE BODY sosl_if
AS
  -- see package header for documentation, can be used as an template for own interface functions
  -- therefore all packages calls are fully qualified
  FUNCTION has_scripts
    RETURN NUMBER
  IS
    l_return       NUMBER;
    -- adjust the variables to your function
    l_log_category VARCHAR2(256) := 'SOSL_IF';
    l_caller       VARCHAR2(256) := 'sosl_if.has_scripts';
  BEGIN
    -- for your own interface function replace the following part with your routine to detect scripts waiting
    SELECT COUNT(*)
      INTO l_return
      FROM sosl_if_script
           -- internal conditions about scripts ready to execute
     WHERE script_active = &SOSL_SCHEMA..sosl_constants.NUM_YES
       AND run_state     = &SOSL_SCHEMA..sosl_constants.RUN_STATE_WAITING
           -- we need an assigned executor for the payload
       AND executor_id   IS NOT NULL
    ;
    -- end of individual section
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE, replace parameters with your function or package names and categories
      &SOSL_SCHEMA..sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      RETURN -1;
  END has_scripts;

  FUNCTION get_next_script
    RETURN &SOSL_SCHEMA..SOSL_PAYLOAD
  IS
    l_payload       &SOSL_SCHEMA..SOSL_PAYLOAD;
    l_executor_id   NUMBER;
    l_ext_script_id VARCHAR2(4000);
    l_script_file   VARCHAR2(4000);
    -- adjust the variables to your function
    l_log_category  VARCHAR2(256) := 'SOSL_IF';
    l_caller        VARCHAR2(256) := 'sosl_if.get_next_script';
    CURSOR cur_script_data
    IS
      -- replace select with your own definition that delivers the executor id, the external script id as CHAR and the
      -- script file name including full or relative path
      SELECT executor_id
           , TRIM(TO_CHAR(script_id)) AS ext_script_id
           , script_name AS script_file
        FROM sosl_if_script
             -- internal conditions about scripts ready to execute
       WHERE script_active = &SOSL_SCHEMA..sosl_constants.NUM_YES
         AND run_state     = &SOSL_SCHEMA..sosl_constants.RUN_STATE_WAITING
             -- we need an assigned executor for the payload
         AND executor_id   IS NOT NULL
             -- adjust the order in which scripts get delivered
       ORDER BY run_group
              , run_order
    ;
  BEGIN
    l_payload := NULL;
    -- check if we have scripts, replace with your own has_scripts function
    IF sosl_if.has_scripts > 0
    THEN
      -- fetch only the first record, statement apart from order is identical to has_scripts statement
      OPEN cur_script_data;
      FETCH cur_script_data INTO l_executor_id, l_ext_script_id, l_script_file;
      CLOSE cur_script_data;
      -- you may want to add checks for the payload data before building the SOSL_PAYLOAD
      l_payload := &SOSL_SCHEMA..SOSL_PAYLOAD(l_executor_id, l_ext_script_id, l_script_file);
    ELSE
      -- log error information
      &SOSL_SCHEMA..sosl_log.minimal_error_log(l_caller, l_log_category, 'get_next_script called without having scripts to run');
      l_payload := NULL;
    END IF;
    RETURN l_payload;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      &SOSL_SCHEMA..sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      RETURN NULL;
  END get_next_script;

  FUNCTION set_script_status( p_run_id IN NUMBER
                            , p_status IN NUMBER
                            )
    RETURN NUMBER
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    l_return        NUMBER;
    l_script_id     NUMBER;
    l_executor_id   NUMBER;
    l_payload       &SOSL_SCHEMA..SOSL_PAYLOAD;
    -- adjust the variables to your function
    l_log_category  VARCHAR2(256) := 'SOSL_IF';
    l_caller        VARCHAR2(256) := 'sosl_if.set_script_status';
  BEGIN
    l_return := -1;
    -- get payload for own identifiers as send by get_next_script
    l_payload := &SOSL_SCHEMA..sosl_server.get_payload(p_run_id);
    IF l_payload IS NOT NULL
    THEN
      -- transform to internal type
      l_script_id   := TO_NUMBER(l_payload.ext_script_id);
      l_executor_id := l_payload.executor_id;
      -- update internal script table, replace with your routine to update internal status
      UPDATE sosl_if_script
         SET run_state = p_status
       WHERE script_id    = l_script_id
         AND executor_id  = l_executor_id
      ;
      COMMIT;
      l_return := 0;
    ELSE
      -- log error information
      &SOSL_SCHEMA..sosl_log.minimal_error_log(l_caller, l_log_category, 'Invalid SOSL_PAYLOAD for run_id: ' || p_run_id || ' and run state ' || p_status);
      l_return := -1;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      &SOSL_SCHEMA..sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      RETURN -1;
  END set_script_status;

  FUNCTION send_mail( p_run_id IN NUMBER
                    , p_status IN NUMBER
                    )
    RETURN NUMBER
  IS
    l_return        NUMBER;
    l_mail_subject  VARCHAR2(256);
    l_mail_body     VARCHAR2(32767);
    l_sender        VARCHAR2(128);
    l_recipients    VARCHAR2(1024);
    l_payload       &SOSL_SCHEMA..SOSL_PAYLOAD;
    -- adjust the variables to your function
    l_log_category  VARCHAR2(256) := 'SOSL_IF';
    l_caller        VARCHAR2(256) := 'sosl_if.send_mail';
  BEGIN
    l_return := -1;
    -- define basic objects
    l_mail_subject  := 'SOSL ' || &SOSL_SCHEMA..sosl_constants.run_state_text(p_status) || ' ';
    l_sender        := 'fake_sender@fake_domain.com';
    l_recipients    := 'fake_recipient_group@fake_domain.com; fake_recipient_special@fake_domain.com';
    IF &SOSL_SCHEMA..sosl_server.has_run_id(p_run_id)
    THEN
      -- get payload for own identifiers as send by get_next_script
      l_payload := &SOSL_SCHEMA..sosl_server.get_payload(p_run_id);
      IF l_payload IS NOT NULL
      THEN
        -- prepare mail
        l_mail_subject  := l_mail_subject || 'Script: ' || TRIM(l_payload.script_file);
        -- format mail body RFC conform, use LF, CR is also valid, but NOT CRLF
        l_mail_body     := 'Dear SOSL user' || &SOSL_SCHEMA..sosl_constants.LF || &SOSL_SCHEMA..sosl_constants.LF ||
                           CASE
                             WHEN p_status = &SOSL_SCHEMA..sosl_constants.RUN_STATE_ERROR
                             THEN 'An ERROR happened during script execution.'
                             ELSE 'The state of the script execution has changed to ' || &SOSL_SCHEMA..sosl_constants.run_state_text(p_status)
                           END || &SOSL_SCHEMA..sosl_constants.LF ||
                           'Script: ' || l_payload.script_file || &SOSL_SCHEMA..sosl_constants.LF ||
                           'Executor ID: ' || l_payload.executor_id || &SOSL_SCHEMA..sosl_constants.LF ||
                           'Script ID: ' || l_payload.ext_script_id || &SOSL_SCHEMA..sosl_constants.LF ||
                           'SOSL_RUN_QUEUE.RUN_ID: ' || p_run_id || &SOSL_SCHEMA..sosl_constants.LF ||
                           &SOSL_SCHEMA..sosl_constants.LF ||
                           'Best regards' || &SOSL_SCHEMA..sosl_constants.LF ||
                           'Your SOSL team'|| &SOSL_SCHEMA..sosl_constants.LF ||
                           &SOSL_SCHEMA..sosl_constants.LF ||
                           'Contact fake_admin@fake_domain.com for more information.'
        ;
      ELSE
        -- we still have data for the mail
        l_mail_subject := l_mail_subject || 'RUN_ID: ' || p_run_id;
        l_mail_body     := 'Dear SOSL user' || &SOSL_SCHEMA..sosl_constants.LF || &SOSL_SCHEMA..sosl_constants.LF ||
                           'An SEVERE ERROR happened during script execution.' || &SOSL_SCHEMA..sosl_constants.LF ||
                           'Script cannot be identified or sosl_server.GET_PAYLOAD has failed.' || &SOSL_SCHEMA..sosl_constants.LF ||
                           'SOSL_RUN_QUEUE.RUN_ID: ' || p_run_id || &SOSL_SCHEMA..sosl_constants.LF ||
                           'Intended state change to: ' || &SOSL_SCHEMA..sosl_constants.run_state_text(p_status) || &SOSL_SCHEMA..sosl_constants.LF ||
                           &SOSL_SCHEMA..sosl_constants.LF ||
                           'Best regards' || &SOSL_SCHEMA..sosl_constants.LF ||
                           'Your SOSL team'|| &SOSL_SCHEMA..sosl_constants.LF ||
                           &SOSL_SCHEMA..sosl_constants.LF ||
                           'Contact fake_admin@fake_domain.com for more information.'
        ;
      END IF;
      IF &SOSL_SCHEMA..sosl_server.dummy_mail(l_sender, l_recipients, l_mail_subject, l_mail_body)
      THEN
        l_return := 0;
      ELSE
        &SOSL_SCHEMA..sosl_log.minimal_error_log(l_caller, l_log_category, 'Could not send fake mail to log.');
        l_return := -1;
      END IF;
    ELSE
      &SOSL_SCHEMA..sosl_log.minimal_error_log('sosl_if.send_mail', 'SOSL_IF', 'RUN_ID ' || p_run_id || ' does not exist.');
      l_mail_subject := l_mail_subject || 'Invalid RUN_ID: ' || p_run_id;
      l_mail_body     := 'Dear SOSL user' || &SOSL_SCHEMA..sosl_constants.LF || &SOSL_SCHEMA..sosl_constants.LF ||
                         'An SEVERE ERROR happened during script execution.' || &SOSL_SCHEMA..sosl_constants.LF ||
                         'Given RUN_ID does not exist in table SOSL_RUN_QUEUE.' || &SOSL_SCHEMA..sosl_constants.LF ||
                         'SOSL_RUN_QUEUE.RUN_ID: ' || p_run_id || &SOSL_SCHEMA..sosl_constants.LF ||
                         'Intended state change to: ' || sosl_constants.run_state_text(p_status) || &SOSL_SCHEMA..sosl_constants.LF ||
                         &SOSL_SCHEMA..sosl_constants.LF ||
                         'Best regards' || &SOSL_SCHEMA..sosl_constants.LF ||
                         'Your SOSL team'|| &SOSL_SCHEMA..sosl_constants.LF ||
                         &SOSL_SCHEMA..sosl_constants.LF ||
                         'Contact fake_admin@fake_domain.com for more information.'
      ;
      IF &SOSL_SCHEMA..sosl_server.dummy_mail(l_sender, l_recipients, l_mail_subject, l_mail_body)
      THEN
        l_return := 0;
      ELSE
        &SOSL_SCHEMA..sosl_log.minimal_error_log(l_caller, l_log_category, 'Could not send fake mail to log.');
        l_return := -1;
      END IF;
    END IF;
    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      -- log the error instead of RAISE
      &SOSL_SCHEMA..sosl_log.exception_log(l_caller, l_log_category, SQLERRM);
      RETURN -1;
  END send_mail;

END;
/
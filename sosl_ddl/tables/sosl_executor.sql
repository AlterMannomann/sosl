-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE TABLE sosl_executor
  ( executor_id           NUMBER(38, 0)   GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , executor_name         VARCHAR2(256)                                             NOT NULL
  , db_user               VARCHAR2(128)                                             NOT NULL
  , function_owner        VARCHAR2(128)                                             NOT NULL
  , fn_has_ids            VARCHAR2(520)                                             NOT NULL
  , fn_get_next_id        VARCHAR2(520)                                             NOT NULL
  , fn_get_executor       VARCHAR2(520)                                             NOT NULL
  , fn_get_script         VARCHAR2(520)                                             NOT NULL
  , fn_set_status         VARCHAR2(520)                                             NOT NULL
  , cfg_file              VARCHAR2(4000)                                            NOT NULL
  , use_mail              NUMBER(1, 0)    DEFAULT 0                                 NOT NULL
  , mail_sender           VARCHAR2(1024)  DEFAULT 'n/a'                             NOT NULL
  , mail_recipients       VARCHAR2(1024)  DEFAULT 'n/a'                             NOT NULL
  , fn_send_db_mail       VARCHAR2(520)   DEFAULT 'sosl_sys.dummy_mail'             NOT NULL
  , executor_active       NUMBER(1, 0)    DEFAULT 0                                 NOT NULL
  , executor_reviewed     NUMBER(1, 0)    DEFAULT 0                                 NOT NULL
  , created               DATE            DEFAULT SYSDATE                           NOT NULL
  , updated               DATE            DEFAULT SYSDATE                           NOT NULL
  , created_by            VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , created_by_os         VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , updated_by            VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , updated_by_os         VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , script_schema         VARCHAR2(128)   DEFAULT NULL
  , executor_description  VARCHAR2(4000)
  )
;
COMMENT ON TABLE sosl_executor IS 'Defines the executors registered with SOSL. To improve security you may activate AUDIT on this table. Will use the alias sexe.';
COMMENT ON COLUMN sosl_executor.executor_id IS 'The generated unique id that identifies the executor.';
COMMENT ON COLUMN sosl_executor.executor_name IS 'The unique name that identifies the executor.';
COMMENT ON COLUMN sosl_executor.db_user IS 'The login name of the database user must match cfg_file login and be USER after login. No mixed case support, converted to upper case. Must exist and have the necessary rights to execute the queued scripts. No update allowed. Create a new executor, if user changes.';
COMMENT ON COLUMN sosl_executor.function_owner IS 'The owner user name of the API functions, refers to the schema where the functions are defined. No mixed case support, converted to upper case. Can differ from the database user that executes SOSL. All API functions must have the same owner for one executor. No update allowed. Create a new executor, if user changes.';
COMMENT ON COLUMN sosl_executor.fn_has_ids IS 'The name of the function to use by HAS_IDS wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall not require parameters and return the amount of waiting scripts as NUMBER or -1 on errors.';
COMMENT ON COLUMN sosl_executor.fn_get_next_id IS 'The name of the function to use by GET_NEXT_ID wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall not require parameters and return the script id as VARCHAR2. It should manage the given script id to ensure that scripts are not run twice.';
COMMENT ON COLUMN sosl_executor.fn_get_executor IS 'The name of the function to use by GET_EXECUTOR wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall require the parameter P_ID IN VARCHAR2 and return the executor id as NUMBER. P_ID is an script id retrieved from GET_NEXT_ID.';
COMMENT ON COLUMN sosl_executor.fn_get_script IS 'The name of the function to use by GET_SCRIPT wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall require the parameter P_ID IN VARCHAR2 and return the script name with full or relative path as VARCHAR2. The script must exist in the given path on the local server SOSL is running.';
COMMENT ON COLUMN sosl_executor.fn_set_status IS 'The name of the function to use by SET_STATUS wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall require the parameters P_ID IN VARCHAR2, P_STATUS IN VARCHAR2 and return 0 or -1 on errors. P_ID is an script id retrieved from GET_NEXT_ID. P_STATUS will always start with the following key words: PREPARING, ENQUEUED, RUNNING, SUCCESS, ERROR. It may contain additional informations in case of errors separated by at least one space char.';
COMMENT ON COLUMN sosl_executor.fn_send_db_mail IS 'The name of the function to use by SEND_DB_MAIL wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall require the parameters P_SENDER IN VARCHAR2, P_RECIPIENTS IN VARCHAR2, P_SUBJECT IN VARCHAR2, P_MESSAGE IN VARCHAR2 and return 0 or -1 on errors. P_SENDER is the email address of the sender. P_RECIPIENTS contains the email addresses of the recipients, delimited by semicolon ";". P_SUBJECT is the email subject to use. P_MESSAGE contains the email message.';
COMMENT ON COLUMN sosl_executor.cfg_file IS 'The filename with absolute or relative path to the login config file for this executor. File and path must exist on the CMD server.';
COMMENT ON COLUMN sosl_executor.executor_active IS 'Defines if the executor is active. Accepts 0 (NO/FALSE) and 1 (YES/TRUE). Not active and reviewed executors will be ignored if they try to run scripts, every attempt gets logged. Can only be set by update, on insert always the default is used.';
COMMENT ON COLUMN sosl_executor.executor_reviewed IS 'Defines if the executor is reviewed, accepted and ready to be used. Accepts 0 (NO/FALSE) and 1 (YES/TRUE). Not active and reviewed executors will be ignored if they try to run scripts, every attempt gets logged. Can only be set by update, on insert always the default is used.';
COMMENT ON COLUMN sosl_executor.created IS 'Date created, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.updated IS 'Date updated, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.created_by IS 'DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.created_by_os IS 'OS user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.updated_by IS 'DB user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.updated_by_os IS 'OS user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.script_schema IS 'The (optional) schema the script should run in. If set will cause an ALTER SESSION SET CURRENT_SCHEMA before executing the script otherwise db user schema is used. DB user must have rights for this schema if set. If acting on own schema or scripts do ALTER SESSION by themselves, you should leave it NULL.';
COMMENT ON COLUMN sosl_executor.executor_description IS 'Optional executor description.';
-- primary key
ALTER TABLE sosl_executor
  ADD CONSTRAINT sosl_executor_pk
  PRIMARY KEY (executor_id)
  ENABLE
;
-- unique constraint
ALTER TABLE sosl_executor
  ADD CONSTRAINT sosl_executor_uk
  UNIQUE (executor_name)
  ENABLE
;
-- check constraints
ALTER TABLE sosl_executor
  ADD CONSTRAINT sosl_executor_chk_use_mail
  CHECK (use_mail IN (0, 1))
  ENABLE
;
ALTER TABLE sosl_executor
  ADD CONSTRAINT sosl_executor_chk_active
  CHECK (executor_active IN (0, 1))
  ENABLE
;
ALTER TABLE sosl_executor
  ADD CONSTRAINT sosl_executor_chk_reviewed
  CHECK (executor_reviewed IN (0, 1))
  ENABLE
;
-- trigger
CREATE OR REPLACE TRIGGER sosl_executor_ins_trg
  BEFORE INSERT ON sosl_executor
  FOR EACH ROW
DECLARE
  l_caller    VARCHAR2(256) := 'sosl_executor_ins_trg';
  l_category  VARCHAR2(256) := 'SOSL_EXECUTOR';
BEGIN
  :NEW.created            := SYSDATE;
  :NEW.created_by         := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.created_by_os      := SYS_CONTEXT('USERENV', 'OS_USER');
  :NEW.updated            := SYSDATE;
  :NEW.updated_by         := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.updated_by_os      := SYS_CONTEXT('USERENV', 'OS_USER');
  :NEW.executor_active    := 0;
  :NEW.executor_reviewed  := 0;
  -- transform users and functions to UPPERCASE, no support currently for special mix-case.
  :NEW.function_owner     := UPPER(:NEW.function_owner);
  :NEW.db_user            := UPPER(:NEW.db_user);
  :NEW.fn_has_ids         := UPPER(:NEW.fn_has_ids);
  :NEW.fn_get_next_id     := UPPER(:NEW.fn_get_next_id);
  :NEW.fn_get_executor    := UPPER(:NEW.fn_get_executor);
  :NEW.fn_get_script      := UPPER(:NEW.fn_get_script);
  :NEW.fn_set_status      := UPPER(:NEW.fn_set_status);
  :NEW.fn_send_db_mail    := UPPER(:NEW.fn_send_db_mail);
  -- check user
  IF NOT sosl_sys.has_db_user(:NEW.db_user)
  THEN
    sosl_log.full_log( p_message => 'The given database user is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20003, 'The given database user is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.');
  END IF;
  IF NOT sosl_sys.has_db_user(:NEW.function_owner)
  THEN
    sosl_log.full_log( p_message => 'The given function owner database user is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20003, 'The given function owner database user is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.');
  END IF;
  -- check configured functions
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_has_ids, 'NUMBER')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_has_ids || ' for has_ids is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20004, 'The given function ' || :NEW.fn_has_ids || ' for has_ids is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_get_next_id, 'VARCHAR2')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_get_next_id || ' for get_next_id is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype VARCHAR2 or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20005, 'The given function ' || :NEW.fn_get_next_id || ' for get_next_id is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype VARCHAR2 or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_get_executor, 'NUMBER')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_get_executor || ' for get_executor is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20006, 'The given function ' || :NEW.fn_get_executor || ' for get_executor is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_get_script, 'VARCHAR2')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_get_script || ' for get_script is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype VARCHAR2 or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20007, 'The given function ' || :NEW.fn_get_script || ' for get_script is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype VARCHAR2 or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_set_status, 'NUMBER')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_set_status || ' for set_status is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20008, 'The given function ' || :NEW.fn_set_status || ' for set_status is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF     :NEW.use_mail = 1
     AND NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_send_db_mail, 'NUMBER')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_send_db_mail || ' for send db mail is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20009, 'The given function ' || :NEW.fn_send_db_mail || ' for send db mail is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  -- log the insert
  sosl_log.full_log( p_message => 'A new executor has been defined for DB user: ' || :NEW.db_user || ' with function owner: ' || :NEW.function_owner || ' created by OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                   , p_log_type => sosl_sys.INFO_TYPE
                   , p_log_category => l_category
                   , p_caller => l_caller
                   )
  ;
EXCEPTION
  WHEN OTHERS THEN
    -- catch and log all undefined exceptions
    IF SQLCODE NOT IN (-20003, -20004, -20005, -20006, -20007, -20008, -20009)
    THEN
      sosl_log.full_log( p_message => 'Unhandled exception in trigger sosl_executor_ins_trg: ' || SQLERRM
                       , p_log_type => sosl_sys.FATAL_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
    END IF;
    -- raise all errors
    RAISE;
END;
/
CREATE OR REPLACE TRIGGER sosl_executor_upd_trg
  BEFORE UPDATE ON sosl_executor
  FOR EACH ROW
DECLARE
  l_change_record VARCHAR2(32767);
  l_caller        VARCHAR2(256) := 'sosl_executor_upd_trg';
  l_category      VARCHAR2(256) := 'SOSL_EXECUTOR';
BEGIN
  l_change_record := 'Changes by OS user ' || SYS_CONTEXT('USERENV', 'OS_USER') || ': ';
  :NEW.updated            := SYSDATE;
  :NEW.updated_by         := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.updated_by_os      := SYS_CONTEXT('USERENV', 'OS_USER');
  -- no overwrite for this values
  IF :NEW.created != :OLD.created
  THEN
    l_change_record := l_change_record || 'Prohibited change of create date to: "' || TO_CHAR(:NEW.created, 'YYYY-MM-DD HH24:MI:SS') || '" ';
    :NEW.created            := :OLD.created;
  END IF;
  :NEW.created_by         := :OLD.created_by;
  :NEW.created_by_os      := :OLD.created_by_os;
  IF UPPER(:NEW.function_owner) != :OLD.function_owner
  THEN
    l_change_record := l_change_record || 'Prohibited change of function owner to: "' || :NEW.function_owner || '" ';
    :NEW.function_owner := :OLD.function_owner;
  END IF;
  IF UPPER(:NEW.db_user) != :OLD.db_user
  THEN
    l_change_record := l_change_record || 'Prohibited change of db user to: "' || :NEW.db_user || '" ';
    :NEW.db_user := :OLD.db_user;
  END IF;
  -- prepare possibly modified values
  IF :NEW.executor_active != :OLD.executor_active
  THEN
    l_change_record := l_change_record || 'Modified EXECUTOR_ACTIVE: "' || sosl_sys.yes_no(:NEW.executor_active) || '" ';
  END IF;
  IF :NEW.executor_reviewed != :OLD.executor_reviewed
  THEN
    l_change_record := l_change_record || 'Modified EXECUTOR_REVIEWED: "' || sosl_sys.yes_no(:NEW.executor_reviewed) || '" ';
  END IF;
  IF UPPER(:NEW.fn_has_ids) != :OLD.fn_has_ids
  THEN
    :NEW.fn_has_ids := UPPER(:NEW.fn_has_ids);
    l_change_record := l_change_record || 'Modified FN_HAS_IDS: "' || :NEW.fn_has_ids || '" ';
  END IF;
  IF UPPER(:NEW.fn_get_next_id) != :OLD.fn_get_next_id
  THEN
    :NEW.fn_get_next_id := UPPER(:NEW.fn_get_next_id);
    l_change_record     := l_change_record || 'Modified FN_GET_NEXT_ID: "' || :NEW.fn_get_next_id || '" ';
  END IF;
  IF UPPER(:NEW.fn_get_executor) != :NEW.fn_get_executor
  THEN
    :NEW.fn_get_executor  := UPPER(:NEW.fn_get_executor);
    l_change_record       := l_change_record || 'Modified FN_GET_EXECUTOR: "' || :NEW.fn_get_executor || '" ';
  END IF;
  IF UPPER(:NEW.fn_get_script) != :OLD.fn_get_script
  THEN
    :NEW.fn_get_script  := UPPER(:NEW.fn_get_script);
    l_change_record       := l_change_record || 'Modified FN_GET_SCRIPT: "' || :NEW.fn_get_script || '" ';
  END IF;
  IF UPPER(:NEW.fn_set_status) != :OLD.fn_set_status
  THEN
    :NEW.fn_set_status := UPPER(:NEW.fn_set_status);
    l_change_record       := l_change_record || 'Modified FN_SET_STATUS: "' || :NEW.fn_set_status || '" ';
  END IF;
  IF UPPER(:NEW.fn_send_db_mail) != :OLD.fn_send_db_mail
  THEN
    :NEW.fn_send_db_mail := UPPER(:NEW.fn_send_db_mail);
    l_change_record       := l_change_record || 'Modified FN_SEND_DB_MAIL: "' || :NEW.fn_send_db_mail || '" ';
  END IF;
  -- do all checks again including user
  -- check user
  IF NOT sosl_sys.has_db_user(:NEW.db_user)
  THEN
    sosl_log.full_log( p_message => 'The given database user is not longer visible for SOSL in ALL_USERS. Executor deactivated. Either the user does not exist or SOSL has no right to see this user.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    :NEW.executor_active := 0;
  END IF;
  IF NOT sosl_sys.has_db_user(:NEW.function_owner)
  THEN
    sosl_log.full_log( p_message => 'The given function owner database user is not longer visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    :NEW.executor_active := 0;
  END IF;
  -- check configured functions
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_has_ids, 'NUMBER')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_has_ids || ' for has_ids is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20004, 'The given function ' || :NEW.fn_has_ids || ' for has_ids is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_get_next_id, 'VARCHAR2')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_get_next_id || ' for get_next_id is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype VARCHAR2 or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20005, 'The given function ' || :NEW.fn_get_next_id || ' for get_next_id is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype VARCHAR2 or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_get_executor, 'NUMBER')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_get_executor || ' for get_executor is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20006, 'The given function ' || :NEW.fn_get_executor || ' for get_executor is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_get_script, 'VARCHAR2')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_get_script || ' for get_script is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype VARCHAR2 or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20007, 'The given function ' || :NEW.fn_get_script || ' for get_script is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype VARCHAR2 or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_set_status, 'NUMBER')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_set_status || ' for set_status is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20008, 'The given function ' || :NEW.fn_set_status || ' for set_status is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF     :NEW.use_mail = 1
     AND NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_send_db_mail, 'NUMBER')
  THEN
    sosl_log.full_log( p_message => 'The given function ' || :NEW.fn_send_db_mail || ' for send db mail is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.'
                     , p_log_type => sosl_sys.FATAL_TYPE
                     , p_log_category => l_category
                     , p_caller => l_caller
                     )
    ;
    RAISE_APPLICATION_ERROR(-20009, 'The given function ' || :NEW.fn_send_db_mail || ' for send db mail is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  -- log the insert
  sosl_log.full_log( p_message => 'The executor ID: ' || :OLD.executor_id || ' has been updated by OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER') || ' see full_message for details.'
                   , p_log_type => sosl_sys.INFO_TYPE
                   , p_log_category => l_category
                   , p_caller => l_caller
                   , p_full_message => TO_CLOB(l_change_record)
                   )
  ;
EXCEPTION
  WHEN OTHERS THEN
    -- catch and log all undefined exceptions
    IF SQLCODE NOT IN (-20004, -20005, -20006, -20007, -20008, -20009)
    THEN
      sosl_log.full_log( p_message => 'Unhandled exception in trigger sosl_executor_upd_trg: ' || SQLERRM
                       , p_log_type => sosl_sys.FATAL_TYPE
                       , p_log_category => l_category
                       , p_caller => l_caller
                       )
      ;
    END IF;
    -- raise all errors
    RAISE;
END;
/

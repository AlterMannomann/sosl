-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE TABLE sosl_executor
  ( executor_id           NUMBER(38, 0)   GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , db_user               VARCHAR2(128)                                             NOT NULL
  , function_owner        VARCHAR2(128)                                             NOT NULL
  , fn_has_ids            VARCHAR2(520)                                             NOT NULL
  , fn_get_next_id        VARCHAR2(520)                                             NOT NULL
  , fn_get_executor       VARCHAR2(520)                                             NOT NULL
  , fn_get_script         VARCHAR2(520)                                             NOT NULL
  , fn_set_status         VARCHAR2(520)                                             NOT NULL
  , cfg_file              VARCHAR2(4000)                                            NOT NULL
  , executor_active       VARCHAR2(3)     DEFAULT 'NO'                              NOT NULL
  , executor_reviewed     VARCHAR2(3)     DEFAULT 'NO'                              NOT NULL
  , created               DATE            DEFAULT SYSDATE                           NOT NULL
  , updated               DATE            DEFAULT SYSDATE                           NOT NULL
  , created_by            VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , created_by_os         VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , updated_by            VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , updated_by_os         VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , executor_description  VARCHAR2(4000)
  )
;
COMMENT ON TABLE sosl_executor IS 'Defines the executors registered with SOSL. To improve security you may activate AUDIT on this table. Will use the alias sexe.';
COMMENT ON COLUMN sosl_executor.executor_id IS 'The generated unique id that identifies the executor.';
COMMENT ON COLUMN sosl_executor.db_user IS 'The login name of the database user must match cfg_file login and be USER after login. No mixed case support, converted to upper case. Must exist and have the necessary rights to execute the queued scripts.';
COMMENT ON COLUMN sosl_executor.function_owner IS 'The owner user name of the API functions, refers to the schema where the functions are defined. No mixed case support, converted to upper case. Can differ from the database user that executes SOSL. All API functions must have the same owner for one executor.';
COMMENT ON COLUMN sosl_executor.fn_has_ids IS 'The name of the function to use by HAS_IDS wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall not require parameters and return the amount of waiting script as NUMBER.';
COMMENT ON COLUMN sosl_executor.fn_get_next_id IS 'The name of the function to use by GET_NEXT_ID wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall not require parameters and return the script id as VARCHAR2. It should manage the given script id to ensure that scripts are not run twice.';
COMMENT ON COLUMN sosl_executor.fn_get_executor IS 'The name of the function to use by GET_EXECUTOR wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall require the parameter P_ID IN VARCHAR2 and return the executor id as NUMBER. P_ID is an script id retrieved from GET_NEXT_ID.';
COMMENT ON COLUMN sosl_executor.fn_get_script IS 'The name of the function to use by GET_SCRIPT wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall require the parameter P_ID IN VARCHAR2 and return the script name with full or relative path as VARCHAR2. The script must exist in the given path on the local server SOSL is running.';
COMMENT ON COLUMN sosl_executor.fn_set_status IS 'The name of the function to use by SET_STATUS wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall require the parameters P_ID IN VARCHAR2, P_STATUS IN VARCHAR2 and return 0 or -1 on errors. P_ID is an script id retrieved from GET_NEXT_ID. P_STATUS will always start with the following key words: PREPARING, ENQUEUED, RUNNING, SUCCESS, ERROR. It may contain additional informations in case of errors separated by at least one space char.';
COMMENT ON COLUMN sosl_executor.cfg_file IS 'The filename with absolute or relative path to the login config file for this executor. File and path must exist on the CMD server.';
COMMENT ON COLUMN sosl_executor.executor_active IS 'Defines if the executor is active. Accepts NO and YES. Not active and reviewed executors will be ignored if they try to run scripts, every attempt gets logged.';
COMMENT ON COLUMN sosl_executor.executor_reviewed IS 'Defines if the executor is reviewed, accepted and ready to be used. Accepts NO and YES. Not active and reviewed executors will be ignored if they try to run scripts, every attempt gets logged.';
COMMENT ON COLUMN sosl_executor.created IS 'Date created, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.updated IS 'Date updated, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.created_by IS 'DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.created_by_os IS 'OS user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.updated_by IS 'DB user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.updated_by_os IS 'OS user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_executor.executor_description IS 'Optional executor description.';
-- primary key
ALTER TABLE sosl_executor
  ADD CONSTRAINT sosl_executor_pk
  PRIMARY KEY (executor_id)
  ENABLE
;
-- check constraints
ALTER TABLE sosl_executor
  ADD CONSTRAINT sosl_executor_chk_active
  CHECK (UPPER(executor_active) IN ('YES', 'NO'))
  ENABLE
;
ALTER TABLE sosl_executor
  ADD CONSTRAINT sosl_executor_chk_reviewed
  CHECK (UPPER(executor_reviewed) IN ('YES', 'NO'))
  ENABLE
;
-- trigger
CREATE OR REPLACE TRIGGER sosl_executor_ins_trg
  BEFORE INSERT ON sosl_executor
  FOR EACH ROW
BEGIN
  :NEW.created            := SYSDATE;
  :NEW.created_by         := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.created_by_os      := SYS_CONTEXT('USERENV', 'OS_USER');
  :NEW.updated            := SYSDATE;
  :NEW.updated_by         := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.updated_by_os      := SYS_CONTEXT('USERENV', 'OS_USER');
  :NEW.executor_active    := UPPER(:NEW.executor_active);
  :NEW.executor_reviewed  := UPPER(:NEW.executor_reviewed);
  -- transform users to UPPERCASE, no support currently for special mix-case.
  :NEW.function_owner     := UPPER(:NEW.function_owner);
  :NEW.db_user            := UPPER(:NEW.db_user);
  :NEW.fn_has_ids         := UPPER(:NEW.fn_has_ids);
  :NEW.fn_get_next_id     := UPPER(:NEW.fn_get_next_id);
  :NEW.fn_get_executor    := UPPER(:NEW.fn_get_executor);
  :NEW.fn_get_script      := UPPER(:NEW.fn_get_script);
  :NEW.fn_set_status      := UPPER(:NEW.fn_set_status);
  -- check user
  IF NOT sosl_sys.has_db_user(:NEW.db_user)
  THEN
    RAISE_APPLICATION_ERROR(-20003, 'The given database user is not visible for SOSL in ALL_USERS. Either the user does not exist or SOSL has no right to see this user.');
  END IF;
  -- check configured functions
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_has_ids, 'NUMBER')
  THEN
    RAISE_APPLICATION_ERROR(-20004, 'The given function ' || :NEW.fn_has_ids || ' for has_ids is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_get_next_id, 'VARCHAR2')
  THEN
    RAISE_APPLICATION_ERROR(-20005, 'The given function ' || :NEW.fn_get_next_id || ' for get_next_id is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype VARCHAR2 or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_get_executor, 'NUMBER')
  THEN
    RAISE_APPLICATION_ERROR(-20006, 'The given function ' || :NEW.fn_get_executor || ' for get_executor is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_get_script, 'VARCHAR2')
  THEN
    RAISE_APPLICATION_ERROR(-20007, 'The given function ' || :NEW.fn_get_script || ' for get_script is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype VARCHAR2 or is not granted with EXECUTE rights to SOSL.');
  END IF;
  IF NOT sosl_sys.has_function(:NEW.function_owner, :NEW.fn_set_status, 'NUMBER')
  THEN
    RAISE_APPLICATION_ERROR(-20008, 'The given function ' || :NEW.fn_set_status || ' for set_status is not visible for SOSL in ALL_ARGUMENTS. Either the function does not exist, function owner is wrong, has wrong return datatype NUMBER or is not granted with EXECUTE rights to SOSL.');
  END IF;

END;
/

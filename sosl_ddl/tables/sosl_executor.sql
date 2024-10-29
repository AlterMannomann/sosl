-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- requires login with the correct schema, either SOSL or your own SOSL schema
-- table is NOT qualified and created in the schema active at execution, columns ordered by access and then space consumption
CREATE TABLE sosl_executor
  ( executor_id           NUMBER(38, 0)   GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , executor_name         VARCHAR2(256)                                             NOT NULL
  , db_user               VARCHAR2(128)                                             NOT NULL
  , function_owner        VARCHAR2(128)                                             NOT NULL
  , fn_has_scripts        VARCHAR2(520)                                             NOT NULL
  , fn_get_next_script    VARCHAR2(520)                                             NOT NULL
  , fn_set_script_status  VARCHAR2(520)                                             NOT NULL
  , cfg_file              VARCHAR2(4000)                                            NOT NULL
  , use_mail              NUMBER(1, 0)    DEFAULT 0                                 NOT NULL
  , fn_send_db_mail       VARCHAR2(520)   DEFAULT 'yourpackage.yourfunction'        NOT NULL
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
COMMENT ON COLUMN sosl_executor.fn_has_scripts IS 'The name of the interface function to use by HAS_SCRIPTS wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall not require parameters and return the amount of waiting scripts as NUMBER or -1 on errors.';
COMMENT ON COLUMN sosl_executor.fn_get_next_script IS 'The name of the interface function to use by GET_NEXT_SCRIPT wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall not require parameters and return the script id, executor id and script file name as type SOSL_PAYLOAD. It should manage the given script id to ensure that scripts are not run twice.';
COMMENT ON COLUMN sosl_executor.fn_set_script_status IS 'The name of the interface function to use by SET_SCRIPT_STATUS wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall require the parameters P_RUN_ID IN NUMBER, P_STATUS IN NUMBER and return 0 or -1 on errors. Details can be fetched from SOSL_RUN_QUEUE. P_STATUS reflects the intended state as defined in SOSL_CONSTANTS RUN% constants. The effective state may differ from the intended state if transition has failed.';
COMMENT ON COLUMN sosl_executor.fn_send_db_mail IS 'The name of the interface function to use by SEND_DB_MAIL wrapper function, e.g. package.function or function. No mixed case support, converted to upper case. The function must have been granted with EXECUTE privilege to SOSL. It shall require the parameters P_RUN_ID IN NUMBER, P_STATUS IN NUMBER and return 0 or -1 on errors. P_STATUS reflects the intended state as defined in SOSL_CONSTANTS RUN% constants. The effective state may differ from the intended state if transition has failed. Message building and sending is up to the defined function. If mail is activated this function is called on every state change.';
COMMENT ON COLUMN sosl_executor.cfg_file IS 'The filename with absolute or relative path to the login config file for this executor. File and path must exist on the CMD server.';
COMMENT ON COLUMN sosl_executor.use_mail IS 'Defines if mail should be provided by SOSL. Accepts 0 (NO/FALSE) and 1 (YES/TRUE). You may also integrate mail behind the SOSL scenes by integrating it into your interface functions.';
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
GRANT SELECT ON sosl_executor TO sosl_reviewer;
GRANT UPDATE ON sosl_executor TO sosl_reviewer;
GRANT INSERT ON sosl_executor TO sosl_executor;
GRANT DELETE ON sosl_executor TO sosl_admin;
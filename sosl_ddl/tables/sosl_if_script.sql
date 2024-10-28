-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- requires login with the correct schema, either SOSL or your own SOSL schema
-- table is NOT qualified and created in the schema active at execution, columns ordered by access and then space consumption
CREATE TABLE sosl_if_script
  ( script_id           NUMBER(38, 0)  GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , script_name         VARCHAR2(2000)                                           NOT NULL
  , run_state           NUMBER(1, 0)   DEFAULT 0                                 NOT NULL
  , run_group           VARCHAR2(30)   DEFAULT 'DEFAULT'                         NOT NULL
  , run_order           NUMBER(38, 0)  DEFAULT 1                                 NOT NULL
  , created             DATE           DEFAULT SYSDATE                           NOT NULL
  , updated             DATE           DEFAULT SYSDATE                           NOT NULL
  , created_by          VARCHAR2(256)  DEFAULT USER                              NOT NULL
  , created_by_os       VARCHAR2(256)  DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , updated_by          VARCHAR2(256)  DEFAULT USER
  , updated_by_os       VARCHAR2(256)  DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')
  , executor_id         NUMBER(38, 0)
  , script_description  VARCHAR2(4000)
  )
;
-- description
COMMENT ON TABLE sosl_if_script IS 'Internal interface table that holds the script file names that should be executed by SOSL. Used for tests and simple batch script setups. No logic control in triggers apart from insert and update dates and users. Will use the alias scrt.';
COMMENT ON COLUMN sosl_if_script.script_id IS 'The generated unique id of the script file.';
COMMENT ON COLUMN sosl_if_script.executor_id IS 'The optional related executor id of the script file. If defined, must match an existing executor. If not defined, script is ignored.';
COMMENT ON COLUMN sosl_if_script.script_name IS 'The name of the script file including full or relative path. Use relative path (relative to batch_base_path or repository location) to ensure running scripts from different machines.';
COMMENT ON COLUMN sosl_if_script.run_order IS 'The order in which the script file should be executed. Same number means in parallel. Higher order numbers wait for scripts with lower order numbers to complete. Must be greater than 0.';
COMMENT ON COLUMN sosl_if_script.run_state IS 'Holds the run state: 0 Waiting, 1 Enqueued, 2 Started, 3 Running, 4 Finished, -1 Error. To rerun a job, set run_state to 1. Will not be accepted if executor is not active and reviewed. Script dependencies are not checked. Can only be 0 or -1 on insert, managed by trigger';
COMMENT ON COLUMN sosl_if_script.run_group IS 'A minimalistic group ID provided as is. Mixed case delivers mixed results. Up to installer to manage specific groups. Allows grouping of scripts.';
COMMENT ON COLUMN sosl_if_script.script_description IS 'Optional description of the script file.';
COMMENT ON COLUMN sosl_if_script.created IS 'Date created, managed by default and trigger.';
COMMENT ON COLUMN sosl_if_script.updated IS 'Date updated, managed by default and trigger.';
COMMENT ON COLUMN sosl_if_script.created_by IS 'DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_if_script.created_by_os IS 'OS user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_if_script.updated_by IS 'DB user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_if_script.updated_by_os IS 'OS user who updated the record, managed by default and trigger.';
-- primary key
ALTER TABLE sosl_if_script
  ADD CONSTRAINT sosl_if_script_pk
  PRIMARY KEY (script_id)
  ENABLE
;
-- constraints
ALTER TABLE sosl_if_script
  ADD CONSTRAINT sosl_if_script_chk_run_state
  CHECK (run_state IN (-1, 0, 1, 2, 3, 4))
;
-- foreign key
ALTER TABLE sosl_if_script
  ADD CONSTRAINT sosl_if_script_fk
  FOREIGN KEY (executor_id)
  REFERENCES sosl_executor (executor_id)
  ON DELETE SET NULL
  ENABLE
;

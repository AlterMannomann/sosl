-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- requires login with the correct schema, either SOSL or your on schema
-- table is NOT qualified and created in the schema active at execution, columns ordered by access and then space consumption
CREATE TABLE sosl_script
  ( script_id           NUMBER(38, 0)  GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , script_name         VARCHAR2(2000)                                           NOT NULL
  , script_order        NUMBER(38, 0)  DEFAULT 1                                 NOT NULL
  , run_state           NUMBER(1, 0)   DEFAULT 0                                 NOT NULL
  , created             DATE           DEFAULT SYSDATE                           NOT NULL
  , updated             DATE           DEFAULT SYSDATE                           NOT NULL
  , created_by          VARCHAR2(256)  DEFAULT USER                              NOT NULL
  , created_by_os       VARCHAR2(256)  DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , updated_by          VARCHAR2(256)  DEFAULT USER                              NOT NULL
  , updated_by_os       VARCHAR2(256)  DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , executor_id         NUMBER(38, 0)
  , script_description  VARCHAR2(4000)
  )
;
-- description
COMMENT ON TABLE sosl_script IS 'Holds the script file names that should be executed by SOSL. Will use the alias scrt.';
COMMENT ON COLUMN sosl_script.script_id IS 'The generated unique id of the script file.';
COMMENT ON COLUMN sosl_script.executor_id IS 'The related executor id of the script file. If defined, must match an existing executor. If not defined, script is ignored.';
COMMENT ON COLUMN sosl_script.script_name IS 'The name of the script file including full or relative path. Use relative path (relative to batch_base_path or repository location) to ensure running scripts from different machines.';
COMMENT ON COLUMN sosl_script.script_order IS 'The order in which the script file should be executed. Same number means in parallel. Higher order numbers wait for scripts with lower order numbers to complete. Must be greater than 0.';
COMMENT ON COLUMN sosl_script.script_description IS 'Optional description of the script file.';
COMMENT ON COLUMN sosl_script.created IS 'Date created, managed by default and trigger.';
COMMENT ON COLUMN sosl_script.updated IS 'Date updated, managed by default and trigger.';
COMMENT ON COLUMN sosl_script.created_by IS 'DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_script.created_by_os IS 'OS user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_script.updated_by IS 'DB user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_script.updated_by_os IS 'OS user who updated the record, managed by default and trigger.';
-- primary key
ALTER TABLE sosl_script
  ADD CONSTRAINT sosl_script_pk
  PRIMARY KEY (script_id)
  ENABLE
;
-- foreign key
ALTER TABLE sosl_script
  ADD CONSTRAINT sosl_script_fk
  FOREIGN KEY (executor_id)
  REFERENCES sosl_executor (executor_id)
  ON DELETE SET NULL
  ENABLE
;
-- trigger
CREATE OR REPLACE TRIGGER sosl_script_ins_trg
  BEFORE INSERT ON sosl_script
  FOR EACH ROW
BEGIN
  :NEW.created        := SYSDATE;
  :NEW.updated        := SYSDATE;
  :NEW.created_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.created_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  :NEW.updated_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.updated_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
END;
/
CREATE OR REPLACE TRIGGER sosl_script_upd_trg
  BEFORE UPDATE ON sosl_script
  FOR EACH ROW
BEGIN
  -- make sure created is not changed
  :NEW.created        := :OLD.created;
  :NEW.created_by     := :OLD.created_by;
  :NEW.created_by_os  := :OLD.created_by_os;
  :NEW.updated        := SYSDATE;
  :NEW.updated_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.updated_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
END;
/
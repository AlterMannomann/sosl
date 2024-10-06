-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE TABLE sosl_script_group
  ( batch_id          NUMBER(38, 0)   GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , batch_group_id    NUMBER(38, 0)                                             NOT NULL
  , script_id         NUMBER(38, 0)                                             NOT NULL
  , order_nr          NUMBER(4, 0)    DEFAULT 1                                 NOT NULL
  , created           DATE            DEFAULT SYSDATE                           NOT NULL
  , updated           DATE            DEFAULT SYSDATE                           NOT NULL
  , created_by        VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , created_by_os     VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , updated_by        VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , updated_by_os     VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , batch_description VARCHAR2(4000)
  )
;
COMMENT ON TABLE sosl_script_group IS 'Relates scripts with a batch group. As long as order_nr is different, a script may be assigned multiple times to a batch group. Equal order_nr mean that those scripts can be executed in parallel. Will use the alias sgrp.';
COMMENT ON COLUMN sosl_script_group.batch_id IS 'Generated unique id for a batch group to script assignement.';
COMMENT ON COLUMN sosl_script_group.batch_group_id IS 'The unique batch group id for the script assignment. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_script_group.script_id IS 'The unique script id to assign to a batch group. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_script_group.order_nr IS 'Defines the order in which scripts are executed in a batch group. Scripts with the same order are executed in parallel. Maximum order is 9999. Batch group, script id and order must be unique.';
COMMENT ON COLUMN sosl_script_group.batch_description IS 'Optional description of this batch group script assignment.';
COMMENT ON COLUMN sosl_script_group.created IS 'Date created, managed by default and trigger.';
COMMENT ON COLUMN sosl_script_group.updated IS 'Date updated, managed by default and trigger.';
COMMENT ON COLUMN sosl_script_group.created_by IS 'DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_script_group.created_by_os IS 'OS user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_script_group.updated_by IS 'DB user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_script_group.updated_by_os IS 'OS user who updated the record, managed by default and trigger.';
-- primary key
ALTER TABLE sosl_script_group
  ADD CONSTRAINT sosl_script_group_pk
  PRIMARY KEY (batch_id)
  ENABLE
;
-- constraints
ALTER TABLE sosl_script_group
  ADD CONSTRAINT sosl_script_group_chk_order_nr
  CHECK (order_nr > 0)
;
-- unique
ALTER TABLE sosl_script_group
  ADD CONSTRAINT sosl_script_group_uk
  UNIQUE (batch_group_id, script_id, order_nr)
  ENABLE
;
-- foreign keys on script_id and batch_group_id
ALTER TABLE sosl_script_group
  ADD CONSTRAINT sosl_script_group_script_id_fk
  FOREIGN KEY (script_id)
  REFERENCES sosl_script (script_id)
  ON DELETE CASCADE
;
ALTER TABLE sosl_script_group
  ADD CONSTRAINT sosl_script_group_batch_group_id_fk
  FOREIGN KEY (batch_group_id)
  REFERENCES sosl_batch_group (batch_group_id)
  ON DELETE CASCADE
;
-- trigger
CREATE OR REPLACE TRIGGER sosl_script_group_ins_trg
  BEFORE INSERT ON sosl_script_group
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
CREATE OR REPLACE TRIGGER sosl_script_group_upd_trg
  BEFORE UPDATE ON sosl_script_group
  FOR EACH ROW
BEGIN
  -- make sure created is not changed
  :NEW.created        := :OLD.created;
  :NEW.created_by     := :OLD.created_by;
  :NEW.created_by_os  := :OLD.created_by_os;
  -- make sure ids are not changed
  :NEW.batch_group_id := :OLD.batch_group_id;
  :NEW.script_id      := :OLD.script_id;
  -- update dates and user
  :NEW.updated        := SYSDATE;
  :NEW.updated_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.updated_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
END;
/
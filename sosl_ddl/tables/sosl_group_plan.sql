-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE TABLE sosl_group_plan
  ( group_plan_id           NUMBER(38, 0)   GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , plan_id                 NUMBER(38, 0)                                             NOT NULL
  , batch_group_id          NUMBER(38, 0)                                             NOT NULL
  , order_nr                NUMBER(4, 0)    DEFAULT 1                                 NOT NULL
  , created                 DATE            DEFAULT SYSDATE                           NOT NULL
  , updated                 DATE            DEFAULT SYSDATE                           NOT NULL
  , created_by              VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , created_by_os           VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , updated_by              VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , updated_by_os           VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , plan_group_description  VARCHAR2(4000)
  )
;
COMMENT ON TABLE sosl_group_plan IS 'Relates batch plans with a batch group. As long as order_nr is different, a batch group may be assigned multiple times to a plan. Equal order_nr mean that those batch groups can be executed in parallel. Will use the alias splg.';
COMMENT ON COLUMN sosl_group_plan.group_plan_id IS 'Generated unique id for a batch plan to group assignement.';
COMMENT ON COLUMN sosl_group_plan.plan_id IS 'The unique script id to assign to a batch plan. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_group_plan.batch_group_id IS 'The unique batch group id for the plan assignment. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_group_plan.order_nr IS 'Defines the order in which batch groups are executed in a batch plan. Batch group with the same order are executed in parallel. Maximum order is 9999. Batch plan, batch group id and order must be unique.';
COMMENT ON COLUMN sosl_group_plan.plan_group_description IS 'Optional description of this batch plan group assignment.';
COMMENT ON COLUMN sosl_group_plan.created IS 'Date created, managed by default and trigger.';
COMMENT ON COLUMN sosl_group_plan.updated IS 'Date updated, managed by default and trigger.';
COMMENT ON COLUMN sosl_group_plan.created_by IS 'DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_group_plan.created_by_os IS 'OS user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_group_plan.updated_by IS 'DB user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_group_plan.updated_by_os IS 'OS user who updated the record, managed by default and trigger.';
-- primary key
ALTER TABLE sosl_group_plan
  ADD CONSTRAINT sosl_group_plan_pk
  PRIMARY KEY (group_plan_id)
  ENABLE
;
-- constraints
ALTER TABLE sosl_group_plan
  ADD CONSTRAINT sosl_group_plan_chk_order_nr
  CHECK (order_nr > 0)
;
-- unique
ALTER TABLE sosl_group_plan
  ADD CONSTRAINT sosl_group_plan_uk
  UNIQUE (group_plan_id, batch_group_id, order_nr)
  ENABLE
;
-- foreign keys on script_id and batch_group_id
ALTER TABLE sosl_group_plan
  ADD CONSTRAINT sosl_group_plan_plan_id_fk
  FOREIGN KEY (plan_id)
  REFERENCES sosl_batch_plan (plan_id)
  ON DELETE CASCADE
;
ALTER TABLE sosl_group_plan
  ADD CONSTRAINT sosl_group_plan_batch_group_id_fk
  FOREIGN KEY (batch_group_id)
  REFERENCES sosl_batch_group (batch_group_id)
  ON DELETE CASCADE
;
-- trigger
CREATE OR REPLACE TRIGGER sosl_group_plan_ins_trg
  BEFORE INSERT ON sosl_group_plan
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
CREATE OR REPLACE TRIGGER sosl_group_plan_upd_trg
  BEFORE UPDATE ON sosl_group_plan
  FOR EACH ROW
BEGIN
  -- make sure created is not changed
  :NEW.created        := :OLD.created;
  :NEW.created_by     := :OLD.created_by;
  :NEW.created_by_os  := :OLD.created_by_os;
  -- make sure ids are not changed
  :NEW.plan_id        := :OLD.plan_id;
  :NEW.batch_group_id := :OLD.batch_group_id;
  -- update dates and user
  :NEW.updated        := SYSDATE;
  :NEW.updated_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.updated_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
END;
/
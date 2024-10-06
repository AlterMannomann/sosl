-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE TABLE sosl_run_queues
  ( run_id          NUMBER(38, 0)   GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , plan_id         NUMBER(38, 0)
  , group_plan_id   NUMBER(38, 0)
  , batch_group_id  NUMBER(38, 0)
  , batch_id        NUMBER(38, 0)
  , script_id       NUMBER(38, 0)
  , run_state       NUMBER(1, 0)    DEFAULT 0                                 NOT NULL
  , created         TIMESTAMP                                                 NOT NULL
  , waiting         TIMESTAMP                                                 NOT NULL
  , enqueued        TIMESTAMP
  , started         TIMESTAMP
  , running         TIMESTAMP
  , finished        TIMESTAMP
  , created_by      VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , created_by_os   VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , waiting_by      VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , waiting_by_os   VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , enqueued_by     VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , enqueued_by_os  VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , started_by      VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , started_by_os   VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , running_by      VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , running_by_os   VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , finished_by     VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , finished_by_os  VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  )
;
COMMENT ON TABLE sosl_run_queues IS 'This table hold old and new runs of batch plans and the execution run state of each script. Granularity is single script. This is not a message queue. Will use the alias srqu.';
COMMENT ON COLUMN sosl_run_queues.run_id IS 'Generated unique id for a batch run script.';
COMMENT ON COLUMN sosl_run_queues.plan_id IS 'The current unique plan id for the batch run. NULL possible if reference record deleted. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queues.plan_id IS 'The current unique group plan id for the batch run. NULL possible if reference record deleted. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queues.batch_group_id IS 'The current unique batch group id for the batch run. NULL possible if reference record deleted. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queues.batch_id IS 'The current unique batch id for the batch run. NULL possible if reference record deleted. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queues.script_id IS 'The current unique script id for the batch run. NULL possible if reference record deleted. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queues.run_state IS 'Holds the run state: 0 Waiting, 1 Enqueued, 2 Started, 3 Running, 4 Finished, -1 Error. To rerun a job, set run_state to 1. Script dependencies are not checked. Always 0 on insert, managed by trigger';
COMMENT ON COLUMN sosl_run_queues.created IS 'The date of record creation. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queues.waiting IS 'The last date of setting the script run state to waiting (0). On insert this is the default managed by trigger.';
COMMENT ON COLUMN sosl_run_queues.enqueued IS 'The last date of setting the script run state to enqueued (1).';
COMMENT ON COLUMN sosl_run_queues.started IS 'The last date of setting the script run state to started (2).';
COMMENT ON COLUMN sosl_run_queues.running IS 'The last date of setting the script run state to running (3).';
COMMENT ON COLUMN sosl_run_queues.finished IS 'The last date of setting the script run state to finished or error (4, -1).';
COMMENT ON COLUMN sosl_run_queues.created_by IS 'DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_run_queues.created_by_os IS 'OS user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_run_queues.waiting_by IS 'Last DB user who set the record run state to waiting (0), managed by default and inser trigger, updates allowed.';
COMMENT ON COLUMN sosl_run_queues.waiting_by_os IS 'Last OS user who set the record run state to waiting (0), managed by default and insert trigger, updates allowed.';
COMMENT ON COLUMN sosl_run_queues.enqueued_by IS 'Last DB user who tried to set the record run state to enqueued (1).';
COMMENT ON COLUMN sosl_run_queues.enqueued_by_os IS 'Last OS user who tried to set the record run state to enqueued (1).';
COMMENT ON COLUMN sosl_run_queues.started_by IS 'Last DB user who tried to set the record run state to started (2).';
COMMENT ON COLUMN sosl_run_queues.started_by_os IS 'Last OS user who tried to set the record run state to started (2).';
COMMENT ON COLUMN sosl_run_queues.running_by IS 'Last DB user who tried to set the record run state to running (3).';
COMMENT ON COLUMN sosl_run_queues.running_by_os IS 'Last OS user who tried to set the record run state to running (3)';
COMMENT ON COLUMN sosl_run_queues.finished_by IS 'Last DB user who tried to set the record run state to finished (4) or -1 on errors.';
COMMENT ON COLUMN sosl_run_queues.finished_by_os IS 'Last OS user who tried to set the record run state to finished (4) or -1 on errors.';
-- primary key
ALTER TABLE sosl_run_queues
  ADD CONSTRAINT sosl_run_queues_pk
  PRIMARY KEY (run_id)
  ENABLE
;
-- constraints
ALTER TABLE sosl_run_queues
  ADD CONSTRAINT sosl_run_queues_chk_run_state
  CHECK (run_state IN (-1, 0, 1, 2, 3, 4))
;
-- foreign keys on all ids referenced, will set record to NULL on DELETE
ALTER TABLE sosl_run_queues
  ADD CONSTRAINT sosl_run_queues_plan_id_fk
  FOREIGN KEY (plan_id)
  REFERENCES sosl_batch_plan (plan_id)
  ON DELETE SET NULL
;
ALTER TABLE sosl_run_queues
  ADD CONSTRAINT sosl_run_queues_group_plan_id_fk
  FOREIGN KEY (group_plan_id)
  REFERENCES sosl_group_plan (group_plan_id)
  ON DELETE SET NULL
;
ALTER TABLE sosl_run_queues
  ADD CONSTRAINT sosl_run_queues_batch_group_id_fk
  FOREIGN KEY (batch_group_id)
  REFERENCES sosl_batch_group (batch_group_id)
  ON DELETE SET NULL
;
ALTER TABLE sosl_run_queues
  ADD CONSTRAINT sosl_run_queues_batch_id_fk
  FOREIGN KEY (batch_id)
  REFERENCES sosl_script_group (batch_id)
  ON DELETE SET NULL
;
-- if script id is DELETED no rerun is possible
ALTER TABLE sosl_run_queues
  ADD CONSTRAINT sosl_run_queues_script_id_fk
  FOREIGN KEY (script_id)
  REFERENCES sosl_script (script_id)
  ON DELETE SET NULL
;
-- trigger
CREATE OR REPLACE TRIGGER sosl_run_queues_ins_trg
  BEFORE INSERT ON sosl_run_queues
  FOR EACH ROW
BEGIN
  -- on insert run state is always 0 waiting
  :NEW.run_state      := 0;
  -- set basic timestamps
  :NEW.created        := SYSTIMESTAMP;
  :NEW.waiting        := SYSTIMESTAMP;
  :NEW.created_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.created_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  :NEW.waiting_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.waiting_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
END;
/
CREATE OR REPLACE TRIGGER sosl_run_queues_upd_trg
  BEFORE UPDATE ON sosl_run_queues
  FOR EACH ROW
BEGIN
  -- make sure created is not changed
  :NEW.created        := :OLD.created;
  :NEW.created_by     := :OLD.created_by;
  :NEW.created_by_os  := :OLD.created_by_os;
  -- update dates and user by run state
  CASE :NEW.run_state
    WHEN 0 THEN
      :NEW.waiting        := SYSTIMESTAMP;
      :NEW.waiting_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
      :NEW.waiting_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
    WHEN 1 THEN
      :NEW.enqueued       := SYSTIMESTAMP;
      :NEW.enqueued_by    := SYS_CONTEXT('USERENV', 'CURRENT_USER');
      :NEW.enqueued_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
    WHEN 2 THEN
      :NEW.started        := SYSTIMESTAMP;
      :NEW.started_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
      :NEW.started_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
    WHEN 3 THEN
      :NEW.running        := SYSTIMESTAMP;
      :NEW.running_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
      :NEW.running_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
    WHEN 4 THEN
      :NEW.finished       := SYSTIMESTAMP;
      :NEW.finished_by    := SYS_CONTEXT('USERENV', 'CURRENT_USER');
      :NEW.finished_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
    ELSE
      -- any other state is an error state
      :NEW.finished       := SYSTIMESTAMP;
      :NEW.finished_by    := SYS_CONTEXT('USERENV', 'CURRENT_USER');
      :NEW.finished_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
      :NEW.run_state      := -1;
  END CASE;
END;
/
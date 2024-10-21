-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE TABLE sosl_run_queue
  ( run_id          NUMBER(38, 0)   GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , run_state       NUMBER(1, 0)    DEFAULT 0                                 NOT NULL
  , executor_id     NUMBER(38, 0)                                             NOT NULL
  , ext_script_id   VARCHAR2(4000)                                            NOT NULL
  , script_file     VARCHAR2(4000)                                            NOT NULL
  , created         TIMESTAMP                                                 NOT NULL
  , waiting         TIMESTAMP
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
COMMENT ON TABLE sosl_run_queue IS 'This table hold old and new runs of batch plans and the execution run state of each script. Granularity is single script. This is not a message queue. Will use the alias srqu.';
COMMENT ON COLUMN sosl_run_queue.run_id IS 'Generated unique id for a batch run script.';
COMMENT ON COLUMN sosl_run_queue.run_state IS 'Holds the run state: 0 Waiting, 1 Enqueued, 2 Started, 3 Running, 4 Finished, -1 Error. To rerun a job, set run_state to 1. Will not be accepted if executor is not active and reviewed. Script dependencies are not checked. Always 0 on insert, managed by trigger';
COMMENT ON COLUMN sosl_run_queue.executor_id IS 'The valid executor id as returned from API (NUMBER). No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queue.ext_script_id IS 'The (external) identifier for the current script as returned from API (VARCHAR2). No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queue.script_file IS 'The script file name including (relative) path from API (VARCHAR2). No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queue.created IS 'The date of record creation. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queue.waiting IS 'The last date of setting the script run state to waiting (0). On insert this is the default managed by trigger.';
COMMENT ON COLUMN sosl_run_queue.enqueued IS 'The last date of setting the script run state to enqueued (1).';
COMMENT ON COLUMN sosl_run_queue.started IS 'The last date of setting the script run state to started (2).';
COMMENT ON COLUMN sosl_run_queue.running IS 'The last date of setting the script run state to running (3).';
COMMENT ON COLUMN sosl_run_queue.finished IS 'The last date of setting the script run state to finished or error (4, -1).';
COMMENT ON COLUMN sosl_run_queue.created_by IS 'DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_run_queue.created_by_os IS 'OS user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_run_queue.waiting_by IS 'Last DB user who set the record run state to waiting (0), managed by default and inser trigger, updates allowed.';
COMMENT ON COLUMN sosl_run_queue.waiting_by_os IS 'Last OS user who set the record run state to waiting (0), managed by default and insert trigger, updates allowed.';
COMMENT ON COLUMN sosl_run_queue.enqueued_by IS 'Last DB user who tried to set the record run state to enqueued (1).';
COMMENT ON COLUMN sosl_run_queue.enqueued_by_os IS 'Last OS user who tried to set the record run state to enqueued (1).';
COMMENT ON COLUMN sosl_run_queue.started_by IS 'Last DB user who tried to set the record run state to started (2).';
COMMENT ON COLUMN sosl_run_queue.started_by_os IS 'Last OS user who tried to set the record run state to started (2).';
COMMENT ON COLUMN sosl_run_queue.running_by IS 'Last DB user who tried to set the record run state to running (3).';
COMMENT ON COLUMN sosl_run_queue.running_by_os IS 'Last OS user who tried to set the record run state to running (3)';
COMMENT ON COLUMN sosl_run_queue.finished_by IS 'Last DB user who tried to set the record run state to finished (4) or -1 on errors.';
COMMENT ON COLUMN sosl_run_queue.finished_by_os IS 'Last OS user who tried to set the record run state to finished (4) or -1 on errors.';
-- primary key
ALTER TABLE sosl_run_queue
  ADD CONSTRAINT sosl_run_queue_pk
  PRIMARY KEY (run_id)
  ENABLE
;
-- constraints
ALTER TABLE sosl_run_queue
  ADD CONSTRAINT sosl_run_queue_chk_run_state
  CHECK (run_state IN (-1, 0, 1, 2, 3, 4))
;
-- foreign keys on all ids referenced, will set record to NULL on DELETE
ALTER TABLE sosl_run_queue
  ADD CONSTRAINT sosl_run_queue_executor_id_fk
  FOREIGN KEY (executor_id)
  REFERENCES sosl_executor (executor_id)
  ON DELETE SET NULL
;
-- trigger
CREATE OR REPLACE TRIGGER sosl_run_queue_ins_trg
  BEFORE INSERT ON sosl_run_queue
  FOR EACH ROW
DECLARE
  l_executor_valid  NUMBER;
BEGIN
  -- check executor, if not accepted and reviewed, set run state to error, else waiting
  SELECT COUNT(*)
    INTO l_executor_valid
    FROM sosl_executor
   WHERE executor_id        = :NEW.executor_id
     AND executor_active    = sosl_sys.YES
     AND executor_reviewed  = sosl_sys.YES
  ;
  IF l_executor_valid = 0
  THEN
    :NEW.run_state      := -1;
    :NEW.waiting        := NULL;
    :NEW.waiting_by     := NULL;
    :NEW.waiting_by_os  := NULL;
    :NEW.finished       := SYSTIMESTAMP;
    :NEW.finished_by    := SYS_CONTEXT('USERENV', 'CURRENT_USER');
    :NEW.finished_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
  ELSE
    :NEW.run_state      := 0;
    :NEW.waiting        := SYSTIMESTAMP;
    :NEW.waiting_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
    :NEW.waiting_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
    :NEW.finished       := NULL;
    :NEW.finished_by    := NULL;
    :NEW.finished_by_os := NULL;
  END IF;
  -- set basic timestamps
  :NEW.created        := SYSTIMESTAMP;
  :NEW.created_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.created_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  -- overwrite any other injected dates and user on insert
  :NEW.enqueued       := NULL;
  :NEW.enqueued_by    := NULL;
  :NEW.enqueued_by_os := NULL;
  :NEW.started        := NULL;
  :NEW.started_by     := NULL;
  :NEW.started_by_os  := NULL;
  :NEW.running        := NULL;
  :NEW.running_by     := NULL;
  :NEW.running_by_os  := NULL;
  :NEW.finished       := NULL;
  :NEW.finished_by    := NULL;
  :NEW.finished_by_os := NULL;
END;
/
CREATE OR REPLACE TRIGGER sosl_run_queue_upd_trg
  BEFORE UPDATE ON sosl_run_queue
  FOR EACH ROW
DECLARE
  l_executor_valid  NUMBER;
BEGIN
  -- make sure created and basics are not changed
  :NEW.created        := :OLD.created;
  :NEW.created_by     := :OLD.created_by;
  :NEW.created_by_os  := :OLD.created_by_os;
  :NEW.executor_id    := :OLD.executor_id;
  :NEW.ext_script_id  := :OLD.ext_script_id;
  :NEW.script_file    := :OLD.script_file;
  -- check executor and prevent updates on run state if not valid
  SELECT COUNT(*) INTO l_executor_valid FROM sosl_executor WHERE executor_id = :NEW.executor_id AND executor_active = 'YES' AND executor_reviewed = 'YES';
  IF l_executor_valid = 0
  THEN
    :NEW.run_state      := :OLD.run_state;
    :NEW.enqueued       := :OLD.enqueued;
    :NEW.enqueued_by    := :OLD.enqueued_by;
    :NEW.enqueued_by_os := :OLD.enqueued_by_os;
    :NEW.started        := :OLD.started;
    :NEW.started_by     := :OLD.started_by;
    :NEW.started_by_os  := :OLD.started_by_os;
    :NEW.running        := :OLD.running;
    :NEW.running_by     := :OLD.running_by;
    :NEW.running_by_os  := :OLD.running_by_os;
    :NEW.finished       := :OLD.finished;
    :NEW.finished_by    := :OLD.finished_by;
    :NEW.finished_by_os := :OLD.finished_by_os;
  ELSE
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
  END IF;
END;
/
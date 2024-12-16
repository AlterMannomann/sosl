-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
CREATE TABLE sosl_run_queue
  ( run_id          NUMBER(38, 0)   GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , run_state       NUMBER(1, 0)    DEFAULT 0                                 NOT NULL
  , executor_id     NUMBER(38, 0)                                             NOT NULL
  , ext_script_id   VARCHAR2(4000)                                            NOT NULL
  , script_file     VARCHAR2(4000)                                            NOT NULL
  , script_guid     VARCHAR2(64)    DEFAULT 'n/a'                             NOT NULL
  , sosl_identifier VARCHAR2(256)   DEFAULT 'n/a'                             NOT NULL
  , created         TIMESTAMP       DEFAULT SYSTIMESTAMP                      NOT NULL
  , waiting         TIMESTAMP
  , enqueued        TIMESTAMP
  , started         TIMESTAMP
  , running_since   TIMESTAMP
  , finished        TIMESTAMP
  , created_by      VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , created_by_os   VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , waiting_by      VARCHAR2(256)   DEFAULT USER
  , waiting_by_os   VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')
  , enqueued_by     VARCHAR2(256)   DEFAULT USER
  , enqueued_by_os  VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')
  , started_by      VARCHAR2(256)   DEFAULT USER
  , started_by_os   VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')
  , running_by      VARCHAR2(256)   DEFAULT USER
  , running_by_os   VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')
  , finished_by     VARCHAR2(256)   DEFAULT USER
  , finished_by_os  VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER')
  )
;
COMMENT ON TABLE sosl_run_queue IS 'This table hold old and new runs of batch plans and the execution run state of each script. Granularity is single script. This is not a message queue. Will use the alias srq.';
COMMENT ON COLUMN sosl_run_queue.run_id IS 'Generated unique id for a batch run script.';
COMMENT ON COLUMN sosl_run_queue.run_state IS 'Holds the run state: 0 Waiting, 1 Enqueued, 2 Started, 3 Running, 4 Finished, -1 Error. To rerun a job, set run_state to 1. Will not be accepted if executor is not active and reviewed. Script dependencies are not checked. Can only be 0 or -1 on insert, managed by trigger';
COMMENT ON COLUMN sosl_run_queue.executor_id IS 'The valid executor id as returned from API (NUMBER). No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queue.ext_script_id IS 'The (external) identifier for the current script as returned from API (VARCHAR2). No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queue.script_file IS 'The script file name including (relative) path from API (VARCHAR2). No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queue.script_guid IS 'The unique id of the SOSL server associated with the script execution. This is a generic reference to SOSLERRORLOG.IDENTIFIER and local server logs. Set by SOSL server.';
COMMENT ON COLUMN sosl_run_queue.sosl_identifier IS 'The unique SOSL identifier id of the SOSL server associated with the script execution. This is a unique reference to SOSLERRORLOG.IDENTIFIER and local server logs. Set by SOSL server.';
COMMENT ON COLUMN sosl_run_queue.created IS 'The date of record creation. No updates allowed, surpressed by trigger.';
COMMENT ON COLUMN sosl_run_queue.waiting IS 'The last date of setting the script run state to waiting (0). On insert this is the default managed by trigger.';
COMMENT ON COLUMN sosl_run_queue.enqueued IS 'The last date of setting the script run state to enqueued (1).';
COMMENT ON COLUMN sosl_run_queue.started IS 'The last date of setting the script run state to started (2).';
COMMENT ON COLUMN sosl_run_queue.running_since IS 'The last date of setting the script run state to running (3).';
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
  REFERENCES sosl_executor_definition (executor_id)
  ON DELETE CASCADE
;
GRANT SELECT ON sosl_run_queue TO sosl_reviewer;
GRANT DELETE ON sosl_run_queue TO sosl_admin;
-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
CREATE TABLE sosl_batch_plan
  ( plan_id           NUMBER(38, 0)   GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , plan_name         VARCHAR2(256)                                             NOT NULL
  , plan_active       VARCHAR2(3)     DEFAULT 'NO'
  , plan_accepted     VARCHAR2(3)     DEFAULT 'NO'
  , job_name          VARCHAR2(128)
  , start_date        TIMESTAMP
  , repeat_interval   VARCHAR2(4000)
  , end_date          TIMESTAMP
  , mail_server       VARCHAR2(255)
  , created           DATE            DEFAULT SYSDATE                           NOT NULL
  , updated           DATE            DEFAULT SYSDATE                           NOT NULL
  , created_by        VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , created_by_os     VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , updated_by        VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , updated_by_os     VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , activated         DATE
  , deactivated       DATE
  , accepted          DATE
  , denied            DATE
  , activated_by_os   VARCHAR2(256)
  , deactivated_by_os VARCHAR2(256)
  , accepted_by_os    VARCHAR2(256)
  , denied_by_os      VARCHAR2(256)
  , plan_description  VARCHAR2(4000)
  )
;
COMMENT ON TABLE sosl_batch_plan IS 'Defines the batch plan which consists of one or more batch groups. Will use the alias spla.';
COMMENT ON COLUMN sosl_batch_plan.plan_id IS 'The generated unique id that identifies the batch plan.';
COMMENT ON COLUMN sosl_batch_plan.plan_name IS 'The unique name of the batch plan.';
COMMENT ON COLUMN sosl_batch_plan.plan_active IS 'Defines if the plan is active. Accepts NO and YES. Not activated plans will not run but inform the log that an attempt was made to start the plan.';
COMMENT ON COLUMN sosl_batch_plan.plan_accepted IS 'Defines if the plan is accepted. Accepts NO and YES. Not accepted plans will not run but inform the log that an attempt was made to start the plan.';
COMMENT ON COLUMN sosl_batch_plan.job_name IS 'If the plan should be scheduled, provide an valid name for the job. Only normal uppercase characters A-Z, numbers and underscore allowed. Trigger will convert lower case to upper case, disable the job if it exists and create or update the job. If job name changes the old job is dropped. Equivalent to parameter in DBMS_SCHEDULER.CREATE_JOB.';
COMMENT ON COLUMN sosl_batch_plan.start_date IS 'The desired start date of the scheduled job, if a scheduler name is defined otherwise ignored. Equivalent to parameter in DBMS_SCHEDULER.CREATE_JOB.';
COMMENT ON COLUMN sosl_batch_plan.repeat_interval IS 'The repeat interval for the scheduler, if a scheduler name is defined otherwise ignored. Equivalent to parameter in DBMS_SCHEDULER.CREATE_JOB.';
COMMENT ON COLUMN sosl_batch_plan.end_date IS 'The desired end date of the scheduled job, if a scheduler name is defined otherwise ignored. Equivalent to parameter in DBMS_SCHEDULER.CREATE_JOB.';
COMMENT ON COLUMN sosl_batch_plan.created IS 'Date created, managed by default and trigger.';
COMMENT ON COLUMN sosl_batch_plan.updated IS 'Date updated, managed by default and trigger.';
COMMENT ON COLUMN sosl_batch_plan.created_by IS 'DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_batch_plan.created_by_os IS 'OS user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_batch_plan.updated_by IS 'DB user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_batch_plan.updated_by_os IS 'OS user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_batch_plan.activated IS 'The date when plan_active was last set or updated to YES, managed by trigger.';
COMMENT ON COLUMN sosl_batch_plan.activated_by_os IS 'The OS user that last updated or set plan_active to YES, managed by trigger.';
COMMENT ON COLUMN sosl_batch_plan.deactivated IS 'The date when plan_active was last set or updated to NO, managed by trigger.';
COMMENT ON COLUMN sosl_batch_plan.deactivated_by_os IS 'The OS user that last updated or set plan_active to NO, managed by trigger.';
COMMENT ON COLUMN sosl_batch_plan.accepted IS 'The date when plan_accepted was last set or updated to YES, managed by trigger.';
COMMENT ON COLUMN sosl_batch_plan.accepted_by_os IS 'The OS user that last updated or set plan_accepted to YES, managed by trigger.';
COMMENT ON COLUMN sosl_batch_plan.denied IS 'The date when plan_accepted was last set or updated to NO, managed by trigger.';
COMMENT ON COLUMN sosl_batch_plan.denied_by_os IS 'The OS user that last updated or set plan_accepted to NO, managed by trigger.';
COMMENT ON COLUMN sosl_batch_plan.plan_description IS 'Optional plan description.';
-- primary key
ALTER TABLE sosl_batch_plan
  ADD CONSTRAINT sosl_batch_plan_pk
  PRIMARY KEY (plan_id)
  ENABLE
;
-- unique
ALTER TABLE sosl_batch_plan
  ADD CONSTRAINT sosl_batch_plan_uk
  UNIQUE (plan_name)
  ENABLE
;
-- check constraints
ALTER TABLE sosl_batch_plan
  ADD CONSTRAINT sosl_batch_plan_chk_active
  CHECK (plan_active IN ('YES', 'NO'))
  ENABLE
;
ALTER TABLE sosl_batch_plan
  ADD CONSTRAINT sosl_batch_plan_chk_accepted
  CHECK (plan_accepted IN ('YES', 'NO'))
  ENABLE
;
ALTER TABLE sosl_batch_plan
  ADD CONSTRAINT sosl_batch_plan_chk_job_name
  CHECK (REGEXP_INSTR(job_name, '^[A-Z0-9_]*$') > 0)
  ENABLE
;
-- trigger
CREATE OR REPLACE TRIGGER sosl_batch_plan_ins_upd_trg
  BEFORE INSERT OR UPDATE ON sosl_batch_plan
  FOR EACH ROW
DECLARE
  l_has_job NUMBER;
BEGIN
  IF INSERTING
  THEN
    :NEW.created        := SYSDATE;
    :NEW.created_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
    :NEW.created_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  END IF;
  :NEW.updated        := SYSDATE;
  :NEW.updated_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.updated_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  IF :NEW.plan_active = 'NO'
  THEN
    :NEW.deactivated       := SYSDATE;
    :NEW.deactivated_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
  ELSIF :NEW.plan_active = 'YES'
  THEN
    :NEW.activated       := SYSDATE;
    :NEW.activated_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
  END IF;
  IF :NEW.plan_accepted = 'NO'
  THEN
    :NEW.denied       := SYSDATE;
    :NEW.denied_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
  ELSIF :NEW.plan_accepted = 'YES'
  THEN
    :NEW.accepted       := SYSDATE;
    :NEW.accepted_by_os := SYS_CONTEXT('USERENV', 'OS_USER');
  END IF;
  -- if job_name IS NOT NULL then create or update the scheduler job
  IF INSERTING AND :NEW.job_name IS NOT NULL
  THEN
    BEGIN
      SELECT COUNT(*) INTO l_has_job FROM user_scheduler_jobs WHERE job_name = :NEW.job_name;
      -- check if already a job with this name exists
      IF l_has_job > 0
      THEN
        DBMS_SCHEDULER.DISABLE(name => :NEW.job_name, force => TRUE);
        -- update the job, set current plan id
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'job_action'
                                    , value => 'BEGIN sosl.run_plan(' || TRIM(TO_CHAR(:NEW.plan_id)) || '); END;'
                                    )
        ;
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'start_date'
                                    , value => :NEW.start_date
                                    )
        ;
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'repeat_interval'
                                    , value => :NEW.repeat_interval
                                    )
        ;
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'end_date'
                                    , value => :NEW.end_date
                                    )
        ;
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'comments'
                                    , value => 'Run PLAN_ID ' || TRIM(TO_CHAR(:NEW.plan_id)) || ' plan info: ' || NVL(:NEW.plan_description, 'N/A')
                                    )
        ;
      ELSE
        -- create the job
        DBMS_SCHEDULER.CREATE_JOB( job_name => :NEW.job_name
                                 , job_type => 'PLSQL_BLOCK'
                                 , job_action => 'BEGIN sosl.run_plan(' || TRIM(TO_CHAR(:NEW.plan_id)) || '); END;'
                                 , number_of_arguments => 0
                                 , start_date => :NEW.start_date
                                 , repeat_interval => :NEW.repeat_interval
                                 , end_date => :NEW.end_date
                                 , enabled => FALSE
                                 , auto_drop => FALSE
                                 , comments => 'Run PLAN_ID ' || TRIM(TO_CHAR(:NEW.plan_id)) || ' plan info: ' || NVL(:NEW.plan_description, 'N/A')
                                 )
        ;
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'store_output'
                                    , value => TRUE
                                    )
        ;
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'logging_level'
                                    , value => DBMS_SCHEDULER.LOGGING_FULL
                                    )
        ;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Could not create or update job ' || :NEW.job_name || ' ERROR: ' || SQLERRM);
    END;
  END IF;
  IF UPDATING AND :NEW.job_name IS NOT NULL
  THEN
    BEGIN
      SELECT COUNT(*) INTO l_has_job FROM user_scheduler_jobs WHERE job_name = :OLD.job_name;
      -- if name has changed, drop old job
      IF     :OLD.job_name IS NOT NULL
         AND :OLD.job_name != :NEW.job_name
         AND l_has_job > 0
      THEN
        DBMS_SCHEDULER.DISABLE(name => :OLD.job_name, force => TRUE);
        DBMS_SCHEDULER.DROP_JOB(job_name => :OLD.job_name, force => TRUE);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20009, 'Could not drop old job ' || :OLD.job_name || ' ERROR: ' || SQLERRM);
    END;
    -- now handle existing job or create a new job
    BEGIN
      SELECT COUNT(*) INTO l_has_job FROM user_scheduler_jobs WHERE job_name = :NEW.job_name;
      IF l_has_job > 0
      THEN
        -- disable and update job
        DBMS_SCHEDULER.DISABLE(name => :NEW.job_name, force => TRUE);
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'start_date'
                                    , value => :NEW.start_date
                                    )
        ;
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'repeat_interval'
                                    , value => :NEW.repeat_interval
                                    )
        ;
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'end_date'
                                    , value => :NEW.end_date
                                    )
        ;
      ELSE
        -- create a new job with the new job name
        DBMS_SCHEDULER.CREATE_JOB( job_name => :NEW.job_name
                                 , job_type => 'PLSQL_BLOCK'
                                 , job_action => 'BEGIN sosl.run_plan(' || TRIM(TO_CHAR(:NEW.plan_id)) || '); END;'
                                 , number_of_arguments => 0
                                 , start_date => :NEW.start_date
                                 , repeat_interval => :NEW.repeat_interval
                                 , end_date => :NEW.end_date
                                 , enabled => FALSE
                                 , auto_drop => FALSE
                                 , comments => 'Run PLAN_ID ' || TRIM(TO_CHAR(:NEW.plan_id)) || ' plan info: ' || NVL(:NEW.plan_description, 'N/A')
                                 )
        ;
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'store_output'
                                    , value => TRUE
                                    )
        ;
        DBMS_SCHEDULER.SET_ATTRIBUTE( name => :NEW.job_name
                                    , attribute => 'logging_level'
                                    , value => DBMS_SCHEDULER.LOGGING_FULL
                                    )
        ;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20008, 'Could not create or update job ' || :NEW.job_name || ' ERROR: ' || SQLERRM);
    END;
  END IF;
END;
/
CREATE OR REPLACE TRIGGER sosl_batch_plan_del_trg
  BEFORE DELETE ON sosl_batch_plan
  FOR EACH ROW
DECLARE
  l_has_job NUMBER;
BEGIN
  -- drop jobs that exist, if plan is deleted
  BEGIN
    SELECT COUNT(*) INTO l_has_job FROM user_scheduler_jobs WHERE job_name = :OLD.job_name;
    -- drop old job
    IF l_has_job > 0
    THEN
      DBMS_SCHEDULER.DISABLE(name => :OLD.job_name, force => TRUE);
      DBMS_SCHEDULER.DROP_JOB(job_name => :OLD.job_name, force => TRUE);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20009, 'Could not drop old job ' || :OLD.job_name || ' ERROR: ' || SQLERRM);
  END;
END;
/
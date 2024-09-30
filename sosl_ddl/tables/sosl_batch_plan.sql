CREATE TABLE sosl_batch_plan
  ( plan_id           NUMBER(38, 0)   GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , plan_name         VARCHAR2(256)                                             NOT NULL
  , plan_active       VARCHAR2(3)     DEFAULT 'NO'
  , plan_accepted     VARCHAR2(3)     DEFAULT 'NO'
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
-- trigger
CREATE OR REPLACE TRIGGER sosl_batch_plan_ins_upd_trg
  BEFORE INSERT OR UPDATE ON sosl_batch_plan
  FOR EACH ROW
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
END;
/
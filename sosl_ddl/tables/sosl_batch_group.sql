CREATE TABLE sosl_batch_group
  ( batch_group_id          NUMBER(38, 0)  GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , batch_group_name        VARCHAR2(256)                                            NOT NULL
  , created                 DATE           DEFAULT SYSDATE                           NOT NULL
  , updated                 DATE           DEFAULT SYSDATE                           NOT NULL
  , created_by              VARCHAR2(256)  DEFAULT USER                              NOT NULL
  , created_by_os           VARCHAR2(256)  DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , updated_by              VARCHAR2(256)  DEFAULT USER                              NOT NULL
  , updated_by_os           VARCHAR2(256)  DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , batch_group_description VARCHAR2(4000)
  )
;
-- description
COMMENT ON TABLE sosl_batch_group IS 'Holds defined batch groups that can be associated with scripts. Will use the alias sbat.';
COMMENT ON COLUMN sosl_batch_group.batch_group_id IS 'The generated unique id of the batch group.';
COMMENT ON COLUMN sosl_batch_group.batch_group_name IS 'The name of the batch group.';
COMMENT ON COLUMN sosl_batch_group.batch_group_description IS 'Optional description of the batch group.';
COMMENT ON COLUMN sosl_batch_group.created IS 'Date created, managed by default and trigger.';
COMMENT ON COLUMN sosl_batch_group.updated IS 'Date updated, managed by default and trigger.';
COMMENT ON COLUMN sosl_batch_group.created_by IS 'DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_batch_group.created_by_os IS 'OS user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_batch_group.updated_by IS 'DB user who updated the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_batch_group.updated_by_os IS 'OS user who updated the record, managed by default and trigger.';
-- primary key
ALTER TABLE sosl_batch_group
  ADD CONSTRAINT sosl_batch_group_pk
  PRIMARY KEY (batch_group_id)
  ENABLE
;
-- trigger
CREATE OR REPLACE TRIGGER sosl_batch_group_ins_trg
  BEFORE INSERT ON sosl_batch_group
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
CREATE OR REPLACE TRIGGER sosl_batch_group_upd_trg
  BEFORE UPDATE ON sosl_batch_group
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
-- create basic entry
INSERT INTO sosl_batch_group
  (batch_group_name, batch_group_description)
  VALUES
  ('SOSL_BATCH_GROUP', 'The default batch group for SOSL if no other batch group is defined.')
;
COMMIT;
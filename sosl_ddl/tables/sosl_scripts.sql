-- requires login with the correct schema, either SOSL or your on schema
-- table is NOT qualified and created in the schema active at execution
CREATE TABLE sosl_scripts
  ( sosl_script_id          NUMBER(38, 0)   NOT NULL
  , sosl_script_name        VARCHAR2(2000)  NOT NULL
  , sosl_script_description VARCHAR2(4000)
  )
;
-- description
COMMENT ON TABLE sosl_scripts IS 'Holds the script file names that should be executed by SOSL. Will use the alias scr.';
COMMENT ON COLUMN sosl_scripts.sosl_script_id IS 'The unique id of the script file.';
COMMENT ON COLUMN sosl_scripts.sosl_script_name IS 'The name of the script file including full or relative path. Use relative path (relative to repository location) to ensure running scripts from different machines.';
COMMENT ON COLUMN sosl_scripts.sosl_script_description IS 'Optional description of the script file.';
-- primary key
ALTER TABLE sosl_scripts
  ADD CONSTRAINT sosl_scripts_pk
  PRIMARY KEY (sosl_script_id)
  ENABLE
;
-- sequence for primary key
CREATE SEQUENCE sosl_scripts_seq
  MINVALUE 1
  INCREMENT BY 1
  START WITH 1
  NOCACHE
  NOORDER
  NOCYCLE
  NOKEEP
  NOSCALE
  GLOBAL
  NOMAXVALUE
;
-- trigger for primary key
CREATE OR REPLACE TRIGGER sosl_scripts_ins_trg
  BEFORE INSERT ON sosl_scripts
  FOR EACH ROW
BEGIN
  :NEW.sosl_script_id := sosl_scripts_seq.NEXTVAL;
END;
/
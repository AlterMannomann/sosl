-- requires login with the correct schema, either SOSL or your on schema
-- table is NOT qualified and created in the schema active at execution
CREATE TABLE sosl_scripts
  ( script_id          GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , script_name        VARCHAR2(2000)  NOT NULL
  , script_description VARCHAR2(4000)
  )
;
-- description
COMMENT ON TABLE sosl_scripts IS 'Holds the script file names that should be executed by SOSL. Will use the alias scrt.';
COMMENT ON COLUMN sosl_scripts.script_id IS 'The unique id of the script file.';
COMMENT ON COLUMN sosl_scripts.script_name IS 'The name of the script file including full or relative path. Use relative path (relative to repository location) to ensure running scripts from different machines.';
COMMENT ON COLUMN sosl_scripts.script_description IS 'Optional description of the script file.';
-- primary key
ALTER TABLE sosl_scripts
  ADD CONSTRAINT sosl_scripts_pk
  PRIMARY KEY (script_id)
  ENABLE
;

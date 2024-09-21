CREATE TABLE sosl_script_group
  ( batch_id        NUMBER(38, 0)   GENERATED ALWAYS AS IDENTITY (NOCACHE NOCYCLE NOMAXVALUE)
  , batch_group_id  NUMBER(38, 0)             NOT NULL
  , script_id       NUMBER(38, 0)             NOT NULL
  , order_nr        NUMBER(4, 0)    DEFAULT 1 NOT NULL
  , description     VARCHAR2(4000)
  )
;

COMMENT ON TABLE sosl_script_group IS 'Relates scripts with a batch group. As long as order_nr is different, a script may be assigned multiple times to a batch group. Equal order_nr mean that those scripts can be executed in parallel. Will use the alias sgrp.';
COMMENT ON COLUMN sosl_script_group.batch_id IS 'Generated unique id for a batch group to script assignement.';
COMMENT ON COLUMN sosl_script_group.batch_group_id IS 'The unique batch group id for the script assignment.';
COMMENT ON COLUMN sosl_script_group.script_id IS 'The unique script id to assign to a batch group.';
COMMENT ON COLUMN sosl_script_group.order_nr IS 'Defines the order in which scripts are executed in a batch group. Scripts with the same order are executed in parallel. Maximum order is 9999. Batch group, script id and order must be unique.';
COMMENT ON COLUMN sosl_script_group.description IS 'Optional description of this batch group script assignment.';

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
  ADD CONSTRAINT fk_sosl_script_group_script_id
  FOREIGN KEY (script_id)
  REFERENCES sosl_script (script_id)
  ON DELETE CASCADE
;
ALTER TABLE sosl_script_group
  ADD CONSTRAINT fk_sosl_script_group_batch_group_id
  FOREIGN KEY (batch_group_id)
  REFERENCES sosl_batch_group (batch_group_id)
  ON DELETE CASCADE
;

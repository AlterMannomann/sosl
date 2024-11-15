-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- requires login with the correct schema, either SOSL or your own SOSL schema
-- requires table to have been created before, as well as used packages
CREATE OR REPLACE TRIGGER sosl_if_script_ins_trg
  BEFORE INSERT ON sosl_if_script
  FOR EACH ROW
BEGIN
  :NEW.created        := SYSDATE;
  :NEW.updated        := NULL;
  :NEW.created_by     := SYS_CONTEXT('USERENV', 'SESSION_USER');
  :NEW.created_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  :NEW.updated_by     := NULL;
  :NEW.updated_by_os  := NULL;
END;
/
CREATE OR REPLACE TRIGGER sosl_if_script_upd_trg
  BEFORE UPDATE ON sosl_if_script
  FOR EACH ROW
BEGIN
  -- make sure created is not changed
  :NEW.created        := :OLD.created;
  :NEW.created_by     := :OLD.created_by;
  :NEW.created_by_os  := :OLD.created_by_os;
  :NEW.updated        := SYSDATE;
  :NEW.updated_by     := SYS_CONTEXT('USERENV', 'SESSION_USER');
  :NEW.updated_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
END;
/
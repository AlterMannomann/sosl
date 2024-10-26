-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- requires login with the correct schema, either SOSL or your own SOSL schema
-- requires table to have been created before, as well as used packages
CREATE OR REPLACE TRIGGER sosl_server_log_ins_trg
  BEFORE INSERT ON sosl_server_log
  FOR EACH ROW
DECLARE
  l_split             BOOLEAN;
  l_self_log_category sosl_server_log.log_category%TYPE     := 'SOSL_TRIGGER';
  l_self_caller       sosl_server_log.caller%TYPE           := 'sosl_server_log_ins_trg';
BEGIN
  -- first set default value if not set, as Oracle does not support default values from package variables
  IF :NEW.log_type = sosl_constants.GEN_NA_TYPE
  THEN
    :NEW.log_type := sosl_constants.LOG_INFO_TYPE;
  END IF;
  -- instead of check constraint to get package support
  IF NOT sosl_log.log_type_valid(:NEW.log_type)
  THEN
    -- do not block logging, log the error instead, move message to full message
    :NEW.full_message := :NEW.message || :NEW.full_message;
    :NEW.message      := 'Invalid log type. Not supported by package SOSL_SYS. Given log type: ' || NVL(:NEW.log_type, sosl_constants.GEN_NULL_TEXT);
    :NEW.log_type     := sosl_constants.LOG_FATAL_TYPE;
  ELSE
    :NEW.log_type := sosl_log.get_valid_log_type(:NEW.log_type);
  END IF;
  :NEW.exec_timestamp := SYSTIMESTAMP;
  :NEW.created_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.created_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  -- split messages
  IF NOT sosl_log.distribute(:NEW.message, :NEW.full_message, 4000)
  THEN
    -- do not block logging, log the error instead, if :NEW.message contains error information leave it there
    IF :NEW.message IS NULL AND :NEW.full_message IS NULL
    THEN
      :NEW.message := 'Full message must be given, if message is NULL or vice versa.';
    END IF;
    :NEW.log_type := sosl_constants.LOG_FATAL_TYPE;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    sosl_log.exception_log(l_self_caller, l_self_log_category, SQLERRM);
    RAISE;
END;
/
CREATE OR REPLACE TRIGGER sosl_server_log_upd_trg
  BEFORE UPDATE ON sosl_server_log
BEGIN
  sosl_log.minimal_error_log( 'sosl_server_log_upd_trg'
                            , 'SOSL_TRIGGER'
                            , '-20000 No updates allowed on a log table.'
                            , 'Forbidden UPDATE on log table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                            )
  ;
  RAISE_APPLICATION_ERROR(-20000, 'No updates allowed on a log table.');
END;
/
CREATE OR REPLACE TRIGGER sosl_server_log_del_trg
  BEFORE DELETE ON sosl_server_log
BEGIN
  sosl_log.minimal_error_log( 'sosl_server_log_del_trg'
                            , 'SOSL_TRIGGER'
                            , '-20001 Delete records from a log table is not allowed. This is an admin job which needs sufficient rights and usage of the SOSL API.'
                            , 'Forbidden DELETE on log table issued by DB user: ' || SYS_CONTEXT('USERENV', 'CURRENT_USER') || ' OS user: ' || SYS_CONTEXT('USERENV', 'OS_USER')
                            )
  ;
  RAISE_APPLICATION_ERROR(-20001, 'Delete records from a log table is not allowed. This is an admin job which needs sufficient rights and usage of the SOSL API.');
END;
/

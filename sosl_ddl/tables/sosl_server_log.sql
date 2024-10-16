-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- requires login with the correct schema, either SOSL or your on schema
-- table is NOT qualified and created in the schema active at execution, columns ordered by access and then space consumption
CREATE TABLE sosl_server_log
  ( exec_timestamp    TIMESTAMP       DEFAULT SYSTIMESTAMP                      NOT NULL
    -- due to Oracle limitations we must use trigger not a package variable, trigger takes care to assign a default INFO log type if getting 'not set'
  , log_type          VARCHAR2(30)    DEFAULT 'not set'                         NOT NULL
  , log_category      VARCHAR2(256)   DEFAULT 'not set'                         NOT NULL
  , message           VARCHAR2(4000)                                            NOT NULL
  , run_id            NUMBER(38, 0)
  , executor_id       NUMBER(38, 0)
  , guid              VARCHAR2(64)
  , sosl_identifier   VARCHAR2(256)
  , caller            VARCHAR2(256)
  , ext_script_id     VARCHAR2(4000)
  , script_file       VARCHAR2(4000)
  , created_by        VARCHAR2(256)   DEFAULT USER                              NOT NULL
  , created_by_os     VARCHAR2(256)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER') NOT NULL
  , full_message      CLOB
  )
  -- monthly partitions
  PARTITION BY RANGE (exec_timestamp)
  INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
  (PARTITION P_OLD
      VALUES LESS THAN (TO_TIMESTAMP('01-01-2024','DD-MM-YYYY'))
  )
;
COMMENT ON TABLE sosl_server_log IS 'Holds the log events of the SOSL server CMD and interaction with the database as well as database events. Update is not allowed. Will use the alias slog.';
COMMENT ON COLUMN sosl_server_log.exec_timestamp IS 'The timestamp of the event. Automatically set by trigger, no set allowed.';
COMMENT ON COLUMN sosl_server_log.log_type IS 'The logging type, supports currently INFO, WARNING, ERROR, FATAL, SUCCESS. Mandatory. Defined in package SOSL_SYS.';
COMMENT ON COLUMN sosl_server_log.log_category IS 'The log writer may provide an short log category description.';
COMMENT ON COLUMN sosl_server_log.message IS 'The shortend log message. Mandatory. If only a CLOB is passed, the short message is build from the CLOB. Categories too long will be cutted.';
COMMENT ON COLUMN sosl_server_log.full_message IS 'The full log message. For messages longer than 4000 bytes or char.';
COMMENT ON COLUMN sosl_server_log.guid IS 'The GUID the process is running with. Can be used as LIKE reference on SOSLERRORLOG.';
COMMENT ON COLUMN sosl_server_log.sosl_identifier IS 'The exact identifier for SOSLERRORLOG if available. No constraints active.';
COMMENT ON COLUMN sosl_server_log.run_id IS 'The associated run id if available. No constraints active.';
COMMENT ON COLUMN sosl_server_log.executor_id IS 'The associated executor id if available. No constraints active.';
COMMENT ON COLUMN sosl_server_log.ext_script_id IS 'The (external) script id if available. No constraints active.';
COMMENT ON COLUMN sosl_server_log.caller IS 'Caller identification if available, to distinguish database processes from SOSL CMD server processes.';
COMMENT ON COLUMN sosl_server_log.created_by IS 'The logged in DB user who created the record, managed by default and trigger.';
COMMENT ON COLUMN sosl_server_log.created_by_os IS 'OS user who created the record, managed by default and trigger.';

-- no primary key, only index
CREATE INDEX sosl_server_log_idx
  ON sosl_server_log (exec_timestamp, log_type, log_category)
;
-- no constraints, as Oracle does not allow package functions in CHECK conditions

-- trigger
CREATE OR REPLACE TRIGGER sosl_server_log_ins_trg
  BEFORE INSERT ON sosl_server_log
  FOR EACH ROW
DECLARE
  l_split BOOLEAN;
BEGIN
  -- first set default value if not set, as Oracle does not support default values from package variables
  IF :NEW.log_type = 'not set'
  THEN
    :NEW.log_type := sosl_sys.INFO_TYPE;
  END IF;
  -- instead of check constraint to get package support
  IF NOT sosl_sys.log_type_valid(:NEW.log_type)
  THEN
    -- do not block logging, log the error instead, move message to full message
    :NEW.full_message := :NEW.message || :NEW.full_message;
    :NEW.message      := 'Invalid log type. Not supported by package SOSL_SYS. Given log type: ' || :NEW.log_type;
    :NEW.log_type     := sosl_sys.FATAL_TYPE;
  ELSE
    :NEW.log_type := sosl_sys.get_valid_log_type(:NEW.log_type);
  END IF;
  :NEW.exec_timestamp := SYSTIMESTAMP;
  :NEW.created_by     := SYS_CONTEXT('USERENV', 'CURRENT_USER');
  :NEW.created_by_os  := SYS_CONTEXT('USERENV', 'OS_USER');
  -- split messages
  IF NOT sosl_sys.distribute(:NEW.message, :NEW.full_message, 4000)
  THEN
    -- do not block logging, log the error instead, if :NEW.message contains error information leave it there
    IF :NEW.message IS NULL AND :NEW.full_message IS NULL
    THEN
      :NEW.message := 'Full message must be given, if message is NULL or vice versa.';
    END IF;
    :NEW.log_type := sosl_sys.FATAL_TYPE;
  END IF;
END;
/
CREATE OR REPLACE TRIGGER sosl_server_log_upd_trg
  BEFORE UPDATE ON sosl_server_log
  FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20005, 'No updates allowed on a log table.');
END;
/
CREATE OR REPLACE TRIGGER sosl_server_log_del_trg
  BEFORE DELETE ON sosl_server_log
  FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20006, 'Delete records from a log table is not allowed. This is an admin job which needs sufficient rights.');
END;
/

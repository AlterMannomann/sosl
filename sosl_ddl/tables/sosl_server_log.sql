CREATE TABLE sosl_server_log
  ( exec_timestamp    TIMESTAMP       DEFAULT SYSTIMESTAMP  NOT NULL
  , log_type          VARCHAR2(30)    DEFAULT 'INFO'        NOT NULL
  , message           VARCHAR2(4000)  NOT NULL
  , full_message      CLOB
  , guid              VARCHAR2(64)
  , sosl_identifier   VARCHAR2(256)
  , caller            VARCHAR2(256)
  )
  -- monthly partitions
  PARTITION BY RANGE (exec_timestamp)
  INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
  (PARTITION P_OLD
      VALUES LESS THAN (TO_TIMESTAMP('01-01-2024','DD-MM-YYYY'))
  )
;
COMMENT ON TABLE sosl_server_log IS 'Holds the log events of the SOSL server CMD and interaction with the database. Update is not allowed. Will use the alias slog.';
COMMENT ON COLUMN sosl_server_log.exec_timestamp IS 'The timestamp of the event. Automatically set by trigger, no update allowed.';
COMMENT ON COLUMN sosl_server_log.log_type IS 'The logging type, supports INFO, WARNING, ERROR, FATAL, SUCCESS. Mandatory.';
COMMENT ON COLUMN sosl_server_log.message IS 'The shortend log message. Mandatory. If only a CLOB is passed, the short message is build from the CLOB.';
COMMENT ON COLUMN sosl_server_log.full_message IS 'The full log message. For messages longer than 4000 bytes or char.';
COMMENT ON COLUMN sosl_server_log.guid IS 'The GUID the process is running with. Can be used as LIKE reference on SOSLERRORLOG.';
COMMENT ON COLUMN sosl_server_log.sosl_identifier IS 'The exact identifier for SOSLERRORLOG if available.';
COMMENT ON COLUMN sosl_server_log.caller IS 'Caller identification if available, to distinguish database processes from SOSL CMD server processes.';
-- no primary key, only index
CREATE INDEX sosl_server_log_idx
  ON sosl_server_log (exec_timestamp)
;
-- constraints
ALTER TABLE sosl_server_log
  ADD CONSTRAINT sosl_server_log_chk_type
  CHECK (log_type IN ('INFO', 'WARNING', 'ERROR', 'FATAL', 'SUCCESS'))
;
-- trigger
CREATE OR REPLACE TRIGGER sosl_server_log_ins_trg
  BEFORE INSERT ON sosl_server_log
  FOR EACH ROW
BEGIN
  :NEW.exec_timestamp := SYSTIMESTAMP;
  IF (:NEW.message IS NULL)
  THEN
    IF :NEW.full_message IS NOT NULL
    THEN
      IF LENGTH(TRIM(:NEW.full_message)) > 4000
      THEN
        :NEW.message := TO_CHAR(SUBSTR(TRIM(:NEW.full_message), 1, 3996)) || ' ...';
      ELSE
        :NEW.message := TO_CHAR(TRIM(:NEW.full_message));
      END IF;
    ELSE
      RAISE_APPLICATION_ERROR(-20003, 'Full message must be given, if message is NULL.');
    END IF;
  END IF;
END;
/
CREATE OR REPLACE TRIGGER sosl_server_log_upd_trg
  BEFORE UPDATE ON sosl_server_log
  FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20004, 'No updates allowed on a log table.');
END;
/

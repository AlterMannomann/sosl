-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
-- requires login with the correct schema, either SOSL or your own SOSL schema
-- table is NOT qualified and created in the schema active at execution, equals SPERRORLOG
CREATE TABLE soslerrorlog
  ( username    VARCHAR2(256)
  , timestamp   TIMESTAMP
    -- older versions than Oracle 23 use VARCHAR2(1024)
  , script      CLOB          -- VARCHAR2(1024)
  , identifier  VARCHAR2(256)
  , message     CLOB
  , statement   CLOB
  )
;
COMMENT ON TABLE soslerrorlog IS 'Userdefined table for SQLPlus error logging';
COMMENT ON COLUMN soslerrorlog.username IS 'Oracle account name';
COMMENT ON COLUMN soslerrorlog.timestamp IS 'Time when the error occurred';
COMMENT ON COLUMN soslerrorlog.script IS 'Name of the originating script if applicable';
COMMENT ON COLUMN soslerrorlog.identifier IS 'User defined identifier string';
COMMENT ON COLUMN soslerrorlog.message IS 'ORA, PLA or SP2 error message. No feed back messages are included. For example, "PL/SQL Block Created" is not recorded.';
COMMENT ON COLUMN soslerrorlog.statement IS 'The statement causing the error';
-- Grants, inherited by others, no guest and user access on tables
GRANT SELECT ON soslerrorlog TO sosl_reviewer;
GRANT DELETE ON soslerrorlog TO sosl_admin;

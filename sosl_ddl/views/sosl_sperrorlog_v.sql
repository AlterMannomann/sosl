-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE VIEW sosl_sperrorlog_v
AS
  SELECT TO_CHAR(timestamp, 'YYYY-MM-DD HH24:MI:SS.FF9') AS exec_time
       , username
       , script
       , identifier
       , message
       , statement
       , timestamp AS exec_timestamp
    FROM soslerrorlog
   ORDER BY timestamp DESC
;
GRANT SELECT ON sosl_sperrorlog_v TO sosl_user;

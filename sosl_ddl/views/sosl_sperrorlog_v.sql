-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE VIEW sosl_sperrorlog_v
AS
  SELECT exec_time
       , username
       , script
       , identifier
       , message
       , statement
       , exec_timestamp
    FROM (SELECT TO_CHAR(timestamp, 'YYYY-MM-DD HH24:MI:SS.FF9') AS exec_time
               , username
               , script
               , identifier
               , message
               , statement
               , timestamp AS exec_timestamp
            FROM soslerrorlog
           UNION ALL
             -- include setup log
          SELECT TO_CHAR(timestamp, 'YYYY-MM-DD HH24:MI:SS.FF9') AS exec_time
               , username
               , script
               , identifier
               , message
               , statement
               , timestamp AS exec_timestamp
            FROM sperrorlog
           WHERE username = (SELECT sosl_schema FROM sosl_install_v)
         )
   ORDER BY exec_timestamp DESC
;
GRANT SELECT ON sosl_sperrorlog_v TO sosl_user;

-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE VIEW sosl_run_stats_by_executor_v
AS
    WITH run_stats AS
         (SELECT /*+MATERIALIZE*/
                 executor_id
               , run_state
               , COUNT(*) AS script_count
            FROM sosl_run_queue
           GROUP BY executor_id
                  , run_state
         )
  SELECT sed.executor_name
       , sosl_constants.run_state_text(run_stats.run_state) AS run_state
       , run_stats.script_count
       , run_stats.executor_id
       , run_stats.run_state                                AS run_state_num
    FROM run_stats
    LEFT OUTER JOIN sosl_executor_definition sed
      ON run_stats.executor_id = sed.executor_id
   ORDER BY run_stats.run_state
          , run_stats.executor_id
;
GRANT SELECT ON sosl_run_stats_by_executor_v TO sosl_user;
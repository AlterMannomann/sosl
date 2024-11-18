-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE VIEW sosl_run_stats_total_v
AS
    WITH run_states AS
         (SELECT -1 AS run_state FROM dual
           UNION ALL
          SELECT 0 AS run_state FROM dual
           UNION ALL
          SELECT 1 AS run_state FROM dual
           UNION ALL
          SELECT 2 AS run_state FROM dual
           UNION ALL
          SELECT 3 AS run_state FROM dual
           UNION ALL
          SELECT 4 AS run_state FROM dual
         )
       , run_stats AS
         (SELECT /*+MATERIALIZE*/
                 run_state
               , COUNT(*) AS script_count
            FROM sosl_run_queue
           GROUP BY run_state
         )
  SELECT sosl_constants.run_state_text(run_states.run_state)  AS run_state
       , NVL(run_stats.script_count, 0)                       AS script_count
       , run_states.run_state                                 AS run_state_num
    FROM run_states
    LEFT OUTER JOIN run_stats
      ON run_states.run_state = run_stats.run_state
   ORDER BY run_states.run_state
;
GRANT SELECT ON sosl_run_stats_total_v TO sosl_user;
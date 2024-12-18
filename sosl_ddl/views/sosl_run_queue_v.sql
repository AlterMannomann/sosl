-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- and https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1
-- Not allowed to be used as AI training material without explicite permission.
CREATE OR REPLACE VIEW sosl_run_queue_v
AS
  SELECT srq.run_id
       , sed.executor_name
       , srq.script_file
       , sosl_constants.run_state_text(srq.run_state)             AS run_state
       , srq.ext_script_id
       , TO_CHAR(srq.created, 'YYYY-MM-DD HH24:MI:SS.FF9')        AS created
       , TO_CHAR(srq.waiting, 'YYYY-MM-DD HH24:MI:SS.FF9')        AS waiting
       , TO_CHAR(srq.enqueued, 'YYYY-MM-DD HH24:MI:SS.FF9')       AS enqueued
       , TO_CHAR(srq.started, 'YYYY-MM-DD HH24:MI:SS.FF9')        AS started
       , TO_CHAR(srq.running_since, 'YYYY-MM-DD HH24:MI:SS.FF9')  AS running_since
       , TO_CHAR(srq.finished, 'YYYY-MM-DD HH24:MI:SS.FF9')       AS finished
       , srq.created_by
       , srq.waiting_by
       , srq.enqueued_by
       , srq.started_by
       , srq.running_by
       , srq.finished_by
       , srq.created_by_os
       , srq.waiting_by_os
       , srq.enqueued_by_os
       , srq.started_by_os
       , srq.running_by_os
       , srq.finished_by_os
       , srq.executor_id
       , srq.run_state                                            AS run_state_num
    FROM sosl_run_queue srq
    LEFT OUTER JOIN sosl_executor_definition sed
      ON srq.executor_id = sed.executor_id
   -- first all scripts pending or running
   ORDER BY srq.run_state
          , srq.created DESC
;
GRANT SELECT ON sosl_run_queue_v TO sosl_user;
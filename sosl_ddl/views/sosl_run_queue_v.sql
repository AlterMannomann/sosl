CREATE OR REPLACE VIEW sosl_run_queue_v
AS
  SELECT srq.script_file
       , sosl_constants.run_state_text(srq.run_state) AS run_state
       , srq.run_id
       , srq.ext_script_id
       , sed.executor_name
       , srq.created
       , srq.waiting
       , srq.enqueued
       , srq.started
       , srq.running_since
       , srq.finished
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
       , srq.run_state AS run_state_num
    FROM sosl_run_queue srq
    LEFT OUTER JOIN sosl_executor_definition sed
      ON srq.executor_id = sed.executor_id
   ORDER BY created DESC
;
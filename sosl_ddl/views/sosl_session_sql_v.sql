-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
-- Short version of GV$SQL
CREATE OR REPLACE VIEW sosl_session_sql_v
AS
  SELECT sql_id
       , last_active_time
       , object_status
       , optimizer_mode
       , rows_processed
       , SUBSTR(REGEXP_REPLACE(sql_text, '\s{2,}', ' '), 1, 80) || '...' AS short_sql
       , parsing_schema_name
       , service
       , child_number
       , optimizer_cost
       , cpu_time
       , elapsed_time
       , locked_total
       , pinned_total
       , physical_read_bytes
       , physical_write_bytes
       , inst_id
       , con_id
       , module
       , action
       , module_hash
       , action_hash
       , sql_text
       , sql_fulltext
    FROM gv$sql
;
GRANT SELECT ON sosl_session_sql_v TO sosl_user;

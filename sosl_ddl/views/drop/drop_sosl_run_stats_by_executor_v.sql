-- (C) 2024 Michael Lindenau licensed via https://www.gnu.org/licenses/agpl-3.0.txt
-- Not allowed to be used as AI training material without explicite permission.
REVOKE SELECT ON sosl_run_stats_by_executor_v FROM sosl_user;
DROP VIEW sosl_run_stats_by_executor_v;
# Views
This folder contains the view definitions for the Simple Oracle Script Loader.

- [SOSL_USER views](#views-for-sosl_user-role)
- [SOSL_ADMIN views](#views-for-sosl_admin-role)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../../README.md)

## Views for SOSL_USER role
Any user with the SOSL_USER role can access this views.

- [SOSL_CONFIG_V](sosl_config_v.sql): Shows the current configuration settings of SOSL
- [SOSL_EXECUTORS_V](sosl_executors_v.sql): Shows details about the current defined executors
- [SOSL_ROLE_PRIVS_V](sosl_role_privs_v.sql): Shows details on current SOSL role privileges
- [SOSL_RUN_QUEUE_V](sosl_run_queue_v.sql): Shows details of the SOSL run queue
- [SOSL_RUN_STATS_BY_EXECUTOR_V](sosl_run_stats_by_executor_v.sql): Shows run statistics grouped by executors
- [SOSL_RUN_STATS_TOTAL_V](sosl_run_stats_total_v.sql): Shows overall SOSL run statistics
- [SOSL_SERVER_LOG_V](sosl_server_log_v.sql): Shows details of the SOSL server logging
- [SOSL_SESSIONS_V](sosl_sessions_v.sql): Shows some SOSL related session details from GV$SESSION and GV$SQL
- [SOSL_SESSION_SQL_V](sosl_session_sql_v.sql): Maps some columns from GV$SQL for analysis
- [SOSL_SPERRORLOG_V](sosl_sperrorlog_v.sql): Shows execution errors from SQLPlus executions of scripts
## Views for SOSL_ADMIN role
You need SOSL_ADMIN role to access this views.

- [SOSL_SESSIONS_ADMIN_V](sosl_sessions_admin_v.sql): Maps complete GV$SESSION content
- [SOSL_SESSION_SQL_ADMIN_V](sosl_session_sql_admin_v.sql): Maps complete GV$SQL content
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).
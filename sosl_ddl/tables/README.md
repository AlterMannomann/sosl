# SOSL tables
This folder contains the table definitions for the Simple Oracle Script Loader.

- [SOSL_EXECUTOR_DEFINITION](#sosl_executor_definition)
- [SOSL_RUN_QUEUE](#sosl_run_queue)
- [SOSL_CONFIG](#sosl_config)
- [SOSL_SERVER_LOG](#sosl_server_log)
- [SOSLERRORLOG](#soslerrorlog)
- [SOSL_IF_SCRIPT](#sosl_if_script)
- [Disclaimer](#disclaimer)
- [AI disclosure](#ai-restriction-and-training-exclusion)
- [Back to main](../../README.md)

Table scripts contain most of the table definition apart from trigger. Those are created later and depend on the SOSL packages. Every table has a complete comment definition accessible in the script and the database.
Where needed, extra comments are placed in the script.

Every table script contains also the needed role grants or revokes.

The [drop folder](drop/README.md) contains all drop scripts needed for the SOSL cleanup. The install and uninstall scripts ensure that the drop scripts are called in correct order.
## SOSL_EXECUTOR_DEFINITION
This table contains the basic definition for executors that run on SOSL. Script [sosl_executor_definition.sql](sosl_executor_definition.sql). No direct dependencies on other tables.

The primary key is EXECUTOR_ID. The EXECUTOR_NAME has to be unique.

Values for DB_USER and FUNCTION_OWNER do not support case-sensitive database user names. Values will be used in upper-case for queries on the user. Once verified and set, these values are final. To change the values, create a new executor. If you want to avoid to lose the run history of an executor just set it to inactive (EXECUTOR_ACTIVE = 0 and/or EXECUTOR_REVIEWED = 0) instead of deleting the executor.
## SOSL_RUN_QUEUE
This table contains the script runs and results as seen from the SOSL server. Script [sosl_run_queue.sql](sosl_run_queue.sql). The effects and results for any executor maybe different, as SOSL does not take care about executor dependencies. It only tries to execute the scripts in this table.

Supported values for column RUN_STATE
- 0 Waiting
- 1 Enqueued
- 2 Started
- 3 Running
- 4 Finished
- -1 Error

Apart from Error which can be applied at any RUN_STATE, the RUN_STATE must be applied in the correct order as listed. One way street, no rerun possible or intended. Queue the script again after fixing it to rerun a script.

There is a strong foreign key using EXECUTOR_ID (NOT NULL) on table SOSL_EXECUTOR_DEFINITION, which will delete all referenced data, if an executor is deleted.

The internal SOSL primary key is RUN_ID. The ID provided by the executor is in EXT_SCRIPT_ID.
## SOSL_CONFIG
This table contains some basic configuration data, where some of the configurations can be used to influence the behavior of the SOSL server. Script [sosl_config.sql](sosl_config.sql).

The primary key is CONFIG_NAME. No direct dependencies on other tables. Every configuration has an explaining column comment describing the configuration.

The configurations are stored as CONFIG_NAME:CONFIG_VALUE pairs. The basic script creating the configuration is stored in [setup/sosl_config_defaults.sql](../../setup/sosl_config_defaults.sql).

The main CONFIG_NAME values for influencing the SOSL server are:
### SOSL_RUNMODE
Allowed values **RUN**, **PAUSE**, **STOP**. If the server is stopped by database configuration it must be manually started again on the server the SOSL server is running. If the server is paused, it will wait for defined SOSL_PAUSE_WAIT time, before checking again the database against configuration changes. In RUN mode the server will wait for incoming scripts and execute them.
### SOSL_MAX_PARALLEL
**Integer** value, **default 8**. The amount of possible parallel processes depends on your server and memory. Test server memory used for a single process to determine the possible maximum for parallel script execution (one sqlplus instance per execution).
### SOSL_DEFAULT_WAIT
**Integer** value, **default 1**. The amount of seconds between database calls if scripts are available.
### SOSL_NOJOB_WAIT
**Integer** value, **default 120**. The amount of seconds between database calls if no scripts are available.
### SOSL_PAUSE_WAIT
**Integer** value, **default 3600**. The amount of seconds between database calls if SOSL_RUNMODE is set to PAUSE.
### SOSL_START_JOBS
**String** in the date format HH24:MI, **default 08:00**. Defines the time the server starts to get active. Relates to the server time on the server SOSL is running as CMD or bash. This may differ from the database time.

The default settings mean in fact, that the server will start to get active on 08:05. See SOSL_STOP_JOBS.

Daybreak is supported, so you might set start to 22:00 and end to 04:05.
### SOSL_STOP_JOBS
**String** in the date format HH24:MI, **default 18:05**. Defines the time the server stops activity and goes to PAUSE mode. Relates to the server time on the server SOSL is running as CMD or bash. This may differ from the database time.

The SOSL_PAUSE_WAIT time has to be taken into account for calculating the start and end time. From SOSL_STOP_JOBS time on the server will switch to SOSL_PAUSE_WAIT time, means for the default, that the server will check every hour if the start time is reached. There should be a small overlap to ensure that server activity is started correctly. So by default the server will check at 08:05 if the start time is reached, which is true at that moment, as SOSL_START_JOBS is set to 08:00. If the overlap is to small, the server might start an hour later as expected.

It will not connect to the database during this time.

Daybreak is supported, so you might set start to 22:00 and end to 04:05.
### Other values
The rest of the configurations is maintained by the SOSL CMD/bash server and information only.
## SOSL_SERVER_LOG
The table contains the main log entries from the server and the database. Script [sosl_server_log.sql](sosl_server_log.sql).

No primary key defined, only an index. Most of the columns are not constrained at all. Only a few NOT NULL constraints. Which log entries are filled is up to the writers of the log.
## SOSLERRORLOG
This table is a version of SPERRORLOG which is only used by SOSL. Script [soslerrorlog.sql](soslerrorlog.sql).

It is used to record all SQLPlus errors that happened while script execution.
## SOSL_IF_SCRIPT
This is an optional table not required for SOSL to work. It is just a simple possibility to configure and start scripts in a defined order. No dependency management. Very basic. Script [sosl_if_script.sql](sosl_if_script.sql).

Primary key is SCRIPT_ID. It sets a weak foreign key (EXECUTOR_ID can be NULL) on SOSL_EXECUTOR_DEFINITION.

Basically this table is for testing and provides an interface example for own implementations.
## Disclaimer
Use this software at your own risk. No liabilities or warranties are given, no support is guaranteed. Any result of executing this software is under the responsibility of the legal entity using this software. For details see license.

&copy; 2024 Michael Lindenau licensed via [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) and [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1)

# AI restriction and training exclusion
**This content is intended ONLY for the HUMAN community NOT for any technical crawlers or AI training input.**

As currently no tools or tags exist to effectively exclude AI from using this content, the author and creator **forbids hereby the usage of this content for AI training purposes**. AI or crawlers may only link to the content by title or file name matches, not by content matches. Human beings, which includes companies represented by human beings, have all the rights disclaimed by [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.txt) apart from using it for any AI training.

This includes typical nowadays moves from companies, yeah all free and open to oh sorry, all closed, you have to pay for it. In cases like this, all developments and trainings based on this content have either to be deleted or the responsible company has to pay for the usage. See [Generic AI Disclosure License](https://toent.ch/licenses/AI_DISCLOSURE_LICENSE_V1).